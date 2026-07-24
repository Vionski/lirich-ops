// Simulate readWasteChecks with a stub DOM
function makeReader(state){
  // state = {checkedValues:[...], otherChecked:bool, otherText:''}
  const $$ = sel => state.checkedValues.map(v=>({value:v})); // all checked checkboxes in the group
  const $ = sel => {
    if(sel.endsWith('-waste-other-cb')) return {checked: state.otherChecked};
    if(sel.endsWith('-waste-other')) return {value: state.otherText};
    if(sel.endsWith('-waste')) return {}; // box exists
    return null;
  };
  return function readWasteChecks(prefix){
    const box=$('#'+prefix+'-waste'); if(!box) return null;
    const types=$$('#'+prefix+'-waste input[type=checkbox]:checked').map(i=>i.value).filter(v=>v && v!=='__other__');
    const ocb=$('#'+prefix+'-waste-other-cb');
    const other=(ocb && ocb.checked) ? ((($('#'+prefix+'-waste-other')||{}).value)||'').trim() : '';
    const display=[...types, other?('Others: '+other):''].filter(Boolean).join('; ');
    return {types, other, display};
  };
}
// Case A: two std types, no other
let r = makeReader({checkedValues:['General Waste','Metal Waste'], otherChecked:false, otherText:'xyz'})('tf');
// Case B: one std + others with text (note __other__ is in checkedValues because the Others cb is checked)
let r2 = makeReader({checkedValues:['Wood Waste','__other__'], otherChecked:true, otherText:'  Concrete slurry '})('tf');
// Case C: nothing checked
let r3 = makeReader({checkedValues:[], otherChecked:false, otherText:''})('tf');
console.log(JSON.stringify({
  A: r,   // expect types [General,Metal], other '', display "General Waste; Metal Waste"
  B: r2,  // expect types [Wood], other 'Concrete slurry' (trimmed), display "Wood Waste; Others: Concrete slurry"
  C: r3,  // expect types [], other '', display ''
}, null, 2));
