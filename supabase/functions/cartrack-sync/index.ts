/* ============================================================
   Lirich — Cartrack Fleet API → SSOT sync (Scope 1 fleet data).
   Pulls per-vehicle DAILY distance + fuel from the Cartrack Fleet API
   into odometer_log / fuel_log, so Scope 1 carbon and the
   odometer-vs-job misuse control run off live telematics instead of
   the emailed CO2 PDF. (task #21)

   Auth to Cartrack: HTTP Basic base64(user:password) — read-only USER
   credential. Region = Singapore → base https://fleetapi-sg.cartrack.com/rest
   Secrets (server-side only): CARTRACK_API_USER, CARTRACK_API_PASSWORD.

   Function is gated by SYNC_KEY (falls back to DEVICE_KEY) so only the
   cron / an admin can trigger it. Writes with the service role.

   MODES (?mode=):
     probe  → calls the candidate endpoints for ONE vehicle + ONE day and
              returns the RAW shapes (status + body), writing NOTHING. Run
              this first to confirm the real field names + whether the
              trucks report fuel via sensor, THEN the field pickers below
              are locked in. (handoff Step 1)
     sync   → (default) lands the target day (?date=YYYY-MM-DD, default
              = yesterday SGT) into odometer_log + fuel_log, idempotent.

   CARBON: this function only LANDS raw litres/km (+ Cartrack's own CO2 as a
   cross-check field). Scope 1 tCO2e is computed downstream from the SSOT
   `factors` table (diesel 2.678) so there is ONE methodology for audit.
   Cartrack's ~230 gCO2/km is a reconciliation check, never the reported number.
   ============================================================ */
import { createClient } from "npm:@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const CT_USER = Deno.env.get("CARTRACK_API_USER") || "";
const CT_PASS = Deno.env.get("CARTRACK_API_PASSWORD") || "";
const CT_BASE = "https://fleetapi-sg.cartrack.com/rest";
const SYNC_KEY = Deno.env.get("SYNC_KEY") || Deno.env.get("DEVICE_KEY") || "";
/* Diesel consumption used to ESTIMATE litres from Cartrack distance — the trucks have NO fuel
   sensor (confirmed: /fuel/level returns empty), so litres are estimated, not measured.
   0.50 L/km = 50 L/100km, indicative for a stop-start collection truck. Refine from actual
   fuel-purchase totals (Σ litres ÷ Σ km). Flagged: fuel_log.entered_by='cartrack-est'. */
const FUEL_L_PER_KM = 0.50;

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "content-type",
};
const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { "content-type": "application/json", ...CORS } });

/* ---- Cartrack HTTP (Basic auth) ---- */
function ctAuth(): string {
  return "Basic " + btoa(`${CT_USER}:${CT_PASS}`);
}
async function ctGet(path: string): Promise<{ status: number; body: unknown }> {
  const r = await fetch(CT_BASE + path, { headers: { Authorization: ctAuth(), Accept: "application/json" } });
  let body: unknown; try { body = await r.json(); } catch { body = await r.text().catch(() => null); }
  return { status: r.status, body };
}
async function ctPost(path: string, payload: unknown): Promise<{ status: number; body: unknown }> {
  const r = await fetch(CT_BASE + path, {
    method: "POST",
    headers: { Authorization: ctAuth(), Accept: "application/json", "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  let body: unknown; try { body = await r.json(); } catch { body = await r.text().catch(() => null); }
  return { status: r.status, body };
}

/* ---- date helpers (SGT = UTC+8) ---- */
function sgtYesterday(): string {
  const now = new Date(Date.now() + 8 * 3600 * 1000); // shift to SGT wall clock
  now.setUTCDate(now.getUTCDate() - 1);
  return now.toISOString().slice(0, 10); // YYYY-MM-DD
}
/* a day's window as Cartrack-format LOCAL timestamps "Y-m-d H:i:s" (account TZ = SGT).
   Cartrack's odometer/trips/fuel endpoints require start_timestamp/end_timestamp in this
   EXACT format — no 'T', no timezone, no milliseconds — else HTTP 422 (confirmed live). */
function sgtDayWindow(dateYmd: string): { startTs: string; endTs: string } {
  return { startTs: `${dateYmd} 00:00:00`, endTs: `${dateYmd} 23:59:59` };
}

/* ---- field pickers (central, so a shape change = one edit; confirm via probe) ---- */
const numFrom = (o: any, keys: string[]): number | null => {
  for (const k of keys) {
    const v = Number(o?.[k]);
    if (Number.isFinite(v)) return v;
  }
  return null;
};
const strFrom = (o: any, keys: string[]): string | null => {
  for (const k of keys) {
    const v = o?.[k];
    if (typeof v === "string" && v.trim()) return v.trim();
  }
  return null;
};
/* unwrap { data: [...] } / { vehicles: [...] } / [...] */
const asArray = (b: any): any[] =>
  Array.isArray(b) ? b : (b?.data ?? b?.vehicles ?? b?.trips ?? b?.results ?? b?.items ?? []);

/* ============================================================ PROBE */
async function probe(reg: string | null, date: string): Promise<unknown> {
  const { startTs, endTs } = sgtDayWindow(date);
  const trunc = (r: { status: number; body: unknown }) => ({
    status: r.status,
    sample: JSON.parse(JSON.stringify(r.body)),
  });
  const out: Record<string, unknown> = { date, window: { startTs, endTs } };

  // 1) vehicles list — learn registration field + count
  const vehicles = await ctGet("/vehicles");
  const varr = asArray(vehicles.body);
  out.vehicles = { status: vehicles.status, count: varr.length,
    regs: varr.map((x) => strFrom(x, ["registration", "reg", "vehicle_registration", "plate"])),
    first: varr[0] ?? null };
  const useReg = reg || strFrom(varr[0] || {}, ["registration", "reg", "vehicle_registration", "plate"]);
  out.useReg = useReg;

  if (useReg) {
    // 2) odometer / daily distance — docs-recommended source for daily km
    out.odometer = trunc(await ctGet(`/vehicles/${encodeURIComponent(useReg)}/odometer?start_timestamp=${encodeURIComponent(startTs)}&end_timestamp=${encodeURIComponent(endTs)}`));
    // 3) trips overlapping the day (has trip_distance + coords + idle)
    out.trips = trunc(await ctGet(`/trips?start_timestamp=${encodeURIComponent(startTs)}&end_timestamp=${encodeURIComponent(endTs)}`));
    // 4) fuel used estimate (needs a fuel sensor — this is the make-or-break check)
    out.fuel_level = trunc(await ctPost("/fuel/level", {
      registrations: [useReg], start_timestamp: startTs, end_timestamp: endTs,
    }));
  }
  return out;
}

/* ============================================================ SYNC
   NB: field pickers below are best-guess from the docs; confirm/adjust
   after the first probe. Idempotent via delete-then-insert on source='cartrack'. */
async function syncDay(date: string): Promise<unknown> {
  const { startTs, endTs } = sgtDayWindow(date);

  // our fleet (registrations we track) + fuel type
  const { data: fleet } = await supa.from("vehicles").select("vehicle_id,vtype,active");
  const regs = (fleet || []).map((v: any) => String(v.vehicle_id));
  const vtypeOf: Record<string, string> = {};
  for (const v of (fleet || []) as any[]) vtypeOf[String(v.vehicle_id)] = (v.vtype || "diesel");

  const vehicles = await ctGet("/vehicles");
  const ctVehicles = asArray(vehicles.body);

  const results: any[] = [];
  for (const v of ctVehicles) {
    const reg = strFrom(v, ["registration", "reg", "vehicle_registration", "plate"]);
    if (!reg || !regs.includes(reg)) continue; // only vehicles in our SSOT

    const row: any = { reg, distance_km: null, odometer_km: null, litres: null, co2_g: null, errors: [] };

    // --- distance (+ cumulative odometer if present) ---
    try {
      const od = await ctGet(`/vehicles/${encodeURIComponent(reg)}/odometer?start_timestamp=${encodeURIComponent(startTs)}&end_timestamp=${encodeURIComponent(endTs)}`);
      const ob = (od.body as any);
      let one = ob && ob.data !== undefined ? ob.data : ob;   // Cartrack wraps payload in { data: {...} }
      if (Array.isArray(one)) one = one[0] || {};
      const distM = numFrom(one, ["distance"]);                          // Cartrack distance is in METRES
      row.distance_km = distM != null ? Math.round(distM / 10) / 100 : null;   // → km, 2dp
      const odoM = numFrom(one, ["current_odometer_value", "end_odometer_value"]); // metres
      row.odometer_km = odoM != null ? Math.round(odoM / 1000) : null;          // → whole km (column is integer)
      row.co2_g = null;   // Cartrack odometer endpoint returns no CO2 (no cross-check field here)
    } catch (e) { row.errors.push("odometer:" + String(e)); }

    // --- fuel (litres used) — only if trucks report a fuel sensor ---
    try {
      const fl = await ctPost("/fuel/level", { registrations: [reg], start_timestamp: startTs, end_timestamp: endTs });
      const fb = asArray((fl.body as any));
      const one = fb.length ? fb[0] : (fl.body as any);
      row.litres = numFrom(one, ["fuel_used", "estimated_fuel_used", "litres_used", "consumed", "fuel_used_litres", "litres"]);
    } catch (e) { row.errors.push("fuel:" + String(e)); }

    // no fuel sensor on the trucks → ESTIMATE litres from distance (indicative, flagged)
    let litresEstimated = false;
    if (row.litres == null && row.distance_km != null) {
      row.litres = Math.round(row.distance_km * FUEL_L_PER_KM * 100) / 100;
      litresEstimated = true;
    }

    // --- land odometer_log (distance + optional cumulative reading) ---
    if (row.distance_km != null || row.odometer_km != null) {
      await supa.from("odometer_log").delete().eq("vehicle_id", reg).eq("read_date", date).eq("source", "cartrack");
      const { error } = await supa.from("odometer_log").insert({
        vehicle_id: reg, read_date: date, odometer_km: row.odometer_km,
        distance_km: row.distance_km, cartrack_co2_g: row.co2_g, source: "cartrack",
        synced_at: new Date().toISOString(),
      });
      if (error) row.errors.push("odo_insert:" + error.message);
    }

    // --- land fuel_log (daily usage as a 'fill' row tagged cartrack) ---
    if (row.litres != null) {
      await supa.from("fuel_log").delete().eq("vehicle_id", reg).eq("fill_date", date).eq("source", "cartrack");
      const { error } = await supa.from("fuel_log").insert({
        vehicle_id: reg, fill_date: date, litres: row.litres, fuel_type: vtypeOf[reg] || "diesel",
        cartrack_co2_g: row.co2_g, entered_by: litresEstimated ? "cartrack-est" : "cartrack", source: "cartrack",
        synced_at: new Date().toISOString(),
      });
      if (error) row.errors.push("fuel_insert:" + error.message);
    }

    results.push(row);
  }

  const landedOdo = results.filter((r) => r.distance_km != null || r.odometer_km != null).length;
  const landedFuel = results.filter((r) => r.litres != null).length;
  return {
    date, matched_vehicles: results.length, landed_odometer: landedOdo, landed_fuel: landedFuel,
    note: landedFuel === 0
      ? "No fuel litres returned — trucks likely have no fuel sensor; derive litres from distance × a diesel L/km factor (set after probe) or use the emailed CO2 report."
      : "ok", results,
  };
}

/* ============================================================ SERVE */
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const url = new URL(req.url);
  const key = url.searchParams.get("key") || req.headers.get("x-sync-key") || "";
  if (!SYNC_KEY || key !== SYNC_KEY) return json({ error: "unauthorized" }, 403);
  if (!CT_USER || !CT_PASS) return json({ error: "Cartrack secrets not set (CARTRACK_API_USER / CARTRACK_API_PASSWORD)" }, 500);

  const mode = (url.searchParams.get("mode") || "sync").toLowerCase();
  const date = url.searchParams.get("date") || sgtYesterday();
  try {
    if (mode === "probe") return json(await probe(url.searchParams.get("reg"), date));
    return json(await syncDay(date));
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
