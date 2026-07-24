/* ============================================================
   Lirich Ops — Supabase Edge Function "sync" (replaces the
   Google Apps Script web app, same wire protocol).

   Endpoints (all require ?key= / body.key = DEVICE_KEY secret):
     GET  ?state=1 → full shared state        GET ?rev=1 → revision
     GET  ?db=1    → clients+pricing+bins+drivers+lists (from SSOT tables)
     POST {action} → mutations (addTrip, addJob, updateTrip, …)

   State blob lives in table app_state (id=1, jsonb, rev) — a straight
   port of the Apps Script ScriptProperties blob, so the driver app is
   unchanged apart from the URL. On every addTrip/updateTrip the trip is
   ALSO upserted into the normalized `collections` table (the SSOT), and
   jobs into `jobs`. Photos go to the public `do-photos` storage bucket.

   emailDO is forwarded to the legacy Apps Script (Gmail lives there).

   Deploy notes: disable "Enforce JWT" for this function; set secrets
   DEVICE_KEY (shared with the app) and LEGACY_SCRIPT_URL (optional).
   ============================================================ */
import { createClient } from "npm:@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const DEVICE_KEY = Deno.env.get("DEVICE_KEY") || "";
const LEGACY_SCRIPT_URL = Deno.env.get("LEGACY_SCRIPT_URL") || "";
const PUB = `${Deno.env.get("SUPABASE_URL")}/storage/v1/object/public/do-photos/`;

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), {
    status,
    headers: { "content-type": "application/json", ...CORS },
  });

/* Safe ISO timestamp — the app may store times as ms-epoch numbers, numeric
   strings, or blanks; a bad value must NOT crash the mirror (it used to throw
   RangeError and silently drop the whole trip). Returns null on anything unparseable. */
function toISO(v: any): string | null {
  if (v == null || v === "") return null;
  const d = new Date(typeof v === "string" && /^-?\d+$/.test(v.trim()) ? Number(v) : v);
  return isNaN(d.getTime()) ? null : d.toISOString();
}

/* ---------------- state blob ---------------- */
async function getState(): Promise<any | null> {
  const { data } = await supa.from("app_state").select("state,rev").eq("id", 1).maybeSingle();
  if (!data) return null;
  const st = data.state;
  st.rev = Number(data.rev);
  return st;
}
async function putState(st: any) {
  const rev = st.rev;
  await supa.from("app_state").upsert({ id: 1, state: st, rev, updated_at: new Date().toISOString() });
}

/* ---------------- ?db=1 — reference payload from SSOT tables ---------------- */
async function customerDB() {
  const out: any = { clients: [], drivers: [], wasteTypes: [], dumpLocations: [], binTypes: [], bins: [] };
  const [{ data: sites }, { data: customers }, { data: rates }, { data: bins }, { data: drivers }, { data: lists }] =
    await Promise.all([
      supa.from("sites").select("site_id,client_id,address,active").eq("active", true),
      supa.from("customers").select("client_id,name,active").eq("active", true),
      supa.from("rate_card").select("site_id,job_type,price"),
      supa.from("bins").select("bin_id,bin_type,active").eq("active", true),
      supa.from("drivers").select("driver_id,name,active").eq("active", true),
      supa.from("ref_lists").select("kind,value"),
    ]);
  const cname: Record<string, string> = {};
  (customers || []).forEach((c: any) => (cname[c.client_id] = c.name));
  const priceBySite: Record<string, Record<string, number>> = {};
  (rates || []).forEach((r: any) => {
    (priceBySite[r.site_id] = priceBySite[r.site_id] || {})[r.job_type] = Number(r.price);
  });
  (sites || []).forEach((s: any) => {
    out.clients.push({
      name: cname[s.client_id] || s.client_id,
      addr: s.address || "",
      contact: "",
      phone: "",
      prices: priceBySite[s.site_id] || {},
    });
  });
  (bins || []).forEach((b: any) => out.bins.push({ no: b.bin_id, size: b.bin_type || "" }));
  (drivers || []).forEach((d: any) => out.drivers.push({ name: d.name, vehicle: "" }));
  (lists || []).forEach((l: any) => {
    if (l.kind === "waste") out.wasteTypes.push(l.value);
    else if (l.kind === "dump") out.dumpLocations.push(l.value);
    else if (l.kind === "bin_type") out.binTypes.push(l.value);
  });
  return out;
}

/* ---------------- photos → storage bucket ---------------- */
async function addPhoto(q: any) {
  const name = `${Date.now().toString(36)}-${(q.name || "do-photo.jpg").replace(/[^\w.\-]/g, "_")}`;
  const bytes = Uint8Array.from(atob(q.b64), (c) => c.charCodeAt(0));
  const { error } = await supa.storage.from("do-photos").upload(name, bytes, { contentType: "image/jpeg" });
  if (error) throw error;
  return { id: name, url: PUB + name, thumb: PUB + name };
}

/* ---------------- normalized SSOT mirror ---------------- */
async function siteIdFor(st: any, clientId: string | null, siteIdx: number) {
  try {
    const c = (st.clients || []).find((x: any) => x.id === clientId);
    if (!c) return null;
    const addr = c.sites && c.sites.length ? (c.sites[siteIdx || 0] || c.sites[0]).addr : "";
    const { data: cust } = await supa.from("customers").select("client_id").ilike("name", c.name).maybeSingle();
    if (!cust) return null;
    if (addr) {
      const { data: s } = await supa.from("sites").select("site_id")
        .eq("client_id", cust.client_id).ilike("address", addr).maybeSingle();
      if (s) return s.site_id;
    }
    const { data: s1 } = await supa.from("sites").select("site_id")
      .eq("client_id", cust.client_id).limit(1).maybeSingle();
    return s1 ? s1.site_id : null;
  } catch (_) { return null; }
}
async function driverIdFor(name: string) {
  if (!name) return null;
  const { data } = await supa.from("drivers").select("driver_id").ilike("name", name).maybeSingle();
  return data ? data.driver_id : null;
}
function pick(urls: any[], kind: string[]) {
  return (urls || []).filter((p: any) => p && p.url && kind.includes(p.kind)).map((p: any) => p.url).join("\n") || null;
}
async function mirrorTrip(st: any, t: any) {
  if (t._test) return; /* office test account never touches the SSOT */
  try {
    const w = t.weight || {};
    const v = t.vessel || {};
    const net = (w.gross || w.gross === 0) && (w.tare || w.tare === 0)
      ? Math.round((Number(w.gross) - Number(w.tare) + (Number(t.weightAdj) || 0)) * 100) / 100 : null;
    const row: any = {
      do_no: t.doNo ? String(t.doNo) : `APP-T${t.id}`,
      source: "live",
      job_no: t.jobId ? String(t.jobId) : null,
      do_date: t.date || null,
      do_type: t.doType || "standard",
      trip_type: t._type || null,
      site_id: await siteIdFor(st, t.clientId, t.jobSiteIdx || 0),
      vessel_name: v.name || null,
      berth: v.location || null,
      vehicle_id: null, /* set below only if the plate exists in vehicles */
      driver_id: await driverIdFor(t._driver || ""),
      job_type: t.jobType || null,
      waste_type: t.waste || null,
      vol_cat_a: v.a || null, vol_cat_b: v.b || null, vol_cat_c: v.c || null,
      vol_cat_d: v.d || null, vol_cat_e: v.e || null, vol_cat_f: v.f || null,
      vol_total_m3: v.total || null,
      gross_kg: w.gross ?? null, tare_kg: w.tare ?? null, net_kg: net,
      weigh_ticket_no: w.ticket || null,
      weight_source: net != null ? "weighbridge" : "volume_est",
      photo_do_ref: pick(t.photos, ["do"]),
      photo_sig_ref: pick(t.photos, ["signature"]),
      photo_weigh_ref: pick(t.photos, ["gross", "tare"]),
      backfill_notes: [
        `app_trip_id=${t.id}`,
        t.disposeTo ? `dispose_to=${t.disposeTo}` : "",
        t.remarks ? `remarks=${t.remarks}` : "",
        pick(t.photos, ["bin", "in", "out"]) ? `bin_photos=${pick(t.photos, ["bin", "in", "out"])}` : "",
      ].filter(Boolean).join(" | ") || null,
      synced_at: new Date().toISOString(),
    };
    if (t.vehicleNo) {
      const { data: veh } = await supa.from("vehicles").select("vehicle_id").eq("vehicle_id", t.vehicleNo).maybeSingle();
      if (veh) row.vehicle_id = veh.vehicle_id;
      else row.backfill_notes = [(row.backfill_notes || ""), `vehicle_raw=${t.vehicleNo}`].filter(Boolean).join(" | ");
    }
    if (t.binIn) {
      const { data: b } = await supa.from("bins").select("bin_id").eq("bin_id", t.binIn).maybeSingle();
      if (b) row.bin_in = b.bin_id;
      else row.backfill_notes = [(row.backfill_notes || ""), `bin_in_raw=${t.binIn}`].filter(Boolean).join(" | ");
    }
    if (t.binOut) {
      const { data: b } = await supa.from("bins").select("bin_id").eq("bin_id", t.binOut).maybeSingle();
      if (b) row.bin_out = b.bin_id;
      else row.backfill_notes = [(row.backfill_notes || ""), `bin_out_raw=${t.binOut}`].filter(Boolean).join(" | ");
    }
    let { error: colErr } = await supa.from("collections").upsert(row, { onConflict: "do_no" });
    if (colErr && row.job_no) {
      /* most likely a job_no FK failure (the job hasn't mirrored) — a trip must
         never be silently dropped, so keep the linkage in notes and retry unlinked */
      console.error("collections upsert error (retrying without job_no)", colErr);
      row.backfill_notes = [(row.backfill_notes || ""), `job_no=${row.job_no}`].filter(Boolean).join(" | ");
      row.job_no = null;
      ({ error: colErr } = await supa.from("collections").upsert(row, { onConflict: "do_no" }));
    }
    if (colErr) console.error("collections upsert FAILED", colErr);
  } catch (e) { console.error("mirrorTrip failed", e); }
}
async function mirrorJob(j: any) {
  if (j._test) return;
  try {
    const { error: jobErr } = await supa.from("jobs").upsert({
      job_no: String(j.id),
      job_date: j.date || null,
      status: j.status || "assigned",
      site_id: null, /* app site linkage arrives with the trip */
      contact: j._contact || null,
      task: j._task || j.task || null,
      bin_size: j.binSize || null,
      waste_type: j.waste || null,
      dump_to: j.dumpTo || null,
      driver_id: await driverIdFor(j._driver || ""),
      started_at: toISO(j.startedAt),
    }, { onConflict: "job_no" });
    if (jobErr) console.error("mirrorJob upsert error", jobErr);
  } catch (e) { console.error("mirrorJob failed", e); }
}

/* ---------------- mutations (straight port of Apps Script apply_) ---------------- */
function find(arr: any[], id: any) { return (arr || []).find((x) => x.id === id) || null; }
async function apply(st: any, q: any) {
  switch (q.action) {
    case "addJob":
      q.job.id = st.seq.job++;
      st.jobs.push(q.job);
      await mirrorJob(q.job);
      break;
    case "updateJob": {
      const j = find(st.jobs, q.id);
      if (j) { Object.assign(j, q.patch); await mirrorJob(j); }
      break;
    }
    case "voidJob": {
      const vj = find(st.jobs, q.id);
      if (vj) {
        if ((st.trips || []).some((x: any) => x.jobId === q.id && x.invoiced))
          throw "This job has an invoiced trip and cannot be voided.";
        vj.status = "void";
        await mirrorJob(vj);
      }
      break;
    }
    case "addTrip": {
      const t = q.trip;
      t.id = st.seq.trip++;
      t.tServer = Date.now();
      if (t.needTicket && t.weight) t.weight.ticket = "LR" + (st.seq.ticket++);
      delete t.needTicket;
      if (t.photosB64 && t.photosB64.length) {
        const jobtag = t.jobId ? t.jobId : "T" + t.id;
        const kinds = t.photoKinds || [];
        const tsArr = t.photoTs || [];
        const PFX: Record<string, string> = { do: "DO", out: "BINOUT", in: "BININ", bin: "BIN", gross: "GROSS", tare: "TARE", signature: "SIG" };
        const cnt: Record<string, number> = {};
        t.photos = [];
        for (let pi = 0; pi < t.photosB64.length; pi++) {
          const kind = kinds[pi] || "do";
          const pfx = PFX[kind] || "DO";
          cnt[pfx] = (cnt[pfx] || 0) + 1;
          try {
            const rec: any = await addPhoto({ b64: t.photosB64[pi], name: `${pfx}-${jobtag}-${cnt[pfx]}.jpg` });
            rec.kind = kind; rec.ts = tsArr[pi] || 0;
            t.photos.push(rec);
          } catch (_) { /* keep the trip even if a photo fails */ }
        }
      }
      delete t.photosB64; delete t.photoKinds; delete t.photoTs;
      const ensureBin = (no: string) => {
        let b = (st.bins || []).find((x: any) => x.no === no);
        if (!b) { b = { no, size: "", status: "unknown", clientId: null, siteIdx: 0, source: "driver", firstSeen: t.date }; st.bins.push(b); }
        if (!b.size && t.jobBinSize) b.size = t.jobBinSize;
        return b;
      };
      if (!t._test) {
        if (t.binIn) { const bi = ensureBin(t.binIn); bi.status = "client"; bi.clientId = t.clientId; bi.siteIdx = t.jobSiteIdx || 0; }
        if (t.binOut) { const bo = ensureBin(t.binOut); bo.status = "yard"; bo.clientId = null; bo.siteIdx = 0; }
      }
      const mirrorSiteIdx = t.jobSiteIdx || 0;
      delete t.jobBinSize;
      if (t.jobId && q.final !== false) { const tj = find(st.jobs, t.jobId); if (tj) { tj.status = "done"; await mirrorJob(tj); } }
      st.trips.push(t);
      t.jobSiteIdx = mirrorSiteIdx; await mirrorTrip(st, t); delete t.jobSiteIdx;
      break;
    }
    case "setTonnAdj": {
      const tr = find(st.trips, q.id);
      if (tr) { tr.tonnAdj = q.adj; await mirrorTrip(st, tr); }
      break;
    }
    case "updateTrip": {
      const tu = find(st.trips, q.id);
      if (tu) {
        const wasFinal = q.patch && "final" in q.patch ? q.patch.final : null;
        if (q.patch) delete q.patch.final;
        Object.assign(tu, q.patch);
        if (tu.weight && tu.weight.gross && !tu.weight.ticket) tu.weight.ticket = "LR" + (st.seq.ticket++);
        if (wasFinal === true && tu.jobId) { const tj2 = find(st.jobs, tu.jobId); if (tj2) { tj2.status = "done"; await mirrorJob(tj2); } }
        await mirrorTrip(st, tu);
      }
      break;
    }
    case "updateBin": {
      const b2 = (st.bins || []).find((b: any) => b.no === q.no);
      if (b2) Object.assign(b2, q.patch);
      break;
    }
    case "addClient":
      st.clients.push(q.client);
      break;
    case "replaceClients":
      st.clients = q.clients;
      break;
    case "replaceBins":
      (q.bins || []).forEach((nb: any) => {
        const eb = (st.bins || []).find((x: any) => x.no === nb.no);
        if (!eb) st.bins.push(nb);
        else if (!eb.size && nb.size) eb.size = nb.size;
      });
      break;
    default:
      throw "Unknown action: " + q.action;
  }
}

/* ---------------- HTTP entry ---------------- */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  try {
    if (req.method === "GET") {
      if ((url.searchParams.get("key") || "") !== DEVICE_KEY) return json({ error: "bad key" }, 403);
      if (url.searchParams.get("db")) return json(await customerDB());
      const st = await getState();
      if (url.searchParams.get("rev")) return json({ rev: st ? st.rev : 0 });
      return json(st || { empty: true, rev: 0 });
    }
    /* POST */
    const q = JSON.parse(await req.text());
    if ((q.key || "") !== DEVICE_KEY) return json({ error: "bad key" }, 403);
    delete q.key;
    if (q.action === "addPhoto") return json(await addPhoto(q));
    if (q.action === "emailDO") {
      if (!LEGACY_SCRIPT_URL) return json({ sent: false, error: "email bridge not configured" });
      const r = await fetch(LEGACY_SCRIPT_URL, { method: "POST", body: JSON.stringify(q) });
      return json(await r.json());
    }
    let st = await getState();
    if (q.action === "initState") {
      if (!st) { st = q.state; st.rev = 1; await putState(st); }
      return json(st);
    }
    if (q.action === "resetState") {
      const prev = st ? st.rev : 0;
      st = q.state; st.rev = prev + 1;
      await putState(st);
      return json(st);
    }
    if (!st) return json({ error: "Database not initialised — open the app once while online." });
    await apply(st, q);
    st.rev++;
    await putState(st);
    return json(st);
  } catch (err) {
    return json({ error: String(err) });
  }
});
