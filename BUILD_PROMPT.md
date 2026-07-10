# Build Brief — "Lirich Ops" Waste Logistics CRM (PWA)

Paste this whole file into a fresh Claude Code session to recreate the app.

---

## 0. What to build

A **mobile-first Progressive Web App (PWA)** called **Lirich Ops** for a
Singapore waste/garbage-disposal company, **Lirich Resources Pte Ltd**. It
digitises the full operation: office assigns jobs → drivers run trips and
capture Delivery Orders (DOs) → pay is auto-calculated → bins are tracked →
earnings export for accounting.

**Hard constraints (match these exactly):**
- **No build step, no framework, no backend.** Plain HTML + CSS + vanilla JS.
- Files: `index.html`, `app.js`, `sw.js`, `manifest.json`, `icon.svg`, `README.md`.
- Data persists in `localStorage` behind a single small **storage adapter object**
  (`const DB = { load(), save() }`) so it can later be swapped for Supabase
  **without touching any view code**.
- Installable + offline (service worker, network-first with cache fallback).
- Mobile-first, single column, max width ~680px, sticky header, bottom tab nav,
  bottom-sheet modals, toast notifications. Clean, production-quality UI.
- Theme: waste/eco **green** `#0f7a4d` (dark `#0b5d3a`), light bg `#eef2f0`,
  card white. Accent colors: amber `#c4860a`, blue `#2563c4`, red `#c4362f`,
  violet `#7a3fc4`. Rounded cards (radius 16px), soft shadows.

---

## 1. Business context & real workflow

Company: **Lirich Resources Pte Ltd**, 23 Gul Drive, Singapore 629471.
Fleet: **5 trucks, 5 drivers, 100 bins**. Two job kinds: **land** (companies)
and **vessel** (ships at PSA port, come with a PSA cargo pass).

Current paper/WhatsApp flow the app replaces:

1. **Operator WhatsApps a driver** the job: company name, address, task, contact.
2. **Driver fills a paper Daily Job Card** row-by-row through the day.
3. On site the driver collects a **Delivery Order**: a *Company DO* (land) or a
   *Vessel DO* (+ an accompanying **PSA cargo pass**).
4. Each task pays per the **Driver Trip Incentive** rate sheet.
5. A **weighing ticket** is produced (gross/tare/net weight).
6. At day end the operator **consolidates earnings** from the job cards, and the
   DOs feed **Xero** invoicing.

---

## 2. Two roles (one install, switch via a header pill)

Simulate multi-device on one install with a role switcher:

- **Operator / Office** — tabs: **Dashboard, Jobs, Bins, Earnings, CRM**.
- **Driver** (choose 1 of 5) — tabs: **My Jobs, Job Card, Bins, My Pay**.

Header shows role avatar + name; driver header also shows `Driver N · Truck PLATE · date`.

---

## 3. Reference data (seed these)

**Drivers** (id, code, name, truck, color):
1 Sathish (green), 2 Karthik (blue), 3 Kumar (amber), 4 Liu (violet), 5 Yao Jun (red).

**Trucks** (plates): XE6221D, XE8496P, XE5876P, XE7330L, XE9012K.

**100 bins** — generate: 55 numbered `7000`–`7054`, 25 as `R01`–`R25`,
20 as `L800`–`L819`. Each bin: `{ no, size, status, clientId, waste }`.
Sizes cycle through: 5ft, 10ft, 10ft, 15ft, 20ft, 30ft.
Bin status ∈ `yard | client | transit | repair`.
Seed a handful out at clients (e.g. `7022`,`R08` → Radha; `7045` → Eng Lee
Styrofoam) and set `L805` = repair.

**Clients / CRM** (name, address, contact, phone, type):
- Eng Lee Logistics Pte Ltd — 9 Gul Circle — Jacky — 84118884 — land
- Radha Exports Pte Ltd — 118 Pioneer Rd L1 — Radha — land
- Aspiration City — Boon Lay Ave — land
- SLG Construction — Tuas South Ave 10 — land
- Tian Heng Eng — Tractor Rd — land
- Pacific International Lines — PSA, BT Gate 2 Commercial Lane — vessel

---

## 4. Pricing engine (CRITICAL — encode exactly)

From the "Driver's Trip Incentive (effective 01 May 2026)" sheet. Model as a
list of **trip types** (each a base rate) plus toggleable **surcharges**. A trip's
pay = base (or distance-based) + sum of selected surcharges.

**Trip types** `{id, label, base, note}`:
| id | label | base |
|----|-------|------|
| send | Send Bin — Island Wide (empty truck return = full trip by distance) | $8 |
| col_s | Collect / Exchange — Short | $8 |
| col_m | Collect / Exchange — Middle | $13 |
| col_l | Collect / Exchange — Long | $18 |
| dump | Dump & Return | $23 |
| nea_wk | NEA Rubbish (Yard→NEA) Mon–Sat | $1.50 × distance (perKm) |
| nea_sun | NEA Rubbish — Sun & PH | $13 |
| wood | Wood Waste (Beejoo/Kimhock) | $18  (i.e. $13 + $5) |
| recycle | Sell Recycle (by distance) | $18 |
| psa | PSA Vessel | $20 (+$5 Sun/PH) |
| stgul | ST Gul / ST Benoi Vessel | $30 (+$5 Sun/PH) |
| vessel | Vessel Visit (other) | $19.50 (incl. base waiting time) |
| add | Additional / Missed Trip | $8 |

**Surcharges** `{id, label, amt}` (checkboxes on the trip form):
- After 7pm (customer request) +$8
- After 7pm (Vessel) +$5
- After Midnight +$5
- Penjuru Terminal / MSW +$10
- On-the-spot loading +$8
- Vessel wait > 2 hrs +$10
- Vessel wait > 4 hrs +$20
- Sunday / Public Holiday +$5

`tripPay(trip)` = `type.perKm ? perKm*distance : type.base`, plus each selected
surcharge amount. Round to 2 dp. The trip form shows this live as the user edits.

---

## 5. Data model (localStorage under one key)

```
state = {
  role: { kind:'operator'|'driver', driverId },
  clients: [ {id,name,addr,contact,phone,type} ],
  bins:    [ {id,no,size,status,clientId,waste} ],
  jobs:    [ {id,clientId,task,binSize,waste,instructions,driverId,truckId,
              status:'assigned'|'in_progress'|'done', date, createdAt} ],
  trips:   [ {id,driverId,date,clientId,typeId,binOut,binIn,timeStart,timeEnd,
              disposeTo,tonnage,distance,surcharges:[],remarks,
              doType:'land'|'vessel',doNo,vessel:{name,a..f},photos:[dataURL],
              weight:{gross,tare,net,ticket}, invoiced} ],
  tab: {operator, driver},
  seq: {job, trip, do, ticket},
}
```

---

## 6. Screens & behaviour

**Operator · Dashboard** — KPI tiles (open jobs today, trips logged, total driver
pay today, bins out at clients). "Fleet today" list: each driver's jobs done/total,
trip count, pay today, on-a-job badge. Bin inventory summary bar (yard/client/repair).
Recent jobs.

**Jobs** (operator = all with status filter tabs; driver = only mine). Each row:
client, address, task, status chip, bin size/waste, assigned driver, base pay.
Tap → detail sheet. **FAB "+ Assign job"** opens a form (client, task type, driver,
bin size, waste, instructions) — the digital WhatsApp message. Job detail lets
operator reassign/delete; lets driver **Accept & start**, then **Log trip / DO**.
Include a WhatsApp deep-link button `https://wa.me/65<phone>` to the client contact.

**Driver · Job Card** — the digital Daily Job Card: a table of today's trips
(#, customer/bin, time, charge) with an auto **Total trip charge**. **FAB "+ Log a
trip / DO"**.

**Trip / DO form** (the core screen):
- Customer, task type (drives pay), Bin OUT / Bin IN, time start/end, dispose-to,
  tonnage, distance.
- Surcharge checkboxes (live-recalc pay).
- DO type toggle **Company (land)** vs **Vessel + PSA**. Vessel reveals waste
  category inputs A–F (Plastics, Food, Domestic, Cooking oil, Incinerator ashes,
  Operational — in m³) + vessel name. DO number auto-increments.
- **Photo capture** (`<input type="file" accept="image/*" capture="environment">`),
  stored as data URLs, thumbnails shown. Attach DO + PSA pass.
- Live "Trip pay" total. Save → appends trip, **auto-moves bins** (see §7),
  marks the linked job `done`.

**Bins** — inventory of all 100: search box, status filter tabs with counts, a
responsive **color-coded grid** (green yard / amber client / blue transit / red
repair) showing bin no + size. Tap a bin → detail; operator can change status
and assign to a client. Legend row.

**Earnings** (operator) — date picker; per-driver expandable cards with each
trip and a subtotal; grand total KPI. Buttons: **Export day (CSV for Xero)** and
**Export DOs for invoicing** (CSV download built in JS, no library).

**CRM** — searchable client list with bins-on-site + trip counts. Client detail:
info, bins on site, billable total, **job-history timeline**, WhatsApp button,
"Assign job" shortcut. **FAB "+ Add"** → new client form.

**My Pay** (driver) — big "earnings today" hero card, totals, trips grouped by
date, and the trip-incentive rate table for reference.

---

## 7. Automation rules

- Saving a trip with **Bin OUT** sets that bin `status=client, clientId=trip.client`.
- Saving a trip with **Bin IN** sets that bin back to `status=yard, clientId=null`.
- Saving a trip whose job is linked marks the **job `done`**.
- Earnings = sum of `tripPay()` over trips, grouped by driver and by day.
- Provide a **"Reset demo data"** action (in the role-switch sheet) that reseeds.

---

## 8. Seed one completed example (so the app isn't empty)

- Job cards for 3 assigned jobs (Eng Lee send-bin, Radha exchange in-progress,
  PIL PSA vessel after-7pm).
- One completed trip: Kumar, Radha Exports, Collect/Exchange Middle ($13),
  bin out `R08` / in `7022`, dispose WDL, 2.2 t, DO #24119,
  weighing ticket LR23141 (gross 17970 / tare 15770 / net 2200 kg).
- Sequence counters start at: job 4, trip 2, DO 24120, ticket 23142.
- Use a fixed "today" = `2026-06-30` so seed data lines up.

---

## 9. PWA plumbing

- `manifest.json`: name "Lirich Ops — Waste Logistics CRM", short_name
  "Lirich Ops", standalone, portrait, theme `#0f7a4d`, bg `#eef2f0`, svg icon
  (any + maskable).
- `sw.js`: cache `['./','./index.html','./app.js','./manifest.json','./icon.svg']`,
  network-first with cache fallback, `skipWaiting` + `clients.claim`.
- Register the SW from `index.html`.
- `icon.svg`: green rounded-square with a simple waste-bin glyph.

---

## 10. Acceptance checklist (verify before finishing)

1. Loads with no console errors; installable; works offline.
2. Operator can assign a job → it appears for the chosen driver.
3. Driver can log a trip; **pay auto-calculates** and updates live with surcharges.
4. Saving a trip **moves the bins** (out→client, in→yard) and totals the job card.
5. Vessel DO shows A–F category fields; photo capture attaches thumbnails.
6. Earnings screen consolidates per driver and exports valid CSV.
7. Bins screen shows all 100, color-coded, searchable, filterable.
8. Role switch (Operator ↔ each of 5 drivers) reflows nav + views correctly.

---

## 11. Nice-to-have / next step (mention, don't block on)

Keep the storage behind the `DB` adapter so a later version can swap `localStorage`
for **Supabase** (free tier) to get real shared multi-device sync ("one CRM"
across the office + 5 driver phones) without rewriting any screens.
