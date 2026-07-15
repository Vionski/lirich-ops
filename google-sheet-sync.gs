/* ============================================================
   Lirich Ops — Google Sheets database (production bridge v4)

   Master data (jobs, trips, clients, bins, counters) lives in this
   script's storage. Every phone reads/writes it. The spreadsheet tabs
   are LIVE VIEWS, rebuilt on every change — do NOT hand-edit Trips/Jobs,
   your edits get overwritten. To change a trip, the operator edits it in
   the app; that updates the database and rewrites the Trips sheet.

   Tabs the OFFICE edits (inputs):
     • "Customers"  A No | B Name | C Location | D Contact | E Phone |
                    F Exchange | G Collect | H Delivery | I Sell | J Dump   (F-J = customer charge)
     • "Lists"      A Driver | B Vehicle | D Bin Type | F Waste | H Dumping
     • "Bin DB"     A Bin No | B Bin Type   (the master bin list — read once to seed unknown
                    bins; size backfills a bin if it doesn't have one yet. Location/status is
                    NEVER read from here — that only ever comes from a driver's trip or an
                    operator override, so don't hand-edit it in this tab.)
   Tabs the APP writes (reports — read only):
     • "Trips"  (rich, one row per trip)   • "Jobs"   • "Trips Archive"   • "Bin Inventory"

   Endpoints:
     doGet ?state=1  → full shared state       doGet ?rev=1 → revision number
     doGet ?db=1     → Customers + Lists + Bin DB (dropdowns + pricing + bin seed)
     doPost {action} → mutations (under a lock)

   After pasting: Deploy → Manage deployments → ✏️ → New version → Deploy.
   ============================================================ */

function json_(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}
function state_() {
  var s = PropertiesService.getScriptProperties().getProperty('STATE');
  return s ? JSON.parse(s) : null;
}
function put_(st) {
  PropertiesService.getScriptProperties().setProperty('STATE', JSON.stringify(st));
}
function n_(v) { var x = String(v == null ? '' : v).replace(/[^0-9.\-]/g, ''); return x === '' ? null : Number(x); }

/* ---------------- reads ---------------- */
function doGet(e) {
  var p = (e && e.parameter) || {};
  if (p.db) return json_(customerDB_());
  if (p.rev) { var st = state_(); return json_({ rev: st ? st.rev : 0 }); }
  var st2 = state_();
  return json_(st2 || { empty: true, rev: 0 });
}

/* find a column by header text (prefix match, then contains); -1 if absent */
function col_(headers, needle) {
  var n = needle.toLowerCase(), i;
  for (i = 0; i < headers.length; i++) if (String(headers[i]).trim().toLowerCase().indexOf(n) === 0) return i;
  for (i = 0; i < headers.length; i++) if (String(headers[i]).trim().toLowerCase().indexOf(n) >= 0) return i;
  return -1;
}

/* Customers tab → clients + per-customer pricing; Lists tab → dropdown options.
   Everything is read BY COLUMN HEADER, so columns can be reordered/inserted freely.
   Falls back to a legacy single "Customer DB" tab if the split tabs aren't there yet. */
function customerDB_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var out = { clients: [], drivers: [], wasteTypes: [], dumpLocations: [], binTypes: [], bins: [] };
  var JOBTYPES = ['Exchange', 'Collect', 'Delivery', 'Sell', 'Dump'];

  // ---- clients (prefer "Customers" tab, else legacy "Customer DB") ----
  var cust = ss.getSheetByName('Customers') || ss.getSheetByName('Customer DB');
  if (cust) {
    var rows = cust.getDataRange().getValues();
    if (rows.length) {
      var h = rows[0];
      var cName = col_(h, 'customer name'), cLoc = col_(h, 'service location'),
          cPerson = col_(h, 'contact person'), cPhone = col_(h, 'contact no');
      var pIdx = JOBTYPES.map(function (jt) { return col_(h, jt.toLowerCase()); });
      var last = '';
      for (var i = 1; i < rows.length; i++) {
        var r = rows[i];
        var name = cName >= 0 ? String(r[cName] || '').trim() : '';
        var addr = cLoc >= 0 ? String(r[cLoc] || '').trim() : '';
        if (name) last = name;
        var cname = name || last;
        if (!cname && !addr) continue;
        var prices = {};
        for (var j = 0; j < 5; j++) { if (pIdx[j] >= 0) { var v = n_(r[pIdx[j]]); if (v != null) prices[JOBTYPES[j]] = v; } }
        out.clients.push({
          name: cname, addr: addr,
          contact: cPerson >= 0 ? String(r[cPerson] || '').trim() : '',
          phone: cPhone >= 0 ? String(r[cPhone] || '').replace(/\D/g, '') : '',
          prices: prices
        });
      }
    }
  }

  // ---- lists (prefer "Lists" tab, read by header) ----
  var lists = ss.getSheetByName('Lists');
  if (lists) {
    var lr = lists.getDataRange().getValues();
    if (lr.length) {
      var lh = lr[0];
      var cDrv = col_(lh, 'driver name'), cVeh = col_(lh, 'vehicle number'),
          cBin = col_(lh, 'bin type'), cWaste = col_(lh, 'waste type'), cDump = col_(lh, 'dumping location');
      for (var k = 1; k < lr.length; k++) {
        var row = lr[k];
        if (cDrv >= 0 && row[cDrv]) out.drivers.push({ name: String(row[cDrv]).trim(), vehicle: cVeh >= 0 ? String(row[cVeh] || '').trim() : '' });
        if (cBin >= 0 && row[cBin]) out.binTypes.push(String(row[cBin]).trim());
        if (cWaste >= 0 && row[cWaste]) out.wasteTypes.push(String(row[cWaste]).trim());
        if (cDump >= 0 && row[cDump]) out.dumpLocations.push(String(row[cDump]).trim());
      }
    }
  } else if (cust && cust.getName() === 'Customer DB') {
    // legacy: lists jammed into K-O of the old single tab
    var rows2 = cust.getDataRange().getValues();
    for (var m = 1; m < rows2.length; m++) {
      var r2 = rows2[m];
      if (r2[11]) out.drivers.push({ name: String(r2[11]).trim(), vehicle: String(r2[12] || '').trim() });
      if (r2[10]) out.binTypes.push(String(r2[10]).trim());
      if (r2[13]) out.wasteTypes.push(String(r2[13]).trim());
      if (r2[14]) out.dumpLocations.push(String(r2[14]).trim());
    }
  }

  // ---- bin DB (master bin list — bin no + size only; location is never read from here) ----
  var binDb = ss.getSheetByName('Bin DB');
  if (binDb) {
    var br = binDb.getDataRange().getValues();
    if (br.length) {
      var bh = br[0];
      var cBno = col_(bh, 'bin no'), cBsize = col_(bh, 'bin type');
      if (cBsize < 0) cBsize = col_(bh, 'size');
      for (var bi = 1; bi < br.length; bi++) {
        var brow = br[bi];
        var no = cBno >= 0 ? String(brow[cBno] || '').trim() : '';
        if (!no) continue;
        out.bins.push({ no: no, size: cBsize >= 0 ? String(brow[cBsize] || '').trim() : '' });
      }
    }
  }
  return out;
}

/* ---------------- writes ---------------- */
function doPost(e) {
  var lock = LockService.getScriptLock();
  lock.waitLock(25000);
  try {
    var q = JSON.parse(e.postData.contents);
    if (q.action === 'addPhoto') return json_(addPhoto_(q));
    if (q.action === 'emailDO') return json_(emailDO_(q));

    var st = state_();
    if (q.action === 'initState') {
      if (!st) { st = q.state; st.rev = 1; put_(st); mirror_(st); }
      return json_(st);
    }
    if (q.action === 'resetState') {
      var prev = st ? st.rev : 0;
      st = q.state; st.rev = prev + 1;
      put_(st); mirror_(st);
      return json_(st);
    }
    if (!st) return json_({ error: 'Database not initialised — open the app once while online.' });

    apply_(st, q);
    st.rev++;
    autoArchive_(st);
    put_(st);
    mirror_(st);
    return json_(st);
  } catch (err) {
    return json_({ error: String(err) });
  } finally {
    try { lock.releaseLock(); } catch (_) {}
  }
}

function apply_(st, q) {
  function find(arr, id) { for (var i = 0; i < arr.length; i++) if (arr[i].id === id) return arr[i]; return null; }
  switch (q.action) {
    case 'addJob':
      q.job.id = st.seq.job++;
      st.jobs.push(q.job);
      break;
    case 'updateJob': {
      var j = find(st.jobs, q.id);
      if (j) for (var k in q.patch) j[k] = q.patch[k];
      break;
    }
    case 'deleteJob':
      st.jobs = st.jobs.filter(function (x) { return x.id !== q.id; });
      break;
    case 'addTrip': {
      var t = q.trip;
      t.id = st.seq.trip++;
      t.tServer = Date.now(); /* server-received time — cross-check vs the phone's photo times */
      if (t.needTicket && t.weight) t.weight.ticket = 'LR' + (st.seq.ticket++);
      delete t.needTicket;
      if (t.photosB64 && t.photosB64.length) {
        var jobtag = t.jobId ? t.jobId : ('T' + t.id);
        var kinds = t.photoKinds || [];
        var PFX = { do: 'DO', out: 'BINOUT', in: 'BININ', bin: 'BIN', gross: 'GROSS', tare: 'TARE', signature: 'SIG' };
        var cnt = {};
        t.photos = [];
        for (var pi = 0; pi < t.photosB64.length; pi++) {
          var kind = kinds[pi] || 'do';
          var pfx = PFX[kind] || 'DO';
          cnt[pfx] = (cnt[pfx] || 0) + 1;
          var nm = pfx + '-' + jobtag + '-' + cnt[pfx];
          try { var rec = addPhoto_({ b64: t.photosB64[pi], name: nm + '.jpg' }); rec.kind = kind; t.photos.push(rec); } catch (perr) {}
        }
      }
      delete t.photosB64;
      delete t.photoKinds;
      /* Bin IN = empty bin arriving at client (status -> client). Bin OUT = full bin leaving client, back to yard (status -> yard).
         A bin no. the state has never seen before is created on the spot — a driver just stood in
         front of it, so it's verified from the moment it's created (status is never 'unknown' here). */
      var ensureBin_ = function (no) {
        var b = st.bins.filter(function (x) { return x.no === no; })[0];
        if (!b) { b = { no: no, size: '', status: 'unknown', clientId: null, siteIdx: 0, source: 'driver', firstSeen: t.date }; st.bins.push(b); }
        if (!b.size && t.jobBinSize) b.size = t.jobBinSize;
        return b;
      };
      if (t.binIn) { var bi = ensureBin_(t.binIn); bi.status = 'client'; bi.clientId = t.clientId; bi.siteIdx = t.jobSiteIdx || 0; }
      if (t.binOut) { var bo = ensureBin_(t.binOut); bo.status = 'yard'; bo.clientId = null; bo.siteIdx = 0; }
      delete t.jobBinSize; delete t.jobSiteIdx;
      /* q.final === false = driver tapped "Save" (waiting on something, e.g. the DO) — the job
         stays open so they can resume it later. Anything else (incl. old clients with no flag) finalises as before. */
      if (t.jobId && q.final !== false) { var tj = find(st.jobs, t.jobId); if (tj) tj.status = 'done'; }
      st.trips.push(t);
      break;
    }
    case 'setTonnAdj': {
      var tr = find(st.trips, q.id);
      if (tr) tr.tonnAdj = q.adj;
      break;
    }
    case 'updateTrip': {
      var tu = find(st.trips, q.id);
      if (tu) {
        var wasFinal = q.patch && ('final' in q.patch) ? q.patch.final : null;
        if (q.patch) delete q.patch.final; /* driver Save/Done flag — not a real trip field */
        for (var k3 in q.patch) tu[k3] = q.patch[k3];
        if (tu.weight && tu.weight.gross && !tu.weight.ticket) tu.weight.ticket = 'LR' + (st.seq.ticket++);
        /* resuming a saved-for-later trip and tapping "Done" now finalises the linked job */
        if (wasFinal === true && tu.jobId) { var tj2 = find(st.jobs, tu.jobId); if (tj2) tj2.status = 'done'; }
      }
      break;
    }
    case 'updateBin': {
      var b2 = st.bins.filter(function (b) { return b.no === q.no; })[0];
      if (b2) for (var k2 in q.patch) b2[k2] = q.patch[k2];
      break;
    }
    case 'addClient':
      st.clients.push(q.client);
      break;
    case 'replaceClients':
      st.clients = q.clients;
      break;
    case 'replaceBins': {
      /* UPSERT only — never overwrites live status/clientId, which only a trip or an operator
         override should touch. This just seeds bins the state doesn't have yet, or backfills
         a still-blank size, so it can't clobber another device's very recent status change. */
      (q.bins || []).forEach(function (nb) {
        var eb = st.bins.filter(function (x) { return x.no === nb.no; })[0];
        if (!eb) { st.bins.push(nb); }
        else if (!eb.size && nb.size) { eb.size = nb.size; }
      });
      break;
    }
    default:
      throw 'Unknown action: ' + q.action;
  }
}

/* ---------------- photos → Drive ---------------- */
function addPhoto_(q) {
  var it = DriveApp.getFoldersByName('Lirich Ops DO Photos');
  var folder = it.hasNext() ? it.next() : DriveApp.createFolder('Lirich Ops DO Photos');
  var blob = Utilities.newBlob(Utilities.base64Decode(q.b64), 'image/jpeg', q.name || 'do-photo.jpg');
  var f = folder.createFile(blob);
  f.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
  var id = f.getId();
  return { id: id, url: 'https://drive.google.com/uc?export=view&id=' + id, thumb: 'https://drive.google.com/thumbnail?id=' + id + '&sz=w240' };
}

/* ---------------- digital DO: render to PDF + email + Drive copy ---------------- */
function emailDO_(q) {
  if (!q.to || !q.html) return { sent: false, error: 'missing to/html' };
  try {
    var pdf = HtmlService.createHtmlOutput(q.html).getAs('application/pdf').setName((q.subject || 'Delivery Order') + '.pdf');
    /* keep an office copy in Drive too, alongside the DO/bin photos */
    var it = DriveApp.getFoldersByName('Lirich Ops DO Photos');
    var folder = it.hasNext() ? it.next() : DriveApp.createFolder('Lirich Ops DO Photos');
    folder.createFile(pdf.copyBlob());
    GmailApp.sendEmail(q.to, q.subject || 'Delivery Order', 'Please find the delivery order attached.\n\nLirich Resources Pte Ltd', { attachments: [pdf], name: 'Lirich Resources' });
    return { sent: true };
  } catch (err) {
    return { sent: false, error: String(err) };
  }
}

/* ---------------- housekeeping ---------------- */
function autoArchive_(st) {
  if (st.trips.length <= 450) return;
  var old = st.trips.splice(0, st.trips.length - 300);
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sh = ss.getSheetByName('Trips Archive') || ss.insertSheet('Trips Archive');
  if (sh.getLastRow() === 0) sh.appendRow(tripHeader_());
  old.forEach(function (t) { sh.appendRow(tripRow_(t)); });
}

/* ---------------- Trips: rich report (one row per trip) ---------------- */
function tripHeader_() {
  return ['Date', 'Job #', 'Driver', 'Customer', 'Service Location', 'Salesperson',
    'Waste Type', 'Trip Type', 'DO Type', 'DO / V No', 'Vehicle No.',
    'Bin Out (full)', 'Bin In (empty)', 'Time Start', 'Time End', 'Dispose To', 'Distance (km)',
    'Tonnage (t)', 'Adjustment (t)', 'Final Tonnage (t)',
    'Gross (kg)', 'Tare (kg)', 'Adjustment (kg)', 'Net (kg)', 'Weighing Ticket',
    'Surcharges', 'Driver Pay ($)', 'Customer Charge ($)',
    'Vessel Name', 'Vessel Location',
    'Cat A Plastics (m³)', 'Cat B Food (m³)', 'Cat C Domestic (m³)', 'Cat D Cooking Oil (m³)', 'Cat E Ashes (m³)', 'Cat F Operational (m³)', 'Total (m³)',
    'Signed', 'Signed By', 'Signer Position',
    'DO Photos', 'Bin Photos', 'Weight Photos', 'DO Photo Links', 'Bin Photo Links', 'Weight Photo Links', 'Remarks', 'Invoiced',
    /* --- photo-stamped times + tamper cross-check (office does OT formulas off these) --- */
    'Time Accept', 'Time DO Photo', 'Time Bin OUT', 'Time Bin IN', 'Time Finish', 'Time Weigh', 'Server Received',
    'Travel (min)', 'Wait (min)', 'Job (min)', 'Accept→Finish (min)', 'Time Flag'];
}
/* ms epoch -> real Date for the sheet (blank if 0/absent). Sheet timezone formats it. */
function tsDate_(ms) { return ms ? new Date(Number(ms)) : ''; }
function mins_(a, b) { return (a && b && b >= a) ? Math.round((b - a) / 60000) : ''; }
function tripRow_(t) {
  var total = Math.round(((Number(t.tonnage) || 0) + (Number(t.tonnAdj) || 0)) * 100) / 100;
  var w = t.weight || {};
  var wNet = (w.gross || w.gross === 0) && (w.tare || w.tare === 0)
    ? Math.round(((Number(w.gross) - Number(w.tare)) + (Number(t.weightAdj) || 0)) * 100) / 100 : '';
  var doP = [], binP = [], wP = [], sigP = '';
  (t.photos || []).forEach(function (p) {
    if (!p || !p.url) return;
    if (p.kind === 'do') doP.push(p.url);
    else if (p.kind === 'gross' || p.kind === 'tare') wP.push(p.url);
    else if (p.kind === 'signature') sigP = p.url;
    else binP.push(p.url);
  });
  var v = t.vessel || {};
  /* durations from the photo timestamps. Driver flow is bins FIRST, then DO —
     travel = accept -> first photo taken on site (whichever kind came first),
     job = binIN (start) -> binOUT (end). Wait is left to office formulas off the raw times. */
  var binTimes = [t.tBinIn, t.tBinOut].filter(Boolean);
  var firstBin = binTimes.length ? Math.min.apply(null, binTimes) : 0;
  var onSite = [t.tDO, t.tBinIn, t.tBinOut].filter(Boolean);
  var firstOnSite = onSite.length ? Math.min.apply(null, onSite) : 0;
  var travel = mins_(t.tAccept, firstOnSite);
  var wait = mins_(t.tDO, firstBin); /* legacy col — blank when DO comes after the bins */
  var jobMin = mins_(t.tBinIn, t.tBinOut);
  var totalMin = mins_(t.tAccept, t.tEnd);   /* accept -> finish, works for every job type incl Sell/Dump */
  /* flag if a photo time is in the future vs the server, or the sync gap is huge (offline/clock changed) */
  var lastPhoto = Math.max(t.tDO || 0, t.tBinOut || 0, t.tBinIn || 0, t.tEnd || 0);
  var flag = '';
  if (t.tServer && lastPhoto) {
    if (lastPhoto > t.tServer + 120000) flag = '⚠️ photo time ahead of server';
    else if (t.tServer - lastPhoto > 12 * 3600000) flag = '⚠️ large sync gap — verify';
  }
  var noDO = (t.jobType === 'Sell' || t.jobType === 'Dump');
  var doCell = noDO ? '—' : (t.doNo ? ((t.doType === 'vessel' ? 'V ' : 'DO ') + t.doNo) : 'PENDING');
  return [
    t.date, t.jobId || '', t._driver || '', t._client || '', t._addr || '', t._sales || '',
    t.waste || '', t._type || '', t.doType || '', doCell, t.vehicleNo || '',
    t.binOut || '', t.binIn || '', t.timeStart || '', t.timeEnd || '', t.disposeTo || '', t.distance || '',
    t.tonnage || 0, t.tonnAdj || 0, total,
    w.gross || '', w.tare || '', t.weightAdj || 0, wNet, w.ticket || '',
    t._surch || '', t._pay || 0, (t._charge != null ? t._charge : ''),
    v.name || '', v.location || '',
    (v.a || ''), (v.b || ''), (v.c || ''), (v.d || ''), (v.e || ''), (v.f || ''), (v.total || ''),
    sigP ? 'YES' : 'No', t.sigName || '', t.sigPosition || '',
    doP.length, binP.length, wP.length, doP.join('\n'), binP.join('\n'), wP.join('\n'), t.remarks || '', t.invoiced ? 'YES' : '',
    tsDate_(t.tAccept), tsDate_(t.tDO), tsDate_(t.tBinOut), tsDate_(t.tBinIn), tsDate_(t.tEnd), tsDate_(t.tWeight), tsDate_(t.tServer),
    travel, wait, jobMin, totalMin, flag
  ];
}

/* rebuild Trips + Jobs tabs from state */
function mirror_(st) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var tSheet = ss.getSheetByName('Trips') || ss.insertSheet('Trips');
  var tRows = [tripHeader_()].concat(st.trips.map(tripRow_));
  tSheet.clearContents();
  tSheet.getRange(1, 1, tRows.length, tRows[0].length).setValues(tRows);
  tSheet.getRange(1, 1, 1, tRows[0].length).setFontWeight('bold');
  tSheet.setFrozenRows(1);

  var jSheet = ss.getSheetByName('Jobs') || ss.insertSheet('Jobs');
  var jRows = [['Job #', 'Date', 'Status', 'Customer', 'Service Location', 'Contact', 'Task', 'Bin Size',
    'Waste', 'Dump To', 'Driver', 'Started At', 'Instructions']];
  st.jobs.forEach(function (j) {
    jRows.push([j.id, j.date, j.status, j._client || '', j._addr || '', j._contact || '', j._task || j.task,
      j.binSize, j.waste, j.dumpTo || '', j._driver || '', j.startedAt || '', j.instructions || '']);
  });
  jSheet.clearContents();
  jSheet.getRange(1, 1, jRows.length, jRows[0].length).setValues(jRows);
  jSheet.getRange(1, 1, 1, jRows[0].length).setFontWeight('bold');
  jSheet.setFrozenRows(1);

  var bSheet = ss.getSheetByName('Bin Inventory') || ss.insertSheet('Bin Inventory');
  var bRows = [binHeader_()].concat(st.bins.map(function (b) { return binRow_(b, st); }));
  bSheet.clearContents();
  bSheet.getRange(1, 1, bRows.length, bRows[0].length).setValues(bRows);
  bSheet.getRange(1, 1, 1, bRows[0].length).setFontWeight('bold');
  bSheet.setFrozenRows(1);
}

/* ---------------- Bin Inventory: rich report (one row per bin, sortable/filterable) ---------------- */
function binHeader_() {
  return ['Bin No.', 'Size', 'Status', 'At Client', 'Site Address', 'Location Verified', 'Source', 'First Seen'];
}
function siteAddr_(st, clientId, siteIdx) {
  var c = st.clients.filter(function (x) { return x.id === clientId; })[0];
  if (!c || !c.sites || !c.sites.length) return '';
  var s = c.sites[siteIdx] || c.sites[0];
  return s ? (s.addr || '') : '';
}
function binRow_(b, st) {
  var c = b.clientId ? st.clients.filter(function (x) { return x.id === b.clientId; })[0] : null;
  var statusLabel = b.status === 'client' ? 'At client' : (b.status === 'yard' ? 'Yard' : 'Unverified');
  return [
    b.no, b.size || '', statusLabel,
    c ? c.name : '', b.status === 'client' ? siteAddr_(st, b.clientId, b.siteIdx || 0) : '',
    b.status === 'unknown' ? 'No' : 'Yes', b.source || 'seed', b.firstSeen || ''
  ];
}
