/* ============================================================
   Lirich — read-only client REPORT function.
   Returns one client's dashboard data from the SSOT (collections),
   so the client portal shows LIVE numbers instead of hardcoded JSON.

   GET ?token=<WP-signed>                    → the token's own client (scoped; ?client ignored)
   GET ?token=<ALL-admin>&client=PIL         → admin selects a client (token client_id=ALL)
   GET ?client=PIL&key=<READ_KEY>            → LEGACY, DISABLED in Step D (29 Jul 2026) → 403

   Carbon is intentionally NOT computed here — the function returns raw
   SSOT aggregates (volumes, per-category m3, tonnage, counts, per-vessel/site);
   the dashboard keeps its own carbon methodology (1 m3 = 1000 kg, 0.35 tCO2e/t
   WtE on disposal, recovery = avoided) and just feeds it live data.

   Security (beta): gated by READ_KEY. RLS-on DB + read-only + the WordPress
   login gate in front. ⚠ A logged-in user could still request another client's
   id — multi-tenant hardening (WP-signed per-client token verified here) is the
   next step (task #16) before onboarding client #2.
   ============================================================ */
import { createClient } from "npm:@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const READ_KEY = Deno.env.get("READ_KEY") || Deno.env.get("DEVICE_KEY") || "";
/* HMAC secret shared with WordPress (WP signs a per-user token, we verify it). Server-side only. */
const LR_TOKEN_SECRET = Deno.env.get("LR_TOKEN_SECRET") || "";
/* Legacy client-visible READ_KEY as a data-auth path — kept ONLY during rollout so the
   currently-live page keeps working until it uses tokens. Step D (29 Jul 2026) set this to
   false: page 2691 now sends WP-signed tokens (verified live), so the READ_KEY branch is
   dead and the cross-client hole is closed — signed tokens are the ONLY auth. (task #16) */
const LEGACY_KEY_ENABLED = false;

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { "content-type": "application/json", ...CORS } });

const n2 = (v: number) => Math.round((v || 0) * 100) / 100;

/* ============================================================
   CARBON ENGINE — single source of truth.
   The front-ends (PIL dashboard + catalog Waste reports) render these
   finished numbers; they do NO carbon math of their own.

   Model (indicative, from measured volume; 1 m3 = 1,000 kg):
     garbage = cat A(plastics)+B(food)+C(domestic)+F(operational)  → non-sludge
     oily    = cat D (cooking oil)     ash = cat E (ashes)
     sludge  = read from SSOT (0 today — no May/Jun PIL sludge in the invoices;
               loads later and auto-flows through recovery/avoided)
     recovered = RECYCLE_ASSUMPTION*garbage + oily + sludge
     disposal  = waste_handled - recovered            (0.9*garbage + ash → WtE)
     cat5 (Scope 3 Cat 5)  = disposal * EF_WTE
     avoided               = recovered * AV_RECOVER
     recovery%             = recovered / waste_handled * 100
   Every figure is INDICATIVE / estimated from volume. The 10% is an
   assumption, not measured (Michelle, 27 Jul 2026). ============ */
const RECYCLE_ASSUMPTION = 0.10; // beta placeholder: 10% of vessel non-sludge (garbage) waste assumed recycled/recovered, pending per-collection disposal route. Indicative, not measured.
const EF_WTE_DEFAULT = 0.35;     // tCO2e/t — Singapore general waste to Waste-to-Energy. Indicative; verify vs NEA GHG M&R.
const AV_RECOVER_DEFAULT = 0.90; // tCO2e/t avoided by diverting to recovery instead of WtE. Indicative.

type Factors = {
  ef_wte: number; av_recover: number; source: string;
  ef_factor: unknown; av_factor: unknown; factors_available?: unknown;
};

/* Pin the carbon factors from the `factors` table DETERMINISTICALLY (audit-safe):
   - candidates are sorted by a stable key first, so selection never depends on DB row order;
   - WtE/disposal factor := the general-waste incineration/WtE row (~0.35);
   - avoided factor := the GENERAL-waste diversion/avoided row explicitly (~0.46), not
     whichever avoided row happens to be first (paper/plastic/metal are higher);
   - the exact rows used are returned in ef_factor/av_factor for the audit trail;
   - falls back to the documented defaults only if no row matches. */
async function loadFactors(): Promise<Factors> {
  let ef_wte = EF_WTE_DEFAULT, av_recover = AV_RECOVER_DEFAULT, source = "default";
  let ef_factor: any = null, av_factor: any = null, available: any[] = [];
  try {
    const { data } = await supa.from("factors").select("*");
    available = ((data || []) as any[]).slice()
      .sort((a, b) => JSON.stringify(a).localeCompare(JSON.stringify(b))); // stable, DB-order-independent
    const num = (r: any) => {
      for (const k of ["value", "factor", "value_kg", "kgco2e", "ef", "amount"]) {
        const v = Number(r?.[k]); if (Number.isFinite(v) && v > 0) return v;
      } return NaN;
    };
    const blob = (r: any) => JSON.stringify(r).toLowerCase();
    // WtE / incineration disposal factor for general waste (~0.35 tCO2e/t)
    ef_factor = available.find((r) => /wte|waste.?to.?energy|inciner/.test(blob(r)) && num(r) > 0.15 && num(r) < 0.6);
    // Avoided-by-diversion factor for GENERAL waste specifically (~0.46); fall back to any avoided row
    av_factor = available.find((r) => /avoid|divert|recover/.test(blob(r)) && /general/.test(blob(r)) && num(r) > 0 && num(r) < 5)
      || available.find((r) => /avoid|divert|recover/.test(blob(r)) && num(r) > 0 && num(r) < 5);
    if (ef_factor) { ef_wte = num(ef_factor); source = "factors"; }
    if (av_factor) { av_recover = num(av_factor); source = "factors"; }
  } catch (_e) { /* keep defaults */ }
  return { ef_wte, av_recover, source, ef_factor, av_factor, factors_available: available };
}

/* cats are in m3; density 1 m3 = 1,000 kg so tonnes == m3 numerically */
function carbonFrom(
  cat: { garbage: number; oily: number; ash: number; sludge: number },
  f: Factors,
) {
  const garbage_t = cat.garbage, oily_t = cat.oily, ash_t = cat.ash, sludge_t = cat.sludge || 0;
  const waste_handled_t = garbage_t + oily_t + ash_t + sludge_t;
  const recovered_t = RECYCLE_ASSUMPTION * garbage_t + oily_t + sludge_t;
  const disposal_t = Math.max(0, waste_handled_t - recovered_t);
  const cat5_tco2e = disposal_t * f.ef_wte;
  const avoided_tco2e = recovered_t * f.av_recover;
  const recovery_pct = waste_handled_t > 0 ? recovered_t / waste_handled_t * 100 : 0;
  return {
    waste_handled_t: n2(waste_handled_t),
    recovered_t: n2(recovered_t),
    diverted_t: n2(recovered_t),
    disposal_t: n2(disposal_t),
    recovery_pct: Math.round(recovery_pct),
    cat5_tco2e: n2(cat5_tco2e),
    avoided_tco2e: n2(avoided_tco2e),
    recycle_assumption_pct: RECYCLE_ASSUMPTION * 100,
    basis: "indicative — estimated from volume",
  };
}

async function clientReport(clientId: string) {
  const { data: cust } = await supa.from("customers").select("name").eq("client_id", clientId).maybeSingle();
  const { data: sites } = await supa.from("sites").select("site_id").eq("client_id", clientId);
  const siteIds = (sites || []).map((s: any) => s.site_id);
  if (!siteIds.length) return { client: clientId, name: cust?.name || clientId, empty: true };

  const { data: rows } = await supa.from("collections")
    .select("do_no,do_date,do_type,trip_type,vessel_name,waste_type,vol_cat_a,vol_cat_b,vol_cat_c,vol_cat_d,vol_cat_e,vol_cat_f,vol_total_m3,net_kg,sludge_requested_t,sludge_actual_t,source")
    .in("site_id", siteIds)
    .order("do_date");

  const months: Record<string, any> = {};
  const vessels: Record<string, any> = {};
  /* per-collection rows in the PIL dashboard's DATA shape, so the front-end can
     drop them in unchanged. Cat mapping: garbage = A plastics + B food + C domestic
     + F operational; oily = D cooking oil; ash = E ashes. Sludge (reqS/actS) is read
     from the SSOT sludge columns — 0 until the PIL invoices are backfilled, then it
     auto-flows into recovery/avoided with no code change. */
  const data: Record<string, any[]> = {};
  const sn: Record<string, number> = {};
  let totVol = 0, totNet = 0, totDos = 0;
  for (const r of (rows || []) as any[]) {
    const mk = (r.do_date || "").slice(0, 7) || "unknown";
    const garbage = (Number(r.vol_cat_a) || 0) + (Number(r.vol_cat_b) || 0) + (Number(r.vol_cat_c) || 0) + (Number(r.vol_cat_f) || 0);
    const oily = Number(r.vol_cat_d) || 0;
    const ash = Number(r.vol_cat_e) || 0;
    /* sludge from the SSOT columns (nullable → 0 until the PIL invoices are backfilled) */
    const reqS = Number(r.sludge_requested_t) || 0;
    const actS = Number(r.sludge_actual_t) || 0;
    (data[mk] = data[mk] || []).push({
      sn: (sn[mk] = (sn[mk] || 0) + 1), date: r.do_date, vessel: r.vessel_name || "", port: r.berth || "",
      voy: "", garbage: n2(garbage), oily: n2(oily), ash: n2(ash), reqS: n2(reqS), actS: n2(actS),
    });
    const m = months[mk] || (months[mk] = { month: mk, dos: 0, volume_m3: 0, net_t: 0, vessels: new Set(),
      cat_a: 0, cat_b: 0, cat_c: 0, cat_d: 0, cat_e: 0, cat_f: 0, reqS: 0, actS: 0 });
    m.dos++; totDos++;
    const vol = Number(r.vol_total_m3) || 0; m.volume_m3 += vol; totVol += vol;
    const net = (Number(r.net_kg) || 0) / 1000; m.net_t += net; totNet += net;
    m.cat_a += Number(r.vol_cat_a) || 0; m.cat_b += Number(r.vol_cat_b) || 0; m.cat_c += Number(r.vol_cat_c) || 0;
    m.cat_d += Number(r.vol_cat_d) || 0; m.cat_e += Number(r.vol_cat_e) || 0; m.cat_f += Number(r.vol_cat_f) || 0;
    m.reqS += reqS; m.actS += actS;
    if (r.vessel_name) { m.vessels.add(r.vessel_name);
      const v = vessels[r.vessel_name] || (vessels[r.vessel_name] = { vessel: r.vessel_name, dos: 0, volume_m3: 0 });
      v.dos++; v.volume_m3 += vol; }
  }
  const f = await loadFactors();
  /* cat volumes → the carbon engine's category buckets (m3, == tonnes at 1 m3=1t).
     sludge = actual recovered sludge from the SSOT (0 until backfilled). */
  const cats = (m: any) => ({
    garbage: (m.cat_a || 0) + (m.cat_b || 0) + (m.cat_c || 0) + (m.cat_f || 0),
    oily: m.cat_d || 0, ash: m.cat_e || 0, sludge: m.actS || 0,
  });
  const monthly = Object.values(months).map((m: any) => ({
    month: m.month, dos: m.dos, volume_m3: n2(m.volume_m3), net_t: n2(m.net_t), vessels: m.vessels.size,
    cat_a_plastics: n2(m.cat_a), cat_b_food: n2(m.cat_b), cat_c_domestic: n2(m.cat_c),
    cat_d_oil: n2(m.cat_d), cat_e_ashes: n2(m.cat_e), cat_f_operational: n2(m.cat_f),
    sludge_requested_t: n2(m.reqS), sludge_actual_t: n2(m.actS),
    carbon: carbonFrom(cats(m), f),
  })).sort((a, b) => a.month.localeCompare(b.month));

  /* totals carbon = engine over the summed categories across all months */
  const totCat = Object.values(months).reduce((acc: any, m: any) => {
    const c = cats(m); acc.garbage += c.garbage; acc.oily += c.oily; acc.ash += c.ash; acc.sludge += c.sludge; return acc;
  }, { garbage: 0, oily: 0, ash: 0, sludge: 0 });
  const totReqS = Object.values(months).reduce((s: number, m: any) => s + (m.reqS || 0), 0);
  const totActS = Object.values(months).reduce((s: number, m: any) => s + (m.actS || 0), 0);

  return {
    client: clientId,
    name: cust?.name || clientId,
    generated_at: new Date().toISOString(),
    basis: "Indicative from measured volume. Client standard 1 m3 = 1,000 kg. Carbon computed by this report layer (single source).",
    assumptions: `Carbon indicative / estimated from volume. Recovery includes a provisional ${RECYCLE_ASSUMPTION * 100}% recycled/recovered assumption on vessel non-sludge waste — not measured, pending per-collection disposal route. No sludge in the current SSOT.`,
    factors_used: f,
    totals: { dos: totDos, volume_m3: n2(totVol), net_t: n2(totNet), months: monthly.length,
      vessels: Object.keys(vessels).length, sludge_requested_t: n2(totReqS), sludge_actual_t: n2(totActS),
      carbon: carbonFrom(totCat, f) },
    monthly,
    vessels: Object.values(vessels).map((v: any) => ({ vessel: v.vessel, dos: v.dos, volume_m3: n2(v.volume_m3) }))
      .sort((a, b) => b.volume_m3 - a.volume_m3),
    /* month -> per-collection rows, matching the dashboard's hardcoded DATA shape */
    data,
  };
}

/* ---- WP-signed token: verify + scope (task #16) ----
   token = base64(client_id + "|" + expiry_unix) + "." + HMAC_SHA256_hex(payload, SECRET)
   WP signs it with hash_hmac('sha256', payload, SECRET); we recompute and compare. */
async function hmacHex(msg: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(msg));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
function timingSafeEq(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0;
  for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}
async function verifyToken(token: string): Promise<{ client_id: string } | null> {
  if (!token || !LR_TOKEN_SECRET) return null;
  const dot = token.lastIndexOf(".");
  if (dot <= 0) return null;
  const payload = token.slice(0, dot), sig = token.slice(dot + 1).toLowerCase();
  const expected = await hmacHex(payload, LR_TOKEN_SECRET);
  if (!timingSafeEq(sig, expected)) return null; // forged / tampered
  let decoded: string;
  try { decoded = atob(payload); } catch { return null; }
  const parts = decoded.split("|");
  if (parts.length !== 2) return null;
  const cid = parts[0].trim().toUpperCase();
  const exp = Number(parts[1]);
  if (!cid || !Number.isFinite(exp)) return null;
  if (Math.floor(Date.now() / 1000) > exp) return null; // expired
  return { client_id: cid };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  const reqClient = (url.searchParams.get("client") || "").toUpperCase();
  const reqAdmin = url.searchParams.get("admin") === "1";

  /* AUTH: prefer the WP-signed token (scopes to one client, overrides ?client).
     Legacy READ_KEY is a temporary fallback for rollout only — removed in Step D. */
  const tok = await verifyToken(url.searchParams.get("token") || "");
  let scoped: string, isAdmin = false, authMode: string;
  if (tok) {
    authMode = "token";
    if (tok.client_id === "ALL") { isAdmin = true; scoped = reqClient; } // admin may select
    else { scoped = tok.client_id; } // FORCE this client — ?client is ignored entirely
  } else if (LEGACY_KEY_ENABLED && READ_KEY && (url.searchParams.get("key") || "") === READ_KEY) {
    authMode = "legacy-key";
    scoped = reqClient;
    isAdmin = reqAdmin;
  } else {
    return json({ error: "unauthorized" }, 403);
  }

  try {
    if (isAdmin && (scoped === "ALL" || !scoped)) {
      const { data: custs } = await supa.from("customers").select("client_id").eq("active", true);
      const out: any[] = [];
      for (const c of (custs || []) as any[]) out.push(await clientReport(c.client_id));
      return json({ auth: authMode, clients: out.filter((r) => !r.empty) });
    }
    if (!scoped) return json({ error: "client required" }, 400);
    const rep = await clientReport(scoped) as Record<string, unknown>;
    rep.auth = authMode;
    return json(rep);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
