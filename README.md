# ♻️ Lirich Ops — Waste Logistics CRM

A mobile-first PWA for **Lirich Resources Pte Ltd** (23 Gul Drive, Singapore).
It digitises the whole paper/WhatsApp workflow: office assigns jobs → drivers
run trips and capture Delivery Orders → pay auto-calculates from the trip
incentive sheet → bins are tracked → earnings export as CSV for Xero.

No build step, no framework, no backend. Plain HTML + CSS + vanilla JS,
`localStorage` persistence, installable, works offline.

## What it replaces (from the sample photos in the parent folder)

| Paper process | In the app |
|---|---|
| WhatsApp message to driver | **Jobs → ＋ Assign job** (client, task, driver, instructions) |
| Paper Daily Job Card | **Driver → Job Card** — auto-totalled trip table |
| Company / Vessel DO + PSA pass | **Log trip / DO** form with land/vessel toggle, A–F waste categories (m³), photo capture |
| Re-typing the DO into records | **📷 → 🔍 OCR**: snap the paper DO, Tesseract.js reads it in the browser and auto-fills DO number, customer, bins, times, gross/tare weights, dispose-to |
| Filing paper DOs | **DO photo archive** (Earnings → 📁): every DO photo stored full-res in IndexedDB, searchable by DO number or client, linked to its trip |
| Driver Trip Incentive sheet | Pricing engine (`TRIP_TYPES` + `SURCHARGES` in `app.js`) — live pay calc |
| Weighing ticket | Gross / tare / net fields, auto ticket number `LR…` |
| Day-end consolidation + Xero | **Earnings** — per-driver subtotals, grand total, 2 CSV exports |

## OCR notes

- OCR runs **entirely in the browser** (Tesseract.js from CDN) — no API keys, no
  per-scan cost, works on the driver's phone. The engine (~15 MB) downloads on
  first use, so the **first scan needs internet**; photos and everything else
  work offline.
- Auto-filled fields only overwrite **empty** fields (except the DO number,
  where the paper DO is the source of truth). The driver always sees a
  "please double-check" summary of what was filled.
- Photos are downscaled to ≤1600 px JPEG before storage, so hundreds of DOs
  fit comfortably in IndexedDB.

## Run it

```powershell
npx serve .          # or: python -m http.server 8080
```

Open the URL on a phone → **Add to Home Screen** to install.

## Logins & roles

Every user signs in with their own account and PIN (demo PINs shown on the
login screen: Operator **1234**, drivers **1111**):
- **Operator / Office** — Dashboard, Jobs, Bins, Earnings, CRM
- **Driver 1–5** (Sathish, Karthik, Kumar, Liu, Yao Jun) — My Jobs, Job Card, Bins, My Pay

The account sheet (header pill) has **Log out**, a demo quick-switch that skips
the PIN, and **Reset demo data**. Demo "today" is fixed to **30 Jun 2026** so
the seed data lines up.

## CRM database

- Clients can have **multiple yards/addresses** and **multiple contact persons**
  — the Assign-job form pulls client → yard → contact as chained dropdowns.
- Each client is linked to a **salesperson** (Marcus or Patrick) for commission:
  Earnings shows a per-salesperson card (clients, trips, adjusted tonnage, value).
- **Import from Excel / Google Sheets** (CRM → ⬆️ Import): upload a CSV or paste
  a shared Google Sheet link; one row per address+contact, same-name rows merge
  into one client with several yards/contacts. Template CSV downloadable.

## Tonnage adjustment

Drivers report tonnage when closing a job. The operator can open any trip (from
CRM history or Earnings) and add a +/- adjustment — e.g. driver 3220, adjustment
+110 → **3330** shown everywhere: trip detail, CRM client totals, salesperson
card, and both CSV exports (Tonnage / Adjustment / Total columns).

## Automations

- Saving a trip with **Bin OUT** → bin becomes `client` at that customer.
- Saving a trip with **Bin IN** → bin returns to `yard`.
- Saving a trip linked to a job → job flips to **done**.
- DO numbers, trip numbers and weighing-ticket numbers auto-increment.

## Notes on exports

- **Export day (CSV for Xero)** — per-trip driver pay + total for payroll/consolidation.
- **Export DOs for invoicing** — one row per DO with description, tonnage and net
  weight. Unit prices are per-client contract, so the `UnitAmount` column is left
  for the office to fill in Xero.

## Next step — real multi-device sync

All persistence goes through the tiny `DB` adapter at the top of `app.js`
(`DB.load()` / `DB.save()`). Swapping it for **Supabase** (free tier) turns this
into one shared CRM across the office + 5 driver phones with no changes to any
view code.
