/* ============================================================
   Lirich Ops — Waste Logistics CRM (local-first PWA)
   Plain vanilla JS, no framework. All persistence goes through
   the DB adapter below so localStorage can later be swapped for
   Supabase without touching any view code.
   ============================================================ */
'use strict';

/* bump alongside sw.js's CACHE string on every deploy — shown in Account so
   it's obvious at a glance whether a device is actually running the latest build */
const APP_VERSION = 'v21';

/* ---------------- storage adapter ---------------- */
const DB = {
  KEY: 'lirich-ops-v1',
  load(){
    try{
      const s = JSON.parse(localStorage.getItem(this.KEY));
      if(s && s.bins && s.seq) return migrate(s);
    }catch(e){}
    return null;
  },
  save(s){ localStorage.setItem(this.KEY, JSON.stringify(s)); },
};

/* ---------------- photo database (IndexedDB) ----------------
   Full-resolution DO photos live here — IndexedDB holds far more
   than localStorage (GBs vs ~5MB). Records:
   {id, full, thumb, tripId, doNo, clientId, driverId, date, createdAt}
   Like DB above, this adapter can be swapped for Supabase Storage
   later without touching view code. */
const PhotoDB = {
  NAME:'lirich-photos', STORE:'photos', _db:null,
  open(){
    if(this._db) return Promise.resolve(this._db);
    return new Promise((res, rej)=>{
      const rq = indexedDB.open(this.NAME, 1);
      rq.onupgradeneeded = ()=>rq.result.createObjectStore(this.STORE, {keyPath:'id'});
      rq.onsuccess = ()=>{ this._db = rq.result; res(this._db); };
      rq.onerror = ()=>rej(rq.error);
    });
  },
  _tx(mode, fn){
    return this.open().then(db=>new Promise((res, rej)=>{
      const tx = db.transaction(this.STORE, mode);
      const out = fn(tx.objectStore(this.STORE));
      tx.oncomplete = ()=>res(out && 'result' in out ? out.result : undefined);
      tx.onerror = ()=>rej(tx.error);
    }));
  },
  put(rec){ return this._tx('readwrite', st=>st.put(rec)); },
  get(id){ return this._tx('readonly', st=>st.get(id)); },
  all(){ return this._tx('readonly', st=>st.getAll()); },
  del(id){ return this._tx('readwrite', st=>st.delete(id)); },
  clear(){ return this._tx('readwrite', st=>st.clear()); },
};

/* photo helpers: downscale camera photos before storing */
function loadImage(src){
  return new Promise((res, rej)=>{
    const im = new Image();
    im.onload = ()=>res(im); im.onerror = rej; im.src = src;
  });
}
async function shrinkImage(dataURL, maxPx, quality){
  const im = await loadImage(dataURL);
  const sc = Math.min(1, maxPx / Math.max(im.width, im.height));
  const cv = document.createElement('canvas');
  cv.width = Math.max(1, Math.round(im.width*sc));
  cv.height = Math.max(1, Math.round(im.height*sc));
  cv.getContext('2d').drawImage(im, 0, 0, cv.width, cv.height);
  return cv.toDataURL('image/jpeg', quality);
}

/* ---------------- fixed reference data ---------------- */
/* real current date (device-local, so Singapore stays Singapore after midnight UTC) */
const TODAY = (()=>{ const d = new Date();
  return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0'); })();

const DRIVERS = [
  {id:1, code:'D1', name:'Sathish', truck:'XE6221D', color:'#0f7a4d'},
  {id:2, code:'D2', name:'Karthik', truck:'XE8496P', color:'#2563c4'},
  {id:3, code:'D3', name:'Kumar',   truck:'XE5876P', color:'#c4860a'},
  {id:4, code:'D4', name:'Liu',     truck:'XE7330L', color:'#7a3fc4'},
  {id:5, code:'D5', name:'Yao Jun', truck:'XE9012K', color:'#c4362f'},
];
const BIN_SIZES = ['5ft','10ft','15ft','20ft','30ft'];
const SALES = ['Marcus', 'Patrick'];
/* customer job-request types — priced per customer in the "Customers" sheet (cols F-J) */
const JOB_TYPES = ['Exchange','Collect','Delivery','Sell','Dump'];

/* Photo sections + which photo stamps which time, per job type.
   Lirich convention: Bin IN = the bin is IN at the client premises (empty, just dropped off),
   Bin OUT = the bin is OUT — leaving the client premises (full, being taken away).
   Times come ONLY from the photo capture on the phone — the driver never types a time. */
const JOB_FLOW = {
  Exchange: { photos:[
      {k:'in',  label:'📷 BIN IN — empty bin dropped at site', hint:'sets Time Start', req:true},
      {k:'out', label:'📷 BIN OUT — full bin picked up', hint:'sets Time End', req:true},
      {k:'do',  label:'📷 DO / PSA', hint:'required', req:true}],
    bins:['in','out'], start:'in', end:'out' },
  Collect:  { photos:[
      {k:'out', label:'📷 BIN OUT — full bin collected', hint:'sets Time Collect', req:true},
      {k:'do', label:'📷 DO', hint:'required', req:true}],
    bins:['out'], mark:'out', markLabel:'Time Collect' },
  Delivery: { photos:[
      {k:'in', label:'📷 BIN IN — empty bin delivered', hint:'sets Time Delivered', req:true},
      {k:'do',  label:'📷 DO', hint:'required', req:true}],
    bins:['in'], mark:'in', markLabel:'Time Delivered' },
  Sell:     { photos:[
      {k:'bin', label:'📷 BIN ON SITE', hint:'sets Time Finish', req:true}],
    bins:[], fixed:true, noDO:true },
  Dump:     { photos:[
      {k:'bin', label:'📷 BIN ON SITE', hint:'sets Time Finish', req:true}],
    bins:[], fixed:true, noDO:true },
};
/* weighbridge photos are NOT part of phase 1 — the yard is a different location from the client
   site, so weight is always captured later via the ⚖️ Add weight step (openWeighForm/saveWeigh). */
function jobFlow(job){ return (job && JOB_FLOW[job.jobType]) || JOB_FLOW.Exchange; }
/* waste types the driver ticks on a land DO (mirrors the paper SEF; multi-select + Others free-text) */
const WASTE_TYPES = ['General Waste','Wood Waste','Plastic Waste','Metal Waste','Mixed Waste','Food Waste'];
function wasteChecksHTML(prefix, selected, otherText){
  const selWords = (selected||[]).map(s=>String(s).toLowerCase().split(' ')[0]);
  return `<div id="${prefix}-waste">
    ${WASTE_TYPES.map(w=>`<label class="checkline"><input type="checkbox" value="${esc(w)}" ${selWords.includes(w.toLowerCase().split(' ')[0])?'checked':''}> ${esc(w)}</label>`).join('')}
    <label class="checkline"><input type="checkbox" id="${prefix}-waste-other-cb" value="__other__" onchange="toggleWasteOther('${prefix}')" ${otherText?'checked':''}> Others</label>
    <input type="text" id="${prefix}-waste-other" placeholder="Specify other waste" value="${esc(otherText||'')}" style="display:${otherText?'block':'none'}; margin-top:6px">
  </div>`;
}
function toggleWasteOther(prefix){
  const cb=$('#'+prefix+'-waste-other-cb'), tx=$('#'+prefix+'-waste-other');
  if(cb&&tx){ tx.style.display=cb.checked?'block':'none'; if(!cb.checked) tx.value=''; }
}
function readWasteChecks(prefix){
  const box=$('#'+prefix+'-waste'); if(!box) return null;
  const types=$$('#'+prefix+'-waste input[type=checkbox]:checked').map(i=>i.value).filter(v=>v && v!=='__other__');
  const ocb=$('#'+prefix+'-waste-other-cb');
  const other=(ocb && ocb.checked) ? ((($('#'+prefix+'-waste-other')||{}).value)||'').trim() : '';
  const display=[...types, other?('Others: '+other):''].filter(Boolean).join('; ');
  return {types, other, display};
}
/* vessel SEF waste-volume categories (Cat A–F m³) — driver types them from the green vessel DO */
function vesselFieldsHTML(prefix, v){
  v = v || {};
  return `<div class="grid2">
      <div><label class="f">VESSEL NAME</label><input type="text" id="${prefix}-name" value="${esc(v.name||'')}" placeholder="e.g. KOTA SETIA"></div>
      <div><label class="f">LOCATION</label><input type="text" id="${prefix}-loc" value="${esc(v.location||'')}" placeholder="e.g. B05"></div>
    </div>
    <label class="f">WASTE VOLUMES (m³) <span style="font-weight:600">(type from the SEF; leave blank if none)</span></label>
    <div class="grid3">${VESSEL_CATS.map(c=>`
      <div><label class="f" style="margin-top:2px">${esc(c.label)}</label>
        <input type="number" step="0.01" min="0" id="${prefix}-${c.k}" value="${v[c.k]!=null?v[c.k]:''}" oninput="vesselTotal('${prefix}')"></div>`).join('')}</div>
    <div class="muted" style="margin-top:4px">Total: <b id="${prefix}-total">${v.total||0}</b> m³</div>`;
}
function vesselTotal(prefix){
  let t=0; VESSEL_CATS.forEach(c=>{ t += Number(($('#'+prefix+'-'+c.k)||{}).value)||0; });
  const el=$('#'+prefix+'-total'); if(el) el.textContent = Math.round(t*100)/100;
}
function readVesselFields(prefix){
  if(!$('#'+prefix+'-name') && !$('#'+prefix+'-a')) return null;
  const v = {name:((($('#'+prefix+'-name')||{}).value)||'').trim(), location:((($('#'+prefix+'-loc')||{}).value)||'').trim()};
  let tot=0; VESSEL_CATS.forEach(c=>{ const n=Number(($('#'+prefix+'-'+c.k)||{}).value)||0; v[c.k]=n; tot+=n; });
  v.total = Math.round(tot*100)/100;
  return v;
}

/* ---------------- signature capture (finger/stylus on the driver's phone) ---------------- */
function signaturePadHTML(prefix, name, position){
  return `<div class="grid2">
      <div><label class="f">CLIENT / DUTY OFFICER NAME</label><input type="text" id="${prefix}-sig-name" value="${esc(name||'')}" placeholder="Name"></div>
      <div><label class="f">POSITION</label><input type="text" id="${prefix}-sig-pos" value="${esc(position||'')}" placeholder="e.g. Site Supervisor"></div>
    </div>
    <div class="sigwrap">
      <canvas id="${prefix}-sig-pad" class="sigpad" width="600" height="220"></canvas>
      <div class="sigwrap-hint" id="${prefix}-sig-hint">Sign here</div>
    </div>
    <div class="row" style="margin-top:6px"><button type="button" class="btn ghost slim" onclick="sigPadClear('${prefix}')">🗑️ Clear signature</button></div>`;
}
function sigPadInit(prefix){
  const cv = $('#'+prefix+'-sig-pad'); if(!cv || cv._sigInit) return;
  cv._sigInit = true;
  const ctx = cv.getContext('2d');
  ctx.lineWidth = 2.4; ctx.lineCap = 'round'; ctx.lineJoin = 'round'; ctx.strokeStyle = '#0b2540';
  let drawing = false, last = null;
  const rect = () => cv.getBoundingClientRect();
  const scale = () => ({sx: cv.width/rect().width, sy: cv.height/rect().height});
  const pos = e=>{ const r=rect(), s=scale(); const p=(e.touches?e.touches[0]:e);
    return {x:(p.clientX-r.left)*s.sx, y:(p.clientY-r.top)*s.sy}; };
  const hint = $('#'+prefix+'-sig-hint');
  const start = e=>{ e.preventDefault(); drawing=true; last=pos(e); if(hint) hint.style.display='none'; };
  const move = e=>{ if(!drawing) return; e.preventDefault(); const p=pos(e);
    ctx.beginPath(); ctx.moveTo(last.x,last.y); ctx.lineTo(p.x,p.y); ctx.stroke(); last=p; cv._hasInk=true; };
  const end = ()=>{ drawing=false; };
  cv.addEventListener('mousedown', start); cv.addEventListener('mousemove', move); window.addEventListener('mouseup', end);
  cv.addEventListener('touchstart', start, {passive:false}); cv.addEventListener('touchmove', move, {passive:false}); cv.addEventListener('touchend', end);
}
function sigPadClear(prefix){
  const cv = $('#'+prefix+'-sig-pad'); if(!cv) return;
  cv.getContext('2d').clearRect(0,0,cv.width,cv.height); cv._hasInk = false;
  const hint = $('#'+prefix+'-sig-hint'); if(hint) hint.style.display='block';
}
/* {name, position, dataUrl} or null if nothing was signed */
function readSignature(prefix){
  const cv = $('#'+prefix+'-sig-pad'); if(!cv) return null;
  const name = ((($('#'+prefix+'-sig-name')||{}).value)||'').trim();
  const position = ((($('#'+prefix+'-sig-pos')||{}).value)||'').trim();
  if(!cv._hasInk) return (name || position) ? {name, position, dataUrl:''} : null;
  return {name, position, dataUrl: cv.toDataURL('image/png')};
}
/* driver's own most-recently-used vehicle plate — remembered so they don't retype it every job */
function lastVehicleForDriver(driverId){
  const mine = S.trips.filter(t=>t.driverId===driverId && t.vehicleNo).sort((a,b)=>b.id-a.id);
  return mine.length ? mine[0].vehicleNo : '';
}
/* earliest capture time (ms) among the tripPhotos of a given kind */
function firstTs(kind){ const ts = tripPhotos.filter(p=>p.kind===kind && p.ts).map(p=>p.ts); return ts.length ? Math.min.apply(null, ts) : 0; }
function msToHM(ms){ if(!ms) return ''; const d = new Date(ms); return String(d.getHours()).padStart(2,'0')+':'+String(d.getMinutes()).padStart(2,'0'); }

/* Central database (Apps Script web app on Michelle's Google Sheet) */
const SHEET_URL_DEFAULT = 'https://script.google.com/macros/s/AKfycbzqN7RX1acurFiK4J86tVae-AjbwTk0jljqIQXZ8CByURbcUc28kRXV3mf-wv6OWOnq4A/exec';
/* superseded deployments — devices still pointing at these are auto-migrated */
const OLD_SHEET_URLS = ['AKfycbztseCf6yQaEa0bFlp3omnGfSk', 'AKfycbzqzzB4f4XmggtBgMi8XUoAq50', 'AKfycbw1a06s2CctmeUR6CtMzN5Zrm0', 'AKfycbxHk9mHMUCM_MoYAcVW1R1HP'];

/* user accounts — driver PIN = the 4 numbers in their vehicle plate (e.g. XE5876P → 5876) */
function truckPin(plate){ const m = String(plate||'').match(/\d{3,}/); return m ? m[0].slice(0,4) : '1111'; }
const USERS = [
  {id:'op', role:'operator', name:'Office / Operator', pin:'1234', color:'#0b5d3a'},
  ...DRIVERS.map(d=>({id:'d'+d.id, role:'driver', driverId:d.id, name:d.name, pin:truckPin(d.truck), color:d.color})),
];

/* ---- Driver's Trip Incentive (effective 01 May 2026) ---- */
const TRIP_TYPES = [
  {id:'send',    label:'Send Bin — Island Wide',            base:8,    note:'Empty truck return = full trip by distance'},
  {id:'col_s',   label:'Collect / Exchange — Short',        base:8},
  {id:'col_m',   label:'Collect / Exchange — Middle',       base:13},
  {id:'col_l',   label:'Collect / Exchange — Long',         base:18},
  {id:'dump',    label:'Dump & Return',                     base:23},
  {id:'nea_wk',  label:'NEA Rubbish (Yard→NEA) Mon–Sat',    perKm:1.5, note:'$1.50 × distance (km)'},
  {id:'nea_sun', label:'NEA Rubbish — Sun & PH',            base:13},
  {id:'wood',    label:'Wood Waste (Beejoo/Kimhock)',       base:18,   note:'$13 + $5'},
  {id:'recycle', label:'Sell Recycle (by distance)',        base:18},
  {id:'psa',     label:'PSA Vessel',                        base:20,   note:'+$5 Sun/PH (tick surcharge)'},
  {id:'stgul',   label:'ST Gul / ST Benoi Vessel',          base:30,   note:'+$5 Sun/PH (tick surcharge)'},
  {id:'vessel',  label:'Vessel Visit (other)',              base:19.5, note:'incl. base waiting time'},
  {id:'add',     label:'Additional / Missed Trip',          base:8},
];
const SURCHARGES = [
  {id:'after7',   label:'After 7pm (customer request)', amt:8},
  {id:'after7v',  label:'After 7pm (Vessel)',           amt:5},
  {id:'midnight', label:'After Midnight',               amt:5},
  {id:'penjuru',  label:'Penjuru Terminal / MSW',       amt:10},
  {id:'spot',     label:'On-the-spot loading',          amt:8},
  {id:'wait2',    label:'Vessel wait > 2 hrs',          amt:10},
  {id:'wait4',    label:'Vessel wait > 4 hrs',          amt:20},
  {id:'sunph',    label:'Sunday / Public Holiday',      amt:5},
];
const VESSEL_CATS = [
  {k:'a', label:'A · Plastics'},
  {k:'b', label:'B · Food waste'},
  {k:'c', label:'C · Domestic waste'},
  {k:'d', label:'D · Cooking oil'},
  {k:'e', label:'E · Incinerator ashes'},
  {k:'f', label:'F · Operational waste'},
];

/* ---------------- pricing engine ---------------- */
function tripPay(trip){
  let p;
  if(trip.price != null && trip.price !== ''){
    /* new model: the operator's chosen job type sets the price (customer charge) */
    p = Number(trip.price)||0;
  }else{
    /* legacy: trip incentive rate sheet */
    const ty = TRIP_TYPES.find(t=>t.id===trip.typeId);
    p = ty ? (ty.perKm ? ty.perKm*(Number(trip.distance)||0) : ty.base) : 0;
  }
  (trip.surcharges||[]).forEach(id=>{
    const sc = SURCHARGES.find(s=>s.id===id);
    if(sc) p += sc.amt;
  });
  return Math.round(p*100)/100;
}
/* job-request types this client is priced for (from the Customers sheet) */
function jobTypeOptions(clientId, selected){
  const c = client(clientId), prices = (c && c.prices) || {};
  const avail = JOB_TYPES.filter(jt => prices[jt] != null);
  if(!avail.length) return '<option value="">— no price set for this client —</option>';
  return avail.map(jt=>`<option value="${jt}" data-price="${prices[jt]}" ${jt===selected?'selected':''}>${jt} — ${money(prices[jt])}</option>`).join('');
}
function jobTypeLabel(j){ return j.jobType || (ttype(j.task)||{}).label || j.task || ''; }
/* full expected pay for a job = basic price + office-set surcharges */
function jobPay(j){
  let p = Number(j.price)||0;
  (j.surcharges||[]).forEach(id=>{ const sc=SURCHARGES.find(s=>s.id===id); if(sc) p+=sc.amt; });
  return Math.round(p*100)/100;
}

/* ---------------- seed ---------------- */
function seed(){
  /* bins are NOT seeded here — they're populated from the "Bin DB" Google Sheet tab
     (fetchSheetDB) and from driver trips as bin numbers are first encountered. */
  return {
    auth: null, /* nobody signed in — login screen shows first */
    role: {kind:'operator', driverId:null},
    tab: {operator:'dash', driver:'myjobs'},
    clients: [
      {id:'c1', name:'Eng Lee Logistics Pte Ltd', type:'land', salesRep:'Patrick',
       sites:[{label:'Gul Circle yard', addr:'9 Gul Circle'}, {label:'Tuas yard', addr:'15 Tuas Ave 8'}],
       contacts:[{name:'Jacky', phone:'84118884'}, {name:'Mei Ling', phone:'91234567'}]},
      {id:'c2', name:'Radha Exports Pte Ltd', type:'land', salesRep:'Marcus',
       sites:[{label:'Pioneer Rd', addr:'118 Pioneer Rd L1'}],
       contacts:[{name:'Radha', phone:''}]},
      {id:'c3', name:'Aspiration City', type:'land', salesRep:'Patrick',
       sites:[{label:'Main', addr:'Boon Lay Ave'}], contacts:[]},
      {id:'c4', name:'SLG Construction', type:'land', salesRep:'Patrick',
       sites:[{label:'Main', addr:'Tuas South Ave 10'}], contacts:[]},
      {id:'c5', name:'Tian Heng Eng', type:'land', salesRep:'Marcus',
       sites:[{label:'Main', addr:'Tractor Rd'}], contacts:[]},
      {id:'c6', name:'Pacific International Lines', type:'vessel', salesRep:'Marcus',
       sites:[{label:'PSA', addr:'PSA, BT Gate 2 Commercial Lane'}],
       contacts:[{name:'Ops Desk', phone:''}]},
    ],
    bins: [],
    jobs: [],
    trips: [],
    seq: {job:1, trip:1, do:1, ticket:1},
    settings: {sheetUrl: SHEET_URL_DEFAULT},
  };
}

/* upgrade older saved states in place (pre-login / pre-multi-site versions) */
function migrate(s){
  if(s.auth === undefined) s.auth = null;
  (s.clients||[]).forEach(c=>{
    if(!c.sites) c.sites = [{label:'Main', addr:c.addr||''}];
    if(!c.contacts) c.contacts = (c.contact||c.phone) ? [{name:c.contact||'', phone:c.phone||''}] : [];
    if(c.salesRep === undefined) c.salesRep = '';
  });
  (s.jobs||[]).forEach(j=>{
    if(j.siteIdx === undefined) j.siteIdx = 0;
    if(j.contactIdx === undefined) j.contactIdx = 0;
  });
  (s.trips||[]).forEach(t=>{ if(t.tonnAdj === undefined) t.tonnAdj = 0; if(t.weightAdj === undefined) t.weightAdj = 0;
    if(t.wasteTypes === undefined) t.wasteTypes = t.waste ? [t.waste] : []; if(t.wasteOther === undefined) t.wasteOther = '';
    if(t.vehicleNo === undefined) t.vehicleNo = ''; if(t.sigName === undefined) t.sigName = ''; if(t.sigPosition === undefined) t.sigPosition = ''; });
  (s.bins||[]).forEach(b=>{
    if(b.status==='transit' || b.status==='repair') b.status = 'unknown'; /* dropped statuses */
    if(b.siteIdx === undefined) b.siteIdx = 0;
    if(b.source === undefined) b.source = 'seed';
    if(b.firstSeen === undefined) b.firstSeen = '';
  });
  if(s.seq && !s.seq.vdo) s.seq.vdo = 17921; /* vessel "V" number sequence */
  if(!s.settings) s.settings = {sheetUrl: SHEET_URL_DEFAULT};
  else if(!s.settings.sheetUrl || OLD_SHEET_URLS.some(o=>s.settings.sheetUrl.includes(o)))
    s.settings.sheetUrl = SHEET_URL_DEFAULT;
  return s;
}

/* ---------------- state ---------------- */
let S = DB.load();
if(!S){ S = seed(); DB.save(S); }
function persist(){ DB.save(S); }

/* ---------------- helpers ---------------- */
const $  = s => document.querySelector(s);
const $$ = s => Array.from(document.querySelectorAll(s));
function esc(s){ return String(s??'').replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function money(n){ return '$' + (Number(n)||0).toFixed(2); }
function client(id){ return S.clients.find(c=>c.id===id); }
function driver(id){ return DRIVERS.find(d=>d.id===Number(id)); }
function ttype(id){ return TRIP_TYPES.find(t=>t.id===id); }
function binByNo(no){ return S.bins.find(b=>b.no===no); }
function cSite(c, i){ return (c && c.sites && (c.sites[i] || c.sites[0])) || {label:'', addr:''}; }
function cContact(c, i){ return (c && c.contacts && (c.contacts[i] || c.contacts[0])) || null; }
function tonnTotal(t){ return Math.round(((Number(t.tonnage)||0) + (Number(t.tonnAdj)||0))*100)/100; }
function weightNet(t){ const w=t.weight||{}; return Math.round((((Number(w.gross)||0)-(Number(w.tare)||0)) + (Number(t.weightAdj)||0))*100)/100; }
function curUser(){ return USERS.find(u=>u.id === (S.auth && S.auth.userId)); }
function fmtDate(s){
  if(!s) return '';
  const [y,m,d] = s.split('-').map(Number);
  return new Date(y,m-1,d).toLocaleDateString('en-SG',{day:'numeric', month:'short', year:'numeric'});
}
function initials(name){ return name.split(' ').map(w=>w[0]).join('').slice(0,2).toUpperCase(); }
function avatarHTML(d, cls){
  return `<span class="avatar ${cls||''}" style="background:${d.color}">${initials(d.name)}</span>`;
}
const STATUS_LABEL = {assigned:'Assigned', in_progress:'In progress', done:'Done'};
/* 'unknown' = location not yet confirmed by any driver trip (grey/unverified in the Bin page).
   Becomes 'yard' or 'client' the moment a trip's Bin IN/OUT touches that bin no. */
const BIN_STATUS = [
  {id:'unknown', label:'Unverified', cls:'b-unknown'},
  {id:'yard',    label:'Yard',       cls:'b-yard'},
  {id:'client',  label:'At client',  cls:'b-client'},
];
function binVerified(b){ return b.status !== 'unknown'; }

/* trips + jobs helpers */
function tripsOn(date){ return S.trips.filter(t=>t.date===date); }
function driverTrips(id, date){ return S.trips.filter(t=>t.driverId===id && (!date || t.date===date)); }
function driverJobs(id, date){ return S.jobs.filter(j=>j.driverId===id && (!date || j.date===date)); }
function payOf(trips){ return trips.reduce((a,t)=>a+tripPay(t),0); }

/* ---------------- ui primitives ---------------- */
function toast(msg){
  const el = document.createElement('div');
  el.className = 'toast'; el.textContent = msg;
  $('#toasts').appendChild(el);
  setTimeout(()=>el.remove(), 4200);
}
function openSheet(html){ $('#sheet').innerHTML = html; $('#overlay').classList.add('open'); }
function closeSheet(){ $('#overlay').classList.remove('open'); }
$('#overlay') && document.addEventListener('click', e=>{
  if(e.target === $('#overlay')) closeSheet();
});
function sheetTitle(t){ return `<h3>${t}<button class="x" onclick="closeSheet()">✕</button></h3>`; }
function segPick(el, wrap){
  $$(wrap+' > button').forEach(b=>b.classList.remove('on'));
  el.classList.add('on');
}

/* ---------------- role & nav ---------------- */
const NAVS = {
  operator: [
    {id:'dash',  ico:'📊', label:'Dashboard'},
    {id:'jobs',  ico:'🗂️', label:'Jobs'},
    {id:'bins',  ico:'🗑️', label:'Bins'},
    {id:'earn',  ico:'💵', label:'Earnings'},
    {id:'crm',   ico:'🏢', label:'CRM'},
  ],
  driver: [
    {id:'myjobs', ico:'🗂️', label:'My Jobs'},
    {id:'card',   ico:'📋', label:'Job Card'},
    {id:'pay',    ico:'💵', label:'My Pay'},
  ],
};
function curTab(){ return S.tab[S.role.kind]; }
function setTab(t){ S.tab[S.role.kind] = t; persist(); render(); }
function openRoleSheet(){
  const u = curUser();
  const isOp = u && u.role==='operator';
  openSheet(sheetTitle('Account') + `
    <div class="item">
      <span class="avatar lg" style="background:${u?u.color:'var(--brand-dark)'}">${isOp ? 'OP' : initials(u?u.name:'?')}</span>
      <div class="grow"><div class="title">${esc(u?u.name:'')}</div>
      <div class="sub">Signed in as ${isOp ? 'Operator / Office' : 'Driver'}</div></div>
    </div>
    ${isOp ? `
    <label class="f">👁️ VIEW A DRIVER'S APP <span style="font-weight:600">(see exactly what they see)</span></label>
    ${DRIVERS.map(d=>`
      <div class="item tap" onclick="viewAsDriver(${d.id})">
        ${avatarHTML(d)}
        <div class="grow"><div class="title">${esc(d.name)}</div><div class="sub">Driver ${d.id}</div></div>
        <span class="icon-btn">›</span>
      </div>`).join('')}` : ''}
    <p class="muted" style="margin:10px 0 8px">To use a different account, log out and sign in with that account's PIN.</p>
    <div style="margin:6px 0"><button class="btn" onclick="logout()">🔒 Log out / switch user</button></div>
    ${isOp ? `<div style="margin-top:8px"><button class="btn danger" onclick="resetDemo()">↺ Reset demo data</button></div>` : ''}
    <p class="muted" style="margin-top:14px; text-align:center; font-size:11px">App build ${APP_VERSION}</p>`);
}
/* operator preview: view a driver's app without logging out (stays authed as operator) */
function viewAsDriver(id){
  S.viewAs = id;
  S.role = {kind:'driver', driverId:id};
  S.tab.driver = 'myjobs';
  persist(); closeSheet(); render();
  toast('👁️ Viewing '+driver(id).name+"'s app");
}
function exitViewAs(){
  delete S.viewAs;
  S.role = {kind:'operator', driverId:null};
  persist(); render();
}

/* ---------------- login ---------------- */
let loginSel = null;
function renderLogin(){
  $('#header').innerHTML = `<div><div class="htitle">♻️ Lirich Ops</div><div class="hsub">Lirich Resources Pte Ltd · 23 Gul Drive</div></div>`;
  $('#nav').innerHTML = '';
  $('#fab').style.display = 'none';
  /* a personal link (?u=d3) locks this device to one driver's account */
  const lock = S.settings.lockUser ? USERS.find(x=>x.id===S.settings.lockUser && x.role==='driver') : null;
  if(lock && !loginSel) loginSel = lock.id;
  const list = lock ? [lock] : USERS;
  const u = USERS.find(x=>x.id===loginSel);
  const skipPin = !!(lock && u && u.id===lock.id); /* personal link = the driver's identity proof, no PIN needed */
  $('#main').innerHTML = `
    <div class="card" style="text-align:center; padding:24px 18px">
      <div style="font-size:42px">♻️</div>
      <h2 style="justify-content:center; font-size:19px">Sign in to Lirich Ops</h2>
      <p class="muted" style="margin:4px 0 0">${lock ? 'This device is set up for '+esc(lock.name)+'.' : 'Pick your account, then enter your PIN.'}</p>
    </div>
    <div class="card">
      ${list.map(x=>`
        <div class="item tap" onclick="loginSel='${x.id}'; renderLogin()">
          <span class="avatar lg" style="background:${x.color}">${x.role==='operator'?'OP':initials(x.name)}</span>
          <div class="grow"><div class="title">${esc(x.name)}</div>
          <div class="sub">${x.role==='operator' ? 'Operator / Office' : 'Driver'}</div></div>
          ${loginSel===x.id ? '<span class="tag">SELECTED</span>' : ''}
        </div>`).join('')}
    </div>
    ${u && skipPin ? `
    <div class="card">
      <div style="margin-top:2px"><button class="btn" onclick="doLogin()">🔓 Sign in as ${esc(u.name)}</button></div>
    </div>` : ''}
    ${u && !skipPin ? `
    <div class="card">
      <label class="f">PIN — ${esc(u.name).toUpperCase()}</label>
      <input type="password" inputmode="numeric" id="login-pin" placeholder="••••" maxlength="6"
        onkeydown="if(event.key==='Enter') doLogin()">
      <div style="margin-top:12px"><button class="btn" onclick="doLogin()">🔓 Sign in</button></div>
    </div>` : ''}
    ${lock
      ? `<div class="card muted" style="text-align:center">This device is linked to ${esc(lock.name)} — no PIN needed.<br><a href="#" onclick="unlockDevice(); return false">Unlock this device</a> (operator PIN needed)</div>`
      : `<div class="card muted" style="text-align:center">Operator PIN <b>1234</b> · each driver's PIN = the 4 numbers in their vehicle plate</div>`}`;
  if(u && !skipPin){ const el = $('#login-pin'); if(el) el.focus(); }
}
function unlockDevice(){
  const pin = prompt('Operator PIN to unlock this device:');
  if(pin !== USERS[0].pin){ toast('❌ Wrong operator PIN'); return; }
  delete S.settings.lockUser;
  loginSel = null;
  persist(); renderLogin(); toast('Device unlocked — all accounts shown');
}
function doLogin(){
  const u = USERS.find(x=>x.id===loginSel);
  if(!u) return;
  const skipPin = S.settings.lockUser === u.id && u.role==='driver'; /* personal link already proves identity */
  if(!skipPin && ((($('#login-pin')||{}).value)||'').trim() !== u.pin){ toast('❌ Wrong PIN — try again'); return; }
  S.auth = {userId:u.id};
  S.role = u.role==='operator' ? {kind:'operator', driverId:null} : {kind:'driver', driverId:u.driverId};
  loginSel = null;
  persist(); render();
  toast('Welcome, ' + u.name + ' 👋');
}
function logout(){
  S.auth = null; loginSel = null;
  persist(); closeSheet(); render();
}
async function resetDemo(){
  const u = curUser();
  if(!u || u.role!=='operator'){ toast('⚠️ Only the operator can reset the database'); return; } /* button is hidden too — this is the real guard */
  if(!confirm('Reset ALL data in the central database back to the seed? Every device will see this.')) return;
  const keepUrl = S.settings.sheetUrl;
  S = seed(); S.settings.sheetUrl = keepUrl; persist();
  PhotoDB.clear().catch(()=>{});
  closeSheet();
  try{ await api('resetState', {state: sharedOf(S)}); }catch(e){}
  render(); toast('Database reset to seed ↺');
  await fetchSheetDB(); /* pull the Bin DB list in immediately, don't wait for a reload */
  render();
}

/* ---------------- render root ---------------- */
function render(){
  /* drivers get a bigger UI — sunlight, gloves, one-handed use */
  document.body.classList.toggle('big-ui', !!(S.auth && S.role && S.role.kind==='driver'));
  if(!S.auth){ renderLogin(); return; }
  /* if the saved tab no longer exists for this role (e.g. driver Bins page removed), fall back */
  if(!NAVS[S.role.kind].some(n=>n.id===curTab())) S.tab[S.role.kind] = NAVS[S.role.kind][0].id;
  renderHeader(); renderNav(); renderFab();
  const t = curTab();
  if(S.role.kind === 'operator'){
    if(t==='dash') vDash();
    else if(t==='jobs') vJobs();
    else if(t==='bins') vBins();
    else if(t==='earn') vEarnings();
    else vCRM();
  }else{
    if(t==='myjobs') vMyJobs();
    else if(t==='card') vJobCard();
    else vMyPay();
  }
  /* operator preview banner — always on top while viewing a driver's app */
  if(S.viewAs && S.auth && S.auth.userId==='op'){
    const dn = driver(S.viewAs);
    $('#main').insertAdjacentHTML('afterbegin',
      `<div class="card" style="background:#fdf3dd; border:1px solid var(--amber); display:flex; align-items:center; gap:10px; margin-bottom:12px">
        <div class="grow"><b>👁️ Office preview</b> — you're seeing <b>${esc(dn?dn.name:'')}</b>'s app.</div>
        <button class="btn slim" onclick="exitViewAs()">◀ Back to Operator</button>
      </div>`);
  }
}
function renderHeader(){
  let sub, pill;
  if(S.role.kind==='operator'){
    sub = 'Lirich Resources Pte Ltd · 23 Gul Drive';
    pill = `<span class="avatar" style="background:var(--brand-dark)">OP</span> Operator ▾`;
  }else{
    const d = driver(S.role.driverId);
    sub = `Driver ${d.id} · ${fmtDate(TODAY)}`;
    pill = `${avatarHTML(d)} ${esc(d.name)} ▾`;
  }
  $('#header').innerHTML = `
    <div><div class="htitle">♻️ Lirich Ops</div><div class="hsub">${sub}</div></div>
    <button class="role-pill" onclick="openRoleSheet()">${pill}</button>`;
}
function renderNav(){
  $('#nav').innerHTML = NAVS[S.role.kind].map(n=>`
    <button class="${curTab()===n.id?'active':''}" onclick="setTab('${n.id}')">
      <span class="ico">${n.ico}</span>${n.label}</button>`).join('');
}
function renderFab(){
  const fab = $('#fab');
  const t = curTab();
  if(S.role.kind==='operator' && (t==='jobs' || t==='dash')){ fab.style.display='block'; fab.textContent='＋ Assign job'; fab.onclick=()=>openJobForm(); }
  else if(S.role.kind==='operator' && t==='crm'){ fab.style.display='block'; fab.textContent='＋ Add'; fab.onclick=()=>openClientForm(); }
  else if(S.role.kind==='driver' && (t==='card'||t==='myjobs')){ fab.style.display='block'; fab.textContent='＋ Log a trip / DO'; fab.onclick=()=>openTripForm({}); }
  else fab.style.display='none';
}

/* ============================================================
   OPERATOR · DASHBOARD
   ============================================================ */
function vDash(){
  const jobsToday  = S.jobs.filter(j=>j.date===TODAY);
  const openJobs   = jobsToday.filter(j=>j.status!=='done');
  const trToday    = tripsOn(TODAY);
  const payToday   = payOf(trToday);
  const binsOut    = S.bins.filter(b=>b.status==='client').length;
  const counts = {};
  BIN_STATUS.forEach(s=>counts[s.id] = S.bins.filter(b=>b.status===s.id).length);
  const colors = {unknown:'#9aa0a6', yard:'var(--brand)', client:'var(--amber)'};

  $('#main').innerHTML = `
    <div class="kpis">
      <div class="kpi amber"><div class="num">${openJobs.length}</div><div class="lbl">OPEN JOBS TODAY</div></div>
      <div class="kpi blue"><div class="num">${trToday.length}</div><div class="lbl">TRIPS LOGGED</div></div>
      <div class="kpi green"><div class="num">${money(payToday)}</div><div class="lbl">DRIVER PAY TODAY</div></div>
      <div class="kpi red"><div class="num">${binsOut}</div><div class="lbl">BINS AT CLIENTS</div></div>
    </div>

    <div style="margin-bottom:12px"><button class="btn" onclick="openJobForm()">➕ Assign a new job</button></div>

    <div class="card">
      <h2>🚛 Fleet today</h2>
      ${DRIVERS.map(d=>{
        const jobs = driverJobs(d.id, TODAY);
        const done = jobs.filter(j=>j.status==='done').length;
        const onJob = jobs.some(j=>j.status==='in_progress');
        const tr = driverTrips(d.id, TODAY);
        return `<div class="item">
          ${avatarHTML(d)}
          <div class="grow">
            <div class="title">${esc(d.name)}
              ${onJob?'<span class="chip st-in_progress">ON A JOB</span>':''}</div>
            <div class="sub">Jobs ${done}/${jobs.length} done · ${tr.length} trip${tr.length===1?'':'s'} logged</div>
          </div>
          <div class="pay">${money(payOf(tr))}</div>
        </div>`;
      }).join('')}
    </div>

    <div class="card">
      <h2>🗑️ Bin inventory <span class="muted" style="font-weight:600">(${S.bins.length} bins)</span></h2>
      <div class="stackbar">${BIN_STATUS.map(s=>
        `<span style="width:${counts[s.id]/(S.bins.length||1)*100}%; background:${colors[s.id]}"></span>`).join('')}</div>
      <div class="legend">${BIN_STATUS.map(s=>
        `<span><span class="dot" style="background:${colors[s.id]}"></span>${s.label} ${counts[s.id]}</span>`).join('')}</div>
    </div>

    <div class="card">
      <h2>🗂️ Recent jobs</h2>
      ${S.jobs.slice(-5).reverse().map(jobRow).join('') || '<div class="empty">No jobs yet.</div>'}
    </div>`;
}

/* ============================================================
   JOBS (operator: all + filters · driver: mine)
   ============================================================ */
let jobFilter = 'all';
function jobRow(j){
  const c = client(j.clientId), d = driver(j.driverId), ty = ttype(j.task);
  return `<div class="item tap" onclick="openJobDetail(${j.id})">
    <div class="grow">
      <div class="title">${esc(c?c.name:'?')} <span class="chip st-${j.status}">${STATUS_LABEL[j.status]}</span></div>
      <div class="sub">${esc(c?cSite(c,j.siteIdx).addr:'')}</div>
      <div class="sub">${esc(ty?ty.label:j.task)} · ${esc(j.binSize)} ${esc(j.waste)} · ${d?esc(d.name):'—'}</div>
    </div>
    <div class="pay">${ty && !ty.perKm ? money(ty.base) : 'by km'}</div>
  </div>`;
}
function vJobs(){
  const F = [['all','All'],['assigned','Assigned'],['in_progress','In progress'],['done','Done']];
  const list = S.jobs.filter(j=>jobFilter==='all'||j.status===jobFilter).slice().reverse();
  $('#main').innerHTML = `
    <div class="ftabs">${F.map(([id,l])=>{
      const n = id==='all' ? S.jobs.length : S.jobs.filter(j=>j.status===id).length;
      return `<button class="${jobFilter===id?'on':''}" onclick="jobFilter='${id}'; render()">${l} (${n})</button>`;
    }).join('')}</div>
    <div style="margin-bottom:10px"><button class="btn" onclick="openJobForm()">➕ Assign a new job</button></div>
    <div class="card">${list.map(jobRow).join('') || '<div class="empty">No jobs in this filter.</div>'}</div>`;
}
/* big, one-tap driver card — action button lives right on the card */
function driverJobCard(j){
  const c = client(j.clientId);
  const site = cSite(c, j.siteIdx);
  const person = cContact(c, j.contactIdx);
  const started = j.status==='in_progress';
  return `<div class="djob">
    <div class="djob-h">${esc(c?c.name:'?')}
      <span class="djob-badge ${started?'run':'go'}">${started?'IN PROGRESS':'NEW'}</span></div>
    <div class="djob-sub">📍 ${esc(site.addr||site.label)}</div>
    <div class="djob-sub"><b>🛠️ ${esc(jobTypeLabel(j))}${j.price?` · 💵 ${money(jobPay(j))}`:''}</b></div>
    <div class="djob-sub muted">🗑️ ${esc(j.binSize)} · ${esc(j.waste)}</div>
    ${j.dumpTo?`<div class="djob-sub muted">♻️ Dispose to: <b>${esc(j.dumpTo)}</b></div>`:''}
    ${j.instructions?`<div class="djob-sub muted">📝 ${esc(j.instructions)}</div>`:''}
    ${person && person.phone?`<a href="https://wa.me/65${esc(person.phone)}" target="_blank" style="text-decoration:none"><button class="btn wa" style="margin-top:10px">💬 Call ${esc(person.name||'customer')}</button></a>`:''}
    ${started
      ? `<button class="btn djob-act" onclick="openTripForm({jobId:${j.id}})">📸 Continue job</button>`
      : `<button class="btn djob-act" onclick="acceptJob(${j.id})">▶️ Accept job</button>`}
  </div>`;
}
function vMyJobs(){
  const mine = driverJobs(S.role.driverId).slice().reverse();
  const open = mine.filter(j=>j.status!=='done');
  const done = mine.filter(j=>j.status==='done');
  $('#main').innerHTML = `
    <h2 style="margin:8px 2px 12px; font-size:17px">🗂️ My jobs — ${fmtDate(TODAY)}</h2>
    ${open.map(driverJobCard).join('') || '<div class="card empty">No jobs right now. 👍</div>'}
    ${done.length?`<div class="card"><h2>✅ Done today (${done.length})</h2>${done.map(j=>{
      const c=client(j.clientId);
      const t = S.trips.find(x=>x.jobId===j.id);
      const hasWeight = t && t.weight && t.weight.gross;
      return `<div class="item"><div class="grow"><div class="title">${esc(c?c.name:'?')}</div>
        <div class="sub">${hasWeight ? '✅ finished · ⚖️ '+t.weight.net+' kg' : '✅ finished'}</div></div>
        ${t && !hasWeight ? `<button class="btn slim" onclick="openWeighForm(${t.id})">⚖️ Add weight</button>` : ''}</div>`;
    }).join('')}</div>`:''}`;
}
/* phase 2 of a trip: DO+bin photos were taken at the client site; the weighbridge
   is back at the office (30-60 min drive) — the driver adds the scale photos here */
function openWeighForm(tripId){
  const t = S.trips.find(x=>x.id===tripId); if(!t) return;
  tripPhotos = [];
  const c = client(t.clientId);
  openSheet(sheetTitle(`⚖️ Weighbridge — ${doLabel(t)}`) + `
    <div class="muted" style="margin-bottom:6px">${esc(c?c.name:'')} — snap the scale display, the app reads the number.</div>
    <label class="f">📷 WEIGHT — GROSS (kg)</label>
    <input type="file" accept="image/*" capture="environment" multiple id="tf-photo-gross" onchange="onPhotoAdd(this,'gross')">
    <div class="thumbs" id="tf-thumbs-gross"></div>
    <label class="f">📷 WEIGHT — TARE (kg)</label>
    <input type="file" accept="image/*" capture="environment" multiple id="tf-photo-tare" onchange="onPhotoAdd(this,'tare')">
    <div class="thumbs" id="tf-thumbs-tare"></div>
    <div class="muted" id="tf-ocr" style="margin-top:6px"></div>
    <div class="grid3">
      <div><label class="f">GROSS (kg)</label><input type="number" id="tf-gross" min="0" placeholder="from photo" oninput="tfNet()"></div>
      <div><label class="f">TARE (kg)</label><input type="number" id="tf-tare" min="0" placeholder="from photo" oninput="tfNet()"></div>
      <div><label class="f">NET (kg)</label><input type="number" id="tf-net" readonly></div>
    </div>
    <div style="margin-top:14px"><button class="btn" onclick="saveWeigh(${t.id})">✅ Save weighbridge</button></div>`);
}
async function saveWeigh(id){
  const t = S.trips.find(x=>x.id===id); if(!t) return;
  const gross = Number($('#tf-gross').value)||0, tare = Number($('#tf-tare').value)||0;
  if(!gross || !tare){ toast('⚠️ Need both gross and tare — snap the scale or type them'); return; }
  closeSheet(); toast('Saving weighbridge…');
  /* upload the scale photos to Drive, then attach weight + photos to the existing trip */
  const jobtag = t.jobId ? t.jobId : ('T'+t.id);
  const newPhotos = []; const cnt = {gross:0, tare:0};
  for(const p of tripPhotos){
    if(p.kind!=='gross' && p.kind!=='tare') continue;
    cnt[p.kind]++;
    try{
      const rec = await api('addPhoto', {b64:p.full.split(',')[1], name:(p.kind==='gross'?'GROSS':'TARE')+'-'+jobtag+'-'+cnt[p.kind]+'.jpg'});
      if(rec && rec.id){
        rec.kind = p.kind; newPhotos.push(rec);
        PhotoDB.put({id:rec.id, full:p.full, thumb:p.thumb, clientId:t.clientId, driverId:t.driverId, date:t.date, createdAt:Date.now()}).catch(()=>{});
      }
    }catch(e){}
  }
  const patch = {
    weight: {gross, tare, net: gross-tare, ticket:(t.weight && t.weight.ticket)||''},
    photos: (t.photos||[]).concat(newPhotos),
  };
  /* Time Weigh = first weight photo's capture time — photo-stamped and locked like every other time */
  const wts = tripPhotos.filter(p=>(p.kind==='gross'||p.kind==='tare') && p.ts).map(p=>p.ts);
  if(wts.length && !t.tWeight) patch.tWeight = Math.min.apply(null, wts);
  await api('updateTrip', {id, patch});
  tripPhotos = [];
  render(); toast('⚖️ Weighbridge saved — office updated ✅');
}

function openJobDetail(id){
  const j = S.jobs.find(x=>x.id===id); if(!j) return;
  const c = client(j.clientId), d = driver(j.driverId), ty = ttype(j.task);
  const isDriver = S.role.kind==='driver';
  const mine = isDriver && j.driverId===S.role.driverId;
  const site = cSite(c, j.siteIdx);
  const person = cContact(c, j.contactIdx);
  openSheet(sheetTitle(`Job #${j.id} <span class="chip st-${j.status}">${STATUS_LABEL[j.status]}</span>`) + `
    <div class="card" style="box-shadow:none; background:var(--bg); margin:8px 0">
      <div class="title" style="font-weight:800; font-size:15px">${esc(c.name)} <span class="tag ${c.type}">${c.type.toUpperCase()}</span></div>
      <div class="muted" style="margin-top:4px">📍 ${esc(site.label)}${site.label?' — ':''}${esc(site.addr)}</div>
      ${person?`<div class="muted">👤 ${esc(person.name)} ${person.phone?'· '+esc(person.phone):''}</div>`:''}
      <div class="muted" style="margin-top:6px">🛠️ ${esc(ty?ty.label:j.task)} · ${esc(j.binSize)} · ${esc(j.waste)}</div>
      ${j.dumpTo?`<div class="muted">♻️ Dump to: ${esc(j.dumpTo)}</div>`:''}
      ${j.instructions?`<div class="muted" style="margin-top:6px">📝 ${esc(j.instructions)}</div>`:''}
      <div class="muted" style="margin-top:6px">🚛 ${d?esc(d.name):'Unassigned'} · ${fmtDate(j.date)}${j.startedAt?` · ▶️ started ${fmtTime12(j.startedAt)}`:''}</div>
      <div class="muted" style="margin-top:6px">💵 Base pay: <b>${ty && !ty.perKm ? money(ty.base) : '$1.50 × km'}</b></div>
    </div>
    ${person && person.phone?`<a href="https://wa.me/65${esc(person.phone)}" target="_blank" style="text-decoration:none"><button class="btn wa" style="margin-bottom:8px">💬 WhatsApp ${esc(person.name||c.name)}</button></a>`:''}
    ${mine && j.status==='assigned' ? `<button class="btn" onclick="acceptJob(${j.id})">▶️ Accept job</button>` : ''}
    ${mine && j.status==='in_progress' ? `<button class="btn" onclick="closeSheet(); openTripForm({jobId:${j.id}})">📋 Log trip / DO for this job</button>` : ''}
    ${S.role.kind==='operator' ? `
      <label class="f">REASSIGN DRIVER</label>
      <div class="row">
        <select id="jd-driver" class="grow">${DRIVERS.map(x=>`<option value="${x.id}" ${x.id===j.driverId?'selected':''}>${esc(x.name)}</option>`).join('')}</select>
        <button class="btn slim" onclick="reassignJob(${j.id})">Save</button>
      </div>
      <div style="margin-top:10px"><button class="btn danger" onclick="deleteJob(${j.id})">🗑️ Delete job</button></div>` : ''}`);
}
async function acceptJob(id){
  const now = Date.now();
  const startedAt = new Date(now).toTimeString().slice(0,5); /* moment the driver pressed Accept */
  closeSheet();
  await api('updateJob', {id, patch:{status:'in_progress', startedAt, acceptedAtMs:now}});
  render();
  toast(`Job accepted at ${fmtTime12(startedAt)} — safe driving! 🚛`);
  openTripForm({jobId:id}); /* straight into the job — no second tap needed */
}
function fmtTime12(t){
  if(!t) return '';
  let [h,m] = t.split(':').map(Number);
  const ap = h>=12 ? 'PM' : 'AM'; h = h%12 || 12;
  return h + ':' + String(m).padStart(2,'0') + ' ' + ap;
}
async function reassignJob(id){
  const driverId = Number($('#jd-driver').value);
  closeSheet();
  await api('updateJob', {id, patch:{driverId, _driver: driver(driverId).name}});
  render(); toast('Job reassigned to '+driver(driverId).name);
}
async function deleteJob(id){
  if(!confirm('Delete this job?')) return;
  closeSheet();
  await api('deleteJob', {id});
  render(); toast('Job deleted');
}

function openJobForm(presetClientId){
  openSheet(sheetTitle('Assign a job') + `
    <p class="muted">This replaces the WhatsApp message to the driver. Client, yard and contact pull from the CRM database.</p>
    <label class="f">CLIENT</label>
    <select id="jf-client" onchange="jfClientChanged()">${S.clients.map(c=>`<option value="${c.id}" ${c.id===presetClientId?'selected':''}>${esc(c.name)}${c.salesRep?' · '+c.salesRep:''}</option>`).join('')}</select>
    <label class="f">YARD / ADDRESS</label>
    <select id="jf-site" onchange="autoDistance()"></select>
    <label class="f">CONTACT PERSON</label>
    <select id="jf-contact"></select>
    <label class="f">JOB TYPE &amp; PRICE <span style="font-weight:600">(the driver sees this price)</span></label>
    <select id="jf-jobtype">${jobTypeOptions(presetClientId||S.clients[0].id)}</select>
    <label class="f">DRIVER · VEHICLE</label>
    <select id="jf-driver">${driverSelectOptions()}</select>
    <div class="grid2">
      <div><label class="f">BIN TYPE</label>
        <select id="jf-size">${binOptions().map(s=>`<option>${esc(s)}</option>`).join('')}</select></div>
      <div><label class="f">WASTE TYPE</label>
        <select id="jf-waste">${selOpts(wasteOptions(), wasteOptions()[0])}</select></div>
    </div>
    <label class="f">DUMPING LOCATION <span style="font-weight:600">(shows as "Dispose to" on the driver's job)</span></label>
    <select id="jf-dump" onchange="autoDistance()"><option value="">— select —</option>${selOpts(dumpOptions())}</select>
    <label class="f">DISTANCE — YARD ➜ DUMPING (KM) <span style="font-weight:600">(auto-estimated, adjust if needed)</span></label>
    <input type="number" id="jf-dist" step="0.1" min="0" placeholder="auto">
    <label class="f">SURCHARGES / EXTRA FEES (TICK IF ANY) <span style="font-weight:600">(added to driver pay; editable after the job is done)</span></label>
    <div id="jf-sur">${SURCHARGES.map(s=>`
      <label class="checkline"><input type="checkbox" value="${s.id}"> ${esc(s.label)}
        <span class="amt">+${money(s.amt)}</span></label>`).join('')}</div>
    <div class="muted" id="jf-sync" style="margin-top:4px">Options come from the "Customer DB" tab of the Google Sheet.</div>
    <label class="f">INSTRUCTIONS FOR DRIVER</label>
    <textarea id="jf-notes" rows="2" placeholder="Gate code, contact on site, timing…"></textarea>
    <div style="margin-top:16px"><button class="btn" onclick="saveJob()">Assign job</button></div>`);
  jfClientChanged();
  refreshJobFormOptions();
}
/* live-refresh the pulldowns from the Google Sheet while the form is open */
function refreshJobFormOptions(){
  fetchSheetDB().then(ok=>{
    const note = $('#jf-sync');
    if(!ok){ if(note) note.textContent = '⚠️ Could not reach the Google Sheet — using last-known options.'; return; }
    const keep = (sel, rebuild)=>{
      const el = $(sel); if(!el) return;
      const v = el.value; el.innerHTML = rebuild;
      if([...el.options].some(o=>o.value===v || o.text===v)) el.value = v;
    };
    keep('#jf-driver', driverSelectOptions());
    keep('#jf-size', binOptions().map(s=>`<option>${esc(s)}</option>`).join(''));
    keep('#jf-waste', selOpts(wasteOptions()));
    keep('#jf-dump', '<option value="">— select at trip time —</option>'+selOpts(dumpOptions()));
    const csel = $('#jf-client');
    if(csel){
      const v = csel.value;
      csel.innerHTML = S.clients.map(c=>`<option value="${c.id}">${esc(c.name)}${c.salesRep?' · '+c.salesRep:''}</option>`).join('');
      if([...csel.options].some(o=>o.value===v)) csel.value = v;
      jfClientChanged();
    }
    if(note) note.textContent = '✅ Options synced live from the Google Sheet ("Customer DB" tab).';
  });
}
function jfClientChanged(){
  const c = client($('#jf-client').value);
  $('#jf-site').innerHTML = (c.sites||[]).map((s,i)=>
    `<option value="${i}">${esc(s.label)}${s.label?' — ':''}${esc(s.addr)}</option>`).join('')
    || '<option value="0">— no address on file —</option>';
  $('#jf-contact').innerHTML = (c.contacts||[]).map((p,i)=>
    `<option value="${i}">${esc(p.name)}${p.phone?' · '+esc(p.phone):''}</option>`).join('')
    || '<option value="0">— no contact on file —</option>';
  if($('#jf-jobtype')) $('#jf-jobtype').innerHTML = jobTypeOptions(c.id); /* prices are per-client */
  autoDistance();
}
async function saveJob(){
  const driverId = Number($('#jf-driver').value);
  const c = client($('#jf-client').value);
  const jtSel = $('#jf-jobtype').selectedOptions[0];
  const jobType = $('#jf-jobtype').value;
  const price = jtSel ? (Number(jtSel.dataset.price)||0) : 0;
  const j = {
    clientId: $('#jf-client').value,
    siteIdx: Number($('#jf-site').value)||0, contactIdx: Number($('#jf-contact').value)||0,
    jobType, price,
    surcharges: $$('#jf-sur input:checked').map(i=>i.value),
    binSize: $('#jf-size').value, waste: $('#jf-waste').value || 'General',
    dumpTo: $('#jf-dump').value,
    distance: Number($('#jf-dist').value) || 0,
    instructions: $('#jf-notes').value.trim(),
    driverId,
    status:'assigned', date: TODAY, createdAt: TODAY+'T'+new Date().toTimeString().slice(0,5),
  };
  /* denormalised display fields for the Google Sheet "Jobs" tab */
  j._client = c ? c.name : ''; j._addr = cSite(c, j.siteIdx).addr;
  j._contact = (cContact(c, j.contactIdx)||{}).name || '';
  j._driver = driver(driverId).name; j._task = jobType;
  closeSheet(); toast('Saving job to database…');
  await api('addJob', {job:j});
  render();
  toast(`Job assigned to ${driver(driverId).name} ✅ — it's on their phone now`);
}

/* ============================================================
   DRIVER · JOB CARD
   ============================================================ */
function vJobCard(){
  const d = driver(S.role.driverId);
  const trips = driverTrips(d.id, TODAY);
  $('#main').innerHTML = `
    <div class="card">
      <h2>📋 Daily Job Card — ${esc(d.name)} · ${fmtDate(TODAY)}</h2>
      <table class="jt">
        <thead><tr><th>#</th><th>CUSTOMER / BIN</th><th>TIME</th><th class="right" style="text-align:right">CHARGE</th></tr></thead>
        <tbody>
        ${trips.map((t,i)=>{
          const c = client(t.clientId), ty = ttype(t.typeId);
          return `<tr onclick="openTripDetail(${t.id})" style="cursor:pointer">
            <td>${i+1}</td>
            <td><b>${esc(c?c.name:'?')}</b><br><span class="muted">${esc(ty?ty.label:'')}${t.binOut?' · out '+esc(t.binOut):''}${t.binIn?' · in '+esc(t.binIn):''} · ${doLabel(t)}</span></td>
            <td>${esc(t.timeStart||'—')}<br>${esc(t.timeEnd||'')}</td>
            <td style="text-align:right"><b>${money(tripPay(t))}</b></td>
          </tr>`;
        }).join('') || '<tr><td colspan="4"><div class="empty">No trips logged today. Tap “＋ Log a trip / DO”.</div></td></tr>'}
        </tbody>
        ${trips.length?`<tfoot><tr><td colspan="3">Total trip charge</td><td style="text-align:right; color:var(--brand)">${money(payOf(trips))}</td></tr></tfoot>`:''}
      </table>
    </div>`;
}

/* ============================================================
   TRIP / DO FORM (core screen)
   ============================================================ */
let tripPhotos = [];
let existingTripPhotos = []; /* already-uploaded photos when resuming a saved-for-later trip (Drive-hosted, read-only) */
function openTripForm(opts){
  tripPhotos = [];
  existingTripPhotos = [];
  const job = opts.jobId ? S.jobs.find(j=>j.id===opts.jobId) : null;
  /* a job still open with a trip already against it = the driver tapped "Save" earlier — resume it */
  const draft = (S.role.kind==='driver' && job) ? S.trips.find(t=>t.jobId===job.id) : null;
  const presetClient = job ? job.clientId : (opts.clientId || S.clients[0].id);
  const presetType = job ? job.task : 'col_m';
  const cli = client(presetClient);

  /* ---- DRIVER: photos drive the clock — sections & times depend on job type ---- */
  if(S.role.kind === 'driver'){
    const flow = jobFlow(job);
    if(draft) existingTripPhotos = draft.photos||[];
    const photoSections = flow.photos.map(s=>`
      <label class="f">${s.label} <span style="font-weight:600">· ${s.hint}</span></label>
      <input type="file" accept="image/*" capture="environment" multiple id="tf-photo-${s.k}" onchange="onPhotoAdd(this,'${s.k}')">
      <div class="thumbs" id="tf-thumbs-${s.k}"></div>`).join('');
    const binFields = flow.bins.length ? `<div class="grid2">
      ${flow.bins.map(k=> k==='out'
        ? `<div><label class="f">BIN OUT NO. <span style="font-weight:600">(full — from photo, fix if wrong)</span></label>
        <input type="text" id="tf-binout" placeholder="e.g. 7022" style="text-transform:uppercase" autocapitalize="characters" value="${esc(draft?draft.binOut||'':'')}"></div>`
        : `<div><label class="f">BIN IN NO. <span style="font-weight:600">(empty — from photo, fix if wrong)</span></label>
        <input type="text" id="tf-binin" placeholder="e.g. R08" style="text-transform:uppercase" autocapitalize="characters" value="${esc(draft?draft.binIn||'':'')}"></div>`
      ).join('')}
    </div>` : '';
    openSheet(sheetTitle(draft ? 'Continue trip' : 'Log trip — snap the DO') + `
      <input type="hidden" id="tf-job" value="${job?job.id:''}">
      <input type="hidden" id="tf-draft" value="${draft?draft.id:''}">
      ${draft ? `<div class="muted" style="margin-bottom:8px">📝 Picking up where you left off — already-sent photos are marked SENT.</div>` : ''}
      ${job ? `
      <div class="card" style="box-shadow:none; background:var(--bg); margin:8px 0; padding:10px 12px">
        <div class="title" style="font-weight:800">${esc(cli.name)}</div>
        <div class="muted">📍 ${esc(cSite(cli, job.siteIdx).addr)}</div>
        <div class="muted">🛠️ ${esc(jobTypeLabel(job))}${job.price?` · 💵 <b>${money(jobPay(job))}</b>`:''}${job.dumpTo?` · ♻️ ${esc(job.dumpTo)}`:''}</div>
      </div>` : `
      <label class="f">CUSTOMER</label>
      <select id="tf-client">${S.clients.map(c=>`<option value="${c.id}" ${c.id===presetClient?'selected':''}>${esc(c.name)}</option>`).join('')}</select>`}
      ${photoSections}
      ${flow.noDO ? '' : `
      <div class="muted" id="tf-ocr" style="margin-top:6px">Snap the DO — the app reads the number and fills the box below. Please check it's correct.</div>
      <label class="f">DO / V NUMBER <span style="font-weight:600">(read from photo — fix if wrong)</span></label>
      <input type="number" id="tf-dono" placeholder="from photo" value="${draft&&draft.doNo?draft.doNo:''}">
      <label class="f">VEHICLE NO. <span style="font-weight:600">(remembers your last one — change if on a different truck today)</span></label>
      <input type="text" id="tf-vehicle" placeholder="e.g. XE6221D" style="text-transform:uppercase" autocapitalize="characters" value="${esc((draft&&draft.vehicleNo)||lastVehicleForDriver(S.role.driverId))}">`}
      ${binFields}
      ${(!flow.noDO && cli.type!=='vessel') ? `
      <label class="f">WASTE TYPE COLLECTED <span style="font-weight:600">(tick all that apply)</span></label>
      ${wasteChecksHTML('tf', draft ? (draft.wasteTypes&&draft.wasteTypes.length?draft.wasteTypes:[draft.waste||'']) : (job ? [job.waste||''] : []), draft?draft.wasteOther||'':'')}` : ''}
      ${(!flow.noDO && cli.type==='vessel') ? `
      <label class="f">🚢 VESSEL SEF — TYPE OF WASTE <span style="font-weight:600">(type volumes from the green DO)</span></label>
      ${vesselFieldsHTML('tfv', draft?draft.vessel:null)}
      <label class="f">REMARKS <span style="font-weight:600">(if any)</span></label>
      <input type="text" id="tf-remarks" placeholder="Optional" value="${esc(draft?draft.remarks||'':'')}">` : ''}
      ${flow.noDO ? '' : `
      <label class="f">✍️ CUSTOMER SIGNATURE <span style="font-weight:600">(optional for now — paper copy is still official)</span></label>
      <div class="thumbs" id="tf-thumbs-signature"></div>
      ${signaturePadHTML('tf', draft?draft.sigName||'':'', draft?draft.sigPosition||'':'')}`}
      <div class="card" id="tf-times" style="box-shadow:none; background:var(--bg); margin:12px 0 4px; padding:10px 12px; font-size:13px">
        ⏱️ Times are logged automatically from your photos — you can't change them.</div>
      ${job && job.price ? `<div class="payline"><span>Pay for this job</span><span>${money(jobPay(job))}</span></div>` : ''}
      <div style="margin-top:14px"><button class="btn" onclick="saveTrip(true)">✅ Done — send to office</button></div>
      <div style="margin-top:8px"><button class="btn ghost" onclick="saveTrip(false)">💾 Save — I'll finish later (e.g. waiting for the DO)</button></div>`);
    updateTimesDisplay();
    renderFormThumbs();
    if(!flow.noDO) sigPadInit('tf');
    return;
  }

  /* ---- OPERATOR: full form ---- */
  openSheet(sheetTitle('Log trip / Delivery Order') + `
    ${job?`<p class="muted">Linked to Job #${job.id} — saving marks it done.</p>`:''}
    <input type="hidden" id="tf-job" value="${job?job.id:''}">
    <label class="f">CUSTOMER</label>
    <select id="tf-client" onchange="tfClientChanged()">${S.clients.map(c=>`<option value="${c.id}" ${c.id===presetClient?'selected':''}>${esc(c.name)}</option>`).join('')}</select>
    <label class="f">TASK TYPE (SETS PAY)</label>
    <select id="tf-type" onchange="tfTypeChanged()">${TRIP_TYPES.map(t=>`<option value="${t.id}" ${t.id===presetType?'selected':''}>${esc(t.label)} — ${t.perKm?'$1.50/km':money(t.base)}</option>`).join('')}</select>
    <div class="muted" id="tf-note" style="margin-top:4px"></div>
    <div class="grid2">
      <div><label class="f">BIN OUT (FULL — BACK TO YARD)</label>
        <input type="text" id="tf-binout" placeholder="e.g. 7022" style="text-transform:uppercase"></div>
      <div><label class="f">BIN IN (EMPTY — TO CLIENT)</label>
        <input type="text" id="tf-binin" placeholder="e.g. R08" style="text-transform:uppercase"></div>
    </div>
    <div class="grid2">
      <div><label class="f">TIME START</label>${timeInput('tf-ts')}</div>
      <div><label class="f">TIME END</label>${timeInput('tf-te')}</div>
    </div>
    <div class="grid3">
      <div><label class="f">DISPOSE TO</label>
        <select id="tf-dispose"><option value="">— select —</option>${selOpts(dumpOptions(), job?job.dumpTo:'')}</select></div>
      <div><label class="f">TONNAGE (t)</label><input type="number" id="tf-ton" step="0.1" min="0" placeholder="0.0"></div>
      <div><label class="f">DISTANCE (km)</label><input type="number" id="tf-dist" step="0.1" min="0" placeholder="0" value="${job&&job.distance?job.distance:''}" oninput="calcFormPay()"></div>
    </div>
    <label class="f">SURCHARGES</label>
    <div id="tf-sur">${SURCHARGES.map(s=>`
      <label class="checkline"><input type="checkbox" value="${s.id}" onchange="calcFormPay()"> ${esc(s.label)}
        <span class="amt">+${money(s.amt)}</span></label>`).join('')}</div>
    <label class="f">DELIVERY ORDER</label>
    <div class="seg" id="tf-dotype">
      <button class="${cli.type!=='vessel'?'on':''}" data-v="land" onclick="segPick(this,'#tf-dotype')">Company (land · DO no.)</button>
      <button class="${cli.type==='vessel'?'on':''}" data-v="vessel" onclick="segPick(this,'#tf-dotype')">Vessel (V no.)</button>
    </div>
    <label class="f">DO / V NUMBER <span style="font-weight:600">(required — from the paper form: scan 🔍 or type it)</span></label>
    <input type="number" id="tf-dono" placeholder="e.g. 24119">
    <label class="f">WEIGHING TICKET (OPTIONAL)</label>
    <div class="grid3">
      <div><label class="f" style="margin-top:0">GROSS (kg)</label><input type="number" id="tf-gross" min="0" oninput="tfNet()"></div>
      <div><label class="f" style="margin-top:0">TARE (kg)</label><input type="number" id="tf-tare" min="0" oninput="tfNet()"></div>
      <div><label class="f" style="margin-top:0">NET (kg)</label><input type="number" id="tf-net" min="0" readonly></div>
    </div>
    <label class="f">PHOTOS — DO + PSA PASS</label>
    <input type="file" accept="image/*" capture="environment" id="tf-photo" onchange="onPhotoAdd(this)">
    <div class="muted" id="tf-ocr" style="margin-top:6px">📷 Snap the paper DO — the app reads it in the background; the office checks the details.</div>
    <div class="thumbs" id="tf-thumbs"></div>
    <label class="f">REMARKS</label>
    <input type="text" id="tf-remarks" placeholder="Optional">
    <div class="payline"><span>Trip pay</span><span id="tf-pay">$0.00</span></div>
    <div style="margin-top:12px"><button class="btn" onclick="saveTrip(true)">Save trip &amp; DO</button></div>`);
  tfTypeChanged();
}
function tfClientChanged(){
  const c = client($('#tf-client').value);
  const seg = c.type==='vessel' ? 'vessel' : 'land';
  $$('#tf-dotype button').forEach(b=>b.classList.toggle('on', b.dataset.v===seg));
}

function tfTypeChanged(){
  const ty = ttype($('#tf-type').value);
  $('#tf-note').textContent = ty.note || '';
  calcFormPay();
}
function tfNet(){
  const g = Number($('#tf-gross').value)||0, t = Number($('#tf-tare').value)||0;
  $('#tf-net').value = g && t ? Math.max(0, g-t) : '';
}
function tfFormTrip(){
  return {
    typeId: $('#tf-type').value,
    distance: $('#tf-dist').value,
    surcharges: $$('#tf-sur input:checked').map(i=>i.value),
  };
}
function calcFormPay(){
  const el = $('#tf-pay');
  if(el && $('#tf-type')) el.textContent = money(tripPay(tfFormTrip()));
}
async function onPhotoAdd(input, kind){
  kind = kind || 'do';
  const files = input.files ? Array.from(input.files) : [];
  if(!files.length) return;
  const st = $('#tf-ocr'); if(st) st.textContent = 'Adding photo…';
  try{
    for(const f of files){
      const raw = await new Promise((res, rej)=>{
        const fr = new FileReader();
        fr.onload = ()=>res(fr.result); fr.onerror = rej; fr.readAsDataURL(f);
      });
      const full  = await shrinkImage(raw, 1600, .85);
      const thumb = await shrinkImage(raw, 240, .7);
      /* append — multiple photos allowed per slot; ts = capture time (the trusted clock) */
      tripPhotos.push({id:'p'+Date.now().toString(36)+Math.random().toString(36).slice(2,6), full, thumb, kind, ts:Date.now()});
    }
    input.value = '';
    renderFormThumbs();
    updateTimesDisplay();
    /* read the DO photo now so the DO number + bins show up for a quick check */
    if(kind==='do'){
      const idx = tripPhotos.findIndex(p=>p.kind==='do');
      if(idx>=0) scanDO(idx);
    }else if(kind==='gross' || kind==='tare'){
      const idx = tripPhotos.map(p=>p.kind).lastIndexOf(kind); /* OCR the most recently added photo */
      if(idx>=0) scanWeight(idx, kind);
    }else if(st){ st.textContent = ''; }
  }catch(e){ if(st) st.textContent = '⚠️ Could not read that photo file.'; }
}
/* read-only live summary of the photo-stamped times on the driver form */
function updateTimesDisplay(){
  const box = $('#tf-times'); if(!box) return;
  const job = ($('#tf-job') && $('#tf-job').value) ? S.jobs.find(j=>j.id===Number($('#tf-job').value)) : null;
  const flow = jobFlow(job);
  const t12 = ms=> ms ? fmtTime12(msToHM(ms)) : '—';
  const acc = job && job.acceptedAtMs ? job.acceptedAtMs : 0;
  let rows = [`<div>▶️ Accepted: <b>${t12(acc)}</b></div>`];
  if(flow.start){ /* Exchange: whichever kind is start/end drives the label */
    const kLabel = k => k==='in' ? 'bin in' : 'bin out';
    rows.push(`<div>🟢 Start (${kLabel(flow.start)}): <b>${t12(firstTs(flow.start))}</b></div>`);
    rows.push(`<div>🔴 End (${kLabel(flow.end)}): <b>${t12(firstTs(flow.end))}</b></div>`);
  }else if(flow.mark){ /* Collect / Delivery */
    rows.push(`<div>⏺️ ${flow.markLabel}: <b>${t12(firstTs(flow.mark))}</b></div>`);
  }else if(flow.fixed){ /* Sell / Dump — no DO, bin-on-site photo = finish */
    rows.push(`<div>✅ Finish (bin photo): <b>${t12(firstTs('bin'))}</b> <span class="muted">· fixed price, no wait/OT</span></div>`);
  }
  const tw = Math.min(firstTs('gross')||Infinity, firstTs('tare')||Infinity);
  if(tw !== Infinity) rows.push(`<div>⚖️ Weighed: <b>${t12(tw)}</b></div>`);
  box.innerHTML = `<div style="font-weight:700; margin-bottom:4px">⏱️ Logged times (from photos — locked)</div>${rows.join('')}`;
}
function photoThumbHTML(p){
  return `<div style="position:relative">
      <img src="${p.thumb}" alt="photo">
      <button class="icon-btn" style="position:absolute; top:-9px; right:-9px; background:var(--card); border-radius:50%; box-shadow:var(--shadow); font-size:10px; padding:3px 7px" onclick="removePhoto('${p.id}')">✕</button>
    </div>`;
}
function removePhoto(id){ tripPhotos = tripPhotos.filter(p=>p.id!==id); renderFormThumbs(); updateTimesDisplay(); }
function alreadySentThumbHTML(p){
  return `<div style="position:relative">
      <img src="${p.thumb||p.url}" alt="photo" style="opacity:.75">
      <span class="tag" style="position:absolute; bottom:2px; left:2px; font-size:8px; background:var(--brand); color:#fff">SENT</span>
    </div>`;
}
function renderFormThumbs(){
  /* driver form: one thumbs div per photo section — already-sent photos (resumed drafts) show first, read-only */
  ['do','out','in','bin','gross','tare','signature'].forEach(k=>{
    const div = $('#tf-thumbs-'+k);
    if(!div) return;
    const already = existingTripPhotos.filter(p=>p.kind===k).map(alreadySentThumbHTML).join('');
    const fresh = tripPhotos.filter(p=>p.kind===k).map(photoThumbHTML).join('');
    div.innerHTML = already + fresh;
  });
  const allDiv = $('#tf-thumbs');
  if(allDiv){ /* operator combined view + manual OCR button */
    allDiv.innerHTML = tripPhotos.map(photoThumbHTML).join('')
      + (tripPhotos.some(p=>p.kind==='do') ? `<button class="btn ghost slim" style="align-self:center" onclick="scanDO(tripPhotos.findIndex(p=>p.kind==='do'))">🔍 Read DO number</button>` : '');
  }
}

/* ---------------- OCR (Tesseract.js, in-browser) ---------------- */
const OCR_CDN = 'https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.min.js';
function ensureOCR(){
  if(window.Tesseract) return Promise.resolve();
  const st = $('#tf-ocr'); if(st) st.textContent = 'Loading OCR engine (first time needs internet)…';
  return new Promise((res, rej)=>{
    const s = document.createElement('script');
    s.src = OCR_CDN;
    s.onload = res;
    s.onerror = ()=>rej(new Error('OCR engine failed to load — check internet connection'));
    document.head.appendChild(s);
  });
}
async function scanDO(i){
  const p = tripPhotos[i]; if(!p) return;
  const st = $('#tf-ocr');
  try{
    await ensureOCR();
    if(st) st.textContent = 'Reading DO… 0%';
    const {data} = await Tesseract.recognize(p.full, 'eng', {logger: m=>{
      if(m.status==='recognizing text' && st) st.textContent = 'Reading DO… ' + Math.round(m.progress*100) + '%';
    }});
    const filled = parseDO(data.text || '');
    if(st) st.textContent = filled.length
      ? '✅ Auto-filled from DO: ' + filled.join(', ') + ' — please double-check.'
      : '⚠️ Couldn\'t recognise any fields on this photo — fill in manually.';
    calcFormPay();
  }catch(e){
    if(st) st.textContent = '⚠️ ' + (e.message || 'OCR failed — fill in manually.');
  }
}
/* pure digit-scale reader — prefers "###kg", falls back to the first number on the photo.
   Comma is a thousands separator here (same convention as the DO gross/tare parser), not a decimal —
   weighbridge LED displays read whole kilograms, and trucks commonly weigh 4-5 digits.
   LED dot-matrix digits often OCR as look-alike letters, so the group BEFORE "kg" tolerates
   them and maps back: O→0 I/l→1 Z→2 S→5 G→6 B→8. The "kg" itself can misread as k9/kq. */
function parseWeightText(text){
  const t = text||'';
  const unfuzz = s => s.replace(/[oO]/g,'0').replace(/[Il|]/g,'1').replace(/[zZ]/g,'2')
                       .replace(/[sS]/g,'5').replace(/[gG]/g,'6').replace(/[bB]/g,'8').replace(/,/g,'');
  const m = t.match(/([\d,oOIl|zZsSgGbB]{2,7})\s*k\s?[g9q]/i);
  if(m){ const n = Number(unfuzz(m[1])); if(!isNaN(n) && n>0) return n; }
  const any = t.match(/[\d,]{2,7}/); /* fallback stays strict digits — no letter guessing without the kg anchor */
  return any ? Number(any[0].replace(/,/g,'')) : null;
}
/* the weighbridge display is a red LED dot-matrix panel — isolate the red pixels
   (digits AND the "kg" are all red) into clean black-on-white for a far better read.
   Downscale first so the LED dots merge into solid strokes, then upscale for OCR. */
async function redLedImage(dataURL){
  const im = await loadImage(dataURL);
  const half = document.createElement('canvas');
  half.width = Math.max(1, Math.round(im.width/2)); half.height = Math.max(1, Math.round(im.height/2));
  half.getContext('2d').drawImage(im, 0, 0, half.width, half.height);
  const cx = half.getContext('2d');
  const d = cx.getImageData(0, 0, half.width, half.height), a = d.data;
  for(let i=0; i<a.length; i+=4){
    const r=a[i], g=a[i+1], b=a[i+2];
    const led = r>90 && r>1.4*g && r>1.4*b;
    a[i]=a[i+1]=a[i+2] = led ? 0 : 255;
  }
  cx.putImageData(d, 0, 0);
  const out = document.createElement('canvas');
  out.width = half.width*3; out.height = half.height*3;
  const ox = out.getContext('2d');
  ox.imageSmoothingEnabled = true;
  ox.drawImage(half, 0, 0, out.width, out.height);
  return out.toDataURL('image/png');
}
async function scanWeight(i, kind){
  const p = tripPhotos[i]; if(!p) return;
  const st = $('#tf-ocr');
  const label = kind === 'gross' ? 'Gross' : 'Tare';
  try{
    await ensureOCR();
    if(st) st.textContent = `Reading ${label.toLowerCase()} weight…`;
    /* pass 1: red-LED isolated image; pass 2 fallback: the raw photo */
    let val = null;
    try{
      const led = await redLedImage(p.full);
      const r1 = await Tesseract.recognize(led, 'eng');
      val = parseWeightText(r1.data.text || '');
    }catch(e){}
    if(val == null){
      const {data} = await Tesseract.recognize(p.full, 'eng', {logger: m=>{
        if(m.status==='recognizing text' && st) st.textContent = `Reading ${label.toLowerCase()} weight… ` + Math.round(m.progress*100) + '%';
      }});
      val = parseWeightText(data.text || '');
    }
    const input = $('#tf-'+kind);
    if(val!=null && input){ input.value = val; tfNet(); }
    if(st) st.textContent = val!=null
      ? `✅ ${label} read: ${val} kg — please check.`
      : `⚠️ Couldn't read the ${label.toLowerCase()} weight — enter it manually.`;
  }catch(e){
    if(st) st.textContent = '⚠️ ' + (e.message || 'OCR failed — enter manually.');
  }
}
/* PURE parser (no DOM). Best-effort — everything the office can confirm in the CRM.
   VESSEL: DO/V number only. LAND: DO number + bin numbers (best guess) + times/weights. */
function parseDOData(text){
  const T = (text||'').replace(/\r/g, '');
  const low = T.toLowerCase();
  const out = {};
  /* DO/V number — ONLY from the printed "No. DO ####" / "No. V ####" label, and the
     number must sit right after it. No random-number fallback (blank beats wrong). */
  const vM  = low.match(/\bno\.?\s*v\b[^\d]{0,4}(\d{4,6})/);
  const doM = low.match(/\bno\.?\s*d\.?\s*o\b\.?[^\d]{0,4}(\d{4,6})/) || low.match(/\bd\.?\s*o\b[^\d]{0,4}(\d{4,6})/);
  if(vM){ out.doNo = Number(vM[1]); out.doType = 'vessel'; }
  else if(doM){ out.doNo = Number(doM[1]); out.doType = 'land'; }
  /* VESSEL → the V number only (the rest is handwritten; office keys it in) */
  if(out.doType === 'vessel') return out;

  /* LAND → best-guess the operational fields (office confirms in the CRM) */
  const cl = S.clients.find(c=>{
    if(/lirich/i.test(c.name)) return false;
    const words = c.name.toLowerCase().split(/\s+/).filter(w=>w.length>3 && !['pte','ltd'].includes(w));
    return words.length && words.every(w=>low.includes(w));
  });
  if(cl) out.clientId = cl.id;
  /* bins — try the labels first, then fall back to any bin-shaped numbers on the form */
  const BINPAT = '(7\\s?\\d{3}|[rl]\\s?\\d{2,3})';
  const outM = low.match(new RegExp('bin\\s*out\\W{0,18}?' + BINPAT));
  const inM  = low.match(new RegExp('bin\\s*in\\W{0,18}?' + BINPAT));
  if(outM) out.binOut = outM[1].replace(/\s/g,'').toUpperCase();
  if(inM)  out.binIn  = inM[1].replace(/\s/g,'').toUpperCase();
  if(!out.binOut && !out.binIn){
    /* tolerant of how OCR renders handwriting: lowercase r/l, a stray space */
    const found = [...new Set((T.match(/\b(7\s?\d{3}|[rl]\s?\d{2,3})\b/gi) || []).map(x=>x.replace(/\s/g,'').toUpperCase()))];
    if(found[0]) out.binIn  = found[0];
    if(found[1]) out.binOut = found[1];
  }
  /* weights */
  const g  = low.match(/gross[^\d]{0,14}([\d,]{3,7})/);
  const ta = low.match(/tare[^\d]{0,14}([\d,]{3,7})/);
  if(g)  out.gross = Number(g[1].replace(/,/g,''));
  if(ta) out.tare  = Number(ta[1].replace(/,/g,''));
  const to = low.match(/([\d.]+)\s*(?:tonnes?|tons?|mt)\b/);
  if(to && Number(to[1]) < 40) out.tonnage = Number(to[1]);
  /* times */
  const times = T.match(/\b(?:[01]?\d|2[0-3])[:.][0-5]\d\b/g) || [];
  if(times[0]) out.timeStart = times[0].replace('.',':').padStart(5,'0');
  if(times[1]) out.timeEnd   = times[1].replace('.',':').padStart(5,'0');
  if(low.includes('wdl')) out.disposeTo = 'WDL';
  else if(low.includes('nea')) out.disposeTo = 'NEA';
  return out;
}
/* operator's inline fill: apply parsed fields to the open form (only empty ones) */
function parseDO(text){
  const d = parseDOData(text);
  const filled = [];
  const setIf = (sel, val, label)=>{ const el = $(sel); if(el && val && !el.value){ el.value = val; filled.push(label); } };
  if(d.clientId && $('#tf-client') && $('#tf-client').value !== d.clientId){
    $('#tf-client').value = d.clientId; tfClientChanged(); filled.push('customer');
  }
  if(d.doNo && $('#tf-dono') && !$('#tf-dono').value){
    $('#tf-dono').value = d.doNo;
    if(d.doType) $$('#tf-dotype button').forEach(b=>b.classList.toggle('on', b.dataset.v===d.doType));
    filled.push((d.doType==='vessel'?'V':'DO') + ' no ' + d.doNo);
  }
  setIf('#tf-binout', d.binOut, 'bin out '+(d.binOut||''));
  setIf('#tf-binin',  d.binIn,  'bin in '+(d.binIn||''));
  if(d.gross) setIf('#tf-gross', d.gross, 'gross');
  if(d.tare)  setIf('#tf-tare',  d.tare,  'tare');
  if(d.gross || d.tare) tfNet();
  if(d.tonnage) setIf('#tf-ton', d.tonnage, 'tonnage');
  if(d.timeStart && !getTimeSel('tf-ts') && setTimeSel('#tf-ts', d.timeStart)) filled.push('time start');
  if(d.timeEnd && !getTimeSel('tf-te') && setTimeSel('#tf-te', d.timeEnd)) filled.push('time end');
  if(d.disposeTo) setIf('#tf-dispose', d.disposeTo, 'dispose to');
  return filled;
}
/* driver's BACKGROUND read — runs AFTER the trip is saved (driver never waits).
   Fills operator/DB-side fields that are still blank so the office can review OCR
   quality; the DO number is the reliable one, the rest is best-effort. */
async function backgroundEnrich(tripId, doPhoto){
  if(!doPhoto) return; /* only the DO photo is read — the bin photo is record-only */
  try{
    await ensureOCR();
    const {data} = await Tesseract.recognize(doPhoto.full, 'eng');
    const d = parseDOData(data.text || '');
    const t = S.trips.find(x=>x.id===tripId);
    if(!t) return;
    const p = {};
    if(!t.doNo && d.doNo){ p.doNo = d.doNo; if(d.doType) p.doType = d.doType; }
    if(!t.binOut && d.binOut) p.binOut = d.binOut;
    if(!t.binIn && d.binIn) p.binIn = d.binIn;
    /* times are NOT taken from OCR — they come from photo capture timestamps (tamper-proof) */
    if(!t.tonnage && d.tonnage) p.tonnage = d.tonnage;
    if(!t.disposeTo && d.disposeTo) p.disposeTo = d.disposeTo;
    if((!t.weight || !t.weight.gross) && d.gross && d.tare)
      p.weight = {gross:d.gross, tare:d.tare, net:d.gross-d.tare, ticket:''};
    if(Object.keys(p).length) await api('updateTrip', {id:tripId, patch:p});
  }catch(e){ /* best-effort — office completes from the photo if this fails */ }
}
/* final=true → "Done" (finalises the job); final=false → "Save" (keeps the job open so the
   driver can resume later, e.g. still waiting on the signed/office DO). Operator saves are
   always final — there's no draft concept on that side. */
async function saveTrip(final){
  const isDriver = S.role.kind==='driver';
  const jobId = $('#tf-job').value ? Number($('#tf-job').value) : null;
  const job = jobId ? S.jobs.find(j=>j.id===jobId) : null;
  const draftId = Number((($('#tf-draft')||{}).value))||0;
  const draft = draftId ? S.trips.find(x=>x.id===draftId) : null;
  const clientId = job ? job.clientId : ($('#tf-client') ? $('#tf-client').value : S.clients[0].id);
  const c = client(clientId);
  /* weight is captured only in phase 2 now — these fields only exist on the operator's own form */
  const gross = Number((($('#tf-gross')||{}).value))||0, tare = Number((($('#tf-tare')||{}).value))||0;
  const hasWeight = gross>0 && tare>0;
  const doNoInput = Number((($('#tf-dono')||{}).value)) || 0;

  let doTypeV, typeId, surcharges, disposeTo, tonnage, distance, remarks;
  let timeStart = '', timeEnd = '', tAccept = 0, tDO = 0, tBinOut = 0, tBinIn = 0, tEnd = 0;
  if(isDriver){
    /* driver: photos are the record AND the clock — times can never be typed.
       "Save" skips this — a partial save is allowed to be partial. */
    const flow = jobFlow(job);
    if(final){
      for(const s of flow.photos){
        const have = tripPhotos.some(p=>p.kind===s.k) || existingTripPhotos.some(p=>p.kind===s.k);
        if(s.req && !have){ toast(`⚠️ ${s.label.replace(/^📷 /,'')} photo is needed 📷`); return; }
      }
    }
    doTypeV = (c && c.type==='vessel') ? 'vessel' : 'land';
    typeId = job ? job.task : (doTypeV==='vessel' ? 'psa' : 'col_m');
    surcharges = job ? (job.surcharges||[]) : []; /* surcharges are set by the office at job start */
    disposeTo = job ? (job.dumpTo||'') : '';
    tonnage = 0;
    distance = job ? (Number(job.distance)||0) : 0;
    remarks = ((($('#tf-remarks')||{}).value)||'').trim(); /* vessel SEF remarks (land form has none) */
    /* photo-stamped times — a resumed draft keeps its original times; only a kind with no
       saved time yet picks one up from this session's photos */
    tAccept = (job && job.acceptedAtMs) || (draft&&draft.tAccept) || 0;
    tDO = (draft&&draft.tDO) || firstTs('do');
    tBinOut = (draft&&draft.tBinOut) || firstTs('out');
    tBinIn = (draft&&draft.tBinIn) || firstTs('in');
    if(flow.start){              /* Exchange: whichever kind is start/end drives the time */
      const tStart = flow.start==='out'?tBinOut:tBinIn, tE = flow.end==='out'?tBinOut:tBinIn;
      timeStart = msToHM(tStart); timeEnd = msToHM(tE); tEnd = tE;
    }else if(flow.mark){          /* Collect (bin out) / Delivery (bin in) */
      const tM = flow.mark==='out'?tBinOut:tBinIn;
      timeStart = msToHM(tM); tEnd = tM;
    }else if(flow.fixed){        /* Sell / Dump: no DO — Accept + bin-on-site photo = finish */
      tEnd = (draft&&draft.tEnd) || firstTs('bin');
      timeStart = msToHM(tAccept); timeEnd = msToHM(tEnd);
    }
    /* DO number filled by background OCR after save, or by the office from the photo */
  }else{
    doTypeV = $('#tf-dotype .on').dataset.v;
    if(!doNoInput){
      toast(`⚠️ Enter the ${doTypeV==='vessel'?'V':'DO'} number from the paper form — scan it with 🔍 or type it`);
      return;
    }
    typeId = $('#tf-type').value;
    surcharges = $$('#tf-sur input:checked').map(i=>i.value);
    disposeTo = $('#tf-dispose').value;
    tonnage = Number($('#tf-ton').value)||0;
    distance = Number($('#tf-dist').value)||0;
    remarks = $('#tf-remarks').value.trim();
    timeStart = getTimeSel('tf-ts'); timeEnd = getTimeSel('tf-te');
  }
  const binOut = ((($('#tf-binout')||{}).value)||'').trim().toUpperCase();
  const binIn = ((($('#tf-binin')||{}).value)||'').trim().toUpperCase();
  const vehicleNo = ((($('#tf-vehicle')||{}).value)||'').trim().toUpperCase();
  const wasteRead = isDriver ? readWasteChecks('tf') : null;
  const waste = wasteRead ? (wasteRead.display || (job?(job.waste||''):'')) : (job ? (job.waste||'') : '');
  const wasteTypes = wasteRead ? wasteRead.types : [];
  const wasteOther = wasteRead ? wasteRead.other : '';
  const vessel = (isDriver && c && c.type==='vessel') ? readVesselFields('tfv') : null;
  const sig = isDriver ? readSignature('tf') : null;
  const sigName = sig?sig.name:'', sigPosition = sig?sig.position:'';
  /* signature image rides the same photo pipeline (Drive storage + PhotoDB cache), tagged its own kind */
  const sigCanvas = isDriver ? $('#tf-sig-pad') : null;
  if(sigCanvas && sigCanvas._hasInk){
    tripPhotos.push({id:'sig'+Date.now().toString(36), full:sigCanvas.toDataURL('image/png'), thumb:sigCanvas.toDataURL('image/png'), kind:'signature', ts:Date.now()});
  }
  /* order Bin IN → Bin OUT → DO → record → weight → signature — matches the form's capture order, named in Drive by kind */
  const kindOrder = {in:0, out:1, do:2, bin:3, gross:4, tare:5, signature:6};
  const photosToUpload = tripPhotos.slice().sort((a,b)=>(kindOrder[a.kind]??9)-(kindOrder[b.kind]??9));
  closeSheet();

  if(draft){
    /* resuming a saved-for-later trip: upload only the NEW photos (existing ones already sent),
       then a minimal patch — never touches office-owned fields like weight/tonnAdj/invoiced */
    toast(photosToUpload.length ? `Saving ${photosToUpload.length} new photo(s)…` : 'Saving…');
    const jobtag = jobId || ('T'+draft.id);
    const PFX = {do:'DO', out:'BINOUT', in:'BININ', bin:'BIN', gross:'GROSS', tare:'TARE', signature:'SIG'};
    const cnt = {}; existingTripPhotos.forEach(p=>{ const k=PFX[p.kind]||'DO'; cnt[k]=(cnt[k]||0)+1; });
    const newPhotoRecords = [];
    for(const p of photosToUpload){
      const k = PFX[p.kind]||'DO'; cnt[k]=(cnt[k]||0)+1;
      try{
        const rec = await api('addPhoto', {b64:p.full.split(',')[1], name:k+'-'+jobtag+'-'+cnt[k]+'.jpg'});
        if(rec && rec.id){ rec.kind = p.kind; newPhotoRecords.push(rec);
          PhotoDB.put({id:rec.id, full:p.full, thumb:p.thumb, clientId, driverId:draft.driverId, date:draft.date, createdAt:Date.now()}).catch(()=>{}); }
      }catch(e){}
    }
    const patch = {
      binOut, binIn, vehicleNo, timeStart, timeEnd, tAccept, tDO, tBinOut, tBinIn, tEnd,
      doNo: doNoInput, doType: doTypeV, waste, wasteTypes, wasteOther, vessel, remarks,
      sigName, sigPosition, photos: existingTripPhotos.concat(newPhotoRecords), final,
    };
    const st = await api('updateTrip', {id: draft.id, patch});
    render();
    toast(final ? '✅ Sent to office — thanks!' : "💾 Progress saved — resume anytime from My Jobs");
    const doPhoto = photosToUpload.find(p=>p.kind==='do');
    if(doPhoto && st && st.trips){ const saved = st.trips.find(x=>x.id===draft.id); if(saved) backgroundEnrich(saved.id, doPhoto); }
    return;
  }

  const t = {
    driverId: isDriver ? S.role.driverId : 1,
    date: TODAY, clientId, typeId,
    jobType: job ? (job.jobType||'') : '',
    price: job && job.price != null ? job.price : null,
    binOut, binIn, vehicleNo,
    timeStart, timeEnd,
    /* raw photo-capture timestamps (ms) — the office does wait/OT maths in Sheets */
    tAccept, tDO, tBinOut, tBinIn, tEnd, tWeight: 0,
    disposeTo, tonnage, tonnAdj: 0, distance, surcharges, remarks,
    doType: doTypeV, doNo: doNoInput,
    waste, wasteTypes, wasteOther, vessel, sigName, sigPosition,
    photos: [],
    weight: hasWeight ? {gross, tare, net: gross-tare, ticket:''} : null,
    weightAdj: 0,
    needTicket: hasWeight,
    /* so the server can size/locate a bin it's never seen before, the moment a driver logs it */
    jobBinSize: job ? (job.binSize||'') : '', jobSiteIdx: job ? (job.siteIdx||0) : 0,
    invoiced: false, jobId,
  };
  /* denormalised display fields for the Google Sheet "Trips" tab */
  const d = driver(t.driverId), ty = ttype(t.typeId);
  t._client = c ? c.name : ''; t._sales = c ? (c.salesRep||'') : '';
  t._addr = c ? cSite(c, job ? job.siteIdx : 0).addr : '';
  t._driver = d.name;
  t._type = t.jobType || (ty ? ty.label : t.typeId);
  t._charge = (t.price != null ? t.price : '');
  t._surch = t.surcharges.map(s=>(SURCHARGES.find(x=>x.id===s)||{}).label).filter(Boolean).join('; ');
  t._pay = tripPay(t);
  t.photosB64 = photosToUpload.map(p=>p.full.split(',')[1]);
  t.photoKinds = photosToUpload.map(p=>p.kind || 'do');
  toast(photosToUpload.length ? `Saving trip + ${photosToUpload.length} photo(s)…` : 'Saving trip to database…');
  const st = await api('addTrip', {trip:t, final});
  const saved = st.trips[st.trips.length-1];
  /* cache full-res locally under the Drive ids so this device can view offline */
  (saved.photos||[]).forEach((ph,i)=>{
    const local = photosToUpload[i];
    if(ph && local) PhotoDB.put({id:ph.id, full:local.full, thumb:local.thumb, clientId:saved.clientId,
      driverId:saved.driverId, date:saved.date, createdAt:Date.now()}).catch(()=>{});
  });
  render();
  toast(isDriver
    ? (final ? '✅ Sent to office! Back at the yard, tap ⚖️ Add weight on this job.' : "💾 Progress saved — resume anytime from My Jobs")
    : `Trip saved — ${doLabel(saved)} · pay ${money(tripPay(saved))} ✅`);
  /* driver: OCR the DO photo in the BACKGROUND and fill the office's fields — driver never waits */
  if(isDriver){
    const doPhoto = photosToUpload.find(p=>p.kind==='do');
    if(doPhoto) backgroundEnrich(saved.id, doPhoto); /* Sell/Dump have no DO — skip OCR */
  }
}
function doLabel(t){ return (t.doType==='vessel' ? 'V ' : 'DO ') + (t.doNo || '⚠️ pending'); }
/* CRM read-out of the photo-stamped times (locked — the driver can't set these) */
function tripTimesHTML(t){
  const f = m => m ? fmtTime12(msToHM(m)) : '';
  const jt = t.jobType || '';
  const rows = [];
  if(t.tAccept) rows.push(`▶️ Accepted <b>${f(t.tAccept)}</b>`);
  if(t.tDO)     rows.push(`📄 DO photo <b>${f(t.tDO)}</b>`);
  if(jt==='Collect'){ if(t.tBinOut) rows.push(`⏺️ Collected (bin out, full) <b>${f(t.tBinOut)}</b>`); }
  else if(jt==='Delivery'){ if(t.tBinIn) rows.push(`⏺️ Delivered (bin in, empty) <b>${f(t.tBinIn)}</b>`); }
  else if(jt==='Sell' || jt==='Dump'){ if(t.tEnd) rows.push(`✅ Finished (bin photo) <b>${f(t.tEnd)}</b>`); }
  else { /* Exchange or legacy: bin IN (empty, start) then bin OUT (full, end) */
    if(t.tBinIn)  rows.push(`🟢 Time IN (bin in, empty) <b>${f(t.tBinIn)}</b>`);
    if(t.tBinOut) rows.push(`🔴 Time OUT (bin out, full) <b>${f(t.tBinOut)}</b>`);
  }
  if(t.tWeight) rows.push(`⚖️ Weighed <b>${f(t.tWeight)}</b>`);
  if(!rows.length){ /* legacy trips with only a typed start/end */
    return (t.timeStart||t.timeEnd)
      ? `<div class="muted" style="margin-top:6px">⏱️ ${esc(t.timeStart||'—')} – ${esc(t.timeEnd||'—')}</div>` : '';
  }
  return `<div style="margin-top:8px; font-size:12.5px; border-left:3px solid var(--brand); padding:2px 0 2px 9px">
    ⏱️ <b>Times — locked, from driver's photos</b><br>${rows.join(' &nbsp;·&nbsp; ')}</div>`;
}
function openTripDetail(id){
  const t = S.trips.find(x=>x.id===id); if(!t) return;
  const c = client(t.clientId), d = driver(t.driverId), ty = ttype(t.typeId);
  openSheet(sheetTitle(`Trip · ${doLabel(t)} <span class="tag ${t.doType==='vessel'?'vessel':''}">${t.doType.toUpperCase()}</span>`) + `
    <div class="card" style="box-shadow:none; background:var(--bg); margin:8px 0">
      <div class="title" style="font-weight:800">${esc(c?c.name:'?')}</div>
      <div class="muted" style="margin-top:4px">${esc(d.name)} · ${fmtDate(t.date)}</div>
      <div class="muted" style="margin-top:6px">🛠️ ${esc(t.jobType||(ty?ty.label:''))}${t.binOut?' · bin out '+esc(t.binOut):''}${t.binIn?' · bin in '+esc(t.binIn):''}</div>
      ${t.waste?`<div class="muted">🗑️ ${esc(t.waste)}</div>`:''}
      ${tripTimesHTML(t)}
      ${t.disposeTo || t.tonnage || t.tonnAdj ? `<div class="muted">♻️ ${t.disposeTo?'Dispose to '+esc(t.disposeTo)+' · ':''}tonnage ${t.tonnage||0}${t.tonnAdj?` <b>${t.tonnAdj>0?'+':''}${t.tonnAdj}</b> = <b>${tonnTotal(t)} t</b> <span class="tag">ADJUSTED</span>`:' t'}</div>`:''}
      ${t.surcharges.length?`<div class="muted">➕ ${t.surcharges.map(s=>esc(SURCHARGES.find(x=>x.id===s)?.label)).join(', ')}</div>`:''}
      ${t.vessel?`<div class="muted">🚢 ${esc(t.vessel.name||'Vessel')} — ${VESSEL_CATS.map(v=>t.vessel[v.k]?v.label.slice(0,1)+':'+t.vessel[v.k]+'m³':'').filter(Boolean).join(' · ')||'no categories'}</div>`:''}
      ${t.weight?`<div class="muted">⚖️ Ticket ${esc(t.weight.ticket)} — gross ${t.weight.gross} / tare ${t.weight.tare}${t.weightAdj?` <b>${t.weightAdj>0?'+':''}${t.weightAdj}</b>`:''} = net <b>${weightNet(t)} kg</b>${t.weightAdj?' <span class="tag">ADJUSTED</span>':''}</div>`:''}
      ${t.remarks?`<div class="muted">📝 ${esc(t.remarks)}</div>`:''}
      ${t.photos.length?`<div class="thumbs">${t.photos.map(p=> typeof p==='string'
        ? `<img src="${p}">`
        : `<img src="${p.thumb}" style="cursor:pointer" onclick="openPhotoView('${p.id}')">`).join('')}</div>
        <div class="muted" style="margin-top:4px">Tap a photo to open the full-size DO from the archive.</div>`:''}
      <div style="margin-top:8px" class="pay">Pay: ${money(tripPay(t))}</div>
    </div>
    ${(t.doType && (t.jobType!=='Sell' && t.jobType!=='Dump')) ? `
    <div class="row" style="margin-bottom:10px">
      <button class="btn ghost slim" onclick="openDOPrint(${t.id})">🖨️ View / Print Digital DO</button>
      ${S.role.kind==='operator' ? `<button class="btn ghost slim" onclick="emailDOPrompt(${t.id})">✉️ Email DO to client</button>` : ''}
    </div>` : ''}
    ${S.role.kind==='operator' ? `
    <label class="f">✏️ OPERATOR — COMPLETE / CORRECT THIS TRIP ${t.doNo?'':'<span class="tag" style="background:#fdf3dd;color:var(--amber)">DO NUMBER PENDING</span>'}</label>
    <div class="grid3">
      <div><label class="f">DO / V NUMBER</label><input type="number" id="te-dono" value="${t.doNo||''}" placeholder="from photo"></div>
      <div><label class="f">TONNAGE (t)</label><input type="number" id="te-ton" step="0.01" value="${t.tonnage||''}"></div>
      <div><label class="f">ADJUSTMENT (t)</label><input type="number" id="te-adj" step="0.01" value="${t.tonnAdj||''}" placeholder="+/-"></div>
    </div>
    <div class="grid3">
      <div><label class="f">GROSS (kg)</label><input type="number" id="te-gross" value="${t.weight?t.weight.gross:''}"></div>
      <div><label class="f">TARE (kg)</label><input type="number" id="te-tare" value="${t.weight?t.weight.tare:''}"></div>
      <div><label class="f">WEIGHT ADJ (kg)</label><input type="number" id="te-wadj" step="0.1" value="${t.weightAdj||''}" placeholder="+/-"></div>
    </div>
    <div class="grid2">
      <div><label class="f">BIN OUT <span style="font-weight:600">(full — leaving client)</span></label><input type="text" id="te-binout" value="${esc(t.binOut||'')}" style="text-transform:uppercase"></div>
      <div><label class="f">BIN IN <span style="font-weight:600">(empty — at client)</span></label><input type="text" id="te-binin" value="${esc(t.binIn||'')}" style="text-transform:uppercase"></div>
    </div>
    <label class="f">VEHICLE NO.</label>
    <input type="text" id="te-vehicle" value="${esc(t.vehicleNo||'')}" style="text-transform:uppercase" placeholder="e.g. XE6221D">
    <div class="grid2">
      <div><label class="f">DISTANCE (km)</label><input type="number" id="te-dist" step="0.1" value="${t.distance||''}"></div>
      <div><label class="f">NET WEIGHT (kg) <span style="font-weight:600">auto</span></label><input type="text" value="${weightNet(t)}" disabled></div>
    </div>
    <div class="grid2">
      <div><label class="f">TIME START</label>${timeInput('te-ts')}</div>
      <div><label class="f">TIME END</label>${timeInput('te-te')}</div>
    </div>
    <label class="f">CUSTOMER</label>
    <select id="te-client">${S.clients.map(x=>`<option value="${x.id}" ${x.id===t.clientId?'selected':''}>${esc(x.name)}</option>`).join('')}</select>
    ${t.doType==='vessel' ? '' : `<label class="f">WASTE TYPE <span style="font-weight:600">(tick all that apply)</span></label>
    ${wasteChecksHTML('te', t.wasteTypes && t.wasteTypes.length ? t.wasteTypes : (t.waste?[t.waste]:[]), t.wasteOther||'')}`}
    <label class="f">DISPOSE TO</label>
    <select id="te-dispose"><option value="">—</option>${selOpts(dumpOptions(), t.disposeTo)}</select>
    <label class="f">💵 DRIVER PAY / FEE ($) <span style="font-weight:600">— basic pay for this trip (surcharges add on top)</span></label>
    <input type="number" id="te-price" step="0.01" value="${t.price!=null?t.price:''}" placeholder="${t.price==null?'(using rate sheet)':''}">
    <label class="f" style="opacity:.6">TRIP TYPE (only used if no fee above)</label>
    <select id="te-type">${TRIP_TYPES.map(x=>`<option value="${x.id}" ${x.id===t.typeId?'selected':''}>${esc(x.label)} — ${x.perKm?'$1.50/km':money(x.base)}</option>`).join('')}</select>
    <label class="f">SURCHARGES</label>
    <div id="te-sur">${SURCHARGES.map(s=>`
      <label class="checkline"><input type="checkbox" value="${s.id}" ${(t.surcharges||[]).includes(s.id)?'checked':''}> ${esc(s.label)}
        <span class="amt">+${money(s.amt)}</span></label>`).join('')}</div>
    ${t.doType==='vessel' ? `
    <label class="f">🚢 VESSEL DETAILS <span style="font-weight:600">(key in from the DO photo)</span></label>
    ${vesselFieldsHTML('tev', t.vessel)}` : ''}
    <label class="f">REMARKS</label>
    <input type="text" id="te-remarks" value="${esc(t.remarks||'')}">
    <label class="checkline" style="margin-top:8px"><input type="checkbox" id="te-inv" ${t.invoiced?'checked':''}> Marked as invoiced</label>
    <div style="margin-top:12px"><button class="btn" onclick="saveTripEdit(${t.id})">💾 Save corrections</button></div>` : ''}`);
  if(S.role.kind==='operator'){ setTimeSel('#te-ts', t.timeStart); setTimeSel('#te-te', t.timeEnd); }
}
async function saveTripEdit(id){
  const t = S.trips.find(x=>x.id===id); if(!t) return;
  const gross = Number($('#te-gross').value)||0, tare = Number($('#te-tare').value)||0;
  const typeId = $('#te-type').value;
  const surcharges = $$('#te-sur input:checked').map(i=>i.value);
  const distance = Number($('#te-dist').value)||0;
  const clientId = $('#te-client').value;
  const price = $('#te-price').value==='' ? null : Number($('#te-price').value);
  const c = client(clientId), dv = driver(t.driverId), ty = ttype(typeId);
  const patch = {
    doNo: Number($('#te-dono').value) || t.doNo || 0,
    tonnage: Number($('#te-ton').value)||0,
    tonnAdj: Number($('#te-adj').value)||0,
    weightAdj: Number($('#te-wadj').value)||0,
    price,
    distance, typeId, surcharges, clientId,
    binOut: ($('#te-binout').value||'').trim().toUpperCase(),
    binIn: ($('#te-binin').value||'').trim().toUpperCase(),
    vehicleNo: ($('#te-vehicle').value||'').trim().toUpperCase(),
    timeStart: getTimeSel('te-ts'), timeEnd: getTimeSel('te-te'),
    ...(function(){ const w = readWasteChecks('te'); return w ? {waste:w.display, wasteTypes:w.types, wasteOther:w.other} : {}; })(),
    disposeTo: $('#te-dispose').value,
    remarks: ($('#te-remarks').value||'').trim(),
    invoiced: $('#te-inv').checked,
    weight: (gross && tare) ? {gross, tare, net: gross-tare, ticket:(t.weight && t.weight.ticket)||''} : t.weight,
  };
  /* vessel details (operator keys them in from the DO photo) */
  if(t.doType==='vessel'){ const v = readVesselFields('tev'); if(v) patch.vessel = v; }
  /* refresh the denormalised fields the Trips sheet reads */
  patch._client = c ? c.name : t._client;
  patch._sales = c ? (c.salesRep||'') : t._sales;
  patch._type = t.jobType || (ty ? ty.label : typeId);
  patch._charge = price!=null ? price : '';
  patch._surch = surcharges.map(s=>(SURCHARGES.find(x=>x.id===s)||{}).label).filter(Boolean).join('; ');
  patch._pay = tripPay({price, typeId, distance, surcharges}); /* price wins if set */
  await api('updateTrip', {id, patch});
  render(); toast('Trip updated — Trips sheet refreshed ✅');
  openTripDetail(id);
}

/* ============================================================
   DIGITAL DELIVERY ORDER — printable copy matching the paper forms
   ============================================================ */
const DO_LETTERHEAD = `
  <div class="doh">
    <div class="doh-logo">L<span>&hearts;</span></div>
    <div class="doh-co">
      <div class="doh-name">LIRICH RESOURCES PTE LTD</div>
      <div class="doh-tag">(Lead Resources To Quality)</div>
      <div class="doh-addr">Warehouse: 23, Gul Drive Singapore 629471<br>
      Office: 18 Boon Lay Way #09-123 Tradehub 21 (S) 609966<br>
      Tel: 6717 6688 &nbsp; Fax: 6793 2309</div>
    </div>
  </div>`;
function doPrintHTML(t){
  const c = client(t.clientId), d = driver(t.driverId);
  const sigPhoto = (t.photos||[]).find(p=>p && p.kind==='signature');
  const isVessel = t.doType==='vessel';
  const noLabel = isVessel ? 'No. V' : 'No. DO';
  const dateStr = fmtDate(t.date);
  const sigBlock = `
    <div class="do-sig-row">
      <div class="do-sig-box">
        ${sigPhoto ? `<img class="do-sig-img" src="${sigPhoto.url||sigPhoto.thumb}">` : '<div class="do-sig-blank">Not signed digitally — see paper copy</div>'}
        <div class="do-sig-line"></div>
        <div class="do-sig-label">Customer / Duty Officer Signature</div>
        <div class="do-sig-meta">Name: ${esc(t.sigName||'_____________________')}</div>
        <div class="do-sig-meta">Position: ${esc(t.sigPosition||'_____________________')}</div>
      </div>
      <div class="do-sig-box">
        <div class="do-sig-meta" style="margin-top:56px">Collected by (Driver): <b>${esc(d?d.name:'')}</b></div>
        <div class="do-sig-meta">Vehicle No.: <b>${esc(t.vehicleNo||'—')}</b></div>
        <div class="do-sig-meta">Time In: <b>${esc(t.timeStart?fmtTime12(t.timeStart):'—')}</b> &nbsp; Time Out: <b>${esc(t.timeEnd?fmtTime12(t.timeEnd):'—')}</b></div>
      </div>
    </div>`;
  const body = isVessel ? `
    <div class="do-field"><b>VESSEL NAME</b> : ${esc(t.vessel?t.vessel.name||'':'')}</div>
    <div class="do-field"><b>LOCATION</b> : ${esc(t.vessel?t.vessel.location||'':'')} &nbsp;&nbsp; <b>DATE</b> : ${dateStr}</div>
    <div class="do-sef-title">SERVICE ENGAGEMENT FORM (SEF)</div>
    <table class="do-table">
      <tr><th>TYPE OF WASTE</th><th>REMARKS (IF ANY)</th></tr>
      <tr><td>
        <table class="do-cats">
          ${VESSEL_CATS.map(cat=>`<tr><td>Cat ${cat.k.toUpperCase()} : ${esc(cat.label.split('·')[1]||cat.label)}</td><td>${t.vessel&&t.vessel[cat.k]?t.vessel[cat.k]:'—'} m³</td></tr>`).join('')}
          <tr><td><b>Total</b></td><td><b>${t.vessel?t.vessel.total||0:0} m³</b></td></tr>
        </table>
      </td><td style="vertical-align:top">${esc(t.remarks||'')}</td></tr>
    </table>
    <div class="do-field" style="margin-top:10px">I hereby certified that the waste information stated above is correct.</div>
  ` : `
    <div class="do-field"><b>COMPANY NAME</b> : ${esc(c?c.name:'')}</div>
    <div class="do-field"><b>DATE OF COLLECTION</b> : ${dateStr}</div>
    <div class="do-sef-title">SERVICE ENGAGEMENT FORM (SEF)</div>
    <div class="do-jd-title">JOB DESCRIPTION</div>
    <div class="do-field">GARBAGE DISPOSAL: We have collected the following open top container of:</div>
    <div class="do-waste-list">${(t.wasteTypes&&t.wasteTypes.length?t.wasteTypes:(t.waste?[t.waste]:[])).map(w=>`<div>☑ ${esc(w)}</div>`).join('') || '<div class="muted">(none ticked)</div>'}
      ${t.wasteOther?`<div>☑ Others: ${esc(t.wasteOther)}</div>`:''}</div>
    <table class="do-bin-table">
      <tr><td>Bin In (empty, at client)</td><td><b>${esc(t.binIn||'—')}</b></td></tr>
      <tr><td>Bin Out (full, back to yard)</td><td><b>${esc(t.binOut||'—')}</b></td></tr>
    </table>
  `;
  return `<!doctype html><html><head><meta charset="utf-8"><title>${noLabel} ${t.doNo||''} — ${esc(c?c.name:'')}</title>
  <style>
    body{font-family:Arial,Helvetica,sans-serif; color:#1a1a1a; max-width:720px; margin:20px auto; padding:0 16px}
    .doh{display:flex; align-items:flex-start; gap:14px; border-bottom:3px solid #111; padding-bottom:10px; margin-bottom:14px}
    .doh-logo{font-size:30px; font-weight:900; color:#0f7a4d}
    .doh-name{font-weight:800; font-size:16px}
    .doh-tag{font-size:11px; font-style:italic; color:#444}
    .doh-addr{font-size:11px; color:#333; margin-top:2px}
    .do-no{float:right; font-size:20px; font-weight:800; color:#b0281c}
    .do-field{margin:8px 0; font-size:13.5px}
    .do-sef-title{background:#111; color:#fff; font-weight:800; padding:6px 10px; margin-top:14px; font-size:13px}
    .do-jd-title{font-weight:800; margin-top:8px; font-size:12.5px}
    .do-waste-list{margin:8px 0; font-size:13px; line-height:1.7}
    .do-bin-table, .do-table{width:100%; border-collapse:collapse; margin-top:8px; font-size:13px}
    .do-bin-table td, .do-table td, .do-table th{border:1px solid #999; padding:6px 8px}
    .do-cats{width:100%; border-collapse:collapse}
    .do-cats td{border:none; padding:3px 4px; font-size:12.5px}
    .do-sig-row{display:flex; gap:24px; margin-top:26px}
    .do-sig-box{flex:1}
    .do-sig-img{max-width:220px; max-height:80px; display:block}
    .do-sig-blank{font-size:11.5px; color:#999; font-style:italic; height:60px; display:flex; align-items:center}
    .do-sig-line{border-top:1px solid #333; margin-top:4px; width:220px}
    .do-sig-label{font-size:10.5px; color:#555; margin-top:2px}
    .do-sig-meta{font-size:12px; margin-top:6px}
    .do-actions{margin:18px 0; display:flex; gap:10px}
    .do-actions button{padding:10px 16px; border-radius:8px; border:none; font-weight:700; font-size:13px; cursor:pointer}
    .do-print-btn{background:#0f7a4d; color:#fff}
    .do-close-btn{background:#eee; color:#333}
    @media print{ .do-actions{display:none} body{margin:0; max-width:none} }
  </style></head>
  <body>
    <div class="do-actions"><button class="do-print-btn" onclick="window.print()">🖨️ Print / Save as PDF</button><button class="do-close-btn" onclick="window.close()">Close</button></div>
    ${DO_LETTERHEAD}
    <div class="do-no">${noLabel} ${t.doNo||'—'}</div>
    <div style="clear:both"></div>
    ${body}
    ${sigBlock}
    <div class="do-field" style="margin-top:18px; font-size:10.5px; color:#888">Digital copy generated by Lirich Ops — not a substitute for the signed paper original during the trial period.</div>
  </body></html>`;
}
function openDOPrint(id){
  const t = S.trips.find(x=>x.id===id); if(!t) return;
  const w = window.open('', '_blank');
  if(!w){ toast('⚠️ Pop-up blocked — allow pop-ups to view the DO'); return; }
  w.document.write(doPrintHTML(t));
  w.document.close();
}
async function emailDOPrompt(id){
  const t = S.trips.find(x=>x.id===id); if(!t) return;
  const c = client(t.clientId);
  const suggested = (cContact(c,0) && cContact(c,0).email) || '';
  const to = prompt(`Email the digital DO to which address?\n(${c?c.name:''})`, suggested);
  if(!to) return;
  toast('Sending DO…');
  try{
    const res = await api('emailDO', {to, subject:`${t.doType==='vessel'?'V':'DO'} ${t.doNo||''} — ${c?c.name:''}`, html: doPrintHTML(t)});
    toast(res && res.sent ? '✅ DO emailed to '+to : '⚠️ Could not send — check the Apps Script is authorised for Gmail');
  }catch(e){ toast('⚠️ '+(e.message||'Send failed')); }
}

/* ============================================================
   GOOGLE SHEET LIVE SYNC (demo bridge via Apps Script web app)
   Mirrors ALL trips into a Google Sheet on every save/adjustment,
   so the office can filter/pivot/report in Sheets on live data.
   ============================================================ */
function sheetRows(){
  const rows = [['Date','Driver','Truck','Client','Salesperson','Trip Type','DO No','Bin Out','Bin In','Time Start','Time End','Dispose To','Tonnage','Adjustment','Total (t)','Distance (km)','Surcharges','Pay (SGD)','DO Type','Photos']];
  S.trips.forEach(t=>{
    const d = driver(t.driverId), c = client(t.clientId), ty = ttype(t.typeId);
    rows.push([t.date, d?d.name:'', d?d.truck:'', c?c.name:'', c?(c.salesRep||''):'', ty?ty.label:'',
      t.doNo, t.binOut||'', t.binIn||'', t.timeStart||'', t.timeEnd||'', t.disposeTo||'',
      t.tonnage||0, t.tonnAdj||0, tonnTotal(t), t.distance||'',
      (t.surcharges||[]).map(s=>{const x=SURCHARGES.find(y=>y.id===s); return x?x.label:s;}).join('; '),
      tripPay(t), t.doType, (t.photos||[]).length]);
  });
  return rows;
}
/* ============================================================
   REMOTE DATABASE (Google Sheets via Apps Script) — the shared
   state (jobs, trips, clients, bins, counters) lives centrally;
   localStorage is only this device's cache. All mutations go
   through api(); other devices pick changes up by polling.
   ============================================================ */
function sharedOf(s){
  return {clients:s.clients, bins:s.bins, jobs:s.jobs, trips:s.trips, seq:s.seq, rev:s.rev||0};
}
function adoptShared(st){
  if(!st || !st.rev) return;
  S.clients = st.clients; S.bins = st.bins; S.jobs = st.jobs;
  S.trips = st.trips; S.seq = st.seq; S.rev = st.rev;
  migrate(S); persist();
}
async function api(action, payload){
  const url = S.settings && S.settings.sheetUrl;
  if(!url){ toast('⚠️ No database URL configured'); throw new Error('no url'); }
  if(!navigator.onLine){ toast('⚠️ You are offline — change NOT saved. Reconnect and try again.'); throw new Error('offline'); }
  /* plain body (no headers) keeps this a "simple" request Apps Script accepts */
  const res = await fetch(url, {method:'POST', body: JSON.stringify(Object.assign({action}, payload||{}))});
  const raw = await res.text();
  let d;
  try{ d = JSON.parse(raw); }
  catch(e){ toast('⚠️ Database script is outdated — paste the new google-sheet-sync.gs and redeploy'); throw new Error('outdated script'); }
  if(d.error){ toast('⚠️ Database: ' + d.error); throw new Error(d.error); }
  if(d.rev) adoptShared(d);
  return d;
}
let remoteReady = false;
async function bootRemote(){
  const url = S.settings && S.settings.sheetUrl;
  if(!url || !navigator.onLine) return;
  try{
    const st = await (await fetch(url + '?state=1')).json();
    if(st.empty){
      /* first device online initialises the central database with its local data */
      await api('initState', {state: sharedOf(S)});
    }else{
      adoptShared(st);
    }
    remoteReady = true;
    render();
  }catch(e){ /* stay on cached data */ }
}
async function pollRemote(){
  try{
    const url = S.settings && S.settings.sheetUrl;
    if(!url || !S.auth || !navigator.onLine) return;
    const r = await (await fetch(url + '?rev=1')).json();
    if(r.rev && r.rev !== S.rev){
      const st = await (await fetch(url + '?state=1')).json();
      if(st.rev){ adoptShared(st); render(); }
    }
  }catch(e){}
}

/* ---- pull the "Customer DB" tab → dropdown options + CRM merge ---- */
async function fetchSheetDB(){
  const url = S.settings && S.settings.sheetUrl;
  if(!url) return false;
  try{
    const res = await fetch(url + '?db=1');
    if(!res.ok) throw 0;
    const d = await res.json();
    if(!d || !Array.isArray(d.clients)) throw 0;
    /* merge clients (name, yards, contact, per-job pricing) into the CRM — never deletes */
    let added = 0;
    d.clients.forEach(row=>{
      if(!row.name) return;
      let c = S.clients.find(x=>x.name.toLowerCase() === row.name.toLowerCase());
      if(!c){
        c = {id:'c'+Date.now().toString(36)+Math.random().toString(36).slice(2,5),
             name:row.name, type:'land', salesRep:'', sites:[], contacts:[], prices:{}};
        S.clients.push(c); added++;
      }
      if(row.addr && !c.sites.some(s=>s.addr.toLowerCase() === row.addr.toLowerCase())){
        c.sites.push({label:'Yard '+(c.sites.length+1), addr:row.addr}); added++;
      }
      if(row.contact || row.phone){
        if(!c.contacts.some(p=>p.name===(row.contact||'') && p.phone===(row.phone||'')))
          c.contacts.push({name:row.contact||'', phone:row.phone||''});
      }
      if(row.prices && Object.keys(row.prices).length) c.prices = row.prices; /* customer charge per job type */
    });
    if(added && remoteReady) api('replaceClients', {clients:S.clients}).catch(()=>{});
    /* merge bin numbers + sizes from the "Bin DB" tab — never touches live status/location,
       that only ever comes from a driver's trip or an operator override */
    let binsAdded = 0;
    (d.bins||[]).forEach(row=>{
      if(!row.no) return;
      let b = S.bins.find(x=>x.no===row.no);
      if(!b){
        S.bins.push({no:row.no, size:row.size||'', status:'unknown', clientId:null, siteIdx:0, source:'seed', firstSeen:TODAY});
        binsAdded++;
      }else if(!b.size && row.size){
        b.size = row.size; binsAdded++;
      }
    });
    if(binsAdded && remoteReady) api('replaceBins', {bins:S.bins}).catch(()=>{});
    /* reference lists for the pulldowns (drivers/vehicles, bin types, waste, dumping) */
    const seenD = new Set();
    S.sheetDB = {
      drivers: (d.drivers||[]).filter(x=>{
        const k = (x.name+'|'+x.vehicle).toLowerCase();
        if(!x.name || seenD.has(k)) return false; seenD.add(k); return true;
      }),
      binTypes: [...new Set((d.binTypes||[]).filter(Boolean))],
      wasteTypes: [...new Set((d.wasteTypes||[]).filter(Boolean))],
      dumpLocations: [...new Set((d.dumpLocations||[]).filter(Boolean))],
    };
    persist();
    return true;
  }catch(e){ return false; }
}
/* bin sizes for the job form = the sizes that actually exist in the bin fleet
   (Bin DB / Bin Inventory "Size" column) — you can't request a size Lirich doesn't own.
   Falls back to the Lists tab, then built-ins, only while the fleet has no sizes yet. */
function binOptions(){
  const fleet = [...new Set(S.bins.map(b=>(b.size||'').trim()).filter(Boolean))]
    .sort((a,b)=>(parseFloat(a)||0)-(parseFloat(b)||0) || a.localeCompare(b));
  if(fleet.length) return fleet;
  return (S.sheetDB && S.sheetDB.binTypes && S.sheetDB.binTypes.length) ? S.sheetDB.binTypes : BIN_SIZES;
}
/* dropdown builders — Google Sheet lists first, built-in fallbacks otherwise */
function wasteOptions(){
  return (S.sheetDB && S.sheetDB.wasteTypes && S.sheetDB.wasteTypes.length)
    ? S.sheetDB.wasteTypes
    : ['General Waste','Wood Waste','Metal Waste','Plastic Waste','Hardcore Waste'];
}
function dumpOptions(){
  return (S.sheetDB && S.sheetDB.dumpLocations && S.sheetDB.dumpLocations.length)
    ? S.sheetDB.dumpLocations
    : ['Lirich Resources Pte Ltd','NEA','WDL','Bee Joo','Kim Hock'];
}
function driverSelectOptions(selectedId){
  /* just the 5 drivers by name — vehicles are no longer tracked (drivers swap trucks) */
  return DRIVERS.map(d=>`<option value="${d.id}" ${d.id===selectedId?'selected':''}>${esc(d.name)}</option>`).join('');
}
function selOpts(list, selected){
  return list.map(o=>`<option ${o===selected?'selected':''}>${esc(o)}</option>`).join('');
}

/* ---- auto distance: yard address → dumping location (free OSM geocoding, cached) ---- */
const DUMP_ADDR = { /* dumping sites are usually named, not addressed — map the known ones */
  'lirich resources pte ltd': '23 Gul Drive Singapore',
  'nea': 'Tuas South Avenue 3 Singapore',
  'bee joo': '5 Sungei Kadut Street 6 Singapore',
  'kim hock': '11 Kranji Crescent Singapore',
  'wah & hua': '17 Kallang Junction Singapore',
  'asia recycling resources pte ltd': '16 Gul Crescent Singapore',
  'hcg environmental pte ltd': '8 Tuas View Circuit Singapore',
  't3 resources pte ltd': '16 Gul Street 3 Singapore',
  'lanco construction & engineering pte ltd': '25 Tuas Avenue 4 Singapore',
};
async function geocode(addr){
  if(!addr) return null;
  const key = addr.toLowerCase().trim();
  const q = DUMP_ADDR[key] || addr;
  let cache = {};
  try{ cache = JSON.parse(localStorage.getItem('lirich-geo')||'{}'); }catch(e){}
  if(cache[key]) return cache[key];
  try{
    const r = await fetch('https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=sg&q='+encodeURIComponent(q));
    const j = await r.json();
    if(j && j[0]){
      cache[key] = {lat:+j[0].lat, lon:+j[0].lon};
      localStorage.setItem('lirich-geo', JSON.stringify(cache));
      return cache[key];
    }
  }catch(e){}
  return null;
}
function havKm(a, b){
  const R = 6371, dLa = (b.lat-a.lat)*Math.PI/180, dLo = (b.lon-a.lon)*Math.PI/180;
  const x = Math.sin(dLa/2)**2 + Math.cos(a.lat*Math.PI/180)*Math.cos(b.lat*Math.PI/180)*Math.sin(dLo/2)**2;
  return 2*R*Math.asin(Math.sqrt(x));
}
async function autoDistance(){
  const el = $('#jf-dist'); if(!el) return;
  const c = client($('#jf-client').value); if(!c) return;
  const addr = cSite(c, Number($('#jf-site').value)||0).addr;
  const dump = $('#jf-dump') ? $('#jf-dump').value : '';
  if(!addr || !dump){ el.placeholder = 'auto (pick yard + dumping first)'; return; }
  el.placeholder = 'calculating…';
  const [A, B] = await Promise.all([geocode(addr), geocode(dump)]);
  if(A && B){
    el.value = Math.round(havKm(A, B) * 1.35 * 10) / 10; /* ×1.35 ≈ road vs straight line */
    el.placeholder = '';
  }else{
    el.placeholder = 'auto failed — type km';
  }
}
/* time entry: driver types digits, colon inserts itself (1111 → 11:11) + AM/PM */
function fmtTimeTyping(el){
  const d = el.value.replace(/\D/g, '').slice(0, 4); /* keep only up to 4 digits */
  el.value = d.length <= 2 ? d : d.slice(0, d.length - 2) + ':' + d.slice(d.length - 2);
}
function timeInput(id){
  return `<div class="row" style="gap:4px">
    <input type="text" id="${id}-t" placeholder="--:--" inputmode="numeric" maxlength="5" style="flex:1.4"
      oninput="fmtTimeTyping(this)">
    <select id="${id}-ap" style="flex:1"><option>AM</option><option>PM</option></select>
  </div>`;
}
/* read the typed time into 24h "HH:MM"; accepts 9:41 / 941 / 22:40 (24h trusted as-is) */
function getTimeSel(id){
  const el = $('#'+id+'-t'); if(!el) return '';
  const m = el.value.trim().match(/^(\d{1,2})[:.]?(\d{2})$/);
  if(!m) return '';
  let h = Number(m[1]);
  if(h < 13){ h = h % 12; if($('#'+id+'-ap').value === 'PM') h += 12; }
  return String(h).padStart(2,'0') + ':' + m[2];
}
/* set the field from a 24h "HH:MM" (used by OCR auto-fill) */
function setTimeSel(idSel, val){
  const id = idSel.replace('#','');
  const el = $('#'+id+'-t'); if(!el || !val) return false;
  const [h, m] = val.split(':').map(Number);
  el.value = (h % 12 || 12) + ':' + String(m).padStart(2,'0');
  $('#'+id+'-ap').value = h >= 12 ? 'PM' : 'AM';
  return true;
}

/* ============================================================
   DO PHOTO ARCHIVE (IndexedDB-backed)
   ============================================================ */
let doSearch = '', doArchCache = null, doArchStats = '';
async function openDOArchive(){
  /* the shared trips carry the Drive photo links — every device sees all DOs */
  const recs = [];
  S.trips.forEach(t=>{
    (t.photos||[]).forEach(p=>{
      if(typeof p === 'string') return;
      recs.push({id:p.id, thumb:p.thumb, url:p.url||null, doNo:t.doNo, label:doLabel(t), tripId:t.id,
        clientId:t.clientId, driverId:t.driverId, date:t.date, createdAt:t.id});
    });
  });
  /* legacy photos stored only on this device */
  try{
    (await PhotoDB.all()).forEach(r=>{
      if(!recs.some(x=>x.id===r.id)) recs.push(r);
    });
  }catch(e){}
  doArchCache = recs.sort((a,b)=>(b.createdAt||0)-(a.createdAt||0));
  const driveCount = doArchCache.filter(r=>r.url).length;
  doArchStats = `${doArchCache.length} DO photo${doArchCache.length===1?'':'s'} · ${driveCount} in Google Drive (folder "Lirich Ops DO Photos")`;
  renderDOArchive();
}
function renderDOArchive(){
  const recs = doArchCache || [];
  const q = doSearch.toLowerCase();
  const list = recs.filter(r=>{
    if(!q) return true;
    const c = client(r.clientId);
    return String(r.doNo||'').includes(q) || (c && c.name.toLowerCase().includes(q));
  });
  openSheet(sheetTitle('📁 DO photo archive') + `
    <input type="text" id="doa-q" placeholder="🔍 DO number or client…" value="${esc(doSearch)}"
      oninput="doSearch=this.value; renderDOArchive(); const el=$('#doa-q'); el.focus(); el.setSelectionRange(el.value.length,el.value.length)">
    <div class="muted" style="margin:8px 0">Showing ${list.length} of ${recs.length} · 💾 ${doArchStats}</div>
    <div class="bin-grid" style="grid-template-columns:repeat(auto-fill,minmax(96px,1fr))">
      ${list.map(r=>`
        <div style="cursor:pointer" onclick="openPhotoView('${r.id}')">
          <img src="${r.thumb}" style="width:100%; aspect-ratio:3/4; object-fit:cover; border-radius:10px; border:1px solid var(--line)">
          <div style="font-size:10.5px; font-weight:800; margin-top:3px">${r.label || 'DO '+(r.doNo||'—')}</div>
          <div class="muted" style="font-size:9.5px">${esc(((client(r.clientId)||{}).name||'')).slice(0,18)}</div>
        </div>`).join('') || '<div class="empty" style="grid-column:1/-1">No DO photos yet — they land here automatically when drivers save trips with photos.</div>'}
    </div>`);
}
async function openPhotoView(id){
  /* prefer the shared Drive copy; fall back to this device's local cache */
  let rec = null, trip = null;
  for(const t of S.trips){
    const p = (t.photos||[]).find(x=>x && x.id===id);
    if(p){ rec = {full:p.url, doNo:t.doNo, label:doLabel(t), clientId:t.clientId, driverId:t.driverId, date:t.date}; trip = t; break; }
  }
  const local = await PhotoDB.get(id).catch(()=>null);
  if(local){ rec = rec || local; rec.full = local.full; } /* local full-res beats Drive URL */
  if(!rec || !rec.full){ toast('Photo not available — check internet'); return; }
  const c = client(rec.clientId), d = driver(rec.driverId);
  openSheet(sheetTitle(`${rec.label || 'DO '+(rec.doNo||'—')}`) + `
    <img src="${rec.full}" style="width:100%; border-radius:12px; border:1px solid var(--line)">
    <div class="muted" style="margin-top:10px">
      ${c?esc(c.name)+' · ':''}${fmtDate(rec.date)}${d?' · '+esc(d.name):''}
    </div>
    ${trip?`<div style="margin-top:10px"><button class="btn ghost" onclick="openTripDetail(${trip.id})">📋 Open linked trip</button></div>`:''}
    <div style="margin-top:8px"><button class="btn ghost" onclick="openDOArchive()">← Back to archive</button></div>`);
}

/* ============================================================
   BINS
   ============================================================ */
let binFilter = 'all', binSearch = '';
function vBins(){
  const counts = {};
  BIN_STATUS.forEach(s=>counts[s.id] = S.bins.filter(b=>b.status===s.id).length);
  const list = S.bins.filter(b=>
    (binFilter==='all' || b.status===binFilter) &&
    (!binSearch || b.no.toLowerCase().includes(binSearch.toLowerCase())));
  $('#main').innerHTML = `
    <input type="text" class="search" placeholder="🔍 Search bin no…" value="${esc(binSearch)}"
      oninput="binSearch=this.value; vBins(); this.focus(); this.setSelectionRange(this.value.length,this.value.length)">
    <div class="ftabs">
      <button class="${binFilter==='all'?'on':''}" onclick="binFilter='all'; render()">All (${S.bins.length})</button>
      ${BIN_STATUS.map(s=>`<button class="${binFilter===s.id?'on':''}" onclick="binFilter='${s.id}'; render()">${s.label} (${counts[s.id]})</button>`).join('')}
    </div>
    <div class="card">
      <div class="bin-grid">${list.map(b=>`
        <button class="bin-cell ${BIN_STATUS.find(s=>s.id===b.status).cls}" onclick="openBinDetail('${b.no}')">${b.no}${b.size?`<small>${esc(b.size)}</small>`:''}</button>`).join('')
        || '<div class="empty" style="grid-column:1/-1">No bins match.</div>'}</div>
      <div class="legend">
        <span><span class="dot" style="background:#9aa0a6"></span>Unverified</span>
        <span><span class="dot" style="background:var(--brand)"></span>Yard</span>
        <span><span class="dot" style="background:var(--amber)"></span>At client</span>
      </div>
    </div>`;
}
function openBinDetail(no){
  const b = binByNo(no);
  const c = b.clientId ? client(b.clientId) : null;
  const isOp = S.role.kind==='operator';
  openSheet(sheetTitle(`Bin ${esc(b.no)}${b.size?' · '+esc(b.size):''}`) + `
    <div class="muted" style="margin-bottom:8px">
      Status: <b>${BIN_STATUS.find(s=>s.id===b.status).label}</b>
      ${c?` — at <b>${esc(c.name)}</b>`:''}
      ${b.source==='driver'?` <span class="tag">ADDED FROM DRIVER LOG</span>`:''}
    </div>
    ${isOp?`
    <label class="f">SET STATUS</label>
    <div class="seg" id="bd-status">${BIN_STATUS.map(s=>
      `<button class="${b.status===s.id?'on':''}" data-s="${s.id}" onclick="segPick(this,'#bd-status'); $('#bd-cli-wrap').style.display=this.dataset.s==='client'?'block':'none'">${s.label}</button>`).join('')}</div>
    <div id="bd-cli-wrap" style="display:${b.status==='client'?'block':'none'}">
      <label class="f">AT CLIENT</label>
      <select id="bd-client">${S.clients.map(x=>`<option value="${x.id}" ${x.id===b.clientId?'selected':''}>${esc(x.name)}</option>`).join('')}</select>
    </div>
    <label class="f">SIZE <span style="font-weight:600">(from Bin DB or a job — fix if wrong)</span></label>
    <input type="text" id="bd-size" value="${esc(b.size||'')}" placeholder="e.g. 10ft">
    <div style="margin-top:14px"><button class="btn" onclick="saveBin('${b.no}')">Save bin</button></div>`
    : '<p class="muted">Only the office can edit bin status.</p>'}`);
}
async function saveBin(no){
  const status = $('#bd-status .on').dataset.s;
  const patch = {
    status,
    clientId: status==='client' ? $('#bd-client').value : null,
    siteIdx: 0,
    size: $('#bd-size').value.trim(),
  };
  closeSheet();
  await api('updateBin', {no, patch});
  render(); toast(`Bin ${no} updated`);
}

/* ============================================================
   OPERATOR · EARNINGS
   ============================================================ */
let earnDate = TODAY;
function vEarnings(){
  const trips = tripsOn(earnDate);
  const total = payOf(trips);
  $('#main').innerHTML = `
    <div class="card row">
      <div class="grow"><label class="f" style="margin-top:0">CONSOLIDATE DATE</label>
        <input type="date" value="${earnDate}" onchange="earnDate=this.value; render()"></div>
      <div class="kpi green" style="box-shadow:none; padding:6px 10px"><div class="num">${money(total)}</div><div class="lbl">GRAND TOTAL</div></div>
    </div>
    ${DRIVERS.map(d=>{
      const tr = trips.filter(t=>t.driverId===d.id);
      return `<details class="drv" ${tr.length?'open':''}>
        <summary>${avatarHTML(d)}
          <div class="grow"><div class="title" style="font-weight:800; font-size:13.5px">${esc(d.name)}</div>
          <div class="sub muted">${tr.length} trip${tr.length===1?'':'s'}</div></div>
          <div class="pay">${money(payOf(tr))}</div></summary>
        <div class="body">
          ${tr.map(t=>{
            const c = client(t.clientId), ty = ttype(t.typeId);
            return `<div class="item tap" onclick="openTripDetail(${t.id})">
              <div class="grow"><div class="title" style="font-size:12.5px">${esc(c?c.name:'?')} · ${doLabel(t)}</div>
              <div class="sub">${esc(ty?ty.label:'')}${t.surcharges.length?' +'+t.surcharges.length+' surcharge(s)':''}</div></div>
              <div class="pay">${money(tripPay(t))}</div></div>`;
          }).join('') || '<div class="empty">No trips this day.</div>'}
        </div>
      </details>`;
    }).join('')}
    <div class="card">
      <h2>💼 By salesperson <span class="muted" style="font-weight:600">(commission allocation · ${fmtDate(earnDate)})</span></h2>
      ${SALES.map(sp=>{
        const cids = S.clients.filter(c=>c.salesRep===sp).map(c=>c.id);
        const tr = trips.filter(t=>cids.includes(t.clientId));
        const tonn = Math.round(tr.reduce((a,t)=>a+tonnTotal(t),0)*100)/100;
        return `<div class="item">
          <span class="avatar" style="background:var(--violet)">${initials(sp)}</span>
          <div class="grow">
            <div class="title">${sp}</div>
            <div class="sub">${cids.length} client${cids.length===1?'':'s'} · ${tr.length} trip${tr.length===1?'':'s'} · ${tonn} t (adjusted)</div>
          </div>
          <div class="pay">${money(payOf(tr))}</div>
        </div>`;
      }).join('')}
      <p class="muted" style="margin:8px 0 0">Trip value shown; invoice value per client contract lives in Xero — tonnage is the allocation basis.</p>
    </div>
    <div class="card">
      <h2>📤 Export</h2>
      <div class="row">
        <button class="btn ghost" onclick="exportDayCSV()">⬇️ Export day (CSV for Xero)</button>
        <button class="btn blue" onclick="exportDOsCSV()">⬇️ Export DOs for invoicing</button>
      </div>
      <div style="margin-top:8px"><button class="btn" onclick="openDOArchive()">📁 DO photo archive</button></div>
    </div>
    <div class="card">
      <h2>📊 Central database (Google Sheets)</h2>
      <p class="muted">All jobs, trips, bins and clients live in one shared database — every phone reads and writes it.
      The spreadsheet's <b>Trips</b> and <b>Jobs</b> tabs are always-current views for filtering and reports;
      DO photos are in the Drive folder "Lirich Ops DO Photos".</p>
      <div class="muted" style="margin-top:6px">Status: ${remoteReady ? '🟢 connected · revision '+(S.rev||0) : (navigator.onLine ? '🟡 connecting…' : '🔴 offline — showing this device\'s cached copy')}</div>
      <div class="row" style="margin-top:10px">
        <button class="btn ghost" onclick="pollRemote().then(()=>{render(); toast('Refreshed from database')})">↻ Refresh now</button>
      </div>
      <label class="f">DATABASE URL (APPS SCRIPT WEB APP)</label>
      <input type="text" id="es-sheet" value="${esc(S.settings.sheetUrl||'')}">
      <div style="margin-top:8px"><button class="btn ghost slim" onclick="S.settings.sheetUrl=$('#es-sheet').value.trim(); persist(); bootRemote(); toast('Database URL saved')">💾 Save URL</button></div>
    </div>`;
}
function downloadCSV(name, rows){
  const csv = rows.map(r=>r.map(c=>{
    c = String(c??'');
    return /[",\n]/.test(c) ? '"'+c.replace(/"/g,'""')+'"' : c;
  }).join(',')).join('\r\n');
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([csv], {type:'text/csv'}));
  a.download = name; a.click(); URL.revokeObjectURL(a.href);
}
function exportDayCSV(){
  const trips = tripsOn(earnDate);
  const rows = [['Date','Driver','Client','Salesperson','Trip Type','DO No','Bin Out','Bin In','Tonnage (t)','Adjustment (t)','Total (t)','Distance (km)','Surcharges','Pay (SGD)']];
  trips.forEach(t=>{
    const d = driver(t.driverId), c = client(t.clientId), ty = ttype(t.typeId);
    rows.push([t.date, d.name, c?c.name:'', c?c.salesRep||'':'', ty?ty.label:'', t.doNo, t.binOut, t.binIn,
      t.tonnage||'', t.tonnAdj||'', tonnTotal(t)||'', t.distance||'', t.surcharges.map(s=>SURCHARGES.find(x=>x.id===s)?.label).join('; '), tripPay(t).toFixed(2)]);
  });
  rows.push(['','','','','','','','','','','','','TOTAL', payOf(trips).toFixed(2)]);
  downloadCSV(`lirich-earnings-${earnDate}.csv`, rows);
  toast('Earnings CSV downloaded');
}
function exportDOsCSV(){
  const trips = tripsOn(earnDate);
  const rows = [['ContactName','InvoiceNumber','InvoiceDate','Description','Quantity','UnitAmount','DO Type','Vessel','Net Weight (kg)']];
  trips.forEach(t=>{
    const c = client(t.clientId), ty = ttype(t.typeId);
    rows.push([c?c.name:'', 'DO-'+t.doNo, t.date,
      `Waste collection — ${ty?ty.label:''}${t.binOut?', bin '+t.binOut:''}${t.weight?', ticket '+t.weight.ticket:''}`,
      tonnTotal(t)||1, '', t.doType, t.vessel?t.vessel.name:'', t.weight?t.weight.net:'']);
  });
  downloadCSV(`lirich-DOs-${earnDate}.csv`, rows);
  toast('DO export downloaded — set unit prices in Xero');
}

/* ============================================================
   OPERATOR · CRM
   ============================================================ */
let crmSearch = '';
function vCRM(){
  const list = S.clients.filter(c=>!crmSearch || c.name.toLowerCase().includes(crmSearch.toLowerCase()));
  $('#main').innerHTML = `
    <input type="text" class="search" placeholder="🔍 Search clients…" value="${esc(crmSearch)}"
      oninput="crmSearch=this.value; vCRM(); this.focus(); this.setSelectionRange(this.value.length,this.value.length)">
    <div class="row" style="margin-bottom:10px">
      <button class="btn ghost slim" onclick="openImportSheet()">⬆️ Import clients (Excel / Google Sheets)</button>
    </div>
    <div class="card">
      ${list.map(c=>{
        const binsOn = S.bins.filter(b=>b.clientId===c.id).length;
        const tr = S.trips.filter(t=>t.clientId===c.id).length;
        return `<div class="item tap" onclick="openClientDetail('${c.id}')">
          <div class="grow">
            <div class="title">${esc(c.name)} <span class="tag ${c.type}">${c.type.toUpperCase()}</span>
              ${c.salesRep?`<span class="tag vessel">💼 ${esc(c.salesRep)}</span>`:''}</div>
            <div class="sub">📍 ${esc(cSite(c,0).addr)}${c.sites && c.sites.length>1?` · +${c.sites.length-1} more yard${c.sites.length>2?'s':''}`:''}</div>
            <div class="sub">${binsOn} bin${binsOn===1?'':'s'} on site · ${tr} trip${tr===1?'':'s'}</div>
          </div>
          <span class="icon-btn">›</span>
        </div>`;
      }).join('') || '<div class="empty">No clients match.</div>'}
    </div>`;
}
function openClientDetail(id){
  const c = client(id);
  const binsOn = S.bins.filter(b=>b.clientId===id);
  const tr = S.trips.filter(t=>t.clientId===id);
  const jobs = S.jobs.filter(j=>j.clientId===id);
  const billable = payOf(tr);
  const tonnage = tr.reduce((a,t)=>a+tonnTotal(t),0);
  const timeline = [
    ...jobs.map(j=>({when:j.createdAt, html:`🗂️ Job #${j.id} — ${esc(ttype(j.task)?.label||'')} <span class="chip st-${j.status}">${STATUS_LABEL[j.status]}</span>`})),
    ...tr.map(t=>({when:t.date+'T'+(t.timeStart||'00:00'), html:`📋 ${doLabel(t)} — ${esc(ttype(t.typeId)?.label||'')} · ${tonnTotal(t)?tonnTotal(t)+' t'+(t.tonnAdj?' (adj '+(t.tonnAdj>0?'+':'')+t.tonnAdj+')':'')+' · ':''}${money(tripPay(t))}${t.photos&&t.photos.length?' · 📷'+t.photos.length:''} <span class="tag" style="cursor:pointer" onclick="event.stopPropagation(); openTripDetail(${t.id})">OPEN</span>`})),
  ].sort((a,b)=>b.when.localeCompare(a.when));
  openSheet(sheetTitle(esc(c.name)) + `
    <div class="muted"><span class="tag ${c.type}">${c.type.toUpperCase()}</span>
      ${c.salesRep?` <span class="tag vessel">💼 Salesperson: ${esc(c.salesRep)}</span>`:''}</div>
    <label class="f">YARDS / ADDRESSES</label>
    ${(c.sites||[]).map(s=>`<div class="muted">📍 ${esc(s.label)}${s.label?' — ':''}${esc(s.addr)}</div>`).join('') || '<div class="muted">None on file</div>'}
    <label class="f">CONTACT PERSONS</label>
    ${(c.contacts||[]).map(p=>`<div class="muted">👤 ${esc(p.name)}${p.phone?' · '+esc(p.phone):''}</div>`).join('') || '<div class="muted">None on file</div>'}
    <div class="kpis" style="margin-top:12px">
      <div class="kpi amber" style="box-shadow:none; background:var(--bg)"><div class="num">${binsOn.length}</div><div class="lbl">BINS ON SITE</div></div>
      <div class="kpi green" style="box-shadow:none; background:var(--bg)"><div class="num">${money(billable)}</div><div class="lbl">TRIP VALUE (${tr.length} TRIPS)</div></div>
      <div class="kpi blue" style="box-shadow:none; background:var(--bg)"><div class="num">${Math.round(tonnage*100)/100}</div><div class="lbl">TOTAL TONNAGE (ADJUSTED)</div></div>
      <div class="kpi" style="box-shadow:none; background:var(--bg)"><div class="num" style="font-size:15px; padding-top:6px"><button class="btn ghost slim" onclick="doSearch='${esc(c.name.split(' ')[0])}'; openDOArchive()">📁 DO photos</button></div><div class="lbl">ARCHIVE</div></div>
    </div>
    ${binsOn.length?`<label class="f">BINS ON SITE</label><div class="row" style="flex-wrap:wrap">${binsOn.map(b=>
      `<button class="bin-cell b-client" style="width:64px" onclick="closeSheet(); openBinDetail('${b.no}')">${b.no}<small>${b.size}</small></button>`).join('')}</div>`:''}
    <label class="f">HISTORY</label>
    <div>${timeline.map(x=>`<div class="item"><div class="grow"><div class="sub" style="font-size:12.5px">${x.html}</div></div></div>`).join('') || '<div class="empty">No history yet.</div>'}</div>
    <div class="row" style="margin-top:14px">
      ${cContact(c,0) && cContact(c,0).phone?`<a href="https://wa.me/65${esc(cContact(c,0).phone)}" target="_blank" style="text-decoration:none; flex:1"><button class="btn wa">💬 WhatsApp</button></a>`:''}
      <button class="btn" onclick="closeSheet(); openJobForm('${c.id}')">＋ Assign job</button>
    </div>`);
}
function openClientForm(){
  openSheet(sheetTitle('Add client') + `
    <label class="f">COMPANY NAME</label><input type="text" id="cf-name" placeholder="Company Pte Ltd">
    <label class="f">YARD LABEL + ADDRESS <span style="font-weight:600">(add more yards via import or later)</span></label>
    <div class="grid2">
      <input type="text" id="cf-sitelabel" placeholder="Main yard">
      <input type="text" id="cf-addr" placeholder="Street, Singapore">
    </div>
    <div class="grid2">
      <div><label class="f">CONTACT PERSON</label><input type="text" id="cf-contact"></div>
      <div><label class="f">PHONE (SG)</label><input type="text" id="cf-phone" placeholder="8xxxxxxx"></div>
    </div>
    <label class="f">SALESPERSON (FOR COMMISSION)</label>
    <select id="cf-sales"><option value="">— none —</option>${SALES.map(s=>`<option>${s}</option>`).join('')}</select>
    <label class="f">TYPE</label>
    <div class="seg" id="cf-type">
      <button class="on" data-v="land">Land (company)</button>
      <button data-v="vessel" onclick="segPick(this,'#cf-type')">Vessel (ship)</button>
    </div>
    <div style="margin-top:16px"><button class="btn" onclick="saveClient()">Add client</button></div>`);
  $$('#cf-type button')[0].onclick = function(){ segPick(this, '#cf-type'); };
}
async function saveClient(){
  const name = $('#cf-name').value.trim();
  if(!name){ toast('Enter the company name'); return; }
  const contact = $('#cf-contact').value.trim();
  const phone = $('#cf-phone').value.trim().replace(/\D/g,'');
  const c = {
    id:'c'+Date.now().toString(36), name,
    type: $('#cf-type .on').dataset.v,
    salesRep: $('#cf-sales').value,
    sites: [{label: $('#cf-sitelabel').value.trim() || 'Main', addr: $('#cf-addr').value.trim()}],
    contacts: (contact||phone) ? [{name:contact, phone}] : [],
  };
  closeSheet();
  await api('addClient', {client:c});
  render();
  toast(name+' added to CRM');
}

/* ---------------- client import (Excel CSV / Google Sheets) ----------------
   One row per client+address+contact combination; rows with the same client
   name merge into one client with multiple yards and contacts. */
function parseCSV(text){
  const rows = []; let row = [], cur = '', inQ = false;
  for(let i=0; i<text.length; i++){
    const ch = text[i];
    if(inQ){
      if(ch==='"'){ if(text[i+1]==='"'){ cur+='"'; i++; } else inQ = false; }
      else cur += ch;
    }
    else if(ch==='"') inQ = true;
    else if(ch===','){ row.push(cur); cur=''; }
    else if(ch==='\n' || ch==='\r'){
      if(ch==='\r' && text[i+1]==='\n') i++;
      row.push(cur); rows.push(row); row = []; cur = '';
    }
    else cur += ch;
  }
  if(cur !== '' || row.length){ row.push(cur); rows.push(row); }
  return rows.filter(r=>r.some(c=>c.trim() !== ''));
}
function applyClientRows(rows){
  if(rows.length < 2) throw new Error('No data rows found');
  const head = rows[0].map(h=>h.trim().toLowerCase());
  const col = name => head.indexOf(name);
  const iName = col('client'), iType = col('type'), iSales = col('salesperson'),
        iLbl = col('address label'), iAddr = col('address'),
        iCN = col('contact name'), iCP = col('contact phone');
  if(iName < 0 || iAddr < 0) throw new Error('CSV needs at least "Client" and "Address" columns');
  let created = 0, merged = 0;
  rows.slice(1).forEach(r=>{
    const name = (r[iName]||'').trim(); if(!name) return;
    let c = S.clients.find(x=>x.name.toLowerCase() === name.toLowerCase());
    if(!c){
      c = {id:'c'+Date.now().toString(36)+Math.random().toString(36).slice(2,5), name,
           type:'land', salesRep:'', sites:[], contacts:[]};
      S.clients.push(c); created++;
    }else merged++;
    if(iType>=0 && (r[iType]||'').trim()) c.type = /vessel/i.test(r[iType]) ? 'vessel' : 'land';
    if(iSales>=0 && (r[iSales]||'').trim()) c.salesRep = r[iSales].trim();
    const addr = (r[iAddr]||'').trim();
    if(addr && !c.sites.some(s=>s.addr.toLowerCase()===addr.toLowerCase()))
      c.sites.push({label:(iLbl>=0 && r[iLbl]||'').trim() || 'Yard '+(c.sites.length+1), addr});
    const cn = (iCN>=0 && r[iCN]||'').trim(), cp = ((iCP>=0 && r[iCP]||'')+'').replace(/\D/g,'');
    if((cn||cp) && !c.contacts.some(p=>p.name.toLowerCase()===cn.toLowerCase() && p.phone===cp))
      c.contacts.push({name:cn, phone:cp});
  });
  persist(); render();
  if(remoteReady) api('replaceClients', {clients:S.clients}).catch(()=>{});
  return {created, mergedRows: merged};
}
function importClientsCSV(file){
  if(!file) return;
  const fr = new FileReader();
  fr.onload = ()=>{
    try{
      const res = applyClientRows(parseCSV(fr.result));
      closeSheet();
      toast(`✅ Imported — ${res.created} new client${res.created===1?'':'s'}, ${res.mergedRows} row${res.mergedRows===1?'':'s'} merged into existing`);
    }catch(e){ toast('⚠️ ' + e.message); }
  };
  fr.readAsText(file);
}
async function importFromSheet(){
  let url = ($('#gs-url').value||'').trim();
  if(!url){ toast('Paste the Google Sheet link first'); return; }
  /* normal share links → CSV export endpoint */
  const m = url.match(/docs\.google\.com\/spreadsheets\/d\/([\w-]+)/);
  if(m && !/format=csv|output=csv/.test(url)) url = `https://docs.google.com/spreadsheets/d/${m[1]}/export?format=csv`;
  try{
    const res = await fetch(url);
    if(!res.ok) throw new Error('Sheet not reachable — is it shared as "Anyone with the link" or published to web?');
    const out = applyClientRows(parseCSV(await res.text()));
    closeSheet();
    toast(`✅ Imported from Google Sheet — ${out.created} new, ${out.mergedRows} merged`);
  }catch(e){ toast('⚠️ ' + (e.message || 'Could not fetch that sheet')); }
}
function downloadTemplate(){
  downloadCSV('lirich-clients-template.csv', [
    ['Client','Type','Salesperson','Address Label','Address','Contact Name','Contact Phone'],
    ['Eng Lee Logistics Pte Ltd','land','Patrick','Gul Circle yard','9 Gul Circle','Jacky','84118884'],
    ['Eng Lee Logistics Pte Ltd','land','Patrick','Tuas yard','15 Tuas Ave 8','Mei Ling','91234567'],
    ['New Client Pte Ltd','land','Marcus','Main','1 Example Road','Contact Person','81234567'],
  ]);
  toast('Template downloaded — fill it in Excel or Google Sheets');
}
function openImportSheet(){
  openSheet(sheetTitle('Import clients from Excel / Google Sheets') + `
    <p class="muted">One row per address + contact combination. Rows with the same client name
    merge into a single client with multiple yards and contact persons. Re-importing updates
    existing clients instead of duplicating them.</p>
    <button class="btn ghost" onclick="downloadTemplate()">📄 Download CSV template</button>
    <label class="f">UPLOAD CSV (EXCEL: SAVE AS → CSV · SHEETS: FILE → DOWNLOAD → CSV)</label>
    <input type="file" accept=".csv,text/csv" onchange="importClientsCSV(this.files[0])">
    <label class="f">OR PASTE A GOOGLE SHEET LINK (SHARED: ANYONE WITH THE LINK)</label>
    <input type="text" id="gs-url" placeholder="https://docs.google.com/spreadsheets/…">
    <div style="margin-top:10px"><button class="btn" onclick="importFromSheet()">🔗 Fetch from Google Sheet</button></div>`);
}

/* ============================================================
   DRIVER · MY PAY
   ============================================================ */
function daysAgoStr(n){
  const d = new Date(); d.setDate(d.getDate()-n);
  return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');
}
function vMyPay(){
  const d = driver(S.role.driverId);
  const all = driverTrips(d.id);
  const today = all.filter(t=>t.date===TODAY);
  const wk = daysAgoStr(6), mo = daysAgoStr(29);
  const week = all.filter(t=>t.date>=wk);
  const last30 = all.filter(t=>t.date>=mo);
  const byDate = {};
  last30.forEach(t=>{ (byDate[t.date] = byDate[t.date]||[]).push(t); });
  const dates = Object.keys(byDate).sort().reverse();
  $('#main').innerHTML = `
    <div class="hero">
      <div class="lbl">MY PAY TODAY — ${esc(d.name).toUpperCase()}</div>
      <div class="num">${money(payOf(today))}</div>
      <div class="lbl">${today.length} trip${today.length===1?'':'s'} today</div>
    </div>
    <div class="kpis">
      <div class="kpi green"><div class="num">${money(payOf(week))}</div><div class="lbl">THIS WEEK (7 DAYS) · ${week.length} TRIP${week.length===1?'':'S'}</div></div>
      <div class="kpi blue"><div class="num">${money(payOf(last30))}</div><div class="lbl">LAST 30 DAYS · ${last30.length} TRIP${last30.length===1?'':'S'}</div></div>
    </div>
    <h2 style="margin:6px 2px 10px; font-size:16px">📅 Last 30 days</h2>
    ${dates.map(date=>`
      <div class="card">
        <h2>${fmtDate(date)} <span class="muted" style="font-weight:700; margin-left:auto">${money(payOf(byDate[date]))}</span></h2>
        ${byDate[date].map(t=>{
          const c = client(t.clientId);
          return `<div class="item tap" onclick="openTripDetail(${t.id})">
            <div class="grow"><div class="title" style="font-size:12.5px">${esc(c?c.name:'?')} · ${doLabel(t)}</div>
            <div class="sub">${esc(t.jobType || (ttype(t.typeId)||{}).label || '')}${(t.surcharges||[]).length?' · +'+t.surcharges.length+' charge(s)':''}</div></div>
            <div class="pay">${money(tripPay(t))}</div></div>`;
        }).join('')}
      </div>`).join('') || '<div class="card empty">No trips in the last 30 days.</div>'}
    <div class="card">
      <h2>💵 Extra charge rates</h2>
      <table class="jt"><tbody>${SURCHARGES.map(s=>`<tr><td>${esc(s.label)}</td><td style="text-align:right"><b>+${money(s.amt)}</b></td></tr>`).join('')}</tbody></table>
    </div>`;
}

/* ---------------- demo DO photo (so the archive isn't empty) ----------------
   Draws a fake scanned Delivery Order for the seed trip (Kumar/Radha, DO 24119)
   and stores it in PhotoDB. Also a handy OCR test target. */
async function seedDemoPhoto(){
  try{
    if(await PhotoDB.get('p-demo-24119')) return;
    const cv = document.createElement('canvas'); cv.width = 800; cv.height = 1000;
    const ctx = cv.getContext('2d');
    ctx.fillStyle = '#fdfcf8'; ctx.fillRect(0,0,800,1000);
    ctx.fillStyle = '#111'; ctx.font = 'bold 34px Arial';
    ctx.fillText('RADHA EXPORTS PTE LTD', 60, 90);
    ctx.font = '22px Arial';
    ctx.fillText('118 Pioneer Rd L1, Singapore', 60, 128);
    ctx.font = 'bold 30px Arial';
    ctx.fillText('DELIVERY ORDER  No: 24119', 60, 200);
    ctx.font = '26px Arial';
    ['Date: 30/06/2026','','Bin Out: R08        Bin In: 7022','Waste: General',
     'Time In: 09:10     Time Out: 10:05','Dispose To: WDL','',
     'WEIGHING TICKET LR23141','Gross: 17,970 kg','Tare: 15,770 kg','Net: 2,200 kg','',
     'Driver: Kumar   Truck: XE5876P','','Received by: ____________________']
      .forEach((l,i)=>ctx.fillText(l, 60, 260+i*44));
    const full = cv.toDataURL('image/jpeg', .9);
    const tcv = document.createElement('canvas'); tcv.width = 180; tcv.height = 225;
    tcv.getContext('2d').drawImage(cv, 0, 0, 180, 225);
    const thumb = tcv.toDataURL('image/jpeg', .7);
    await PhotoDB.put({id:'p-demo-24119', full, thumb, tripId:1, doNo:24119,
      clientId:'c2', driverId:3, date:TODAY, createdAt:1});
    const t1 = S.trips.find(t=>t.doNo===24119);
    if(t1 && !t1.photos.length){ t1.photos = [{id:'p-demo-24119', thumb}]; persist(); }
  }catch(e){ /* photo demo is best-effort */ }
}

/* ---------------- boot ---------------- */
/* personal driver links (?u=d1 … ?u=d5) lock this device to that driver;
   the lock is remembered so it survives Add to Home Screen */
try{
  const uParam = new URLSearchParams(location.search).get('u');
  if(uParam && USERS.some(x=>x.id===uParam && x.role==='driver')){
    S.settings.lockUser = uParam;
    persist();
  }
}catch(e){}
/* never boot into an operator preview — start clean */
if(S.viewAs){ delete S.viewAs; if(S.auth && S.auth.userId==='op') S.role={kind:'operator',driverId:null}; persist(); }
render();
bootRemote();                       /* connect to the central database */
fetchSheetDB();                     /* dropdown options from "Customer DB" tab */
setInterval(pollRemote, 25000);     /* pick up other devices' changes */
window.addEventListener('online', ()=>{ toast('Back online — syncing'); bootRemote(); });
