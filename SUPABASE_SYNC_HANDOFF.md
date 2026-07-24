# Driver app → Supabase sync — deploy handoff (for Claude Code)

Repointing the LirichOps driver app off the Google Apps Script bridge onto Supabase.
**Everything is written and committed in this repo. Only the deploy + secrets + one-time
init remain — all doable from this folder with the Supabase CLI.**

Supabase project: **Lirich**, ref `zjtvrlbyfeirnrlqgefo`, region ap-southeast-1.

## What's already done
- **`supabase/functions/sync/index.ts`** — the Edge Function. Same wire protocol as the old
  Apps Script (`?state=1`, `?rev=1`, `?db=1`, POST `{action}`), so the app needs no logic
  change beyond the URL. Every `addTrip`/`updateTrip` also upserts a normalized row into
  `collections` (SSOT, `source='live'`, dedupe on `do_no`), jobs into `jobs`. Photos → public
  `do-photos` storage bucket. `?db=1` builds dropdowns/pricing from the SSOT tables
  (`sites`, `customers`, `rate_card`, `bins`, `drivers`, `ref_lists`). `emailDO` is forwarded
  to the legacy Apps Script (Gmail stays there) — set `LEGACY_SCRIPT_URL` if you want DO emails,
  else it returns a graceful "not configured".
- **`app.js`** — `SHEET_URL_DEFAULT` now the function URL
  `https://zjtvrlbyfeirnrlqgefo.supabase.co/functions/v1/sync`; added `const DEVICE_KEY`
  (`3c55a26e60493d32504ab0a5d1cf898922396f399e27e2e8`); `api()` sends the key in the POST body;
  the three GET call sites (`bootRemote`, `pollRemote`, `fetchSheetDB`) go through the new
  `dbGet()` helper which appends `&key=`; `OLD_SHEET_URLS` gets `'AKfycb'` so any device still
  on an Apps Script URL auto-migrates on next load. Settings-panel label → "Central database (Supabase)".
- **`sw.js`** — cache bumped `v39` → `v40` (forces the new app.js onto installed phones).
- **DB prerequisites already run in Supabase** (verified): tables `app_state` (jsonb blob, id=1)
  and `ref_lists` (kind/value, seeded 7 waste + 7 dump), public storage bucket `do-photos`.

## Steps to finish (from this repo folder)
1. `supabase login` (needs Michelle's Supabase access token — she generates it at
   supabase.com/dashboard/account/tokens; do NOT hardcode it).
2. `supabase functions deploy sync --project-ref zjtvrlbyfeirnrlqgefo --no-verify-jwt`
   (`--no-verify-jwt` is REQUIRED — the app calls it with the device key, not a Supabase JWT).
3. Set the function secrets (service role key auto-injects as `SUPABASE_SERVICE_ROLE_KEY`, but
   set the app key):
   `supabase secrets set DEVICE_KEY=3c55a26e60493d32504ab0a5d1cf898922396f399e27e2e8 --project-ref zjtvrlbyfeirnrlqgefo`
   (optional Gmail bridge: `supabase secrets set LEGACY_SCRIPT_URL=<old apps script /exec url>`).
4. **One-time state init.** The app's `bootRemote()` auto-inits when it finds an empty DB
   (`?state=1` → `{empty:true}` → it POSTs `initState` with its local cache). So the FIRST device
   to open the updated app seeds `app_state`. Cleanest: Michelle opens the app online once as the
   operator (whose local cache already holds the real clients/bins/jobs/trips). Verify a row
   appears in `app_state` and `rev` starts incrementing.
5. **Deploy the app** (GitHub Pages) — commit + push this repo; the driver-facing link is unchanged.
   Phones pick up sw v40 on next load. Old Apps Script deployment can stay live as a fallback for
   a few days, then be retired.

## Test loop (do before telling drivers)
- Open app → operator → confirm dropdowns populate (that's `?db=1` hitting the SSOT).
- Assign a job, log a trip WITH a photo as a driver → confirm: (a) trip appears on a second
  device after poll (shared state works), (b) a row lands in `collections` with `source='live'`
  and the photo URL resolves from the `do-photos` bucket, (c) a row lands in `jobs`.
- Use the office **test driver** account for one trip → confirm it does NOT write to `collections`
  (the `_test` guard is ported).
- Backfill rows already in `collections` (130) must be untouched — live trips only ADD (upsert on
  `do_no`); adjustments still go through the `adjustments` table.

## Notes / gotchas
- RLS is ON with no policies, so the anon key can't read/write tables — correct. The function uses
  the **service role** key server-side; the device key is the app's gate. Never ship the service
  role key to the phone.
- The state blob is a straight port of the Apps Script ScriptProperties JSON, so `initState`/
  `resetState`/`adoptShared` all still line up.
- Nightly GitHub backup already dumps `collections` etc.; add `app_state` to the dump list in
  `.github/workflows/db-backup.yml` (the `for t in …` line) so the live app state is backed up too.
