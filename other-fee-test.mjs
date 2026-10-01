import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('./app.js', import.meta.url), 'utf8');
const paySection = source.slice(source.indexOf('function tripPay('), source.indexOf('function jobTypeOptions('))
  + source.slice(source.indexOf('function jobTypeLabel('), source.indexOf('function seed()'));
const payContext = vm.createContext({
  SURCHARGES:[{id:'after7',label:'After 7pm',amt:8}],
  TRIP_TYPES:[{id:'col_m',label:'Collection',base:20}],
  money:n=>'$'+(Number(n)||0).toFixed(2),
});
vm.runInContext(paySection+';globalThis.tripPay=tripPay;globalThis.jobPay=jobPay;globalThis.surchargeSummary=surchargeSummary;', payContext);
assert.equal(payContext.jobPay({price:40,surcharges:['after7'],otherFeeAmount:3.25}), 51.25);
assert.equal(payContext.tripPay({price:40,surcharges:['after7'],otherFeeAmount:3.25}), 51.25);
assert.equal(payContext.surchargeSummary({surcharges:['after7'],otherFeeReason:'Special lift',otherFeeAmount:3.25}), 'After 7pm; Special lift (+$3.25)');

const formStart=source.indexOf('function openJobForm('), formEnd=source.indexOf('/* live-refresh the pulldowns',formStart);
const formSource=source.slice(formStart,formEnd);
function buildJobForm(role){
  let html='';
  const client={id:'c1',name:'Example Client'};
  const context=vm.createContext({
    S:{role:{kind:role,driverId:1},clients:[client],jobs:[]},
    SURCHARGES:[{id:'after7',label:'After 7pm',amt:8}],
    money:n=>'$'+(Number(n)||0).toFixed(2),
    TODAY:'2026-10-01', JF_PENDING:null,
    $:()=>null,
    isTestMode:()=>false, client:id=>id==='c1'?client:null, pickableClients:()=>[client], esc:s=>String(s??''),
    sheetTitle:s=>s, openSheet:s=>{html=s;},
    jobTypeOptions:()=>'<option value="Collect">Collect</option>', driverSelectOptions:()=>'<option value="1">Driver</option>',
    binOptions:()=>['5 ft'], wasteOptions:()=>['General Waste'], selOpts:()=>'<option>General Waste</option>',
    dumpSelectHTML:()=>'', isLirichClient:()=>false, jfClientChanged:()=>{}, jfOtherFeeToggled:()=>{}, refreshJobFormOptions:()=>{},
  });
  vm.runInContext(formSource,context);
  vm.runInContext("openJobForm('c1')",context);
  return html;
}
assert.match(buildJobForm('operator'), /id="jf-other"/);
assert.match(buildJobForm('operator'), /id="jf-other-reason"/);
assert.match(buildJobForm('operator'), /id="jf-other-amount"/);
assert.doesNotMatch(buildJobForm('driver'), /id="jf-other"|id="jf-other-reason"|id="jf-other-amount"/);
console.log('Other fee is operator-only and included in job/trip pay calculations');
