/* ============================================================
   Lirich — master-data sync (Google Sheet → SSOT). (task #22)
   The operator maintains clients / sites / bins / pricing in a friendly
   Google Sheet; a bound Apps Script POSTs the tabs here and this function
   UPSERTS them into the SSOT reference tables using the service role.

   Security model (better than Apps-Script-holds-service-key): the sheet's
   Apps Script only holds our DEVICE_KEY and calls this function; the Supabase
   service role NEVER leaves Supabase. One-way only: sheet → Supabase.

   ⚠ REFERENCE TABLES ONLY. Never touches Trips / Jobs / collections
   (those are app-owned; writing them corrupts live data).

   POST body (JSON), any subset of:
     { customers:[...], sites:[...], bins:[...], rate_card:[...] }
   Keys are immutable match keys: client_id / site_id / bin_id / (site_id+job_type).
   Retire rows with active=false in the sheet — never hard-delete.

   Gated by ?key= / x-sync-key = SYNC_KEY (→ DEVICE_KEY). JWT-verify OFF.
   ============================================================ */
import { createClient } from "npm:@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const SYNC_KEY = Deno.env.get("SYNC_KEY") || Deno.env.get("DEVICE_KEY") || "";

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "content-type,x-sync-key",
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { "content-type": "application/json", ...CORS } });

/* ---- coercers (sheet cells arrive as strings) ---- */
const s = (v: unknown): string | null => {
  if (v === null || v === undefined) return null;
  const t = String(v).trim();
  return t === "" ? null : t;
};
const num = (v: unknown): number | null => {
  const t = s(v);
  if (t === null) return null;
  const n = Number(t.replace(/[, ]/g, ""));
  return Number.isFinite(n) ? n : null;
};
const bool = (v: unknown, dflt = true): boolean => {
  const t = s(v);
  if (t === null) return dflt;
  return /^(true|t|yes|y|1|active)$/i.test(t);
};

/* pick only known columns from a sheet row (ignore extra/blank columns) */
function customerRow(r: any) {
  const client_id = s(r.client_id);
  if (!client_id) return null;
  return {
    client_id: client_id.toUpperCase(),
    name: s(r.name), payment_terms: s(r.payment_terms), sales_rep: s(r.sales_rep),
    xero_contact_id: s(r.xero_contact_id),
    contact_name: s(r.contact_name), contact_phone: s(r.contact_phone), contact_email: s(r.contact_email),
    active: bool(r.active),
  };
}
function siteRow(r: any) {
  const site_id = s(r.site_id), client_id = s(r.client_id);
  if (!site_id || !client_id) return null;
  return {
    site_id, client_id: client_id.toUpperCase(),
    site_name: s(r.site_name), address: s(r.address),
    contact_name: s(r.contact_name), contact_phone: s(r.contact_phone), contact_email: s(r.contact_email),
    active: bool(r.active),
  };
}
function binRow(r: any) {
  const bin_id = s(r.bin_id);
  if (!bin_id) return null;
  return {
    bin_id, bin_type: s(r.bin_type), volume_m3: num(r.volume_m3), tare_kg: num(r.tare_kg),
    owner: s(r.owner), purchase_cost: num(r.purchase_cost), active: bool(r.active),
  };
}
function rateRow(r: any) {
  const site_id = s(r.site_id), job_type = s(r.job_type);
  if (!site_id || !job_type) return null;
  return { site_id, job_type, price: num(r.price), valid_from: s(r.valid_from), created_by: "sheet" };
}

async function upsert(table: string, rows: any[], onConflict: string) {
  if (!rows.length) return { table, upserted: 0, skipped: 0 };
  const { error, count } = await supa.from(table).upsert(rows, { onConflict, count: "exact" });
  if (error) return { table, error: error.message, attempted: rows.length };
  return { table, upserted: count ?? rows.length };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  const key = url.searchParams.get("key") || req.headers.get("x-sync-key") || "";
  if (!SYNC_KEY || key !== SYNC_KEY) return json({ error: "unauthorized" }, 403);

  /* GET ?dump=1 → current master data (for one-time sheet seeding + re-seed). Read-only. */
  if (req.method === "GET" && url.searchParams.get("dump") === "1") {
    const [c, si, b, rc] = await Promise.all([
      supa.from("customers").select("client_id,name,payment_terms,sales_rep,xero_contact_id,contact_name,contact_phone,contact_email,active").order("client_id"),
      supa.from("sites").select("site_id,client_id,site_name,address,contact_name,contact_phone,contact_email,active").order("site_id"),
      supa.from("bins").select("bin_id,bin_type,volume_m3,tare_kg,owner,purchase_cost,active").order("bin_id"),
      supa.from("rate_card").select("site_id,job_type,price,valid_from").order("site_id").order("job_type"),
    ]);
    return json({ customers: c.data || [], sites: si.data || [], bins: b.data || [], rate_card: rc.data || [] });
  }

  if (req.method !== "POST") return json({ error: "GET ?dump=1 to read, or POST { customers?, sites?, bins?, rate_card? } to upsert" }, 405);

  let body: any;
  try { body = await req.json(); } catch { return json({ error: "invalid JSON body" }, 400); }

  const out: any = { ok: true, results: [] };
  try {
    // customers first (sites FK them), then sites, bins, rate_card
    if (Array.isArray(body.customers)) {
      const rows = body.customers.map(customerRow).filter(Boolean);
      out.results.push(await upsert("customers", rows, "client_id"));
    }
    if (Array.isArray(body.sites)) {
      const rows = body.sites.map(siteRow).filter(Boolean);
      out.results.push(await upsert("sites", rows, "site_id"));
    }
    if (Array.isArray(body.bins)) {
      const rows = body.bins.map(binRow).filter(Boolean);
      out.results.push(await upsert("bins", rows, "bin_id"));
    }
    if (Array.isArray(body.rate_card)) {
      const rows = body.rate_card.map(rateRow).filter(Boolean);
      // no unique (site_id,job_type) constraint → replace per site_id present in the payload
      const siteIds = [...new Set(rows.map((r: any) => r.site_id))];
      let del = 0, ins = 0, err: string | null = null;
      if (siteIds.length) {
        const d = await supa.from("rate_card").delete({ count: "exact" }).in("site_id", siteIds);
        if (d.error) err = "delete:" + d.error.message; else del = d.count ?? 0;
        if (!err) {
          const i = await supa.from("rate_card").insert(rows, { count: "exact" });
          if (i.error) err = "insert:" + i.error.message; else ins = i.count ?? rows.length;
        }
      }
      out.results.push(err ? { table: "rate_card", error: err } : { table: "rate_card", replaced_sites: siteIds.length, deleted: del, inserted: ins });
    }
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
  out.ok = !out.results.some((r: any) => r.error);
  return json(out, out.ok ? 200 : 207);
});
