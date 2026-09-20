import * as XLSX from "npm:xlsx@0.18.5";
import { PDFDocument, StandardFonts, rgb } from "npm:pdf-lib@1.17.1";
import fontkit from "npm:@pdf-lib/fontkit@1.1.1";
import { CINZEL_BASE64 } from "./cinzel_font.ts";
import {
  authenticate,
  PortalContext,
  resolveClient,
  writeAccessEvent,
} from "../_shared/portal_auth.ts";

type Collection = Record<string, any>;
type Period = { from: string; to: string; label: string };
const SGT = "Asia/Singapore";

function singaporeDate(date = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: SGT, year: "numeric", month: "2-digit", day: "2-digit" }).format(date);
}

function addDays(iso: string, days: number): string {
  const value = new Date(`${iso}T00:00:00Z`);
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString().slice(0, 10);
}

const allowedOrigins = (Deno.env.get("PORTAL_ALLOWED_ORIGINS") || "https://www.lirichgroup.com")
  .split(",").map((v) => v.trim()).filter(Boolean);

function cors(req: Request): HeadersInit {
  const origin = req.headers.get("origin") || "";
  return {
    "Access-Control-Allow-Origin": allowedOrigins.includes(origin) ? origin : allowedOrigins[0],
    "Access-Control-Allow-Methods": "GET,POST,PUT,OPTIONS",
    "Access-Control-Allow-Headers": "authorization,content-type",
    "Access-Control-Max-Age": "600",
    "Vary": "Origin",
  };
}

function response(req: Request, data: unknown, status = 200, requestId?: string): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "x-request-id": requestId || "", ...cors(req) },
  });
}

function failStatus(message: string): number {
  if (/missing_bearer|invalid_token|expired_token|account_inactive|mismatch|unsupported_token/.test(message)) return 401;
  if (/staff_client_required|client_required|invalid_period|invalid_format|invalid_widget|not_found/.test(message)) return 400;
  if (/forbidden|denied/.test(message)) return 403;
  return 500;
}

function period(url: URL, body: any = {}): Period {
  const now = new Date();
  const from = String(body.from || url.searchParams.get("from") || `${now.getUTCFullYear()}-01-01`).slice(0, 10);
  const to = String(body.to || url.searchParams.get("to") || now.toISOString().slice(0, 10)).slice(0, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(from) || !/^\d{4}-\d{2}-\d{2}$/.test(to) || from > to) {
    throw new Error("invalid_period");
  }
  return { from, to, label: String(body.period_label || `${from} to ${to}`) };
}

function number(value: unknown): number {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function round(value: number, places = 2): number {
  const factor = 10 ** places;
  return Math.round((value + Number.EPSILON) * factor) / factor;
}

function monthKey(date: string): string {
  return String(date || "unknown").slice(0, 7);
}

async function tenantRows(ctx: PortalContext, clientId: string, p: Period) {
  const { data: customer, error: customerError } = await ctx.db.from("customers")
    .select("client_id,name").eq("client_id", clientId).maybeSingle();
  if (customerError) throw new Error(customerError.message);
  if (!customer) throw new Error("client_not_found");

  const { data: sites, error: siteError } = await ctx.db.from("sites")
    .select("site_id,site_name,address").eq("client_id", clientId).eq("active", true).order("site_name");
  if (siteError) throw new Error(siteError.message);
  const siteIds = (sites || []).map((s: any) => s.site_id);
  if (!siteIds.length) return { customer, sites: [], collections: [], reviews: [], adjustments: [] };

  const fields = [
    "do_no", "do_date", "do_type", "trip_type", "site_id", "vessel_name", "berth", "voyage_no",
    "waste_type", "vol_cat_a", "vol_cat_b", "vol_cat_c", "vol_cat_d", "vol_cat_e", "vol_cat_f",
    "vol_cat_i", "vol_oily_rags_m3", "vol_expired_med_m3", "vol_other_m3", "other_desc",
    "vol_total_m3", "net_kg", "weight_source", "weigh_ticket_no", "photo_do_ref", "photo_sig_ref",
    "photo_weigh_ref", "sludge_requested_t", "sludge_actual_t", "dispose_to", "source",
  ].join(",");
  /* PostgREST caps one response at 1000 rows. ST Engineering alone clears that
     in a year, so an unpaginated read silently truncated the materials mix, the
     evidence list and every row-derived total - the header said 1000 collections
     while the engine counted 1016. Page until the server returns a short page.
     Added 14 Sep 2026. */
  const collections: any[] = [];
  for (let offset = 0; offset <= 100000; offset += 1000) {
    const page = await ctx.db.from("collections")
      .select(fields).is("superseded_by", null).in("site_id", siteIds).gte("do_date", p.from).lte("do_date", p.to)
      .order("do_date").order("do_no").range(offset, offset + 999);
    if (page.error) throw new Error(page.error.message);
    const chunk = page.data || [];
    for (const row of chunk) collections.push(row);
    if (chunk.length < 1000) break;
  }
  const doNos = (collections || []).map((r: any) => r.do_no);
  if (!doNos.length) return { customer, sites: sites || [], collections: [], reviews: [], adjustments: [] };
  /* 19 Sep 2026 - PostgREST filters travel in the URL. .in("do_no", doNos) across a
     9-month STE range built a request line of roughly 10 KB and fetch refused to send
     it, so the client workspace rendered a raw TypeError. Query in fixed batches.
     Result is identical: every adjustment for a given do_no lands in the SAME batch,
     so the ordered "latest wins" below is unaffected by the split. */
  const IN_CHUNK = 100;
  const uniqDoNos = Array.from(new Set(doNos.filter(Boolean)));
  const reviews: any[] = [];
  const adjustments: any[] = [];
  /* Batches run concurrently: they are independent reads and the earlier sequential
     loop turned one round trip into six. Order is still deterministic - results are
     reassembled in slice order below, and every adjustment for a do_no sits in one
     slice, so the ordered "latest wins" is unaffected. */
  const slices: string[][] = [];
  for (let i = 0; i < uniqDoNos.length; i += IN_CHUNK) slices.push(uniqDoNos.slice(i, i + IN_CHUNK));
  const batched = await Promise.all(slices.map(async (slice) => {
    const [rvR, ajR] = await Promise.all([
      ctx.db.from("collection_reviews").select("do_no,reviewed,reviewed_by,reviewed_at").in("do_no", slice),
      ctx.db.from("adjustments").select("do_no,field,new_value,reason,adjusted_by,adjusted_at").in("do_no", slice).order("adjusted_at"),
    ]);
    if (rvR.error) throw new Error(rvR.error.message);
    if (ajR.error) throw new Error(ajR.error.message);
    return { rv: rvR.data || [], aj: ajR.data || [] };
  }));
  for (const b of batched) { reviews.push(...b.rv); adjustments.push(...b.aj); }
  const latest = new Map<string, any>();
  for (const a of adjustments || []) latest.set(`${a.do_no}:${a.field}`, a);
  const effective = (collections || []).map((row: any) => {
    const copy = { ...row };
    for (const field of ["net_kg", "vol_total_m3", "waste_type", "dispose_to"]) {
      const item = latest.get(`${row.do_no}:${field}`);
      if (item) copy[field] = field === "net_kg" || field === "vol_total_m3" ? number(item.new_value) : item.new_value;
    }
    return copy;
  });
  return { customer, sites: sites || [], collections: effective, reviews: reviews || [], adjustments: adjustments || [] };
}

const density = { a: 0.0239684, b: 0.2746868, c: 0.1631509, d: 0.8976043, e: 1, f: 0.0818721, i: 0.2100197, rags: 0.0889914, med: 1, other: 0.1631509 };
const disposalFactor = { b: 0.5697939, c: 1.5304606, e: 0.0124606, f: 0.1114606, rags: 1.4791273 };

async function factorSet(ctx: PortalContext) {
  const { data, error } = await ctx.db.from("factors").select("id,domain,key,value,unit,basis,source_ref,valid_from,valid_to,vintage")
    .in("domain", ["waste", "avoided"]).eq("key", "general_waste").order("valid_from", { ascending: false });
  if (error) throw new Error(error.message);
  const waste = (data || []).find((r: any) => r.domain === "waste");
  const avoided = (data || []).find((r: any) => r.domain === "avoided");
  if (!waste || !avoided) throw new Error("factor_missing");
  return { waste, avoided };
}

// Reviewed site-token map: the invoice reconciliation view names sites by a short token,
// the sites table by full name. Confirmed by Michelle 15 Sep 2026. Clients absent here
// fall back to exact site-name matching.
const SITE_TOKEN_MAP: any = { STE: { "Benoi Yard": "Benoi", "Gul Yard": "Gul", "Tuas Nexus": "Tuas Nexus", "CDPL Tuas Dormitory": "CDPL" } };
function summarize(rows: Collection[], sites: any[], reviews: any[], factors: any) {
  const _rowDoNos = new Set(rows.map((r: any) => String(r.do_no)));
            // Count a review only against a row inside this period, so the numerator and the
            // denominator always describe the same set of loads.
            const reviewed = new Set(reviews.filter((r: any) => r.reviewed).map((r: any) => String(r.do_no)).filter((d: string) => _rowDoNos.has(d)));
  const siteMap = new Map(sites.map((s: any) => [s.site_id, s]));
  const monthly: Record<string, any> = {};
  const bySite: Record<string, any> = {};
  const material = { plastics: 0, food: 0, domestic: 0, cooking_oil: 0, ash: 0, operational: 0, ewaste: 0, oily_rags: 0, medicine: 0, other: 0, sludge: 0 };
  const materialWeight: Record<string, number> = {};
  const wbByMonth = {}, rowsByMonth = {};
    let gapRows = 0, netKg = 0, volume = 0, docBacked = 0, weighed = 0, wbKg = 0;
  for (const row of rows) {
    const mk = monthKey(row.do_date);
    monthly[mk] ||= { month: mk, collections: 0, volume_m3: 0, net_kg: 0, verified: 0 };
    monthly[mk].collections++;
    monthly[mk].volume_m3 += number(row.vol_total_m3);
    monthly[mk].net_kg += number(row.net_kg);
    if (reviewed.has(row.do_no)) monthly[mk].verified++;
    const s = siteMap.get(row.site_id) || { site_name: row.site_id };
    bySite[row.site_id] ||= { site_id: row.site_id, site_name: s.site_name || row.site_id, collections: 0, volume_m3: 0, net_t: 0 };
    bySite[row.site_id].collections++;
    bySite[row.site_id].volume_m3 += number(row.vol_total_m3);
    bySite[row.site_id].net_t += number(row.net_kg) / 1000;
    material.plastics += number(row.vol_cat_a); material.food += number(row.vol_cat_b);
    material.domestic += number(row.vol_cat_c); material.cooking_oil += number(row.vol_cat_d);
    material.ash += number(row.vol_cat_e); material.operational += number(row.vol_cat_f);
    material.ewaste += number(row.vol_cat_i); material.oily_rags += number(row.vol_oily_rags_m3);
    material.medicine += number(row.vol_expired_med_m3); material.other += number(row.vol_other_m3);
    material.sludge += number(row.sludge_actual_t);
    const materialName = String(row.waste_type || "Unclassified").trim() || "Unclassified";
    materialWeight[materialName] = (materialWeight[materialName] || 0) + number(row.net_kg) / 1000;
    netKg += number(row.net_kg); volume += number(row.vol_total_m3);
    { const _ym = String(row.do_date || "").slice(0, 7); rowsByMonth[_ym] = (rowsByMonth[_ym] || 0) + 1; if (row.weight_source === "weighbridge" || String(row.weigh_ticket_no || "").trim()) wbByMonth[_ym] = (wbByMonth[_ym] || 0) + number(row.net_kg); }
      if (!(row.photo_do_ref || row.photo_weigh_ref || String(row.weigh_ticket_no || "").trim()) && (number(row.net_kg) > 0 || number(row.vol_total_m3) > 0)) gapRows++;
      if (row.photo_do_ref || row.photo_weigh_ref || row.weigh_ticket_no) docBacked++;
    /* Weighbridge-confirmed means the load crossed a bridge and the system holds
       the evidence: weight_source weighbridge, or a chit number on the row. Mass
       alone is not confirmation - it used to be counted as such, which is how a
       figure labelled verified came to include unweighed backfill. 14 Sep 2026. */
    if (row.weight_source === "weighbridge" || String(row.weigh_ticket_no || "").trim()) { weighed++; wbKg += number(row.net_kg); }
  }
  const recoveredT = material.plastics * density.a + material.cooking_oil * density.d + material.ewaste * density.i + material.sludge;
  const disposedT = material.food * density.b + material.domestic * density.c + material.ash * density.e + material.operational * density.f + material.oily_rags * density.rags + material.medicine * density.med + material.other * density.other;
  const cat5 = material.food * density.b * disposalFactor.b + material.domestic * density.c * disposalFactor.c + material.ash * density.e * disposalFactor.e + material.operational * density.f * disposalFactor.f + material.oily_rags * density.rags * disposalFactor.rags + (material.medicine * density.med + material.other * density.other) * number(factors.waste.value);
  const derivedHandledT = recoveredT + disposedT;
  // Net weight is the authoritative handled total when weighbridge data exists.
  // Category-volume densities remain the controlled fallback for legacy records.
  const handledT = netKg > 0 ? netKg / 1000 : derivedHandledT;
  const quality = {
    reviewed_pct: rows.length ? Math.round(reviewed.size / rows.length * 100) : 0,
    weighed_pct: rows.length ? Math.round(weighed / rows.length * 100) : 0,
    document_backed_pct: rows.length ? Math.round(docBacked / rows.length * 100) : 0,
    gaps: gapRows,
  };
  const score = Math.round((quality.reviewed_pct + quality.weighed_pct + quality.document_backed_pct) / 3);
  const status = rows.length === 0 || quality.gaps > 0 ? "data_gaps" : score < 90 ? "in_review" : "ready";
  return {
    by_month: { wb: wbByMonth, rows: rowsByMonth },
    totals: { collections: rows.length, volume_m3: round(volume), verified_weight_t: round(wbKg / 1000), waste_handled_t: round(handledT), recovered_t: round(recoveredT), disposed_t: round(disposedT), recovery_pct: derivedHandledT ? round(recoveredT / derivedHandledT * 100, 1) : 0, recovery_available: derivedHandledT > 0 },
    carbon: { scope_3_category_5_tco2e: round(cat5), avoided_tco2e: round(recoveredT * number(factors.avoided.value)), intensity_tco2e_per_t: handledT ? round(cat5 / handledT, 4) : 0, factor_coverage_pct: 100, factors },
    quality: { ...quality, score, status },
    monthly: Object.values(monthly).map((m: any) => ({ ...m, volume_m3: round(m.volume_m3), net_t: round(m.net_kg / 1000) })).sort((a: any, b: any) => a.month.localeCompare(b.month)),
    sites: Object.values(bySite).map((s: any) => ({ ...s, volume_m3: round(s.volume_m3), net_t: round(s.net_t) })).sort((a: any, b: any) => (b.net_t || b.volume_m3) - (a.net_t || a.volume_m3)),
    materials: (netKg > 0
      ? Object.entries(materialWeight).map(([key, value]) => ({ key, net_t: round(value), volume_m3: 0 }))
      : Object.entries(material).map(([key, value]) => ({ key, net_t: 0, volume_m3: round(number(value)) })))
      .sort((a, b) => (b.net_t || b.volume_m3) - (a.net_t || a.volume_m3)),
  };
}

/* The portal asks the report engine one question per request. It goes with the
   caller's own WP token, so the engine applies the caller's scope and the portal
   gains no privilege by asking. The engine owns the record lock (its four release
   rules) and the recovery / carbon maths, which need waste_routes and the temporal
   factor set the portal does not read. Reading them here means the two surfaces
   cannot drift. Returns null when the engine is unreachable; callers fail closed.
   Added 13 Sep 2026. */
/* The engine reports all time with a per month series, so only a window that is
   a whole number of calendar months can be answered exactly from its buckets. */
function isWholeMonths(from: string, to: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(from) || !/^\d{4}-\d{2}-\d{2}$/.test(to)) return false;
  if (from.slice(8) !== "01" || from > to) return false;
  const last = new Date(Date.UTC(Number(to.slice(0, 4)), Number(to.slice(5, 7)), 0)).getUTCDate();
  return Number(to.slice(8)) === last;
}
/* The whole calendar months that sit entirely inside a window. A period ending
   mid-month - a year-to-date view, or "last 30 days" - used to refuse to report
   recovery at all, because the engine only buckets by month. Report the months
   it does fully cover and say which. Added 14 Sep 2026. */
function coveredMonths(from: string, to: string): string[] {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(from) || !/^\d{4}-\d{2}-\d{2}$/.test(to) || from > to) return [];
  let sy = Number(from.slice(0, 4)), sm = Number(from.slice(5, 7));
  if (Number(from.slice(8)) !== 1) { sm++; if (sm > 12) { sm = 1; sy++; } }
  let ey = Number(to.slice(0, 4)), em = Number(to.slice(5, 7));
  const last = new Date(Date.UTC(ey, em, 0)).getUTCDate();
  if (Number(to.slice(8)) !== last) { em--; if (em < 1) { em = 12; ey--; } }
  const keys: string[] = [];
  while (sy < ey || (sy === ey && sm <= em)) {
    keys.push(String(sy) + "-" + String(sm).padStart(2, "0"));
    sm++; if (sm > 12) { sm = 1; sy++; }
  }
  return keys;
}
function monthsBetween(from: string, to: string): string[] {
  const keys: string[] = [];
  let y = Number(from.slice(0, 4)), m = Number(from.slice(5, 7));
  const ey = Number(to.slice(0, 4)), em = Number(to.slice(5, 7));
  while (y < ey || (y === ey && m <= em)) {
    keys.push(String(y) + "-" + String(m).padStart(2, "0"));
    m++; if (m > 12) { m = 1; y++; }
  }
  return keys;
}

async function engineFor(bearer: string, clientId: string, p: Period) {
  if (!bearer) return null;
  const base = Deno.env.get("SUPABASE_URL") || "";
  const _cm = coveredMonths(String(p.from), p.to);
  const _lm = _cm.length ? _cm[_cm.length - 1] : "";
  const _ef = _cm.length ? _cm[0] + "-01" : p.from;
  const _et = _cm.length ? new Date(Date.UTC(Number(_lm.slice(0, 4)), Number(_lm.slice(5, 7)), 0)).toISOString().slice(0, 10) : p.to;
  if (!base) return null;
  const url = base + "/functions/v1/report?what=client&client=" + encodeURIComponent(clientId) +
    "&from=" + encodeURIComponent(_ef) + "&to=" + encodeURIComponent(_et) +
    "&token=" + encodeURIComponent(bearer);
  const stop = new AbortController();
  const timer = setTimeout(() => stop.abort(), 20000);
  try {
    const res = await fetch(url, { signal: stop.signal });
    if (!res.ok) return null;
    const body = await res.json();
    return body && Array.isArray(body.released_dos) ? body : null;
  } catch (_e) {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

async function snapshot(ctx: PortalContext, clientId: string, p: Period, eng: any = null) {
  const [tenant, factors] = await Promise.all([tenantRows(ctx, clientId, p), factorSet(ctx)]);
  /* Show only what the lock released. One source of truth, upstream. */
  let lock: any = { applied: false, released: 0, withheld: 0 };
  if (eng && Array.isArray(eng.released_dos)) {
    const released = new Set(eng.released_dos.map((d: any) => String(d)));
    const before = tenant.collections.length;
    tenant.collections = tenant.collections.filter((r: any) => released.has(String(r.do_no)));
    tenant.adjustments = (tenant.adjustments || []).filter((a: any) => released.has(String(a.do_no)));
    lock = { applied: true, released: tenant.collections.length, withheld: before - tenant.collections.length };
  }
  const invAcc: any[] = [];
    // Commercial outcome per load, filled in below, read where `out` is assembled.
    const _cls: any = {};
  {
    const _st: any = SITE_TOKEN_MAP[clientId] || {};
    const _nameById: any = {};
    for (const s of (tenant.sites || [])) _nameById[String(s.site_id)] = s.site_name;
    const _inv = await ctx.db.from("v_invoice_vs_collections").select("month,site,stream,flag").eq("client_id", clientId);
    if (_inv.error) throw new Error(_inv.error.message);
    const _ok = new Set((_inv.data || []).filter((g: any) => String(g.flag || "") === "OK").map((g: any) => String(g.month) + "|" + String(g.site || "") + "|" + String(g.stream || "")))
      const _qKeys = new Set((_inv.data || []).filter((g: any) => String(g.flag || "") .indexOf("VARIANCE") >= 0).map((g: any) => String(g.month) + "|" + String(g.site || "") + "|" + String(g.stream || "")))
      const _niKeys = new Set((_inv.data || []).filter((g: any) => String(g.flag || "") === "RECORDED NOT INVOICED").map((g: any) => String(g.month) + "|" + String(g.site || "") + "|" + String(g.stream || "")));
    for (const r of (tenant.collections || [])) {
      const _sn = _nameById[String(r.site_id)] || "";
      const _tk = _st[String(_sn)] || String(_sn);
      const _k = String(r.do_date || "").slice(0, 7) + "|" + _tk + "|" + String(r.waste_type || "");
        _cls[String(r.do_no)] = _ok.has(_k) ? "ok" : (_qKeys.has(_k) ? "query" : (_niKeys.has(_k) ? "not_invoiced" : "unmatched"));
        if (_ok.has(_k)) invAcc.push({ do_no: r.do_no, reviewed: true, reviewed_by: "settled invoice", reviewed_at: null });
    }
  }
  const _cov = new Set(coveredMonths(String(p.from), p.to));
    const out: any = { client: { id: clientId, name: tenant.customer.name }, period: p, generated_at: new Date().toISOString(), ...summarize((_cov && _cov.size ? tenant.collections.filter((c: any) => _cov.has(String(c.do_date || "").slice(0, 7))) : tenant.collections), tenant.sites, (tenant.reviews || []).concat(invAcc), factors), collections: tenant.collections, reviews: tenant.reviews, adjustments: tenant.adjustments, lock };
    const _covColl = tenant.collections.filter((c: any) => _cov.has(String(c.do_date).slice(0, 7)));
    const _tally = { invoice_reconciled: 0, invoice_query: 0, not_invoiced: 0 };
    for (const c of _covColl) {
      const v = _cls[String(c.do_no)];
      if (v === "ok") _tally.invoice_reconciled++;
      else if (v === "query") _tally.invoice_query++;
      else _tally.not_invoiced++;
    }
    out.exception_summary = { loads: _covColl.length, invoice_reconciled: _tally.invoice_reconciled, invoice_query: _tally.invoice_query, not_invoiced: _tally.not_invoiced, open_commercial: _tally.invoice_query + _tally.not_invoiced };
  /* Recovery and carbon come from the engine month buckets, never from a
     portal-side guess. The engine measures land rows by mass and vessel rows by
     volume and keeps the two series separate, so both are read and added. Scope 3
     Category 5 exists for vessel rows only - land tonnage is disclosed as excluded
     rather than counted as zero, because the land methodology is not signed off. */
  const covered = coveredMonths(String(p.from), String(p.to));
  const exact = isWholeMonths(String(p.from), String(p.to));
  if (eng && covered.length) {
    const vm = new Map<string, any>(((eng.monthly || []) as any[]).map((x: any) => [String(x.month), x]));
    const lm = new Map<string, any>((((eng.land && eng.land.monthly) || []) as any[]).map((x: any) => [String(x.month), x]));
    let vesselT = 0, vesRec = 0, vesVol = 0, volPctWeighted = 0;
    let landT = 0, landRec = 0;
    let cat5 = 0, avoided = 0, bio = 0, fos = 0, inert = 0;
    for (const k of covered) {
      const v = vm.get(k), l = lm.get(k);
      const vc = v && v.carbon ? v.carbon : null;
      if (v) {
        const vol = Number(v.volume_m3) || 0;
        vesVol += vol;
        if (vc) volPctWeighted += (Number(vc.recovery_pct) || 0) * vol;
      }
      if (vc) {
        vesselT += Number(vc.waste_handled_t) || 0;
        vesRec += Number(vc.recovered_t) || 0;
        cat5 += Number(vc.cat5_tco2e) || 0;
        avoided += Number(vc.avoided_tco2e) || 0;
        bio += Number(vc.cat5_biogenic_tco2e) || 0;
        fos += Number(vc.cat5_fossil_tco2e) || 0;
        inert += Number(vc.cat5_inert_tco2e) || 0;
      }
      if (l) { landT += Number(l.net_t) || 0; landRec += Number(l.recovered_t) || 0; }
    }
    const handled = vesselT + landT;
    /* Land recovery is measured by mass, vessel recovery by volume. Blending the
       two into one percentage would state a number that no measurement supports,
       so each basis is reported on its own and the headline is withheld when both
       are present in the window. */
    const landPct = landT > 0 ? round((landRec / landT) * 100, 1) : null;
    const vesPct = vesVol > 0 ? round(volPctWeighted / vesVol, 1) : null;
    out.totals.waste_handled_t = round(handled, 3);
        if (out.by_month && covered.length) {
          out.totals.verified_weight_t = round(covered.reduce((a, k) => a + (out.by_month.wb[k] || 0), 0) / 1000, 2);
          out.totals.collections = covered.reduce((a, k) => a + (out.by_month.rows[k] || 0), 0);
          out.totals.period_basis = "Figures cover whole calendar months " + covered[0] + " to " + covered[covered.length - 1] + ". A month still in progress is excluded until it closes.";
        }
    out.totals.recovered_t = round(vesRec + landRec, 3);
    out.totals.recovery_land = { handled_t: round(landT, 3), recovered_t: round(landRec, 3), pct: landPct, basis: "mass, weighbridge net tonnes" };
          if (out.totals.recovery_land && Number(out.totals.recovery_land.handled_t) > 0) {
            out.totals.disposed_t = round(Number(out.totals.waste_handled_t) - Number(out.totals.recovered_t), 2);
          }
    out.totals.recovery_vessel = { handled_t: round(vesselT, 3), recovered_t: round(vesRec, 3), volume_m3: round(vesVol, 3), pct: vesPct, basis: "volume, m3 collected" };
    out.totals.recovery_pct = (landT > 0 && vesVol > 0) ? null : (landT > 0 ? landPct : vesPct);
    out.totals.recovery_available = out.totals.recovery_pct !== null;
    out.totals.recovery_basis = (landT > 0 && vesVol > 0)
      ? "no single figure: land recovery is measured by mass and vessel recovery by volume, so the two are reported separately"
      : (landT > 0 ? "route-confirmed recovery by mass, report engine" : "route-confirmed recovery by volume, report engine");
    out.totals.recovery_months = covered;
    if (!exact) {
      out.totals.recovery_basis = String(out.totals.recovery_basis) + ". Covers whole calendar months " + covered[0] +
        " to " + covered[covered.length - 1] + "; part-months at either end of the window are excluded because the engine reports by month";
    }
    out.carbon.scope_3_category_5_tco2e = round(cat5, 3);
    out.carbon.avoided_tco2e = round(avoided, 3);
    out.carbon.biogenic_tco2e = round(bio, 3);
    out.carbon.fossil_tco2e = round(fos, 3);
    out.carbon.inert_tco2e = round(inert, 3);
    out.carbon.intensity_tco2e_per_t = vesselT > 0 ? round(cat5 / vesselT, 4) : null;
    out.carbon.factor_coverage_pct = handled > 0 ? round((vesselT / handled) * 100, 1) : null;
    out.carbon.covered_t = round(vesselT, 3);
    out.carbon.excluded_t = round(landT, 3);
    out.carbon.complete = landT === 0 && vesselT > 0;
    out.carbon.source = "report-engine";
    out.carbon.basis = landT > 0
      ? "Scope 3 Category 5 covers vessel rows only. " + round(landT, 3) + " t of land tonnage in this period carries no emissions figure: the land methodology is not signed off."
      : "Scope 3 Category 5, vessel rows, report engine factor set.";

  // Land Scope 3 Category 5 (Option C, approved by Michelle 16 Sep 2026).
  // Computed by the report engine, which owns the factor mapping; this layer only
  // passes it through. Vessel and land are NEVER summed: vessel recovery is measured
  // by volume and land by weighed mass, so each is reported beside its own basis.
  const _lc: any = (eng && (eng as any).land && (eng as any).land.carbon) || null;
  if (_lc && _lc.ok === true) {
    (out as any).carbon.land = {
      headline_tco2e: _lc.headline_tco2e,
      headline_basis: _lc.headline_basis,
      allocation_tco2e: _lc.allocation_tco2e,
      allocation_basis: _lc.allocation_basis,
      avoided_tco2e: _lc.avoided_tco2e,
      avoided_basis: _lc.avoided_basis,
      never_sum: true,
      gwp: _lc.gwp,
      detail: _lc.detail,
      gaps: _lc.gaps,
      caveat: _lc.caveat
    };
    (out as any).carbon.excluded_t = 0;
    (out as any).carbon.complete = true;
    (out as any).carbon.basis = 'Vessel streams on SEFR waste-to-energy by volume; land streams on the approved mapping by weighed mass. Reported separately and never summed.';
  }
  } else {
    out.totals.recovered_t = null;
    out.totals.recovery_pct = null;
    out.totals.recovery_available = false;
    out.totals.recovery_months = [];
    out.totals.recovery_basis = eng ? "the window does not contain a complete calendar month, and the engine reports recovery by month" : "report engine unavailable";
    out.carbon.scope_3_category_5_tco2e = null;
    out.carbon.avoided_tco2e = null;
    out.carbon.intensity_tco2e_per_t = null;
    out.carbon.complete = false;
    out.carbon.factor_coverage_pct = null;
    out.carbon.source = "unavailable";
    out.carbon.basis = out.totals.recovery_basis;
  }
  /* The materials mix grouped by the raw waste_type string, so ST Engineering
     showed fenders under five labels and tyres under two. Group by the material
     the engine already resolves from waste_routes instead. Vessel clients keep
     their volume-based mix. Added 14 Sep 2026. */
  if (eng && eng.land && eng.land.ok && Array.isArray(eng.land.routes)) {
    const matOf: Record<string, string> = {};
    for (const rt of (eng.land.routes as any[])) matOf[String(rt.cat)] = String(rt.material);
    const byMat: Record<string, number> = {};
    let landKg = 0;
    const lrows: any = eng.land.rows || {};
    for (const k of Object.keys(lrows)) {
      for (const lr of (lrows[k] || [])) {
        const kg = Number(lr.net) || 0;
        if (!kg) continue;
        landKg += kg;
        const label = lr.cat ? (matOf[String(lr.cat)] || String(lr.cat)) : "Unclassified";
        byMat[label] = (byMat[label] || 0) + kg;
      }
    }
    const vesselVol = ((eng.monthly || []) as any[]).reduce((a: number, m: any) => a + (Number(m.volume_m3) || 0), 0);
    if (landKg > 0 && vesselVol === 0) {
      out.materials = Object.keys(byMat)
        .map((k) => ({ key: k, net_t: round(byMat[k] / 1000, 2), volume_m3: 0 }))
        .sort((a: any, b: any) => b.net_t - a.net_t);
    }
  }
  return out;
}

function metadataRows(s: any, templateVersion: any, account: any) {
  return [
    ["Client", s.client.name], ["Client ID", s.client.id], ["Reporting period", s.period.label],
    ["Period start", s.period.from], ["Period end", s.period.to],
    ["Reporting coverage", (function () { const pb = String((s.totals && s.totals.period_basis) || ""); const mm = pb.match(/\d{4}-\d{2}/g) || []; if (mm.length) { const a = mm[0], b = mm[mm.length - 1]; return (a === b ? a : a + " to " + b) + " \u2014 whole closed calendar months only"; } return "not stated"; })()], ["Template", templateVersion?.template_id || "Management report"],
    ["Template version", templateVersion?.version || "layout"], ["Generated at", s.generated_at],
    ["Generated by", account.wp_login], ["Data-quality status", s.quality.status],
  ];
}

function xlsxBytes(s: any, templateVersion: any, account: any): Uint8Array {
  const workbook = XLSX.utils.book_new();
  const meta = XLSX.utils.aoa_to_sheet([["LIRICH GROUP — CONTROLLED REPORT"], [], ...metadataRows(s, templateVersion, account)]);
  meta["!cols"] = [{ wch: 24 }, { wch: 60 }];
  XLSX.utils.book_append_sheet(workbook, meta, "Report metadata");
  const summary = XLSX.utils.json_to_sheet([{ ...s.totals, ...s.carbon, factors: undefined, data_quality_score: s.quality.score, status: s.quality.status }]);
  XLSX.utils.book_append_sheet(workbook, summary, "Summary");
  XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(s.monthly), "Monthly trend");
  XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(s.materials), "Materials");
  XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(s.sites), "Sites");
  XLSX.utils.book_append_sheet(workbook, XLSX.utils.json_to_sheet(s.collections), "Approved records");
  return XLSX.write(workbook, { type: "array", bookType: "xlsx", compression: true }) as Uint8Array;
}

async function pdfBytes(s: any, templateVersion: any, account: any): Promise<Uint8Array> {
  const doc = await PDFDocument.create();
  doc.registerFontkit(fontkit);
  const regular = await doc.embedFont(StandardFonts.Helvetica);
  const bold = await doc.embedFont(StandardFonts.HelveticaBold);
  const brandFontBytes = Uint8Array.from(atob(CINZEL_BASE64), (c) => c.charCodeAt(0));
  const brandFont = await doc.embedFont(brandFontBytes, { subset: true });
  const gold = rgb(0.76, 0.55, 0.07), navy = rgb(0.035, 0.11, 0.19), blue = rgb(0.08, 0.36, 0.59);
  const teal = rgb(0.03, 0.55, 0.47), orange = rgb(0.98, 0.44, 0.09), grey = rgb(0.35, 0.39, 0.43);
  const pale = rgb(0.96, 0.97, 0.98), paleBlue = rgb(0.92, 0.96, 0.98), lineGrey = rgb(0.84, 0.86, 0.88), white = rgb(1, 1, 1), black = rgb(0, 0, 0);
  const size: [number, number] = [595.28, 841.89];
  const n = (value: any) => Number.isFinite(Number(value)) ? Number(value) : 0;
  const fmt = (value: any, digits = 1) => n(value).toLocaleString("en-SG", { minimumFractionDigits: digits, maximumFractionDigits: digits });
  const clean = (value: any) => String(value ?? "").replace(/[–—]/g, "-").replace(/[^\x20-\x7E]/g, " ").replace(/\s+/g, " ").trim();
  const drawRight = (p: any, text: string, x: number, y: number, fontSize: number, font = regular, color = navy) => {
    const value = clean(text); p.drawText(value, { x: x - font.widthOfTextAtSize(value, fontSize), y, size: fontSize, font, color });
  };
  const wrap = (text: string, maxWidth: number, fontSize: number, font = regular) => {
    const words = clean(text).split(" ").filter(Boolean), lines: string[] = []; let current = "";
    for (const word of words) { const test = current ? `${current} ${word}` : word; if (font.widthOfTextAtSize(test, fontSize) <= maxWidth) current = test; else { if (current) lines.push(current); current = word; } }
    if (current) lines.push(current); return lines;
  };
  const paragraph = (p: any, text: string, x: number, y: number, maxWidth: number, fontSize = 8.5, color = grey, leading = 12, font = regular) => {
    const lines = wrap(text, maxWidth, fontSize, font); lines.forEach((line, i) => p.drawText(line, { x, y: y - i * leading, size: fontSize, font, color })); return y - lines.length * leading;
  };
  const header = (p: any, eyebrow: string, title: string, subtitle: string) => {
    p.drawRectangle({ x: 0, y: 754, width: size[0], height: 88, color: white });
    p.drawRectangle({ x: 0, y: 748, width: size[0], height: 6, color: orange });
    p.drawText("LIRICH GROUP", { x: 42, y: 798, size: 22, font: brandFont, color: black });
    p.drawText(clean(eyebrow).toUpperCase(), { x: 43, y: 779, size: 7.5, font: bold, color: navy });
    p.drawText(clean(title), { x: 42, y: 717, size: 22, font: bold, color: navy });
    p.drawText(clean(subtitle), { x: 42, y: 697, size: 9, font: regular, color: grey });
  };
  const section = (p: any, title: string, x: number, y: number, width = 511) => {
    p.drawText(clean(title).toUpperCase(), { x, y, size: 10, font: bold, color: gold });
    p.drawLine({ start: { x, y: y - 7 }, end: { x: x + width, y: y - 7 }, thickness: 1, color: lineGrey });
  };
  const card = (p: any, x: number, y: number, width: number, label: string, value: string, note: string, accent: any) => {
    p.drawRectangle({ x, y, width, height: 78, color: white, borderColor: lineGrey, borderWidth: 0.8 });
    p.drawRectangle({ x, y, width: 5, height: 78, color: accent });
    p.drawText(clean(label).toUpperCase(), { x: x + 15, y: y + 56, size: 7, font: bold, color: grey });
    p.drawText(clean(value), { x: x + 15, y: y + 31, size: 17, font: bold, color: navy });
    p.drawText(clean(note), { x: x + 15, y: y + 13, size: 6.8, font: regular, color: grey });
  };
  const horizontalBars = (p: any, rows: any[], x: number, y: number, width: number, height: number, labelKey: string, valueKey: string, unit: string, color: any) => {
    const data = (rows || []).filter((r: any) => n(r[valueKey]) > 0).slice(0, 7), max = Math.max(...data.map((r: any) => n(r[valueKey])), 1);
    if (!data.length) { p.drawText("No measured data is available for this period.", { x, y: y - 15, size: 8, font: regular, color: grey }); return; }
    const rowH = height / data.length;
    data.forEach((r: any, i: number) => {
      const yy = y - i * rowH; const label = clean(r[labelKey]).slice(0, 27); const value = n(r[valueKey]);
      p.drawText(label, { x, y: yy, size: 7.2, font: regular, color: navy });
      const barX = x + 135, barY = yy - 1;
      p.drawRectangle({ x: barX, y: barY, width: width - 205, height: 8, color: paleBlue });
      p.drawRectangle({ x: barX, y: barY, width: Math.max(2, (width - 205) * value / max), height: 8, color });
      drawRight(p, `${fmt(value, value >= 100 ? 0 : 1)} ${unit}`, x + width, yy, 7.2, bold, navy);
    });
  };
  const footer = (p: any, pageNo: number, pageCount: number) => {
    p.drawLine({ start: { x: 42, y: 35 }, end: { x: 553, y: 35 }, thickness: 0.6, color: gold });
    p.drawText(`Controlled report | ${clean(s.client.id)} | ${clean(s.period.from)} to ${clean(s.period.to)}`, { x: 42, y: 20, size: 6.5, font: regular, color: grey });
    drawRight(p, `Page ${pageNo} of ${pageCount}`, 553, 20, 6.5, regular, grey);
  };

  // Page 1 - executive dashboard
  const p1 = doc.addPage(size);
  header(p1, "Client sustainability report", clean(s.client.name), `${clean(s.period.label)} | Generated ${clean(String(s.generated_at).slice(0, 10))}`);
  p1.drawRectangle({ x: 42, y: 648, width: 511, height: 30, color: paleBlue, borderColor: lineGrey, borderWidth: 0.7 });
  p1.drawText("CLIENT REPORT", { x: 53, y: 659, size: 8, font: bold, color: gold });
  p1.drawText(`${fmt(s.totals?.collections, 0)} completed collections`, { x: 165, y: 659, size: 8, font: bold, color: navy });
  p1.drawText("Prepared from controlled operational records", { x: 320, y: 659, size: 7.5, font: regular, color: grey });
  section(p1, "Performance at a glance", 42, 625);
  const recovery = s.totals?.recovery_pct == null ? "Separate bases" : `${fmt(s.totals.recovery_pct, 1)}%`;
  const landCarbon = s.carbon?.land || null;
  const scope3Value = n(s.carbon?.scope_3_category_5_tco2e) || n(landCarbon?.headline_tco2e);
  const avoidedValue = n(s.carbon?.avoided_tco2e) || n(landCarbon?.avoided_tco2e);
  const factorCoverage = n(s.carbon?.factor_coverage_pct) || (landCarbon && s.carbon?.complete ? 100 : 0);
  card(p1, 42, 522, 161, "Waste handled", `${fmt(s.totals?.waste_handled_t, 1)} t`, `${fmt(s.totals?.collections, 0)} completed collections`, teal);
  card(p1, 217, 522, 161, "Recovery", recovery, s.totals?.recovery_pct == null ? "Land mass / vessel volume" : `${fmt(s.totals?.recovered_t, 1)} t recovered`, blue);
  card(p1, 392, 522, 161, "Net weight recorded", `${fmt(s.totals?.verified_weight_t, 1)} t`, "Based on weighbridge records", gold);
  card(p1, 42, 430, 161, "Scope 3 Category 5", `${fmt(scope3Value, 1)} tCO2e`, landCarbon ? "Approved land-waste method" : "Waste generated in operations", navy);
  card(p1, 217, 430, 161, "Avoided emissions", `${fmt(avoidedValue, 1)} tCO2e`, "Reported outside the inventory", orange);
  card(p1, 392, 430, 161, "Factor coverage", `${fmt(factorCoverage, 0)}%`, "Of disclosed activity data", teal);
  section(p1, "Monthly waste handled", 42, 404);
  const monthly = (s.monthly || []).slice(-12), chartX = 50, chartY = 171, chartW = 495, chartH = 190;
  p1.drawRectangle({ x: chartX, y: chartY, width: chartW, height: chartH, color: white, borderColor: lineGrey, borderWidth: 0.7 });
  const maxMonthly = Math.max(...monthly.map((m: any) => n(m.net_t)), 1);
  const plotLeft = chartX + 35, plotRight = chartX + chartW - 10, plotWidth = plotRight - plotLeft;
  const slot = plotWidth / Math.max(monthly.length, 1);
  [0, 0.25, 0.5, 0.75, 1].forEach((q) => { const yy = chartY + 28 + q * 135; p1.drawLine({ start: { x: chartX + 35, y: yy }, end: { x: chartX + chartW - 10, y: yy }, thickness: 0.35, color: lineGrey }); p1.drawText(fmt(maxMonthly * q, 0), { x: chartX + 5, y: yy - 2, size: 5.8, font: regular, color: grey }); });
  monthly.forEach((m: any, i: number) => { const bh = 135 * n(m.net_t) / maxMonthly; const barWidth = Math.max(6, slot * 0.58); const bx = plotLeft + i * slot + (slot - barWidth) / 2; p1.drawRectangle({ x: bx, y: chartY + 28, width: barWidth, height: bh, color: i === monthly.length - 1 ? orange : blue }); const monthLabel = clean(m.month).slice(5); p1.drawText(monthLabel, { x: bx + (barWidth - regular.widthOfTextAtSize(monthLabel, 5.8)) / 2, y: chartY + 12, size: 5.8, font: regular, color: grey }); });
  p1.drawText("Net tonnes by closed calendar month", { x: 50, y: 150, size: 7.5, font: regular, color: grey });
  p1.drawText("The latest bar is highlighted.", { x: 405, y: 150, size: 7.5, font: regular, color: grey });
  p1.drawRectangle({ x: 42, y: 74, width: 511, height: 55, color: pale });
  p1.drawText("REPORTING NOTE", { x: 54, y: 110, size: 7, font: bold, color: gold });
  paragraph(p1, clean(s.totals?.period_basis || s.carbon?.basis || "Figures reflect the controlled reporting period and available verified records."), 54, 95, 485, 7.3, grey, 10);

  // Page 2 - operational composition
  const p2 = doc.addPage(size);
  header(p2, "Operational analysis", "Materials and service locations", "Where the activity came from and how recovery is measured");
  section(p2, "Material profile", 42, 665);
  const materialUsesMass = (s.materials || []).some((r: any) => n(r.net_t) > 0); const materialKey = materialUsesMass ? "net_t" : "volume_m3"; const materialUnit = materialUsesMass ? "t" : "m3";
  horizontalBars(p2, s.materials || [], 42, 628, 511, 185, "key", materialKey, materialUnit, teal);
  p2.drawText(`Top measured materials (${materialUsesMass ? "weighed mass" : "collected volume"})`, { x: 42, y: 426, size: 7.3, font: regular, color: grey });
  section(p2, "Service location comparison", 42, 398);
  const siteUsesMass = (s.sites || []).some((r: any) => n(r.net_t) > 0); const siteKey = siteUsesMass ? "net_t" : "volume_m3"; const siteUnit = siteUsesMass ? "t" : "m3";
  horizontalBars(p2, s.sites || [], 42, 361, 511, 145, "site_name", siteKey, siteUnit, blue);
  section(p2, "Recovery outcome", 42, 198);
  const handled = n(s.totals?.waste_handled_t), recovered = n(s.totals?.recovered_t), disposed = Math.max(0, n(s.totals?.disposed_t));
  if (s.totals?.recovery_pct != null && handled > 0) {
    const rw = 511 * Math.min(1, recovered / handled);
    p2.drawRectangle({ x: 42, y: 139, width: 511, height: 28, color: paleBlue });
    p2.drawRectangle({ x: 42, y: 139, width: rw, height: 28, color: teal });
    p2.drawRectangle({ x: 42 + rw, y: 139, width: Math.max(0, 511 - rw), height: 28, color: orange });
    p2.drawText(`Recovered ${fmt(recovered, 1)} t`, { x: 42, y: 119, size: 8, font: bold, color: teal });
    drawRight(p2, `Disposed ${fmt(disposed, 1)} t`, 553, 119, 8, bold, orange);
  } else {
    p2.drawRectangle({ x: 42, y: 117, width: 511, height: 50, color: pale });
    p2.drawText("Recovery rates use separate measurement bases", { x: 55, y: 148, size: 10, font: bold, color: navy });
    paragraph(p2, clean(s.totals?.recovery_basis || "Land activity is measured by mass and vessel activity by collected volume; they are presented separately."), 55, 132, 480, 7.3, grey, 10);
  }
  p2.drawText("Avoided emissions are disclosed separately and are not deducted from the Scope 3 inventory.", { x: 42, y: 87, size: 7.3, font: regular, color: grey });

  // Page 3 - detailed table and methodology
  const p3 = doc.addPage(size);
  header(p3, "Report detail", "Monthly activity and controls", "A review-ready summary of the data behind the dashboard");
  section(p3, "Monthly activity", 42, 665);
  const tx = [42, 190, 330, 455];
  p3.drawRectangle({ x: 42, y: 620, width: 511, height: 25, color: navy });
  ["Month", "Collections", "Volume (m3)", "Net weight (tonnes)"].forEach((h, i) => p3.drawText(h, { x: tx[i] + 5, y: 629, size: 7, font: bold, color: white }));
  (s.monthly || []).slice(-12).forEach((m: any, i: number) => { const yy = 598 - i * 24; if (i % 2 === 0) p3.drawRectangle({ x: 42, y: yy - 5, width: 511, height: 23, color: pale }); const values = [clean(m.month), fmt(m.collections, 0), fmt(m.volume_m3, 1), fmt(m.net_t, 1)]; values.forEach((v, j) => p3.drawText(v, { x: tx[j] + 5, y: yy + 2, size: 7.3, font: j === 0 ? bold : regular, color: navy })); });
  section(p3, "Methodology and assurance", 42, 290);
  const notes = [
    ["Boundary", clean(s.totals?.period_basis || `Records dated ${s.period.from} to ${s.period.to}.`)],
    ["GHG treatment", clean(s.carbon?.basis || "Scope 3 Category 5 is calculated from controlled waste factors. Avoided emissions are reported separately.")],
    ["Data basis", "The report uses completed collection records for the stated period. Supporting operational evidence is retained in Lirich's controlled system."],
    ["Controls", "Calculations use controlled Lirich methodology records. The generated artifact is stored with a SHA-256 checksum and an immutable audit record."],
  ];
  let noteY = 257;
  for (const [label, text] of notes) { p3.drawText(label.toUpperCase(), { x: 42, y: noteY, size: 7, font: bold, color: gold }); noteY = paragraph(p3, text, 132, noteY, 421, 7.5, grey, 10) - 10; }
  p3.drawRectangle({ x: 42, y: 62, width: 511, height: 48, color: paleBlue, borderColor: lineGrey, borderWidth: 0.6 });
  p3.drawText("CONTROLLED REPORT", { x: 54, y: 91, size: 8, font: bold, color: navy });
  p3.drawText(`Template ${clean(templateVersion?.template_id || "PORTAL_MANAGEMENT")} ${clean(templateVersion?.version || "")}`, { x: 54, y: 75, size: 7, font: regular, color: grey });
  drawRight(p3, `Generated by ${clean(account?.wp_login || "authorised user")}`, 541, 75, 7, regular, grey);

  const pages = doc.getPages(); pages.forEach((p, i) => footer(p, i + 1, pages.length));
  doc.setTitle(`Lirich report - ${clean(s.client.name)} - ${clean(s.period.label)}`);
  doc.setAuthor("Lirich Group"); doc.setSubject("Controlled client sustainability report");
  return await doc.save({ useObjectStreams: false });
}

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

const DASHBOARD_CACHE_VERSION = 1;
const DASHBOARD_CACHE_TTL_MS = 6 * 60 * 60 * 1000;

function dashboardSummary(data: any) {
  return {
    lock: data.lock,
    client: data.client,
    period: data.period,
    generated_at: data.generated_at,
    totals: data.totals,
    quality: data.quality,
    monthly: data.monthly,
    materials: data.materials,
    sites: data.sites,
    carbon: data.carbon,
    exception_summary: data.exception_summary,
  };
}

async function cachedDashboardSummary(
  ctx: PortalContext,
  clientId: string,
  p: Period,
  build: () => Promise<any>,
) {
  const lookup = await ctx.admin.from("portal_dashboard_cache")
    .select("payload,generated_at,expires_at,source_row_count")
    .eq("client_id", clientId)
    .eq("period_from", p.from)
    .eq("period_to", p.to)
    .eq("cache_version", DASHBOARD_CACHE_VERSION)
    .maybeSingle();
  if (!lookup.error && lookup.data && Date.parse(lookup.data.expires_at) > Date.now()) {
    return {
      ...(lookup.data.payload as Record<string, unknown>),
      cache: {
        hit: true,
        generated_at: lookup.data.generated_at,
        expires_at: lookup.data.expires_at,
        source_row_count: lookup.data.source_row_count,
      },
    };
  }

  const full = await build();
  const payload = dashboardSummary(full);
  const generatedAt = new Date().toISOString();
  const expiresAt = new Date(Date.now() + DASHBOARD_CACHE_TTL_MS).toISOString();
  const sourceRowCount = Number(full.collections?.length || full.totals?.collections || 0);
  const stored = await ctx.admin.from("portal_dashboard_cache").upsert({
    client_id: clientId,
    period_from: p.from,
    period_to: p.to,
    cache_version: DASHBOARD_CACHE_VERSION,
    payload,
    generated_at: generatedAt,
    expires_at: expiresAt,
    source_row_count: sourceRowCount,
  }, { onConflict: "client_id,period_from,period_to,cache_version" });
  if (stored.error) console.error("portal_dashboard_cache_write", stored.error.message);
  return {
    ...payload,
    cache: {
      hit: false,
      generated_at: generatedAt,
      expires_at: expiresAt,
      source_row_count: sourceRowCount,
    },
  };
}

async function exportArtifact(ctx: PortalContext, clientId: string, p: Period, body: any, eng: any = null) {
  const format = String(body.format || "").toLowerCase();
  if (!['pdf', 'xlsx'].includes(format)) throw new Error("invalid_format");
  const { data: reportingPeriod, error: periodError } = await ctx.db.from("reporting_periods")
    .select("id,status,data_quality_status").eq("client_id", clientId).eq("period_start", p.from).eq("period_end", p.to).maybeSingle();
  if (periodError) throw new Error(periodError.message);
  let anchorPeriod: any = reportingPeriod;
      let coveredPeriodIds: string[] = reportingPeriod ? [reportingPeriod.id] : [];
      if (!anchorPeriod) {
        const span = await ctx.db.from("reporting_periods").select("id,status,data_quality_status,period_start,period_end").eq("client_id", clientId).lte("period_start", p.to).gte("period_end", p.from).order("period_start");
        if (span.error) throw new Error(span.error.message);
        const spanRows = (span.data || []).filter((r: any) => String(r.status || "") !== "superseded");
        if (!spanRows.length) throw new Error("reporting_period_not_found");
        const rank: any = { data_gaps: 3, in_review: 2, ready: 1 };
        const worst = spanRows.map((r: any) => String(r.data_quality_status || "")).filter((s: string) => !!s).sort((x: string, y: string) => (rank[y] || 0) - (rank[x] || 0))[0] || "";
        anchorPeriod = { ...spanRows[spanRows.length - 1] };
        if (worst) anchorPeriod.data_quality_status = worst;
        coveredPeriodIds = spanRows.map((r: any) => r.id);
      }
  let templateQuery = ctx.db.from("report_template_versions").select("id,template_id,version,status,checksum_sha256").eq("status","active");
  templateQuery = body.template_version_id ? templateQuery.eq("id",body.template_version_id) : templateQuery.eq("template_id","PORTAL_MANAGEMENT");
  const result = await templateQuery.maybeSingle();
  if (result.error) throw new Error(result.error.message);
  if (!result.data) throw new Error("template_version_not_found");
  const templateVersion: any = result.data;
  const data = await snapshot(ctx, clientId, p, eng);
  const generated = new Date().toISOString();
  data.generated_at = generated;
  const bytes = format === "xlsx" ? xlsxBytes(data, templateVersion, ctx.account) : await pdfBytes(data, templateVersion, ctx.account);
  const hash = await sha256Hex(bytes);
  const artifactId = crypto.randomUUID();
  const path = `${clientId}/${p.from}_${p.to}/${artifactId}.${format}`;
  const contentType = format === "pdf" ? "application/pdf" : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
  const upload = await ctx.admin.storage.from("client-reports").upload(path, bytes, { contentType, upsert: false });
  if (upload.error) throw new Error(`artifact_upload_failed:${upload.error.message}`);
  const row = {
    id: artifactId, client_id: clientId, reporting_period_id: anchorPeriod.id,
    template_version_id: templateVersion.id, format, bucket_id: "client-reports", object_path: path,
    sha256: hash, byte_size: bytes.byteLength, generated_at: generated, generated_by: ctx.account.id,
    data_quality_status: anchorPeriod.data_quality_status || data.quality.status, generation_status: "completed",
    data_snapshot: { client: data.client, period: data.period, totals: data.totals, carbon: data.carbon, quality: data.quality, period_coverage: { from: p.from, to: p.to, reporting_period_ids: coveredPeriodIds, exact_period_match: !!reportingPeriod } },
    layout_snapshot: body.layout || {},
  };
  const inserted = await ctx.db.from("report_artifacts").insert(row);
  if (inserted.error) {
    await ctx.admin.storage.from("client-reports").remove([path]);
    throw new Error(`artifact_record_failed:${inserted.error.message}`);
  }
  const signed = await ctx.admin.storage.from("client-reports").createSignedUrl(path, 300, { download: true });
  if (signed.error) throw new Error(`artifact_sign_failed:${signed.error.message}`);
  await writeAccessEvent(ctx, "report.export", "success", { client_id: clientId, endpoint: "export", format, reporting_period_id: anchorPeriod.id, template_version_id: templateVersion.id, artifact_id: artifactId, sha256: hash }, true);
  const { data_snapshot: _dataSnapshot, layout_snapshot: _layoutSnapshot, ...publicArtifact } = row;
  return { artifact: publicArtifact, download_url: signed.data.signedUrl, expires_in: 300 };
}

async function route(req: Request, ctx: PortalContext) {
  const url = new URL(req.url);
  const action = (url.searchParams.get("route") || "session").replace(/^\/+/, "");
  let body: any = {};
  if (req.method === "POST" || req.method === "PUT") body = await req.json().catch(() => ({}));
  if (action === "session") return { account: { id: ctx.account.id, wp_login: ctx.account.wp_login, display_name: ctx.account.display_name, role: ctx.account.role, client_id: ctx.account.client_id }, staff: ctx.staff };
  if (action === "clients") {
    if (!ctx.staff) throw new Error("forbidden");
    const { data, error } = await ctx.db.from("customers").select("client_id,name").eq("active", true).order("name");
    if (error) throw new Error(error.message); return { clients: data || [] };
  }
  const requested = String(body.client || url.searchParams.get("client") || "") || null;
  const clientId = resolveClient(ctx, requested);
  const p = period(url, body);
  const bearer = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "").trim();
  let engCache: any = undefined;
  const engine = async () => {
    if (engCache === undefined) engCache = await engineFor(bearer, clientId, p);
    if (!engCache) throw new Error("report_engine_unavailable");
    return engCache;
  };
  if (["overview", "materials", "carbon"].includes(action)) {
  const data = await cachedDashboardSummary(ctx, clientId, p, async () =>
    await snapshot(ctx, clientId, p, await engine())
  );
    if (action === "overview") return { lock: data.lock, client: data.client, period: data.period, generated_at: data.generated_at, totals: data.totals, quality: data.quality, monthly: data.monthly, materials: data.materials, exceptions: data.quality.gaps, exception_summary: data.exception_summary, cache: data.cache };
    if (action === "materials") return { client: data.client, period: data.period, totals: data.totals, quality: data.quality, monthly: data.monthly, materials: data.materials, sites: data.sites, cache: data.cache };
    return { client: data.client, period: data.period, totals: data.totals, quality: data.quality, carbon: data.carbon, monthly: data.monthly.map((m: any) => ({ month: m.month, net_t: m.net_t })), cache: data.cache };
  }
  if (action === "bookings") {
    const from = singaporeDate(), to = addDays(from, 6);
    const { data: jobs, error } = await ctx.db.from("job_orders")
      .select("client_reference,service_date,window_from,window_to,site_id,job_type,bin_type,bin_qty,status,received_via,updated_at")
      .eq("client_id", clientId).gte("service_date", from).lte("service_date", to)
      .order("service_date").order("window_from");
    if (error) throw new Error(error.message);
    const siteIds = [...new Set((jobs || []).map((job: any) => job.site_id).filter(Boolean))];
    const siteNames = new Map<string, string>();
    if (siteIds.length) {
      const sites = await ctx.db.from("sites").select("site_id,site_name").eq("client_id", clientId).in("site_id", siteIds);
      if (sites.error) throw new Error(sites.error.message);
      for (const site of sites.data || []) siteNames.set(site.site_id, site.site_name || "Client site");
    }
    const labels: Record<string, string> = { draft:"Awaiting confirmation",unassigned:"Confirmed",assigned:"Scheduled",accepted:"In progress",in_progress:"In progress",done:"Completed",cancelled:"Cancelled",no_show:"Completed" };
    return { client_id: clientId, from, to, timezone: SGT, bookings: (jobs || []).map((job: any) => ({
      reference: job.client_reference || "Pending reference", service_date: job.service_date,
      window_from: job.window_from, window_to: job.window_to, site_name: siteNames.get(job.site_id) || "Client site",
      job_type: job.job_type, bin_type: job.bin_type, quantity: job.bin_qty,
      status: labels[job.status] || "Awaiting confirmation", source: job.received_via === "client_portal" ? "Client portal" : "Planned service",
      updated_at: job.updated_at,
    })) };
  }
  if (action === "evidence") {
    const engE = await engine();
    const engRelE = new Set((engE.released_dos || []).map((d: any) => String(d)));
    const tenant=await tenantRows(ctx,clientId,p), doNos=tenant.collections.map((r:any)=>String(r.do_no)).filter((d:string)=>engRelE.has(d));
    tenant.adjustments=(tenant.adjustments||[]).filter((a:any)=>engRelE.has(String(a.do_no)));
    if(!doNos.length)return {client_id:clientId,period:p,evidence:[],exceptions:[],corrections:[]};
    /* 19 Sep 2026 - same URL-length fix as the corrections query above: PostgREST .in()
       travels in the URL, so a 9-month STE range overflowed the request line. Batched,
       then sorted and capped exactly as before so the response is unchanged. */
    const EV_CHUNK = 100;
    const uniqEvDos = Array.from(new Set(doNos.filter(Boolean)));
    let evAll: any[] = [];
    const evSlices: string[][] = [];
    for (let i = 0; i < uniqEvDos.length; i += EV_CHUNK) evSlices.push(uniqEvDos.slice(i, i + EV_CHUNK));
    const evBatches = await Promise.all(evSlices.map(async (s2) => {
      const r2 = await ctx.db.from("evidence_assets").select("id,client_id,do_no,evidence_kind,review_status,created_at,content_type").eq("client_id", clientId).in("do_no", s2).order("created_at", { ascending: false }).limit(1000);
      if (r2.error) throw new Error(r2.error.message);
      return r2.data || [];
    }));
    for (const b of evBatches) evAll = evAll.concat(b);
    evAll.sort((a: any, b: any) => String(b.created_at).localeCompare(String(a.created_at)));
    const data = evAll.slice(0, 1000);
    const periods=await ctx.db.from("reporting_periods").select("id").eq("client_id",clientId).lte("period_start",p.to).gte("period_end",p.from);
    if(periods.error)throw new Error(periods.error.message);const periodIds=(periods.data||[]).map((x:any)=>x.id);
    let exceptions:any[]=[];if(periodIds.length){const result=await ctx.db.from("report_exceptions").select("id,exception_type,severity,status,resolution,created_at,do_no").eq("client_id",clientId).in("reporting_period_id",periodIds).order("created_at",{ascending:false});if(result.error)throw new Error(result.error.message);exceptions=result.data||[];}
    return { client_id: clientId, period: p, evidence: data || [], exceptions, corrections:tenant.adjustments };
  }
  if (action === "query.create") {
        const qMsg = String(body.message || "").trim();
        if (!qMsg) throw new Error("message_required");
        if (qMsg.length > 2000) throw new Error("message_too_long");
        const qRow: any = {
          client_id: clientId,
          reporting_period_id: null,
          do_no: String(body.do_no || "").trim() || null,
          exception_type: "client_query",
          severity: "info",
          status: "open",
          detail: { message: qMsg, period_from: p.from, period_to: p.to, site: String(body.site || "").trim() || null, source: "client_portal" },
          created_by: ctx.account.id
        };
        const qIns = await ctx.db.from("report_exceptions").insert(qRow).select("id,created_at").maybeSingle();
        if (qIns.error) throw new Error(qIns.error.message);
        return { ok: true, id: qIns.data ? qIns.data.id : null, created_at: qIns.data ? qIns.data.created_at : null };
      }
      if (action === "loads") {
        const tenantL = await tenantRows(ctx, clientId, p);
        const engL = await engine();
        const relL = new Set((engL.released_dos || []).map((d: any) => String(d)));
        const siteKey = String(url.searchParams.get("site") || body.site || "").trim();
        const siteNameById: any = {};
        for (const s of (tenantL.sites || [])) siteNameById[String(s.site_id)] = s.site_name;
        const reviewedSet = new Set((tenantL.reviews || []).filter((r: any) => r.reviewed === true).map((r: any) => String(r.do_no)));
        const siteTokens: any = SITE_TOKEN_MAP[clientId] || {};
        const invMap: any = {};
        {
          const inv = await ctx.db.from("v_invoice_vs_collections").select("month,site,stream,flag,amount_billed").eq("client_id", clientId);
          if (inv.error) throw new Error(inv.error.message);
          for (const g of (inv.data || [])) invMap[String(g.month) + "|" + String(g.site || "") + "|" + String(g.stream || "")] = g;
        }
        const loads = (tenantL.collections || [])
          .filter((r: any) => relL.has(String(r.do_no)))
          .filter((r: any) => !siteKey || String(r.site_id) === siteKey || String(siteNameById[String(r.site_id)] || "") === siteKey)
          .map((r: any) => { const _sn = siteNameById[String(r.site_id)] || r.site_id; const _tok = siteTokens[String(_sn || "")] || String(_sn || ""); const _g = invMap[String(r.do_date || "").slice(0, 7) + "|" + _tok + "|" + String(r.waste_type || "")]; const _f = _g ? String(_g.flag || "") : ""; const _weighed = !!(String(r.weigh_ticket_no || "").trim() || String(r.weight_source || "") === "weighbridge"); const _rev = reviewedSet.has(String(r.do_no)); return { do_no: r.do_no, do_date: r.do_date, site_id: r.site_id, site_name: _sn, material: r.waste_type, net_kg: r.net_kg, weigh_ticket_no: r.weigh_ticket_no || "", weight_source: r.weight_source || "", dispose_to: r.dispose_to || "", reviewed: _rev, recorded: true, weighed: _weighed, accepted: _f === "OK", invoice_state: !_g ? "unknown" : (_f === "OK" ? "accepted" : (_f === "RECORDED, NOT INVOICED" ? "not_invoiced" : "variance")) }; })
          .sort((a: any, b: any) => String(a.do_date || "").localeCompare(String(b.do_date || "")) || String(a.do_no || "").localeCompare(String(b.do_no || "")));
        return { client_id: clientId, period: p, site: siteKey, count: loads.length, loads, ladder: { recorded: loads.length, weighed: loads.filter((x: any) => x.weighed).length, accepted: loads.filter((x: any) => x.accepted).length, reviewed: loads.filter((x: any) => x.reviewed).length } };
      }
      if (action === "templates") {
    const { data, error } = await ctx.db.from("report_template_versions").select("id,template_id,version,status,effective_from,effective_to,release_notes,report_templates(name,framework,kind)").in("status", ctx.staff ? ["draft","active","superseded","retired"] : ["active"]).order("template_id");
    if (error) throw new Error(error.message); return { templates: data || [] };
  }
  if (action === "reports") {
    const periods=await ctx.db.from("reporting_periods").select("*").eq("client_id",clientId).lte("period_start",p.to).gte("period_end",p.from).order("period_end",{ascending:false});
    if(periods.error)throw new Error(periods.error.message);const ids=(periods.data||[]).map((x:any)=>x.id);
    if(!ids.length)return {client_id:clientId,periods:[],artifacts:[],issues:[]};
    const [artifacts,issues]=await Promise.all([
      ctx.db.from("report_artifacts").select("id,format,generated_at,generated_by,data_quality_status,sha256,byte_size,template_version_id,reporting_period_id").eq("client_id",clientId).in("reporting_period_id",ids).order("generated_at",{ascending:false}),
      ctx.db.from("report_issues").select("*").eq("client_id",clientId).in("reporting_period_id",ids).order("issued_at",{ascending:false}),
    ]);
    for(const result of [artifacts,issues])if(result.error)throw new Error(result.error.message);
    return {client_id:clientId,periods:periods.data||[],artifacts:artifacts.data||[],issues:issues.data||[]};
  }
  if (action === "layout") {
    const key = String(body.layout_key || url.searchParams.get("layout_key") || "default");
    if (req.method === "GET") {
      const { data, error } = await ctx.db.from("portal_saved_layouts").select("*").eq("portal_account_id", ctx.account.id).eq("client_id", clientId).eq("layout_key", key).maybeSingle();
      if (error) throw new Error(error.message); return { layout: data || null };
    }
    if (req.method !== "PUT") throw new Error("method_not_allowed");
    const widgets = Array.isArray(body.widget_keys) ? [...new Set(body.widget_keys.map(String))] : [];
    const catalog = await ctx.db.from("report_widget_catalog").select("widget_key").eq("enabled", true);
    if (catalog.error) throw new Error(catalog.error.message);
    const allowed = new Set((catalog.data || []).map((w: any) => w.widget_key));
    if (widgets.some((w) => !allowed.has(w))) throw new Error("invalid_widget");
    const row = { portal_account_id: ctx.account.id, client_id: clientId, layout_key: key, name: String(body.name || "Default"), widget_keys: widgets, settings: body.settings && typeof body.settings === "object" ? body.settings : {}, version: number(body.version) + 1 || 1 };
    const { data, error } = await ctx.db.from("portal_saved_layouts").upsert(row, { onConflict: "portal_account_id,client_id,layout_key" }).select().single();
    if (error) throw new Error(error.message); return { layout: data };
  }
  if (action === "export" && req.method === "POST") return await exportArtifact(ctx, clientId, p, body, await engine());
  if (action === "artifact.download") {
    const id = String(url.searchParams.get("id") || "");
    const { data, error } = await ctx.db.from("report_artifacts").select("id,bucket_id,object_path,client_id").eq("id", id).eq("client_id", clientId).maybeSingle();
    if (error) throw new Error(error.message); if (!data) throw new Error("artifact_not_found");
    const signed = await ctx.admin.storage.from(data.bucket_id).createSignedUrl(data.object_path, 300, { download: true });
    if (signed.error) throw new Error(signed.error.message);
    await writeAccessEvent(ctx, "report.download", "success", { client_id: clientId, endpoint: action, artifact_id: id }, true);
    return { download_url: signed.data.signedUrl, expires_in: 300 };
  }
  if (action === "evidence.download") {
    const id = String(url.searchParams.get("id") || "");
    const { data, error } = await ctx.db.from("evidence_assets").select("id,bucket_id,object_path,client_id").eq("id", id).eq("client_id", clientId).maybeSingle();
    if (error) throw new Error(error.message); if (!data) throw new Error("evidence_not_found");
    const signed = await ctx.admin.storage.from(data.bucket_id).createSignedUrl(data.object_path, 300);
    if (signed.error) throw new Error(signed.error.message);
    await writeAccessEvent(ctx, "evidence.view", "success", { client_id: clientId, endpoint: action, evidence_id: id }, true);
    return { signed_url: signed.data.signedUrl, expires_in: 300 };
  }
  if (action === "evidence.review" && req.method === "POST") {
    if (!ctx.staff) throw new Error("forbidden");
    const status = String(body.review_status || "");
    if (!["verified","review","corrected"].includes(status)) throw new Error("invalid_review_status");
    const { data, error } = await ctx.db.from("evidence_assets").update({ review_status: status }).eq("id", body.id).eq("client_id", clientId).select().single();
    if (error) throw new Error(error.message); return { evidence: data };
  }
  if (action === "exception.resolve" && req.method === "POST") {
    if (!ctx.staff) throw new Error("forbidden");
    const status = String(body.status || "resolved");
    if (!["resolved","waived"].includes(status)) throw new Error("invalid_exception_status");
    const { data, error } = await ctx.db.from("report_exceptions").update({ status, resolution: String(body.resolution || ""), resolved_at: new Date().toISOString(), resolved_by: ctx.account.id }).eq("id", body.id).eq("client_id", clientId).select().single();
    if (error) throw new Error(error.message); return { exception: data };
  }
  if (action === "period.assess" && req.method === "POST") {
    if (!ctx.staff) throw new Error("forbidden");
    const next = String(body.status || "");
    if (!["ready","in_review","data_gaps","superseded"].includes(next)) throw new Error("invalid_period_status");
    const existing = await ctx.db.from("reporting_periods").select("id,status").eq("client_id",clientId).eq("period_start",p.from).eq("period_end",p.to).maybeSingle();
    if (existing.error) throw new Error(existing.error.message);
    const row = { client_id:clientId,period_start:p.from,period_end:p.to,label:p.label,status:next,data_quality_status:next,data_quality_summary:body.data_quality_summary||{},assessed_at:new Date().toISOString(),assessed_by:ctx.account.id };
    const saved = await ctx.db.from("reporting_periods").upsert(row,{onConflict:"client_id,period_start,period_end"}).select().single();
    if (saved.error) throw new Error(saved.error.message);
    const event = await ctx.db.from("report_readiness_events").insert({reporting_period_id:saved.data.id,client_id:clientId,from_status:existing.data?.status||null,to_status:next,data_quality_summary:row.data_quality_summary,actor_id:ctx.account.id,request_id:ctx.requestId});
    if (event.error) throw new Error(event.error.message);
    await writeAccessEvent(ctx,"report.readiness","success",{client_id:clientId,endpoint:action,reporting_period_id:saved.data.id,to_status:next},true);
    return { period:saved.data };
  }
  if (action === "report.issue" && req.method === "POST") {
    if (!ctx.staff) throw new Error("forbidden");
    const periodId=String(body.reporting_period_id||""), artifactIds=Array.isArray(body.artifact_ids)?body.artifact_ids.map(String):[];
    if (!periodId||!artifactIds.length) throw new Error("issue_period_and_artifacts_required");
    const checked=await ctx.db.from("report_artifacts").select("id").eq("client_id",clientId).eq("reporting_period_id",periodId).in("id",artifactIds);
    if(checked.error)throw new Error(checked.error.message);if((checked.data||[]).length!==artifactIds.length)throw new Error("artifact_scope_mismatch");
    const issueId=crypto.randomUUID(), issueNumber=String(body.issue_number||`${clientId}-${p.to.replaceAll("-","")}-${Date.now().toString(36).toUpperCase()}`);
    const issue=await ctx.db.from("report_issues").insert({id:issueId,client_id:clientId,reporting_period_id:periodId,issue_number:issueNumber,issued_by:ctx.account.id,supersedes_issue_id:body.supersedes_issue_id||null,note:body.note||null});
    if(issue.error)throw new Error(issue.error.message);
    const links=await ctx.db.from("report_issue_artifacts").insert(artifactIds.map((artifact_id:string)=>({report_issue_id:issueId,artifact_id})));
    if(links.error)throw new Error(links.error.message);
    await writeAccessEvent(ctx,"report.issue","success",{client_id:clientId,endpoint:action,reporting_period_id:periodId,issue_id:issueId},true);
    return { issue:{id:issueId,issue_number:issueNumber,issued_at:new Date().toISOString(),supersedes_issue_id:body.supersedes_issue_id||null} };
  }
  throw new Error("route_not_found");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors(req) });
  let ctx: PortalContext | null = null;
  try {
    ctx = await authenticate(req);
    const data = await route(req, ctx);
    await writeAccessEvent(ctx, "portal.request", "success", { endpoint: new URL(req.url).searchParams.get("route") || "session" }, ctx.staff);
    return response(req, data, 200, ctx.requestId);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const status = failStatus(message);
    if (ctx) await writeAccessEvent(ctx, "portal.request", status < 500 ? "denied" : "failed", { endpoint: new URL(req.url).searchParams.get("route") || "session", error: message });
    /* 19 Sep 2026 - never hand an unexpected exception to a client surface. The STE
       workspace rendered a raw TypeError carrying an internal container IP, the project
       URL and several hundred of that client's own DO numbers, on a panel headed
       CLIENT WORKSPACE - SECURE. Deliberate 4xx messages are ours and stay; any 5xx is
       replaced with a fixed string. Full detail is already in the access event above
       and in the function logs. */
    console.error("portal.request failed:", message);
    const clientMessage = status >= 500
      ? "This report could not be generated. Please contact Lirich."
      : message;
    return response(req, { error: clientMessage, request_id: ctx?.requestId }, status, ctx?.requestId);
  }
});
