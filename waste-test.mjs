const esc = s => String(s??'').replace(/[&<>"']/g, c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const WASTE_TYPES = ['General Waste','Wood Waste','Plastic Waste','Metal Waste','Mixed Waste','Food Waste'];
function wasteChecksHTML(prefix, selected, otherText){
  const selWords = (selected||[]).map(s=>String(s).toLowerCase().split(' ')[0]);
  return `<div id="${prefix}-waste">
    ${WASTE_TYPES.map(w=>`<label class="checkline"><input type="checkbox" value="${esc(w)}" ${selWords.includes(w.toLowerCase().split(' ')[0])?'checked':''}> ${esc(w)}</label>`).join('')}
    <label class="checkline"><input type="checkbox" id="${prefix}-waste-other-cb" value="__other__" onchange="toggleWasteOther('${prefix}')" ${otherText?'checked':''}> Others</label>
    <input type="text" id="${prefix}-waste-other" placeholder="Specify other waste" value="${esc(otherText||'')}" style="display:${otherText?'block':'none'}; margin-top:6px">
  </div>`;
}
// Test 1: pre-check from job.waste = "General" (single word, from saveJob default)
const h1 = wasteChecksHTML('tf', ['General'], '');
const generalChecked = /value="General Waste" checked/.test(h1);
const woodChecked = /value="Wood Waste" checked/.test(h1);
// Test 2: pre-check from "Wood Waste" (full label)
const h2 = wasteChecksHTML('tf', ['Wood Waste'], '');
const woodChecked2 = /value="Wood Waste" checked/.test(h2);
// Test 3: Others with text -> checkbox checked + input visible
const h3 = wasteChecksHTML('te', [], 'Concrete slurry');
const otherChecked = /id="te-waste-other-cb" value="__other__" onchange="toggleWasteOther\('te'\)" checked/.test(h3);
const otherVisible = /display:block/.test(h3);
const otherValue = /value="Concrete slurry"/.test(h3);
// Test 4: multi-select from array
const h4 = wasteChecksHTML('tf', ['General Waste','Metal Waste'], '');
const multiGeneral = /value="General Waste" checked/.test(h4);
const multiMetal = /value="Metal Waste" checked/.test(h4);
const mixedNotChecked = !/value="Mixed Waste" checked/.test(h4);

console.log(JSON.stringify({
  test1_general_from_single_word: generalChecked, test1_wood_not: !woodChecked,
  test2_wood_full_label: woodChecked2,
  test3_other_checked: otherChecked, test3_other_visible: otherVisible, test3_other_value: otherValue,
  test4_multi_general: multiGeneral, test4_multi_metal: multiMetal, test4_mixed_unchecked: mixedNotChecked,
}, null, 2));
