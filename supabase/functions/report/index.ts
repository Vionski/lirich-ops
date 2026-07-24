/* ============================================================
   Lirich — read-only client REPORT function.
   Returns one client's dashboard data from the SSOT (collections),
   so the client portal shows LIVE numbers instead of hardcoded JSON.

   GET ?client=PIL&key=<READ_KEY>            → that client's aggregates
   GET ?client=ALL&key=<READ_KEY>&admin=1    → all clients (admin view)

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

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { "content-type": "application/json", ...CORS } });

const n2 = (v: number) => Math.round((v || 0) * 100) / 100;

async function clientReport(clientId: string) {
  const { data: cust } = await supa.from("customers").select("name").eq("client_id", clientId).maybeSingle();
  const { data: sites } = await supa.from("sites").select("site_id").eq("client_id", clientId);
  const siteIds = (sites || []).map((s: any) => s.site_id);
  if (!siteIds.length) return { client: clientId, name: cust?.name || clientId, empty: true };

  const { data: rows } = await supa.from("collections")
    .select("do_no,do_date,do_type,trip_type,vessel_name,waste_type,vol_cat_a,vol_cat_b,vol_cat_c,vol_cat_d,vol_cat_e,vol_cat_f,vol_total_m3,net_kg,source")
    .in("site_id", siteIds)
    .order("do_date");

  const months: Record<string, any> = {};
  const vessels: Record<string, any> = {};
  /* per-collection rows in the PIL dashboard's DATA shape, so the front-end can
     drop them in unchanged. Cat mapping: garbage = A plastics + B food + C domestic
     + F operational; oily = D cooking oil; ash = E ashes. Vessel jobs have no
     separate sludge field in the SSOT, so reqS/actS = 0 (was manual on the old DO). */
  const data: Record<string, any[]> = {};
  const sn: Record<string, number> = {};
  let totVol = 0, totNet = 0, totDos = 0;
  for (const r of (rows || []) as any[]) {
    const mk = (r.do_date || "").slice(0, 7) || "unknown";
    const garbage = (Number(r.vol_cat_a) || 0) + (Number(r.vol_cat_b) || 0) + (Number(r.vol_cat_c) || 0) + (Number(r.vol_cat_f) || 0);
    const oily = Number(r.vol_cat_d) || 0;
    const ash = Number(r.vol_cat_e) || 0;
    (data[mk] = data[mk] || []).push({
      sn: (sn[mk] = (sn[mk] || 0) + 1), date: r.do_date, vessel: r.vessel_name || "", port: r.berth || "",
      voy: "", garbage: n2(garbage), oily: n2(oily), ash: n2(ash), reqS: 0, actS: 0,
    });
    const m = months[mk] || (months[mk] = { month: mk, dos: 0, volume_m3: 0, net_t: 0, vessels: new Set(),
      cat_a: 0, cat_b: 0, cat_c: 0, cat_d: 0, cat_e: 0, cat_f: 0 });
    m.dos++; totDos++;
    const vol = Number(r.vol_total_m3) || 0; m.volume_m3 += vol; totVol += vol;
    const net = (Number(r.net_kg) || 0) / 1000; m.net_t += net; totNet += net;
    m.cat_a += Number(r.vol_cat_a) || 0; m.cat_b += Number(r.vol_cat_b) || 0; m.cat_c += Number(r.vol_cat_c) || 0;
    m.cat_d += Number(r.vol_cat_d) || 0; m.cat_e += Number(r.vol_cat_e) || 0; m.cat_f += Number(r.vol_cat_f) || 0;
    if (r.vessel_name) { m.vessels.add(r.vessel_name);
      const v = vessels[r.vessel_name] || (vessels[r.vessel_name] = { vessel: r.vessel_name, dos: 0, volume_m3: 0 });
      v.dos++; v.volume_m3 += vol; }
  }
  const monthly = Object.values(months).map((m: any) => ({
    month: m.month, dos: m.dos, volume_m3: n2(m.volume_m3), net_t: n2(m.net_t), vessels: m.vessels.size,
    cat_a_plastics: n2(m.cat_a), cat_b_food: n2(m.cat_b), cat_c_domestic: n2(m.cat_c),
    cat_d_oil: n2(m.cat_d), cat_e_ashes: n2(m.cat_e), cat_f_operational: n2(m.cat_f),
  })).sort((a, b) => a.month.localeCompare(b.month));

  return {
    client: clientId,
    name: cust?.name || clientId,
    generated_at: new Date().toISOString(),
    basis: "Indicative from measured volume. Client standard 1 m3 = 1,000 kg. Carbon applied by the report layer.",
    totals: { dos: totDos, volume_m3: n2(totVol), net_t: n2(totNet), months: monthly.length,
      vessels: Object.keys(vessels).length },
    monthly,
    vessels: Object.values(vessels).map((v: any) => ({ vessel: v.vessel, dos: v.dos, volume_m3: n2(v.volume_m3) }))
      .sort((a, b) => b.volume_m3 - a.volume_m3),
    /* month -> per-collection rows, matching the dashboard's hardcoded DATA shape */
    data,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  if ((url.searchParams.get("key") || "") !== READ_KEY) return json({ error: "bad key" }, 403);
  const client = (url.searchParams.get("client") || "").toUpperCase();
  const admin = url.searchParams.get("admin") === "1";
  try {
    if (client === "ALL" && admin) {
      const { data: custs } = await supa.from("customers").select("client_id").eq("active", true);
      const out: any[] = [];
      for (const c of (custs || []) as any[]) out.push(await clientReport(c.client_id));
      return json({ clients: out.filter((r) => !r.empty) });
    }
    if (!client) return json({ error: "client required" }, 400);
    return json(await clientReport(client));
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
