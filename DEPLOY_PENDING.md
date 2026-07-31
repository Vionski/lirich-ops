# Driver-app deploy — PENDING (hand to Claude Code)

The previous batch (My Jobs/Job Card rework, Cancel job, Late jobs, void `voidedOn`) is DEPLOYED.
This file now tracks the NEXT change only.

## Pending (29 Jul 2026) — branded cancel dialog
Front-end ONLY (no Edge Function change).
- `app.js`: added `lrAsk` / `lrInfo` / `lrConfirm` / `lrPrompt` — custom in-app dialogs so the popup
  header reads **"Lirich"** instead of the browser's forced **"vionski.github.io says"** origin label
  (native `confirm`/`prompt`/`alert` origin text can't be relabelled from JS — only avoided with a
  custom UI). `voidJob` (the driver "Cancel job" flow + operator "Void") now routes through these:
  branded confirm ("Cancel job" / "Keep job", red) + branded info for the invoiced-guard. **Driver
  cancel no longer asks for a reason** (one tap; reason auto-set to "Client cancelled", office
  reconciles later). Operator "Void" still prompts for a reason. Cancel button remains on every active
  job (incl. today's); only hidden once done.
- **ALL other native dialogs also converted** to the branded dialog (no more "vionski.github.io says"
  anywhere): operator PIN unlock (`unlockDevice`), reset-all-data confirm, email-DO address prompt.
- `sw.js`: cache bumped **v43 → v44** so phones refresh.
- Also in this push (#25): the **operator Jobs list** now shows each job's date (`📅 dd Mon`), matching
  the driver cards.

## Deploy step (Claude Code) — one step
`git add app.js sw.js` → commit → `git push origin master`. GitHub Pages; driver link unchanged;
phones pick up sw v44 on next open. No function redeploy needed.

## Pending batch 2 (29 Jul 2026) — weight rules + type-ahead client (front-end only)
- **Weight: 0 is now valid** (`saveWeigh`) — some jobs are weighed by the client, not us. Blank is
  still blocked; a "Client weighs — finish (0)" button fills 0 and saves. "Weighed" now = a weight
  record EXISTS (incl 0), so `weightPending`/`hasWeight`/`needsWeight` all treat 0 as done → a
  weighable job can't silently finish without a weigh entry, but 0 clears it. (#2 + #3)
- **Dump/Sell jobs are now weighable too** — only `vessel` (volume-based) is excluded. Disposal sites
  (e.g. Beejoo) weigh at the bridge and recyclables sell by weight. Effect: any done-without-weight
  LAND job auto-surfaces as "⚖️ WEIGH PENDING" (this is what moves the stuck Beejoo job back to the
  add-weight phase — no manual data edit). ⚠ Old demo "done" jobs without weight will also re-surface;
  driver clears each with a real weight or the "Client weighs (0)" button.
- **Type-ahead client on the job form** (`openJobForm`) for BOTH driver + operator: `jf-client` is now
  an `<input list=jf-clientlist>`; `jfClientId()` resolves the typed name → client id; saveJob guards
  "pick a customer from the list". (#26)
- **e-DO header phone corrected** (both the e-DO form + the DO print header): `Tel: 6717 6688` →
  **`6793 0173`** (the website's official number; fax 6793 2309 + 23 Gul Drive address + tagline already
  correct). Kept the "Office: 18 Boon Lay Way" line (website shows only 23 Gul Dr — confirm if it should
  be dropped). Dashboard still shows 89892239 (likely mobile/WhatsApp) — #49 needs Michelle to say which
  number belongs where.
- `sw.js` cache **v44 → v45**. Deploy = same one `git push` (app.js + sw.js), no function change.

## Client picker — names only, no salesperson (30 Jul 2026)
Michelle: the client dropdown in the app was showing the salesperson (e.g. "Aspiration City · Patrick").
Salesperson is internal-DB/reporting only — must NOT show in the app picker. **Already satisfied in the
repo:** every client selector renders `esc(c.name)` only — job form `jf-client` (datalist, "type to
search") line ~1088-89, e-DO/trip `tf-client` line ~1309/1368, edit-trip `te-client` line ~1969. No
`salesRep` in any `<option>`. Salesperson is kept only in the operator's internal CRM client card +
"By salesperson" earnings view (the "later report"). **Takes effect on the next app push** (the live
GitHub-Pages build is older and still shows "· Patrick"). No new code needed — ships with this batch.
NOTE: the job form has type-ahead search; the e-DO/trip `tf-client` is still a plain native `<select>`
(no search box). If Michelle wants the search box on the DO/trip screen too, convert tf-client/te-client
to the same `<input list=...>` datalist pattern — deferred to the next app batch (needs deploy+test).

## LIRICH GROUP branding in app header — match website (#68, 30 Jul 2026)
Michelle: make the app's Lirich name/tagline use the **same font + colour as the lirichgroup.com header**.
Applied to the app's on-screen `#header` (both `renderLogin` line ~612 and `renderHeader` line ~738):
replaced the plain `logo.png + "Lirich Resources"` title with the website branding block —
**gold Cinzel gradient `LIRICH GROUP`** + **white calligraphic `利瑞集团`** + **`Enrichment of Resources`
tagline** (Trebuchet, letter-spaced). The functional sub-line (driver/date or "Waste logistics · 23 Gul
Drive") is kept below; the role-pill on the right is unchanged.
- `index.html`: added Google-Fonts `<link>` (Cinzel + Ma Shan Zheng, `display=swap`) in `<head>`, and new
  CSS classes `.lr-brand/.lr-line1/.lr-wm/.lr-cn/.lr-tag` (+ `body.big-ui` sizes). The `.lr-wm` gold
  gradient is copied EXACTLY from the live site wordmark (`linear-gradient(105deg,#6e5312,#c89b18 10%,…,
  #8a6a1f)` + shimmer overlay + `background-clip:text`). `.lr-cn` = Ma Shan Zheng→KaiTi→STKaiti→Kaiti SC→
  cursive (calligraphy, matches website; offline falls back to KaiTi like the site does). `.lr-tag` =
  Trebuchet, letter-spacing .34em, uppercase.
- **DO / e-DO document headers deliberately NOT changed** — they must stay the legal entity
  `LIRICH RESOURCES PTE LTD`, and a gold gradient prints invisible (browsers drop backgrounds on print).
- `sw.js` cache **v45 → v46** so phones pick it up.
- **Offline note:** Cinzel + Ma Shan Zheng load from Google Fonts when online; offline the wordmark falls
  to serif and the Chinese to KaiTi (same as the website's own fallback). If a fully-offline exact match
  is wanted later, self-host the two woff2 files in the repo and add them to the SW `ASSETS` list.
- Deploy = the same one `git push` (index.html + app.js + sw.js), no Edge-Function change. Ships with the
  pending driver-app batch. **Preview shown to Michelle in chat before deploy.**

## e-DO + DO letterhead — remove OLD address, match website (30 Jul 2026)
Michelle: printed/completed e-DOs showed an **old address**. Confirmed against the live lirichgroup.com
/contact/ page (source of truth): the official contact is **23 Gul Drive, Singapore 629471 · Tel 6793
0173 · Fax 6793 2309 · sales@lirichresources.sg** — the site does NOT list "18 Boon Lay Way / Tradehub
21 / 609966" (that was the outdated office line). Fixed in BOTH the e-DO form header (`edo-co`, line ~1290)
and the printed DO letterhead (`DO_LETTERHEAD` / `doh-addr`, line ~2042):
- Removed the `Office: 18 Boon Lay Way #09-123 Tradehub 21 (S) 609966` line entirely.
- Address now reads **`23 Gul Drive, Singapore 629471`** (dropped the odd "Warehouse: 23, Gul Drive"
  label + stray comma, matches the website).
- Phone/fax already correct (`Tel: 6793 0173 · Fax: 6793 2309`); tagline normalised to
  `(Enrichment of Resources)` in both (the e-DO had `( … )` with inner spaces).
- Legal entity name `LIRICH RESOURCES PTE LTD` + Chinese `利瑞资源私人有限公司` unchanged (correct for the DO).
- The letterhead renders at print time, so once deployed EVERY new print/reprint uses the new address —
  historical saved PDFs stay as-is. Verified: `node --check` clean; `grep` shows no Boon Lay/Tradehub/
  609966/6717 left in app.js.
- **Deploy = the same one `git push` (app.js; sw already bumped to v46 by the branding change).** Until
  pushed, the live GitHub-Pages app still prints the old address.

## Job-specific on-site contact (#23, 31 Jul 2026) — front-end only
Michelle backlog #23. The job form (`openJobForm`, both operator + driver) already picks a CONTACT
PERSON from the CRM; added an optional **"ON-SITE CONTACT FOR THIS JOB"** name + phone pair
(`jf-cname-ovr` / `jf-cphone-ovr`) that overrides the CRM contact **for that job only** — for when the
person to call at the site differs from the customer record.
- New helper `jobContact(j)`: per-job override (`j.contactName`/`j.contactPhone`) wins, else falls back to
  the CRM `cContact(c, contactIdx)`. Returns null only when there is no contact at all.
- `saveJob` stores `contactName`/`contactPhone` on the job (blank = use CRM) and denormalises
  `j._contact` + new `j._contactPhone` from `jobContact(j)`.
- Display now uses `jobContact(j)`: the driver job card ("💬 Call {name}" WhatsApp button) and the
  operator Job Detail (👤 line) both show the effective contact. **No behaviour change when the override
  is blank** (jobContact === the old CRM contact).
- `sw.js` cache **v46 → v47**. Deploy = the same one `git push` (app.js + sw.js), no Edge-Function change.
  Ships with this pending batch.

## Operator edits un-accepted jobs (#24, 31 Jul 2026) — front-end only
Backlog #24. The operator's Job Detail sheet now shows **"✏️ Edit job (not yet accepted)"** on any job
with `status==='assigned'` (i.e. the driver has NOT pressed Accept). It reopens the SAME job form
(`openJobForm(null, jobId)`) fully prefilled and saves via `updateJob` (patch), not `addJob`.
- New module-level `JF_EDIT` = the job being edited (null otherwise; reset on every openJobForm call
  and consumed on save).
- Prefill: date/client/notes/distance/surcharges/contact-override inline in the HTML; site, contact
  and job-type restored inside `jfClientChanged` (site must be set BEFORE the per-site job-type
  pricing rebuild); driver/bin/waste/dump set after `jfClientChanged()`. `autoDistance` keeps the
  saved distance while editing (only recalcs if the field is cleared).
- Save guard: if the driver accepted the job while the form was open (`status!=='assigned'` on save),
  the edit is REFUSED with a branded info dialog ("void it and assign a new job instead") — no
  clobbering of in-progress work. `status`/`createdAt` are stripped from the patch so the original
  assignment time survives.
- `sw.js` cache **v47 → v48**. Deploy = the same one `git push` (app.js + sw.js), no Edge-Function
  change. Ships with this pending batch.

## Driver daily Job Card — official template print (#82 driver side, 31 Jul 2026)
`app.js`: new `jobCardHTML(driverId,date)` + `printJobCard()` render the paper DRIVER DAILY JOB CARD
template (08 Operations Samples sample 2): header Driver/Vehicle/Date, table SN|Customer&Location|
Bin In/Out|Time Start/End|Dispose To|Tonnage|Trip Charge|Remarks (padded to 10 rows), totals,
mileage lines, Driver/Checked/Approved signature blocks. Button "🖨️ Print job card (official
format)" added to the driver's Job Card tab; completed trips of the day only; pay shown (Michelle's
choice). `sw.js` v48 → **v49**. Deploy = same one `git push`. (Operator-side editable/printable job
card with audited overrides is ALREADY LIVE in the operator console — no app dependency.)

## Still open (unchanged)
PIL password reset `PIL-beta-2026` → strong unique value (Michelle's action).
Backlog #23–27 (contact field, edit un-accepted jobs, operator Jobs-list date, searchable dropdown,
"Other" location) — not built yet.
