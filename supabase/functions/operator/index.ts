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
async function verifyToken(token: string): Promise<{ client_id: string; role: string; user_key: string | null } | null> {
  if (!token || !LR_TOKEN_SECRET) return null;
  const dot = token.lastIndexOf("."); if (dot <= 0) return null;
  const payload = token.slice(0, dot), sig = token.slice(dot + 1).toLowerCase();
  if (!timingSafeEq(sig, await hmacHex(payload, LR_TOKEN_SECRET))) return null;
  let decoded: string; try { decoded = atob(payload); } catch { return null; }
  const p = decoded.split("|");
  let client_id: string, role: string, exp: number, user_key: string | null = null;
  if (p.length === 3) { client_id = p[0]; role = p[1]; exp = Number(p[2]); }
  else if (p.length === 4) {
    /* 4-part (#105): client_id|role|user_key|expiry — user_key = WP user_login,
       maps to console_users.wp_login for per-tab permission enforcement. */
    client_id = p[0]; role = p[1]; user_key = (p[2] || "").trim().toLowerCase() || null; exp = Number(p[3]);
  }
  else if (p.length === 2) { client_id = p[0]; exp = Number(p[1]); role = client_id.trim().toUpperCase() === "ALL" ? "admin" : "client"; }
  else return null;
  if (!client_id || !Number.isFinite(exp)) return null;
  if (Math.floor(Date.now() / 1000) > exp) return null;
  return { client_id: client_id.trim().toUpperCase(), role: (role || "client").trim().toLowerCase(), user_key };
}

async function isLocked(driver_id: number, month: string): Promise<boolean> {
  if (!driver_id || !month) return false;
  try {
    const { data } = await supa.from("salary_approvals").select("locked").eq("driver_id", driver_id).eq("month", month).maybeSingle();
    return !!(data && data.locked);
  } catch (_e) { return false; }
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
  if (what === "drivers") return (await supa.from("drivers").select("driver_id,name,active").order("driver_id").limit(lim)).data; // collections driver filter (13 Aug 2026)
  if (what === "collections") {
    let q = supa.from("collections").select("do_no,do_date,do_type,trip_type,vessel_name,berth,waste_type,job_type,dispose_to,gross_kg,tare_kg,net_kg,vol_total_m3,site_id,source,photo_do_ref,driver_id").order("do_date", { ascending: false }).limit(lim);
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
  if (what === "base_salary") {
    let q = supa.from("driver_base_salary").select("*").limit(lim);
    if (s(f?.month)) q = q.eq("month", s(f.month));
    return (await q).data;
  }
  if (what === "salary_approvals") {
    let q = supa.from("salary_approvals").select("*").limit(lim);
    if (s(f?.month)) q = q.eq("month", s(f.month));
    return (await q).data;
  }
  if (what === "reviews") {
    /* operator "seen & OK" ticks on collections rows (Michelle, 7 Aug 2026) */
    return (await supa.from("collection_reviews").select("*").limit(3000)).data;
  }
  if (what === "notes") {
    let q = supa.from("notes").select("*").order("id", { ascending: false }).limit(lim);
    if (s(f?.entity_type)) q = q.eq("entity_type", s(f.entity_type));
    if (s(f?.entity_id)) q = q.eq("entity_id", s(f.entity_id));
    if (s(f?.assign_to)) q = q.eq("assign_to", s(f.assign_to)).eq("done", false);
    return (await q).data;
  }
  if (what === "stages") return (await supa.from("pipeline_stages").select("*").eq("pipeline", "marine").order("sort_order")).data;
  if (what === "enquiries") {
    let q = supa.from("enquiries").select("*").eq("pipeline", "marine").order("id", { ascending: false }).limit(lim);
    q = f.archived ? q.eq("archived", true) : q.eq("archived", false);
    return (await q).data;
  }
  if (what === "requirements") return (await supa.from("requirements").select("*").order("blocking", { ascending: false }).order("framework").order("id").limit(lim)).data; // compliance view (21 Aug 2026)
  if (what === "methodology") return (await supa.from("methodology_decisions").select("*").eq("status", "active").order("decided_on").limit(lim)).data; // compliance view (21 Aug 2026)
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

/* ---- #105 per-tab access control (step 3, 5 Aug 2026) ----
   Tokens now carry the WP user_login (4-part). If it maps to an ACTIVE
   console_users row, every action is checked server-side against
   console_permissions. Legacy 2/3-part tokens (no identity) keep the old
   role-only behaviour during rollout. Unknown identities FAIL CLOSED. */
const TAB_READ: Record<string, string> = {
  customers: "master", sites: "master", bins: "master", rate_card: "master", audit: "master",
  jobs: "collections", collections: "collections", adjustments: "collections", drivers: "collections",
  app_state: "jobcard", odometer: "jobcard", jobcard_overrides: "jobcard",
  yard_inbound: "nea", yard_stock: "nea",
  stages: "marine", enquiries: "marine",
  base_salary: "jobcard", salary_approvals: "collections", notes: "master",
  reviews: "collections",
  requirements: "reqs", methodology: "reqs",
};
const TAB_WRITE: Record<string, string> = {
  "master.upsert": "master", "adjustment.add": "collections",
  "yard.inbound.add": "nea", "yard.stock.add": "nea", "jobcard.set": "jobcard",
  "enquiry.add": "marine", "enquiry.update": "marine", "enquiry.move": "marine", "enquiry.archive": "marine",
  "stage.add": "marine", "stage.rename": "marine", "stage.reorder": "marine", "stage.deactivate": "marine",
  "collection.set_dispose": "collections", "collection.review": "collections",
  "collection.set_weight": "collections", "salary.base.set": "jobcard",
  "salary.approve": "salary_approve", "salary.unlock": "salary_approve",
  "note.add": "master", "note.done": "master",
};

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

  /* resolve per-tab permissions for identified users (#105 step 3) */
  let perms: Record<string, { v: boolean; e: boolean }> | null = null;
  let permUser: string | null = null;
  if (tok && tok.user_key) {
    const { data: cu } = await supa.from("console_users").select("user_key,active").eq("wp_login", tok.user_key).maybeSingle();
    if (!cu || !cu.active) return json({ error: "forbidden: user "+JSON.stringify(tok.user_key)+" is not provisioned in console_users - ask an admin to add you" }, 403);
    permUser = cu.user_key;
    const { data: ps } = await supa.from("console_permissions").select("tab,can_view,can_edit").eq("user_key", cu.user_key);
    perms = {};
    for (const p of (ps || []) as any[]) perms[p.tab] = { v: !!p.can_view, e: !!p.can_edit };
  }
  const allow = (tab: string, edit: boolean): boolean => {
    if (!perms) return true; /* legacy token - role checks only (rollout) */
    const p = perms[tab];
    if (!p) return false;
    return edit ? p.e : p.v;
  };

  try {
    let body: any = {};
    if (req.method === "POST") { try { body = await req.json(); } catch { return json({ error: "invalid JSON" }, 400); } }
    const action = s(body.action) || s(url.searchParams.get("action")) || "";

    // reads (operator/admin/client-of-own — here operator/admin)
    if (action === "perms.get") {
      if (!["operator", "admin"].includes(role)) return json({ error: "forbidden" }, 403);
      return json({ ok: true, actor, role, user: permUser, perms });
    }

    if (action === "read" || req.method === "GET") {
      if (!["operator", "admin"].includes(role)) return json({ error: "forbidden" }, 403);
      const what = s(body.what) || s(url.searchParams.get("what")) || "";
      const rtab = TAB_READ[what];
      if (rtab && !allow(rtab, false)) return json({ error: "forbidden: no view permission for tab "+JSON.stringify(rtab) }, 403);
      return json({ ok: true, actor, role, data: await read(what, body.filters || {}) });
    }

    /* #100 Phase B (6 Aug 2026): mint a short-lived signed URL for a private
       do-photos object. View-level — collections tab view permission; it reads
       evidence, mutates nothing (deliberately not audited to avoid flooding
       audit_log with every photo view). */
    if (action === "photo.sign") {
      if (!["operator", "admin"].includes(role)) return json({ error: "forbidden" }, 403);
      if (!allow("collections", false)) return json({ error: "forbidden: no view permission for tab \"collections\"" }, 403);
      const path = s(body.path).replace(/^\/+/, "");
      if (!path || path.includes("..")) return json({ error: "bad path" }, 400);
      const { data, error } = await supa.storage.from("do-photos").createSignedUrl(path, 3600);
      if (error || !data?.signedUrl) return json({ error: "sign failed: " + String(error?.message || error) }, 400);
      return json({ ok: true, url: data.signedUrl });
    }

    // writes require operator|admin
    if (!["operator", "admin"].includes(role)) return json({ error: "forbidden (writes need operator role)" }, 403);

    const wtab = TAB_WRITE[action];
    if (wtab && !allow(wtab, true)) return json({ error: "forbidden: no edit permission for tab "+JSON.stringify(wtab) }, 403);

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
    /* ---- #101 Marine enquiry Kanban (archive-only, every write audited) ---- */
    if (action === "enquiry.add") {
      const ef: any = {};
      for (const k of ["title", "company", "contact_name", "contact_email", "contact_phone", "services", "message", "owner", "source", "next_action", "next_due"])
        if (s(body[k]) !== null) ef[k] = s(body[k]);
      if (body.value_sgd != null && num(body.value_sgd) != null) ef.value_sgd = num(body.value_sgd);
      if (!ef.title && !ef.company) return json({ result: { error: "title or company is required" } });
      let stage_id = Number(body.stage_id) || null;
      if (!stage_id) {
        const { data: st } = await supa.from("pipeline_stages").select("id").eq("pipeline", "marine").eq("active", true).order("sort_order").limit(1).maybeSingle();
        stage_id = st ? st.id : null;
      }
      if (!stage_id) return json({ result: { error: "no active stage to place the enquiry in" } });
      ef.stage_id = stage_id; ef.pipeline = "marine"; ef.archived = false;
      if (!ef.source) ef.source = "console";
      const { data: ins, error } = await supa.from("enquiries").insert(ef).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "enquiry.add", "enquiries", String(ins.id), null, ins);
      return json({ ok: true, actor, result: { ok: true, row: ins } });
    }
    if (action === "enquiry.update") {
      const id = Number(body.id); if (!id) return json({ result: { error: "id required" } });
      const { data: before } = await supa.from("enquiries").select("*").eq("id", id).maybeSingle();
      if (!before) return json({ result: { error: "unknown enquiry " + id } });
      const ef: any = {};
      for (const k of ["title", "company", "contact_name", "contact_email", "contact_phone", "services", "message", "owner", "next_action", "next_due"])
        if (k in body) ef[k] = s(body[k]);
      if ("value_sgd" in body) ef.value_sgd = body.value_sgd == null || body.value_sgd === "" ? null : num(body.value_sgd);
      const { data: after, error } = await supa.from("enquiries").update(ef).eq("id", id).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "enquiry.update", "enquiries", String(id), before, after);
      return json({ ok: true, actor, result: { ok: true, row: after } });
    }
    if (action === "enquiry.move") {
      const id = Number(body.id), stage_id = Number(body.stage_id);
      if (!id || !stage_id) return json({ result: { error: "id and stage_id required" } });
      const { data: before } = await supa.from("enquiries").select("id,stage_id").eq("id", id).maybeSingle();
      if (!before) return json({ result: { error: "unknown enquiry " + id } });
      const { error } = await supa.from("enquiries").update({ stage_id }).eq("id", id);
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "enquiry.move", "enquiries", String(id), { stage_id: before.stage_id }, { stage_id });
      return json({ ok: true, actor, result: { ok: true } });
    }
    if (action === "enquiry.archive") {
      const id = Number(body.id); if (!id) return json({ result: { error: "id required" } });
      const { data: before } = await supa.from("enquiries").select("id,archived").eq("id", id).maybeSingle();
      if (!before) return json({ result: { error: "unknown enquiry " + id } });
      const { error } = await supa.from("enquiries").update({ archived: true, archived_at: new Date().toISOString(), archived_by: actor }).eq("id", id);
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "enquiry.archive", "enquiries", String(id), { archived: before.archived }, { archived: true });
      return json({ ok: true, actor, result: { ok: true } });
    }
    if (action === "stage.add") {
      const name = s(body.name); if (!name) return json({ result: { error: "name required" } });
      const { data: mx } = await supa.from("pipeline_stages").select("sort_order").eq("pipeline", "marine").order("sort_order", { ascending: false }).limit(1).maybeSingle();
      const row: any = { pipeline: "marine", name, sort_order: (mx ? Number(mx.sort_order) : 0) + 1, active: true };
      if (s(body.colour)) row.colour = s(body.colour);
      const { data: ins, error } = await supa.from("pipeline_stages").insert(row).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "stage.add", "pipeline_stages", String(ins.id), null, ins);
      return json({ ok: true, actor, result: { ok: true, row: ins } });
    }
    if (action === "stage.rename") {
      const id = Number(body.id), name = s(body.name);
      if (!id || !name) return json({ result: { error: "id and name required" } });
      const { data: before } = await supa.from("pipeline_stages").select("id,name").eq("id", id).maybeSingle();
      if (!before) return json({ result: { error: "unknown stage " + id } });
      const { error } = await supa.from("pipeline_stages").update({ name }).eq("id", id);
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "stage.rename", "pipeline_stages", String(id), { name: before.name }, { name });
      return json({ ok: true, actor, result: { ok: true } });
    }
    if (action === "stage.reorder") {
      const ids = Array.isArray(body.ids) ? body.ids.map(Number).filter(Boolean) : [];
      if (!ids.length) return json({ result: { error: "ids array required" } });
      for (let i = 0; i < ids.length; i++) {
        await supa.from("pipeline_stages").update({ sort_order: i + 1 }).eq("id", ids[i]);
      }
      await audit(actor, "stage.reorder", "pipeline_stages", null, null, { order: ids });
      return json({ ok: true, actor, result: { ok: true } });
    }
    if (action === "stage.deactivate") {
      const id = Number(body.id); if (!id) return json({ result: { error: "id required" } });
      const { count } = await supa.from("enquiries").select("id", { count: "exact", head: true }).eq("stage_id", id).eq("archived", false);
      if (count && count > 0) return json({ result: { error: "column still holds " + count + " open enquiries - move or archive them first" } });
      const { data: before } = await supa.from("pipeline_stages").select("id,name,active").eq("id", id).maybeSingle();
      if (!before) return json({ result: { error: "unknown stage " + id } });
      const { error } = await supa.from("pipeline_stages").update({ active: false }).eq("id", id);
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "stage.deactivate", "pipeline_stages", String(id), { active: before.active }, { active: false });
      return json({ ok: true, actor, result: { ok: true } });
    }
    /* ---- Phase 1 CRM actions (6 Aug 2026) ---- */
    if (action === "collection.set_dispose") {
      const do_no = s(body.do_no), dispose_to = s(body.dispose_to);
      if (!do_no || !dispose_to) return json({ result: { error: "do_no and dispose_to required" } });
      const { data: before } = await supa.from("collections").select("do_no,dispose_to").eq("do_no", do_no).maybeSingle();
      if (!before) return json({ result: { error: "unknown do_no " + do_no } });
      const { error } = await supa.from("collections").update({ dispose_to }).eq("do_no", do_no);
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "collection.set_dispose", "collections", do_no, { dispose_to: before.dispose_to }, { dispose_to });
      return json({ ok: true, actor, result: { ok: true } });
    }
    if (action === "collection.set_weight") {
      /* Direct weight CORRECTION (Michelle, 15 Aug 2026). Deliberately NOT an adjustment:
         an adjustment records a measured difference against the recorded figure, whereas this
         fixes a figure that was keyed wrongly (classically gross and tare the wrong way round)
         so the record matches the weighbridge ticket. Both are audited; adjustments untouched. */
      const do_no = s(body.do_no);
      const gross = Number(body.gross_kg), tare = Number(body.tare_kg);
      if (!do_no) return json({ result: { error: "do_no required" } });
      if (!isFinite(gross) || !isFinite(tare)) return json({ result: { error: "gross_kg and tare_kg must be numbers" } });
      if (gross < 0 || tare < 0) return json({ result: { error: "weights cannot be negative" } });
      const net = Math.round((gross - tare) * 100) / 100;
      if (net < 0) return json({ result: { error: "NET would be negative - GROSS is the full truck, TARE the empty one" } });
      const { data: before } = await supa.from("collections")
        .select("do_no,gross_kg,tare_kg,net_kg,source").eq("do_no", do_no).maybeSingle();
      if (!before) return json({ result: { error: "unknown do_no " + do_no } });
      const { error } = await supa.from("collections")
        .update({ gross_kg: gross, tare_kg: tare, net_kg: net }).eq("do_no", do_no);
      if (error) return json({ result: { error: error.message } });
      /* live rows are a MIRROR of the driver app — patch the app's own trip too, otherwise the
         next sync of that trip would silently overwrite this correction. */
      let app_patched = false;
      try {
        const { data: st } = await supa.from("app_state").select("state,rev").eq("id", 1).maybeSingle();
        const state: any = st?.state;
        if (state && Array.isArray(state.trips)) {
          const t = state.trips.find((x: any) => String(x.doNo || ("APP-T" + x.id)) === do_no);
          if (t) {
            t.weight = { gross, tare, net, ticket: (t.weight && t.weight.ticket) || "" };
            await supa.from("app_state").upsert({
              id: 1, state, rev: (Number(st?.rev) || 0) + 1, updated_at: new Date().toISOString(),
            });
            app_patched = true;
          }
        }
      } catch (_) { /* collections is already corrected — report app_patched=false */ }
      await audit(actor, "collection.set_weight", "collections", do_no,
        { gross_kg: before.gross_kg, tare_kg: before.tare_kg, net_kg: before.net_kg },
        { gross_kg: gross, tare_kg: tare, net_kg: net, app_patched,
          reason: s(body.reason) || "weight correction (operator console)" });
      return json({ ok: true, actor, result: { ok: true, net_kg: net, app_patched } });
    }
    if (action === "collection.review") {
      /* operator "seen & OK" tick (Michelle, 7 Aug 2026) — operational metadata,
         lives in collection_reviews so the raw collections row stays immutable.
         Un-ticking keeps the row (reviewed=false); history is in audit_log. */
      const do_no = s(body.do_no); const reviewed = !!body.reviewed;
      if (!do_no) return json({ result: { error: "do_no required" } });
      const { data: before } = await supa.from("collection_reviews").select("*").eq("do_no", do_no).maybeSingle();
      const row = { do_no, reviewed, reviewed_by: permUser || actor, reviewed_at: new Date().toISOString() };
      const { data: after, error } = await supa.from("collection_reviews").upsert(row, { onConflict: "do_no" }).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "collection.review", "collection_reviews", do_no, before, after);
      return json({ ok: true, actor, result: { ok: true, row: after } });
    }
    if (action === "salary.base.set") {
      const driver_id = Number(body.driver_id), month = String(s(body.month) || "");
      const base = num(body.base_sgd);
      if (!driver_id || !/^\d{4}-\d{2}$/.test(month) || base == null || base < 0)
        return json({ result: { error: "driver_id, month YYYY-MM and non-negative base_sgd required" } });
      if (await isLocked(driver_id, month))
        return json({ result: { error: "salary month " + month + " is APPROVED and locked - unlock it first" } });
      const { data: before } = await supa.from("driver_base_salary").select("*").eq("driver_id", driver_id).eq("month", month).maybeSingle();
      const row: any = { driver_id, month, base_sgd: base, entered_by: actor };
      const reimb = num(body.reimbursement_sgd), deduct = num(body.deduction_sgd);
      if (reimb != null && reimb >= 0) row.reimbursement_sgd = reimb;
      if (deduct != null && deduct >= 0) row.deduction_sgd = deduct;
      const { data: after, error } = await supa.from("driver_base_salary")
        .upsert(row, { onConflict: "driver_id,month" }).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "salary.base.set", "driver_base_salary", driver_id + ":" + month, before, after);
      return json({ ok: true, actor, result: { ok: true, row: after } });
    }
    if (action === "salary.approve" || action === "salary.unlock") {
      const driver_id = Number(body.driver_id), month = String(s(body.month) || "");
      if (!driver_id || !/^\d{4}-\d{2}$/.test(month))
        return json({ result: { error: "driver_id and month YYYY-MM required" } });
      const lock = action === "salary.approve";
      /* Michelle 7 Aug 2026: ONLY Sheryl and Qris may unlock an approved month.
         Enforced on user identity (console_users key), not role — an admin
         token without one of these identities is also refused. */
      if (!lock && !["sheryl", "qris"].includes(permUser || ""))
        return json({ result: { error: "Only Sheryl or Qris can unlock an approved salary" } });
      const driver_key = String(s(body.driver_key) || "").toUpperCase().replace(/[^A-Z0-9_]/g, "");
      if (lock) {
        /* Michelle 13 Aug 2026: a month cannot be approved while any of the driver's
           DOs in the period is still un-reviewed on the Collections tab.
           collections.driver_id is a TEXT key (e.g. YAO_JUN) - the console resolves
           and sends it as driver_key alongside the numeric app driver_id. */
        if (!driver_key)
          return json({ result: { error: "driver_key missing - reload the operator console and try again" } });
        const gs = /^\d{4}-\d{2}-\d{2}$/.test(s(body.period_start)) ? s(body.period_start) : month + "-01";
        const ge = /^\d{4}-\d{2}-\d{2}$/.test(s(body.period_end)) ? s(body.period_end) : month + "-31";
        const { data: cds } = await supa.from("collections").select("do_no,driver_id")
          .gte("do_date", gs).lte("do_date", ge).limit(2000);
        const nk = (x: any) => String(x == null ? "" : x).toUpperCase().replace(/[^A-Z0-9]/g, "");
        const dos = (cds || []).filter((r: any) => nk(r.driver_id) === nk(driver_key)).map((r: any) => String(r.do_no));
        let pending: string[] = [];
        if (dos.length) {
          const { data: rv } = await supa.from("collection_reviews").select("do_no,reviewed").in("do_no", dos);
          const ok = new Set((rv || []).filter((x: any) => x.reviewed).map((x: any) => String(x.do_no)));
          pending = dos.filter((d) => !ok.has(d));
        }
        if (pending.length)
          return json({ result: { error: "Cannot approve: " + pending.length + " DO(s) in this period are not yet reviewed on the Collections tab: " + pending.slice(0, 12).join(", ") + (pending.length > 12 ? " ..." : ""), pending } });
      }
      const { data: before } = await supa.from("salary_approvals").select("*").eq("driver_id", driver_id).eq("month", month).maybeSingle();
      const arow: any = { driver_id, month, approved_by: actor, approved_at: new Date().toISOString(), locked: lock };
      if (driver_key) arow.driver_key = driver_key;
      const ps = s(body.period_start), pe = s(body.period_end);
      if (/^\d{4}-\d{2}-\d{2}$/.test(ps)) arow.period_start = ps;
      if (/^\d{4}-\d{2}-\d{2}$/.test(pe)) arow.period_end = pe;
      const { data: after, error } = await supa.from("salary_approvals")
        .upsert(arow, { onConflict: "driver_id,month" }).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, action, "salary_approvals", driver_id + ":" + month, before, after);
      return json({ ok: true, actor, result: { ok: true, row: after } });
    }
    if (action === "note.add") {
      const row: any = { entity_type: s(body.entity_type), entity_id: s(body.entity_id), author: actor, body: s(body.body) };
      if (!row.entity_type || !row.entity_id || !row.body) return json({ result: { error: "entity_type, entity_id and body required" } });
      if (s(body.assign_to)) row.assign_to = s(body.assign_to);
      if (s(body.due)) row.due = s(body.due);
      const { data: ins, error } = await supa.from("notes").insert(row).select().single();
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "note.add", "notes", String(ins.id), null, ins);
      return json({ ok: true, actor, result: { ok: true, row: ins } });
    }
    if (action === "note.done") {
      const id = Number(body.id); if (!id) return json({ result: { error: "id required" } });
      const { error } = await supa.from("notes").update({ done: true }).eq("id", id);
      if (error) return json({ result: { error: error.message } });
      await audit(actor, "note.done", "notes", String(id), { done: false }, { done: true });
      return json({ ok: true, actor, result: { ok: true } });
    }
    if (action === "jobcard.set") {
      const lockMonth = String(s(body.card_date) || "").slice(0, 7);
      if (await isLocked(Number(body.driver_id), lockMonth)) {
        return json({ result: { error: "salary month " + lockMonth + " is APPROVED and locked - unlock it first (Qris/Sheryl)" } });
      }
      return json({ ok: true, actor, result: await jobcardSet(s(body.card_date) || "", Number(body.driver_id), s(body.field_key) || "", body.old_value, body.new_value, actor) });
    }
    return json({ error: "unknown action: " + action }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
