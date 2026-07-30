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

## Still open (unchanged)
PIL password reset `PIL-beta-2026` → strong unique value (Michelle's action).
Backlog #23–27 (contact field, edit un-accepted jobs, operator Jobs-list date, searchable dropdown,
"Other" location) — not built yet.
