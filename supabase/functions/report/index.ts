/* ============================================================
   Lirich — read-only client REPORT function.
   Returns one client's dashboard data from the SSOT (collections),
   so the client portal shows LIVE numbers instead of hardcoded JSON.

   GET ?token=<WP-signed>                    → the token's own client (scoped; ?client ignored)
   GET ?token=<ALL-admin>&client=PIL         → admin selects a client (token client_id=ALL)
   GET ?client=PIL&key=<READ_KEY>            → LEGACY, DISABLED in Step D (29 Jul 2026) → 403

   Carbon IS computed here (single source of truth for methodology): raw SSOT
   aggregates + carbonFrom() using factors pinned from the `factors` table.
   REBASED 2026-07-31 to official SG sources (SEFR 2025 general-waste 0.1115).
   EPA SWITCH 2026-08-12 (Michelle): per-category US EPA densities + per-material
   SEFR disposal factors applied TOGETHER (two-errors rule); sludge/ash stay
   1 m3 = 1 t; recovery %% stays by volume; rule = actual weight when recorded,
   EPA conversion otherwise. Mirrors Lirich_Carbon_Calculation_Basis.xlsx.

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
     recovered = cat A plastics + cat D oil + cat I e-waste + sludge  (route-confirmed)
     disposal  = cat B food + cat C domestic + cat F operational + cat E ash + other
     cat5 (Scope 3 Cat 5)  = disposal * EF_WTE
     avoided               = recovered * AV_RECOVER
     recovery%             = recovered / waste_handled * 100
   Every figure is INDICATIVE / estimated from volume. The 10% is an
   assumption, not measured (Michelle, 27 Jul 2026). ============ */
/* RETIRED 5 Aug 2026. Recovery is no longer assumed: it is taken from the CONFIRMED
   disposal route per MARPOL category, recorded in the waste_routes table.
   Kept only so historical responses remain interpretable. */
const RECYCLE_ASSUMPTION_RETIRED = 0.10;
const EF_WTE_DEFAULT = 0.1115;     // tCO2e/t — SEFR 2025 (NEA-sourced, netzerohub.sg): SG general waste incineration/WtE. Rebased 2026-07-31.
const AV_RECOVER_DEFAULT = 0.1115; // tCO2e/t avoided per tonne diverted = avoided WtE incineration (SEFR general-waste factor; conservative, excludes material credits). Rebased 2026-07-31.

type Factors = {
  ef_wte: number; av_recover: number; source: string;
  ef_factor: unknown; av_factor: unknown; factors_available?: unknown;
  forPeriod?: (month: string) => { ef_wte: number; av_recover: number; ef_valid_from?: string; av_valid_from?: string; vintage_fallback: boolean };
};

/* Pin the carbon factors from the `factors` table DETERMINISTICALLY (audit-safe):
   - candidates are sorted by a stable key first, so selection never depends on DB row order;
   - WtE/disposal factor := the waste|general_waste row (SEFR 2025 official: 0.1115 tCO2e/t);
   - avoided factor := the avoided|general_waste row (0.1115 = avoided WtE per tonne diverted,
     conservative, excludes material-recovery credits), never paper/plastic/metal rows;
   - the exact rows used are returned in ef_factor/av_factor for the audit trail;
   - if either pinned row is ABSENT the function THROWS (fail loud) — it never guesses. */
async function loadFactors(): Promise<Factors> {
  let ef_wte = EF_WTE_DEFAULT, av_recover = AV_RECOVER_DEFAULT, source = "default";
  let ef_factor: any = null, av_factor: any = null, available: any[] = [];
  let missing = false;
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
    void blob;
    // PRIMARY (deterministic, schema-exact): domain/key pin — waste|general_waste = the
    // SEFR WtE disposal factor (0.1115); avoided|general_waste = avoided-WtE-per-tonne-diverted.
    ef_factor = available.find((r) => r?.domain === "waste" && r?.key === "general_waste" && Number.isFinite(num(r)));
    av_factor = available.find((r) => r?.domain === "avoided" && r?.key === "general_waste" && Number.isFinite(num(r)));
    /* NO FALLBACK — DELIBERATE. A pinned factor that cannot be found must FAIL LOUD.
       On 5 Aug 2026 a regex fallback silently selected the EMA GRID factor (0.402, an
       ELECTRICITY factor) after this key was renamed, applied it to waste, and put a
       wrong Scope 3 figure on the live client dashboard for hours. A visible error is
       always better than a plausible wrong number. Never guess a factor. */
    if (!ef_factor || !av_factor) missing = true;
    if (ef_factor) { ef_wte = num(ef_factor); source = "factors"; }
    if (av_factor) { av_recover = num(av_factor); source = "factors"; }
  } catch (_e) { missing = true; }
  if (missing) {
    throw new Error(
      "factor_missing: required emission factors not found. The report layer pins " +
      "waste|general_waste (disposal) and avoided|general_waste (avoided). One or both " +
      "is absent from the factors table. These keys are a CONTRACT — never rename them; " +
      "add a new row instead. Refusing to substitute an unrelated factor.",
    );
  }
  /* TEMPORAL RESOLUTION (architecture step 3, 18 Aug 2026).
     ISO 14064-1 Annex E (normative): factors are selected FOR THE REPORTING PERIOD,
     never "latest". Rule per (domain,key):
       1. candidates whose [valid_from, valid_to] overlaps the month -> pick max valid_from;
       2. if none overlap (months BEFORE our first adoption date), fall back to the
          EARLIEST known row and FLAG vintage_fallback=true - visible, never silent;
       3. if the key has no rows at all, the loud factor_missing throw above already fired.
     With today's single-vintage table every month resolves to the same row, so output
     is byte-identical; when the 2025/2026 vintages are inserted (new rows, never renames)
     each month picks up its own value automatically. */
  const numv = (r: any) => {
    for (const k of ["value", "factor", "value_kg", "kgco2e", "ef", "amount"]) {
      const v = Number(r?.[k]); if (Number.isFinite(v) && v > 0) return v;
    } return NaN;
  };
  const pickTemporal = (domain: string, key: string, month: string) => {
    const rows = available.filter((r: any) => r?.domain === domain && r?.key === key && Number.isFinite(numv(r)));
    if (!rows.length) return null;
    const pStart = month + "-01", pEnd = month + "-31";
    const inP = rows.filter((r: any) => {
      const vf = r?.valid_from ? String(r.valid_from).slice(0, 10) : "";
      const vt = r?.valid_to ? String(r.valid_to).slice(0, 10) : "";
      return (!vf || vf <= pEnd) && (!vt || vt >= pStart);
    }).sort((a: any, b: any) => String(b?.valid_from || "").localeCompare(String(a?.valid_from || "")));
    if (inP.length) return { row: inP[0], fallback: false };
    const earliest = rows.slice().sort((a: any, b: any) =>
      String(a?.valid_from || "").localeCompare(String(b?.valid_from || "")))[0];
    return { row: earliest, fallback: true };
  };
  const forPeriod = (month: string) => {
    const e = pickTemporal("waste", "general_waste", month);
    const a = pickTemporal("avoided", "general_waste", month);
    if (!e || !a) {
      throw new Error("factor_missing: temporal resolution found no waste|general_waste or avoided|general_waste row for period " + month + ". Add a factors row with an appropriate valid_from; never rename existing keys.");
    }
    return {
      ef_wte: numv(e.row), av_recover: numv(a.row),
      ef_valid_from: e.row?.valid_from ? String(e.row.valid_from).slice(0, 10) : undefined,
      av_valid_from: a.row?.valid_from ? String(a.row.valid_from).slice(0, 10) : undefined,
      vintage_fallback: e.fallback || a.fallback,
    };
  };
  return { ef_wte, av_recover, source, ef_factor, av_factor, factors_available: available, forPeriod };
}

/* ============================================================
   DENSITIES + PER-MATERIAL FACTORS — SWITCHED TOGETHER 12 Aug 2026 (Michelle).
   The two-errors-that-cancel rule: 1 m3 = 1 t OVERSTATED mass while the blended
   0.1115 factor UNDERSTATED emissions. Both corrections now applied in ONE change,
   exactly matching Lirich_Carbon_Calculation_Basis.xlsx (PIL Worked Example:
   July 2026 = 9.40 t handled, 2.02 tCO2e).

   STANDING RULE (Michelle, 12 Aug 2026): when a SEF/DO carries an ACTUAL WEIGHT,
   that weight is used; when only volume is recorded, convert at the US EPA
   Volume-to-Weight densities below. No PIL vessel row carries a weight today, so
   every PIL figure is EPA-converted; weighed rows take precedence as they arrive.

   DENSITIES t/m3 — US EPA Volume-to-Weight Conversion Factors memo, April 2016
   (public domain), loose/uncompacted values (vessel garbage is skip-collected).
   1 lb/yd3 = 0.593276 kg/m3. Full provenance: Conversion Factors sheet of the
   calculations workbook.
     A plastics     40.4 lb/yd3 (mixed bottles #1-#7, loose)      = 0.0239684
     B food         463 lb/yd3                                     = 0.2746868
     C domestic     275 lb/yd3 (mixed MSW uncompacted, midpoint)   = 0.1631509
     D cooking oil  412 lb per 55 US gal (FOG)                     = 0.8976043
     E ashes        NO EPA category — 1.0 retained (immaterial)
     F operational  138 lb/yd3 (commercial, uncompacted)           = 0.0818721
     I e-waste      354 lb/yd3 (computer-related electronics)      = 0.2100197
     oily rags      150 lb/yd3 (mixed textiles, midpoint)          = 0.0889914
     expired med    NO EPA category — 1.0 retained (no stream yet)
     other          275 lb/yd3 (composition unknown -> mixed MSW)  = 0.1631509
     sludge         LIQUID — 1 m3 = 1 t per Michelle 3 Aug 2026, unchanged
   EPA is a US proxy, stated as such; the density weighing exercise (#116)
   replaces it with measured values.

   DISPOSAL EMISSION FACTORS tCO2e/t — SEFR (NEA-sourced, netzerohub.sg),
   applied to DISPOSED mass only (recovered streams carry no disposal factor):
     B food        0.5697939 (SEFR Incineration of food waste)
     C domestic    1.5304606 (SEFR paper/cardboard — Michelle's representative
                              material decision for mixed domestic, 5 Aug 2026)
     E ashes       0.0124606 (SEFR glass/inert incineration proxy)
     F operational 0.1114606 (SEFR Incineration of other waste)
     oily rags     1.4791273 (SEFR Incineration of textile waste — corrected
                              12 Aug 2026: Michelle pointed out the downloaded
                              SEFR set carries the full 11-category waste list,
                              incl. textile; the 0.1115 proxy is retired here)
     med/other     -> the pinned waste|general_waste factor (0.1115) = SEFR
                      "Incineration of other waste" — provenance CONFIRMED
                      against the downloaded SEFR set (waste|other 0.1114606).
     A plastics (2.7624606) and D oil carry factors in the workbook but are
     route-confirmed RECOVERED, so no disposal emissions apply.

   RECOVERY IS ROUTE-CONFIRMED, NOT ASSUMED (5 Aug 2026, waste_routes):
     RECOVERED  Cat A plastics (Asia Recycling), Cat D cooking oil (GreenTec),
                Cat I e-waste, sludge (GreenTec Energy)
     DISPOSED   Cat B food / C domestic / F operational (TSIP), Cat E ash
                (TMTS -> Semakau), rags/med/other (route not established)
   ⚠ Recovery counts 100%% of Cat A as accepted by Asia Recycling — unconfirmed
   with the recycler; flagged to Michelle.
   Recovery %% stays a VOLUME ratio (density-free, exact) so it is IDENTICAL to
   the pre-density figures — only tonnage and carbon moved. ============ */
const DENS = {
  plastics: 0.0239684, food: 0.2746868, domestic: 0.1631509, oily: 0.8976043,
  ash: 1.0, operational: 0.0818721, ewaste: 0.2100197, rags: 0.0889914,
  med: 1.0, other: 0.1631509,
} as const;
const EF_MAT = {
  food: 0.5697939, domestic: 1.5304606, ash: 0.0124606, operational: 0.1114606,
  rags: 1.4791273, // SEFR Incineration of textile waste (downloaded set; corrected 12 Aug 2026)
} as const;
function carbonFrom(
  cat: {
    plastics: number; food: number; domestic: number; operational: number;
    oily: number; ash: number; ewaste: number; rags: number; med: number;
    other: number; sludge: number;
  },
  f: Factors,
) {
  const v = (x: number) => x || 0;
  /* mass per category = volume x EPA density; sludge is already tonnes (1 m3 = 1 t) */
  const mA = v(cat.plastics) * DENS.plastics, mB = v(cat.food) * DENS.food,
    mC = v(cat.domestic) * DENS.domestic, mD = v(cat.oily) * DENS.oily,
    mE = v(cat.ash) * DENS.ash, mF = v(cat.operational) * DENS.operational,
    mI = v(cat.ewaste) * DENS.ewaste, mR = v(cat.rags) * DENS.rags,
    mM = v(cat.med) * DENS.med, mO = v(cat.other) * DENS.other,
    mS = v(cat.sludge);
  const recovered_t = mA + mD + mI + mS;
  const disposal_t = mB + mC + mE + mF + mR + mM + mO;
  const waste_handled_t = recovered_t + disposal_t;
  /* Scope 3 Cat 5 = per-material factors on DISPOSED mass only */
  const cat5_tco2e = mB * EF_MAT.food + mC * EF_MAT.domestic + mE * EF_MAT.ash +
    mF * EF_MAT.operational + mR * EF_MAT.rags + (mM + mO) * f.ef_wte;
  const avoided_tco2e = recovered_t * f.av_recover;
  /* recovery %% BY VOLUME — density-free and exact, unchanged by the EPA switch.
     Sludge participates at its 1 m3 = 1 t equivalence (as before). */
  const recVol = v(cat.plastics) + v(cat.oily) + v(cat.ewaste) + v(cat.sludge);
  const totVolAll = recVol + v(cat.food) + v(cat.domestic) + v(cat.ash) +
    v(cat.operational) + v(cat.rags) + v(cat.med) + v(cat.other);
  const recovery_pct = totVolAll > 0 ? recVol / totVolAll * 100 : 0;
  /* #99 — biogenic split is now TRUE per-material (no longer volume-apportioned):
     biogenic = B food + C domestic(paper-representative); fossil = F operational
     + rags/med/other; inert = E ashes. Headline cat5 = sum of the three. */
  const cat5_biogenic_tco2e = mB * EF_MAT.food + mC * EF_MAT.domestic;
  const cat5_fossil_tco2e = mF * EF_MAT.operational + mR * EF_MAT.rags + (mM + mO) * f.ef_wte;
  const cat5_inert_tco2e = mE * EF_MAT.ash;
  return {
    cat5_biogenic_tco2e: n2(cat5_biogenic_tco2e),
    cat5_fossil_tco2e: n2(cat5_fossil_tco2e),
    cat5_inert_tco2e: n2(cat5_inert_tco2e),
    biogenic_basis: "per-material: biogenic = B food + C domestic (paper-representative, SEFR); fossil = F operational + Remarks streams; inert = E ash (NEA GHG M&R App. Part II v4)",
    waste_handled_t: n2(waste_handled_t),
    recovered_t: n2(recovered_t),
    diverted_t: n2(recovered_t),
    disposal_t: n2(disposal_t),
    recovery_pct: Math.round(recovery_pct),
    cat5_tco2e: n2(cat5_tco2e),
    avoided_tco2e: n2(avoided_tco2e),
    recovery_basis: "route-confirmed per MARPOL category (waste_routes); %% by volume, density-free",
    recovered_streams: "Cat A plastics, Cat D cooking oil, Cat I e-waste, sludge",
    density_basis: "US EPA Volume-to-Weight Conversion Factors (April 2016), per-category, loose/uncompacted; sludge and ash 1 m3 = 1 t (stated assumptions); adopted 12 Aug 2026; not weighed",
    basis: "indicative — tonnage converted from volume at US EPA per-category densities",
  };
}

async function clientReport(clientId: string) {
  const { data: cust } = await supa.from("customers").select("name").eq("client_id", clientId).maybeSingle();
  const { data: sites } = await supa.from("sites").select("site_id").eq("client_id", clientId);
  const siteIds = (sites || []).map((s: any) => s.site_id);
  if (!siteIds.length) return { client: clientId, name: cust?.name || clientId, empty: true };

  const { data: rows } = await supa.from("collections")
    .select("do_no,do_date,do_type,trip_type,vessel_name,berth,voyage_no,waste_type,vol_cat_a,vol_cat_b,vol_cat_c,vol_cat_d,vol_cat_e,vol_cat_f,vol_cat_i,vol_oily_rags_m3,vol_expired_med_m3,vol_other_m3,other_desc,vol_total_m3,net_kg,sludge_requested_t,sludge_actual_t,source")
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
    /* #113 (6 Aug 2026): split the Remarks-column "other" volume by its recorded
       description so Oily Rags / Expired Medicine get their own columns instead of
       hiding inside Others. Classification is by other_desc keyword; anything
       unrecognised stays in "other" (conservative). Totals are unchanged. */
    /* #124 (8 Aug 2026): the vessel DO in the driver app now captures oily rags and
       expired medicine in their OWN fields, so prefer the explicit columns. Rows
       captured before that carry everything in vol_other_m3 and are still split by
       the other_desc keyword (fallback). Totals are unchanged either way. */
    const otherVol = Number(r.vol_other_m3) || 0;
    const desc = String(r.other_desc || "").toLowerCase();
    const colRags = Number(r.vol_oily_rags_m3) || 0;
    const colMed = Number(r.vol_expired_med_m3) || 0;
    const explicit = colRags > 0 || colMed > 0;
    const oRags = explicit ? colRags : (/rag/.test(desc) ? otherVol : 0);
    const oMed = explicit ? colMed : (/med/.test(desc) ? otherVol : 0);
    const oRest = explicit ? otherVol : (otherVol - oRags - oMed);
    (data[mk] = data[mk] || []).push({
      sn: (sn[mk] = (sn[mk] || 0) + 1), date: r.do_date, vessel: r.vessel_name || "", port: r.berth || "",
      voy: r.voyage_no || "", garbage: n2(garbage), oily: n2(oily), ash: n2(ash), reqS: n2(reqS), actS: n2(actS),
      /* per-row MARPOL categories for the monthly report table (5 Aug 2026) */
      ca: n2(Number(r.vol_cat_a) || 0), cb: n2(Number(r.vol_cat_b) || 0),
      cc: n2(Number(r.vol_cat_c) || 0), cd: n2(Number(r.vol_cat_d) || 0),
      ce: n2(Number(r.vol_cat_e) || 0), cf: n2(Number(r.vol_cat_f) || 0),
      cor: n2(oRags), cem: n2(oMed),
      cio: n2((Number(r.vol_cat_i) || 0) + oRest),
    });
    const m = months[mk] || (months[mk] = { month: mk, dos: 0, volume_m3: 0, net_t: 0, vessels: new Set(),
      cat_a: 0, cat_b: 0, cat_c: 0, cat_d: 0, cat_e: 0, cat_f: 0, cat_i: 0, cat_o: 0,
      cat_rags: 0, cat_med: 0, reqS: 0, actS: 0,
      dq_rows: 0, dq_doc: 0, dq_weighed: 0 });
    m.dos++; totDos++;
    /* verification-readiness stats (ISO 14064-3 evidence view, 12 Aug 2026):
       doc-backed = row's do_no is a real document number (SEFPEND-* rows were loaded
       from client-report summaries and await their per-job SEF); weighed = a real
       weighbridge net exists on the row. */
    m.dq_rows++;
    if (String(r.do_no || "").indexOf("SEFPEND") !== 0) m.dq_doc++;
    if ((Number(r.net_kg) || 0) > 0) m.dq_weighed++;
    const vol = Number(r.vol_total_m3) || 0; m.volume_m3 += vol; totVol += vol;
    const net = (Number(r.net_kg) || 0) / 1000; m.net_t += net; totNet += net;
    m.cat_a += Number(r.vol_cat_a) || 0; m.cat_b += Number(r.vol_cat_b) || 0; m.cat_c += Number(r.vol_cat_c) || 0;
    m.cat_d += Number(r.vol_cat_d) || 0; m.cat_e += Number(r.vol_cat_e) || 0; m.cat_f += Number(r.vol_cat_f) || 0;
    m.cat_i += Number(r.vol_cat_i) || 0; m.cat_o += oRest;
    m.cat_rags += oRags; m.cat_med += oMed;
    m.reqS += reqS; m.actS += actS;
    if (r.vessel_name) { m.vessels.add(r.vessel_name);
      const v = vessels[r.vessel_name] || (vessels[r.vessel_name] = { vessel: r.vessel_name, dos: 0, volume_m3: 0 });
      v.dos++; v.volume_m3 += vol; }
  }
  const f = await loadFactors();
  /* cat volumes → the carbon engine's category buckets (m3, == tonnes at 1 m3=1t).
     sludge = actual recovered sludge from the SSOT (0 until backfilled). */
  const cats = (m: any) => ({
    plastics: m.cat_a || 0, food: m.cat_b || 0, domestic: m.cat_c || 0,
    operational: m.cat_f || 0, oily: m.cat_d || 0, ash: m.cat_e || 0,
    ewaste: m.cat_i || 0,
    /* rags + expired med are Remarks streams with no established route → disposed;
       passed SEPARATELY since 12 Aug 2026 because each has its own EPA density. */
    rags: m.cat_rags || 0, med: m.cat_med || 0, other: m.cat_o || 0,
    sludge: m.actS || 0,
  });
  /* data_quality per month: %% weighed rows, %% of volume on a confirmed disposal
     route (rags/med/other have no established route), %% of rows backed by a
     per-job document. Presented to the client as the verification-readiness line. */
  const dq = (m: any) => {
    const confVol = (m.cat_a || 0) + (m.cat_b || 0) + (m.cat_c || 0) + (m.cat_d || 0) +
      (m.cat_e || 0) + (m.cat_f || 0) + (m.cat_i || 0) + (m.actS || 0);
    const allVol = confVol + (m.cat_rags || 0) + (m.cat_med || 0) + (m.cat_o || 0);
    return {
      weighed_pct: m.dq_rows > 0 ? Math.round(m.dq_weighed / m.dq_rows * 100) : 0,
      route_confirmed_pct: allVol > 0 ? Math.round(confVol / allVol * 100) : 0,
      doc_backed_pct: m.dq_rows > 0 ? Math.round(m.dq_doc / m.dq_rows * 100) : 0,
      sef_pending: m.dq_rows - m.dq_doc,
    };
  };
  const monthly = Object.values(months).map((m: any) => ({
    month: m.month, dos: m.dos, volume_m3: n2(m.volume_m3), net_t: n2(m.net_t), vessels: m.vessels.size,
    data_quality: dq(m),
    cat_a_plastics: n2(m.cat_a), cat_b_food: n2(m.cat_b), cat_c_domestic: n2(m.cat_c),
    cat_d_oil: n2(m.cat_d), cat_e_ashes: n2(m.cat_e), cat_f_operational: n2(m.cat_f),
    cat_i_ewaste: n2(m.cat_i), cat_other: n2(m.cat_o),
    cat_oily_rags: n2(m.cat_rags), cat_expired_med: n2(m.cat_med),
    sludge_requested_t: n2(m.reqS), sludge_actual_t: n2(m.actS),
    carbon: (() => {
      const fm = f.forPeriod ? f.forPeriod(m.month) : (f as any);
      const c = carbonFrom(cats(m), fm as any) as any;
      c.factor_valid_from = (fm as any).ef_valid_from;
      c.factor_vintage_fallback = !!(fm as any).vintage_fallback;
      return c;
    })(),
  })).sort((a, b) => a.month.localeCompare(b.month));

  /* totals carbon = engine over the summed categories across all months */
  const totCat = Object.values(months).reduce((acc: any, m: any) => {
    const c = cats(m);
    acc.plastics += c.plastics; acc.food += c.food; acc.domestic += c.domestic;
    acc.operational += c.operational; acc.oily += c.oily; acc.ash += c.ash;
    acc.ewaste += c.ewaste; acc.rags += c.rags; acc.med += c.med;
    acc.other += c.other; acc.sludge += c.sludge;
    return acc;
  }, { plastics: 0, food: 0, domestic: 0, operational: 0, oily: 0, ash: 0, ewaste: 0, rags: 0, med: 0, other: 0, sludge: 0 });
  const totReqS = Object.values(months).reduce((s: number, m: any) => s + (m.reqS || 0), 0);
  const totActS = Object.values(months).reduce((s: number, m: any) => s + (m.actS || 0), 0);

  return {
    client: clientId,
    name: cust?.name || clientId,
    generated_at: new Date().toISOString(),
    basis: "Indicative from measured volume. Tonnage converted per category at US EPA Volume-to-Weight densities (April 2016); sludge and ash at 1 m3 = 1,000 kg (stated assumptions). Adopted 12 Aug 2026. Carbon computed by this report layer (single source).",
    assumptions: "STANDING RULE (12 Aug 2026): actual weight from the SEF/weighbridge is used when recorded; otherwise volume is converted at US EPA per-category densities. Scope 3 Cat 5 uses per-material SEFR disposal factors on disposed mass. Recovery is route-confirmed, not assumed: Cat A plastics (Asia Recycling), Cat D cooking oil and sludge (GreenTec Energy) and Cat I e-waste are counted as recovered; Cat B, C and F go to incineration at TSIP and Cat E ash to landfill via TMTS. Recovery percent is a volume ratio and carries no density assumption. No tonnage has been weighed yet; EPA is a stated US proxy pending the density weighing exercise.",
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
async function verifyToken(token: string): Promise<{ client_id: string; role: string } | null> {
  if (!token || !LR_TOKEN_SECRET) return null;
  const dot = token.lastIndexOf(".");
  if (dot <= 0) return null;
  const payload = token.slice(0, dot), sig = token.slice(dot + 1).toLowerCase();
  const expected = await hmacHex(payload, LR_TOKEN_SECRET);
  if (!timingSafeEq(sig, expected)) return null; // forged / tampered
  let decoded: string;
  try { decoded = atob(payload); } catch { return null; }
  const parts = decoded.split("|");
  let cid: string, role: string, exp: number;
  if (parts.length === 2) {
    /* legacy 2-part: client_id|expiry — role derived (ALL = admin, else client) */
    cid = parts[0].trim().toUpperCase();
    role = cid === "ALL" ? "admin" : "client";
    exp = Number(parts[1]);
  } else if (parts.length === 3) {
    /* 3-part (#41 phase 2b / #84 SSO): client_id|role|expiry */
    cid = parts[0].trim().toUpperCase();
    role = parts[1].trim().toLowerCase();
    exp = Number(parts[2]);
  } else if (parts.length === 4) {
    /* 4-part (#105 per-tab access): client_id|role|user_key|expiry.
       This fn only scopes DATA by client_id/role; user_key (parts[2]) is for the
       operator fn's permission checks and is deliberately ignored here. */
    cid = parts[0].trim().toUpperCase();
    role = parts[1].trim().toLowerCase();
    exp = Number(parts[3]);
  } else return null;
  if (!cid || !Number.isFinite(exp)) return null;
  if (Math.floor(Date.now() / 1000) > exp) return null; // expired
  return { client_id: cid, role };
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
    if (tok.client_id === "ALL" || tok.role === "admin" || tok.role === "operator") {
      isAdmin = true; scoped = reqClient; // staff (admin/operator) may select any client
    }
    else { scoped = tok.client_id; } // FORCE this client — ?client is ignored entirely
  } else if (LEGACY_KEY_ENABLED && READ_KEY && (url.searchParams.get("key") || "") === READ_KEY) {
    authMode = "legacy-key";
    scoped = reqClient;
    isAdmin = reqAdmin;
  } else {
    return json({ error: "unauthorized" }, 403);
  }

  try {
    /* Templates-as-data (architecture step 4): serve a report definition from
       report_templates so presentation surfaces render from configuration.
       Read-only; requires the same auth as any report read. */
    const tplId = (url.searchParams.get("template") || "").trim();
    if (tplId) {
      const { data: tpl, error: te } = await supa.from("report_templates")
        .select("template_id,kind,name,framework,build_status,structure")
        .eq("template_id", tplId).maybeSingle();
      if (te) return json({ error: String((te as any).message || te) }, 500);
      if (!tpl) return json({ error: "template not found: " + tplId }, 404);
      return json({ auth: authMode, template: tpl });
    }
    /* Methodology annex (ISO 14064-1 s6.2): active quantification-approach
       decisions from the methodology register, oldest first. */
    if (url.searchParams.get("methodology") === "1") {
      const { data: md, error: me } = await supa.from("methodology_decisions")
        .select("decided_on,decided_by,topic,decision,standard_hook,affects")
        .eq("status", "active").order("decided_on", { ascending: true });
      if (me) return json({ error: String((me as any).message || me) }, 500);
      return json({ auth: authMode, methodology: md || [] });
    }
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
