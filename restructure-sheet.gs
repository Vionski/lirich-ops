/* ============================================================
   ONE-TIME cleanup — run this once from the Apps Script editor.
   Splits the crowded "Customer DB" tab into:
     • "Customers" tab  → A-J (No, Name, Location, Contact, Phone, and
                           the 5 job-type prices Exchange/Collect/Delivery/Sell/Dump)
     • "Lists" tab      → the reference data that was jammed into K-O
                           (Drivers+Vehicles, Bin Types, Waste Types, Dumping Locations)

   HOW TO RUN:
     1. Open the Lirich spreadsheet → Extensions → Apps Script.
     2. Paste this whole function at the bottom of the code, Save (Ctrl+S).
     3. In the function dropdown pick "restructureSheet", click ▶ Run.
     4. Check the Lirich sheet — you now have "Customers" and "Lists" tabs.
   Safe to run once. It preserves everything (nothing is lost).
   ============================================================ */
function restructureSheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  // guard: if already done, do nothing (safe to click twice)
  if (ss.getSheetByName('Customers') && !ss.getSheetByName('Customer DB')) {
    Logger.log('Already restructured — Customers + Lists tabs exist. Nothing to do.');
    return;
  }
  var cust = ss.getSheetByName('Customer DB');
  if (!cust) throw 'No "Customer DB" tab found.';

  var rows = cust.getDataRange().getValues();
  // 0-indexed columns of the reference lists currently living in K-O:
  //   K=10 Bin Type, L=11 Driver, M=12 Vehicle, N=13 Waste, O=14 Dumping
  var drivers = [], bins = [], waste = [], dump = [];
  var seenD = {}, seenB = {}, seenW = {}, seenU = {};
  for (var i = 1; i < rows.length; i++) {
    var r = rows[i];
    var dn = String(r[11] || '').trim(), vn = String(r[12] || '').trim();
    if (dn) { var k = dn + '|' + vn; if (!seenD[k]) { seenD[k] = 1; drivers.push([dn, vn]); } }
    var bt = String(r[10] || '').trim(); if (bt && !seenB[bt]) { seenB[bt] = 1; bins.push(bt); }
    var wt = String(r[13] || '').trim(); if (wt && !seenW[wt]) { seenW[wt] = 1; waste.push(wt); }
    var du = String(r[14] || '').trim(); if (du && !seenU[du]) { seenU[du] = 1; dump.push(du); }
  }

  // (re)build the Lists tab — each list in its own column, growing independently
  var lists = ss.getSheetByName('Lists');
  if (lists) ss.deleteSheet(lists);
  lists = ss.insertSheet('Lists');
  lists.getRange('A1').setValue('Driver Name');
  lists.getRange('B1').setValue('Vehicle Number');
  lists.getRange('D1').setValue('Bin Type');
  lists.getRange('F1').setValue('Waste Type');
  lists.getRange('H1').setValue('Dumping Location');
  lists.getRange(1, 1, 1, 8).setFontWeight('bold');
  for (var a = 0; a < drivers.length; a++) {
    lists.getRange(a + 2, 1).setValue(drivers[a][0]);
    lists.getRange(a + 2, 2).setValue(drivers[a][1]);
  }
  for (var b = 0; b < bins.length; b++)  lists.getRange(b + 2, 4).setValue(bins[b]);
  for (var c = 0; c < waste.length; c++) lists.getRange(c + 2, 6).setValue(waste[c]);
  for (var d = 0; d < dump.length; d++)  lists.getRange(d + 2, 8).setValue(dump[d]);
  lists.setColumnWidth(1, 130); lists.setColumnWidth(2, 130); lists.setColumnWidth(3, 24);
  lists.setColumnWidth(4, 110); lists.setColumnWidth(5, 24); lists.setColumnWidth(6, 140);
  lists.setColumnWidth(7, 24); lists.setColumnWidth(8, 280);

  // remove columns K-O (11..15) from the customer tab and rename it
  cust.deleteColumns(11, 5);
  if (cust.getName() !== 'Customers') cust.setName('Customers');

  Logger.log('Done. Customers tab cleaned (A-J). Lists tab created — drivers: %s, bins: %s, waste: %s, dumping: %s',
    drivers.length, bins.length, waste.length, dump.length);
}
