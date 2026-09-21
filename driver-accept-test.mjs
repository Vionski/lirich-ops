import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('./app.js', import.meta.url), 'utf8');
const section = (start, end) => source.slice(source.indexOf(start), source.indexOf(end, source.indexOf(start)));
const job = {id:785, clientId:'missing-client', siteIdx:0, driverId:5, status:'assigned',
  date:'2026-09-21', jobType:'Exchange', binSize:'5 ft', waste:'General Waste',
  _client:'Eng Leng Contractors Pte Ltd', _addr:'8 Buroh Street'};
let form = '';
const context = vm.createContext({
  S:{jobs:[job], trips:[], clients:[{id:job.clientId, name:job._client, type:'land',
    sites:[{addr:job._addr}]}], role:{kind:'driver', driverId:5}},
  tripPhotos:[], existingTripPhotos:[],
  client:id=>context.S.clients.find(c=>c.id===id),
  jobById:id=>context.S.jobs.find(j=>j.id===id),
  jobFlow:()=>({photos:[{k:'do',label:'DO photo',hint:'required',req:true}], bins:[], noDO:false}),
  esc:s=>String(s??''), cSite:(c,i)=>c?.sites?.[i] || c?.sites?.[0] || {addr:''},
  fmtDate:s=>s, lastVehicleForDriver:()=>'', wasteChecksHTML:()=>'', signaturePadHTML:()=>'',
  sheetTitle:s=>s, openSheet:s=>{form=s;}, updateTimesDisplay:()=>{},
  renderFormThumbs:()=>{}, sigPadInit:()=>{}, closeSheet:()=>{}, render:()=>{}, toast:()=>{},
  fmtTime12:()=>'',
  api:async()=>{context.S.clients=[]; job.status='in_progress';},
});
vm.runInContext(section('function clientForJob(', 'function driver(')
  + section('async function acceptJob(', 'function fmtTime12(')
  + section('function openTripForm(', 'function tfClientChanged('), context);

await vm.runInContext('acceptJob(785)', context);
assert.equal(job.status, 'in_progress');
assert.match(form, /Job — e-DO/);
assert.match(form, /Eng Leng Contractors Pte Ltd/);
assert.match(form, /8 Buroh Street/);
assert.match(form, /id="tf-photo-do"/);
assert.doesNotMatch(form, /Add a job/);
console.log('Driver accept opens e-DO with DO photo even if the server response omits the CRM client');
