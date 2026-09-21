import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import vm from 'node:vm';

const source = readFileSync(new URL('./app.js', import.meta.url), 'utf8');
const section = (start, end) => source.slice(source.indexOf(start), source.indexOf(end, source.indexOf(start)));
const jobs = [
  {id:784, driverId:5, status:'assigned', _client:'Older job'},
  {id:785, driverId:5, status:'assigned', clientId:'eng-leng',
    _client:'Eng Leng Contractors Pte Ltd', _addr:'8 Buroh Street', jobType:'Exchange'},
];
let opened = null;
const ctx = vm.createContext({
  S:{role:{kind:'driver',driverId:6}, jobs, trips:[], clients:[]}, TODAY:'2026-09-21',
  isTestDriver:id=>Number(id)===6, closeSheet:()=>{}, render:()=>{}, toast:()=>{},
  openTripForm:opts=>{opened=opts.jobId;},
  $:sel=>({value:sel==='#tf-job'?'-1':''}),
  tripPhotos:[],
});
vm.runInContext(section('let TEST_JOB = null', '/* ---------------- helpers')
  + section('function driverJobs(', 'function payOf(')
  + section('async function acceptJob(', 'function fmtTime12(')
  + section('async function saveTripInner(', 'function doLabel(')
  + section('async function api(', 'let remoteReady'), ctx);

assert.equal(vm.runInContext('driverJobs(6)[0]._client', ctx), 'Eng Leng Contractors Pte Ltd');
assert.equal(vm.runInContext('driverJobs(6)[0].id', ctx), -1);
assert.equal(jobs.length, 2);
await vm.runInContext('acceptJob(-1)', ctx);
assert.equal(opened, -1);
assert.equal(vm.runInContext('TEST_JOB.status', ctx), 'in_progress');
await assert.rejects(vm.runInContext("api('addTrip', {})", ctx), /test driver database write blocked/);

ctx.tripPhotos = [{id:'photo1', kind:'do', full:'data:image/jpeg;base64,AAAA', thumb:'thumb1'}];
await vm.runInContext('saveTripInner(false)', ctx);
assert.equal(vm.runInContext('TEST_TRIP.photos.length', ctx), 1);
assert.equal(vm.runInContext('TEST_JOB.status', ctx), 'in_progress');
ctx.tripPhotos = [{id:'photo2', kind:'in', full:'data:image/jpeg;base64,BBBB', thumb:'thumb2'}];
await vm.runInContext('saveTripInner(true)', ctx);
assert.equal(vm.runInContext('TEST_TRIP.photos.length', ctx), 2);
assert.equal(vm.runInContext('TEST_JOB.status', ctx), 'done');
assert.equal(jobs.length, 2);
assert.equal(ctx.S.trips.length, 0);
console.log('Test Driver job and photos stay out of shared jobs, trips, and API writes');
