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
  return { site_id, job_type, price: num(r.price), valid_from: s(r.valid_from) || new Date().toISOString().slice(0, 10), created_by: "portal" };
}
const PK: Record<string, string> = { customers: "client_id", sites: "site_id", bins: "bin_id" };
const SHAPER: Record<string, (r: any) => any> = { customers: customerRow, sites: siteRow, bins: binRow };

async function masterUpsert(table: string, rows: any[], actor: string) {
  if (!["customers", "sites", "bins", "rate_card"].includes(table)) return { error: "bad table" };
  if (!Array.isArray(rows) || !rows.length) return { table, upserted: 0 };

  // rate_card = replace per site (no unique (site_id,job_type)); audit per site + ROLLBACK on insert failure
  if (table === "rate_card") {
    const shaped = rows.map(rateRow).filter(Boolean) as any[];
    const siteIds = [...new Set(shaped.map((r) => r.site_id))];
    let count = 0;
    for (const sid of siteIds) {
      const { data: before } = await supa.from("rate_card").select("*").eq("site_id", sid);
      await supa.from("rate_card").delete().eq("site_id", sid);
      const ins = shaped.filter((r) => r.site_id === sid);
      const { error } = await supa.from("rate_card").insert(ins);
      if (error) {
        // rollback: re-insert the deleted rows so a bad edit never wipes a site's prices
        if (before && before.length) {
          const restore = before.map((b: any) => { const { id: _drop, ...keep } = b; return keep; });
          await supa.from("rate_card").insert(restore);
        }
        return { table, error: error.message, site_id: sid, rolled_back: true };
      }
      count += ins.length;
      await audit(actor, "rate_card.replace", "rate_card", sid, (before || []).map((r: any) => ({ job_type: r.job_type, price: r.price })), ins.map((r) => ({ job_type: r.job_type, price: r.price })));
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
  const lim = Math.min(Number(f?.limit) || 500, 5000);
  if (what === "customers") return (await supa.from("customers").select("*").order("client_id").limit(lim)).data;
  if (what === "sites") return (await supa.from("sites").select("*").order("site_id").limit(lim)).data;
  if (what === "bins") return (await supa.from("bins").select("*").order("bin_id").limit(lim)).data;
  if (what === "rate_card") return (await supa.from("rate_card").select("*").order("site_id").order("job_type").limit(lim)).data;
  if (what === "jobs") return (await supa.from("jobs").select("*").order("date", { ascending: false }).limit(lim)).data;
  if (what === "collections") {
    let q = supa.from("collections").select("do_no,do_date,do_type,trip_type,vessel_name,waste_type,job_type,dispose_to,gross_kg,tare_kg,net_kg,vol_total_m3,site_id,source").order("do_date", { ascending: false }).limit(lim);
    if (s(f?.site_id)) q = q.eq("site_id", s(f.site_id));
    return (await q).data;
  }
  if (what === "adjustments") {
    let q = supa.from("adjustments").select("*").order("id", { ascending: false }).limit(lim);
    if (s(f?.do_no)) q = q.eq("do_no", s(f.do_no));
    return (await q).data;
  }
  if (what === "yard_inbound") return (await supa.from("yard_inbound").select("*").order("log_date", { ascending: false }).limit(lim)).data;
  if (what === "yard_stock") return (await supa.from("yard_stock").select("*").order("take_date", { ascending: false }).limit(lim)).data;
  if (what === "audit") return (await supa.from("audit_log").select("*").order("at", { ascending: false }).limit(lim)).data;
  if (what === "app_state") {
    // full driver-app state blob (jobs+trips with pay detail) — operator/admin only (enforced by caller)
    const { data } = await supa.from("app_state").select("state").eq("id", 1).maybeSingle();
    return data ? data.state : { error: "no app_state" };
  }
  if (what === "odometer") {
    // Cartrack daily odometer for job-card mileage prefill: filters {vehicle_id, date}
    let q = supa.from("odometer_log").select("*").order("read_date", { ascending: false }).limit(lim);
    if (s(f?.vehicle_id)) q = q.eq("vehicle_id", s(f.vehicle_id));
    if (s(f?.date)) q = q.eq("read_date", s(f.date));
    return (await q).data;
  }
  if (what === "jobcard_overrides") {
    let q = supa.from("jobcard_overrides").select("*").order("id", { ascending: true }).limit(lim);
    if (s(f?.card_date)) q = q.eq("card_date", s(f.card_date));
    if (f?.driver_id != null) q = q.eq("driver_id", Number(f.driver_id));
    return (await q).data;
  }
  return { error: "unknown read: " + what };
}

/* ---- Job card override: append-only, audited. App-sourced values are never
   mutated; the console renders latest override per field_key with provenance. ---- */
async function jobcardSet(card_date: string, driver_id: number, field_key: string, old_value: unknown, new_value: unknown, actor: string) {
  if (!card_date || !field_key || !(driver_id >= 0)) return { error: "card_date, driver_id, field_key required" };
  const row = {
    card_date, driver_id, field_key,
    old_value: old_value == null ? null : String(old_value),
    new_value: new_value == null ? null : String(new_value),
    actor,
  };
  const { data: ins, error } = await supa.from("jobcard_overrides").insert(row).select().single();
  if (error) return { error: error.message };
  await audit(actor, "jobcard.set", "jobcard", card_date + "|" + driver_id + "|" + field_key, { value: row.old_value }, { value: row.new_value });
  return { ok: true, override: ins };
}

/* ---- Phase 4: weight/volume correction. `collections` raw is NEVER edited;
   the correction is appended to `adjustments` (collections_effective view =
   latest adjustment wins) + mirrored to audit_log. ---- */
const ADJUSTABLE = ["net_kg", "vol_total_m3"]; // fields the collections_effective view honors
async function adjustmentAdd(do_no: string, field: string, new_value: unknown, reason: string, actor: string) {
  if (!do_no) return { error: "do_no required" };
  if (!ADJUSTABLE.includes(field)) return { error: "field not adjustable: " + field + " (allowed: " + ADJUSTABLE.join(", ") + ")" };
  const nv = num(new_value);
  if (nv === null || nv < 0) return { error: "new_value must be a number >= 0" };
  if (!reason) return { error: "reason required" };
  const { data: coll } = await supa.from("collections").select("do_no,net_kg,vol_total_m3").eq("do_no", do_no).maybeSingle();
  if (!coll) return { error: "unknown do_no: " + do_no };
  const old_value = (coll as any)[field] == null ? null : String((coll as any)[field]);
  const row = { do_no, field, old_value, new_value: String(nv), reason, adjusted_by: actor };
  const { data: ins, error } = await supa.from("adjustments").insert(row).select().single();
  if (error) return { error: error.message };
  await audit(actor, "adjustment.add", "collections", do_no, { [field]: old_value }, { [field]: String(nv), reason });
  return { ok: true, adjustment: ins };
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
    if (action === "adjustment.add") {
      return json({ ok: true, actor, result: await adjustmentAdd(s(body.do_no) || "", s(body.field) || "", body.new_value, s(body.reason) || "", actor) });
    }
    if (action === "yard.inbound.add" || action === "yard.stock.add") {
      const table = action === "yard.inbound.add" ? "yard_inbound" : "yard_stock";
      const row: any = table === "yard_inbound"
        ? { log_date: s(body.log_date), waste_type: s(body.waste_type), source_name: s(body.source_name), source_addr: s(body.source_addr), qty_t: num(body.qty_t), remarks: s(body.remarks), entered_by: actor }
        : { take_date: s(body.take_date), waste_type: s(body.waste_type), qty_t: num(body.qty_t), remarks: s(body.remarks), entered_by: actor };
      if (!row.waste_type || row.qty_t == null || row.qty_t < 0) return json({ result: { error: "waste_type and a non-negative qty_t are required" } });
      if (table === "yard_inbound" && (!row.log_date || !row.source_name)) return json({ result: { error: "log_date and source_name are required" } });
      if (table === "yard_stock" && !row.take_date) return json({ result: { error: "take_date is required" } });
      const { data: ins, error } = await supa.from(table).insert(row).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, action, table, String(ins.id), null, ins);
      return json({ ok: true, actor, result: { ok: true, row: ins } });
    }
    if (action === "jobcard.set") {
      return json({ ok: true, actor, result: await jobcardSet(s(body.card_date) || "", Number(body.driver_id), s(body.field_key) || "", body.old_value, body.new_value, actor) });
    }
    return json({ error: "unknown action: " + action }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
