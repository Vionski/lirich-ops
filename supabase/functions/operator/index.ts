/* ============================================================
   Lirich — Operator Portal API (task #41, Phase 2).
   Role-gated master-data editing + reads for the web operator portal.
   EVERY write appends an attributed row to `audit_log` (who / when /
   action / entity / before -> after) — the VVB/IPO-grade change record.

   `collections` stay IMMUTABLE — weight/task corrections go to `adjustments`
   (Phase 4), never overwriting the raw DO.

   AUTH: WP-signed token = base64(client_id|role|expiry).HMAC (task #16),
   backward-compatible with the 2-part base64(client_id|expiry) token
   (role derived: ALL->admin, else->client). Writes require role operator|admin.
   Legacy DEVICE_KEY kept during rollout (retire once the portal issues role
   tokens) — with the legacy key, actor='legacy-key' and role='admin'.
   JWT-verify OFF (gated here).
   ============================================================ */
import { createClient } from "npm:@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const LR_TOKEN_SECRET = Deno.env.get("LR_TOKEN_SECRET") || "";
const LEGACY_KEY = Deno.env.get("READ_KEY") || Deno.env.get("DEVICE_KEY") || "";
const LEGACY_KEY_ENABLED = true; // retire once the operator WP page issues role tokens

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "content-type,x-sync-key",
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { "content-type": "application/json", ...CORS } });

/* ---- coercers (portal sends strings) ---- */
const s = (v: unknown): string | null => {
  if (v === null || v === undefined) return null;
  const t = String(v).trim(); return t === "" ? null : t;
};
const num = (v: unknown): number | null => {
  const t = s(v); if (t === null) return null;
  const n = Number(t.replace(/[, ]/g, "")); return Number.isFinite(n) ? n : null;
};
const bool = (v: unknown, dflt = true): boolean => {
  const t = s(v); if (t === null) return dflt; return /^(true|t|yes|y|1|active)$/i.test(t);
};

/* ---- token verify (role-aware, backward-compatible) ---- */
async function hmacHex(msg: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(msg));
  return [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
function timingSafeEq(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let r = 0; for (let i = 0; i < a.length; i++) r |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return r === 0;
}
async function verifyToken(token: string): Promise<{ client_id: string; role: string } | null> {
  if (!token || !LR_TOKEN_SECRET) return null;
  const dot = token.lastIndexOf("."); if (dot <= 0) return null;
  const payload = token.slice(0, dot), sig = token.slice(dot + 1).toLowerCase();
  if (!timingSafeEq(sig, await hmacHex(payload, LR_TOKEN_SECRET))) return null;
  let decoded: string; try { decoded = atob(payload); } catch { return null; }
  const p = decoded.split("|");
  let client_id: string, role: string, exp: number;
  if (p.length === 3) { client_id = p[0]; role = p[1]; exp = Number(p[2]); }
  else if (p.length === 2) { client_id = p[0]; exp = Number(p[1]); role = client_id.trim().toUpperCase() === "ALL" ? "admin" : "client"; }
  else return null;
  if (!client_id || !Number.isFinite(exp)) return null;
  if (Math.floor(Date.now() / 1000) > exp) return null;
  return { client_id: client_id.trim().toUpperCase(), role: (role || "client").trim().toLowerCase() };
}

async function audit(actor: string, action: string, entity: string, entity_id: string | null, before: unknown, after: unknown) {
  await supa.from("audit_log").insert({ actor, action, entity, entity_id, before, after });
}

/* ---- master-data row shapers (portal edits one/few rows at a time) ---- */
function customerRow(r: any) {
  const client_id = s(r.client_id); if (!client_id) return null;
  const o: any = { client_id: client_id.toUpperCase() };
  for (const k of ["name", "payment_terms", "sales_rep", "xero_contact_id", "contact_name", "contact_phone", "contact_email"])
    if (k in r && s(r[k]) !== null) o[k] = s(r[k]);
  if ("active" in r && s(r.active) !== null) o.active = bool(r.active);
  return o;
}
function siteRow(r: any) {
  const site_id = s(r.site_id), client_id = s(r.client_id);
  if (!site_id || !client_id) return null;
  return {
    site_id, client_id: client_id.toUpperCase(), site_name: s(r.site_name), address: s(r.address),
    contact_name: s(r.contact_name), contact_phone: s(r.contact_phone), contact_email: s(r.contact_email),
    active: bool(r.active),
  };
}
function binRow(r: any) {
  const bin_id = s(r.bin_id); if (!bin_id) return null;
  return { bin_id, bin_type: s(r.bin_type), volume_m3: num(r.volume_m3), tare_kg: num(r.tare_kg), owner: s(r.owner), purchase_cost: num(r.purchase_cost), active: bool(r.active) };
}
function rateRow(r: any) {
  const site_id = s(r.site_id), job_type = s(r.job_type);
  if (!site_id || !job_type) return null;
  return { site_id, job_type, price: num(r.price), valid_from: s(r.valid_from), created_by: "portal" };
}
const PK: Record<string, string> = { customers: "client_id", sites: "site_id", bins: "bin_id" };
const SHAPER: Record<string, (r: any) => any> = { customers: customerRow, sites: siteRow, bins: binRow };

async function masterUpsert(table: string, rows: any[], actor: string) {
  if (!["customers", "sites", "bins", "rate_card"].includes(table)) return { error: "bad table" };
  if (!Array.isArray(rows) || !rows.length) return { table, upserted: 0 };

  // rate_card = replace per site (no unique (site_id,job_type)); audit per site
  if (table === "rate_card") {
    const shaped = rows.map(rateRow).filter(Boolean) as any[];
    const siteIds = [...new Set(shaped.map((r) => r.site_id))];
    let count = 0;
    for (const sid of siteIds) {
      const { data: before } = await supa.from("rate_card").select("job_type,price").eq("site_id", sid);
      await supa.from("rate_card").delete().eq("site_id", sid);
      const ins = shaped.filter((r) => r.site_id === sid);
      const { error } = await supa.from("rate_card").insert(ins);
      if (error) return { table, error: error.message, site_id: sid };
      count += ins.length;
      await audit(actor, "rate_card.replace", "rate_card", sid, before || [], ins.map((r) => ({ job_type: r.job_type, price: r.price })));
    }
    return { table, replaced_sites: siteIds.length, inserted: count };
  }

  // customers/sites/bins = per-row before/after upsert + audit
  const pk = PK[table], shape = SHAPER[table];
  let upserted = 0;
  for (const raw of rows) {
    const row = shape(raw); if (!row) continue;
    const idv = row[pk];
    const { data: before } = await supa.from(table).select("*").eq(pk, idv).maybeSingle();
    const { error } = await supa.from(table).upsert(row, { onConflict: pk });
    if (error) return { table, error: error.message, id: idv };
    upserted++;
    await audit(actor, table + ".upsert", table, idv, before || null, row);
  }
  return { table, upserted };
}

async function read(what: string, f: any) {
  const lim = Math.min(Number(f?.limit) || 500, 2000);
  if (what === "customers") return (await supa.from("customers").select("*").order("client_id").limit(lim)).data;
  if (what === "sites") return (await supa.from("sites").select("*").order("site_id").limit(lim)).data;
  if (what === "bins") return (await supa.from("bins").select("*").order("bin_id").limit(lim)).data;
  if (what === "rate_card") return (await supa.from("rate_card").select("*").order("site_id").order("job_type").limit(lim)).data;
  if (what === "jobs") return (await supa.from("jobs").select("*").order("date", { ascending: false }).limit(lim)).data;
  if (what === "collections") {
    let q = supa.from("collections").select("do_no,do_date,do_type,trip_type,vessel_name,waste_type,net_kg,vol_total_m3,site_id,source").order("do_date", { ascending: false }).limit(lim);
    if (s(f?.site_id)) q = q.eq("site_id", s(f.site_id));
    return (await q).data;
  }
  if (what === "audit") return (await supa.from("audit_log").select("*").order("at", { ascending: false }).limit(lim)).data;
  return { error: "unknown read: " + what };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);

  // auth: signed role token, else legacy key
  const tok = await verifyToken(url.searchParams.get("token") || "");
  const key = url.searchParams.get("key") || req.headers.get("x-sync-key") || "";
  let role = "", actor = "";
  if (tok) { role = tok.role; actor = tok.client_id === "ALL" ? "admin" : tok.client_id; }
  else if (LEGACY_KEY_ENABLED && LEGACY_KEY && key === LEGACY_KEY) { role = "admin"; actor = "legacy-key"; }
  else return json({ error: "unauthorized" }, 403);

  try {
    let body: any = {};
    if (req.method === "POST") { try { body = await req.json(); } catch { return json({ error: "invalid JSON" }, 400); } }
    const action = s(body.action) || s(url.searchParams.get("action")) || "";

    // reads (operator/admin/client-of-own — here operator/admin)
    if (action === "read" || req.method === "GET") {
      if (!["operator", "admin"].includes(role)) return json({ error: "forbidden" }, 403);
      const what = s(body.what) || s(url.searchParams.get("what")) || "";
      return json({ ok: true, actor, role, data: await read(what, body.filters || {}) });
    }

    // writes require operator|admin
    if (!["operator", "admin"].includes(role)) return json({ error: "forbidden (writes need operator role)" }, 403);

    if (action === "master.upsert") {
      return json({ ok: true, actor, result: await masterUpsert(s(body.table) || "", body.rows || [], actor) });
    }
    // adjustment.add is Phase 4 (collections UI) — stubbed here for shape
    return json({ error: "unknown action: " + action }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
