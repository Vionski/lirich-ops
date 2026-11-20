/* =====================================================================================
   LIRICH LEARN — SHARED RULES
   The single source of truth for sorting rules, streams, item masses and CO2e factors.

   WHY THIS FILE EXISTS
   The games roadmap flagged the risk in one line: "Content accuracy multiplies. Every
   game repeats the same sorting rules. One wrong rule now appears in nine places."
   Before this file, the rules were duplicated across Sort It!, Bin or Not?, On Route
   and Pick Line. Change a ruling here and it changes everywhere, once.

   RULE FOR ANYONE EDITING
   Do not add or change an item without checking it against the current NEA list below.
   A rule taught wrong at scale is worse than no game.

   SOURCE
   List of items that are recyclable and not — National Environment Agency
   https://www.nea.gov.sg/docs/default-source/our-services/waste-management/list-of-items-that-are-recyclable-and-not.pdf
   Rulings in this file were taken from that list on 13 August 2026.
   Nothing here claims NEA approval, compliance or certification. It cites the list.

   LOADING
   Plain classic script, no modules, no build step. It must load this way so the games
   keep working by double-clicking the HTML from a folder or a USB stick — ES modules
   are blocked by the browser over file://, a classic script is not.
   Include it BEFORE the game's own script:
       <script src="lirich-rules.js"></script>
   ===================================================================================== */
"use strict";
(function (root) {

  /* ---- PROVENANCE -------------------------------------------------------------- */
  var META = {
    version: '1.1',
    rulesCheckedOn: '2026-08-13',
    /* A second reading of the same published NEA list was taken on 18 Sep 2026, which
       added 24 items (74 in total). It also produced ONE disagreement with the August
       reading — the drinking straw — which is recorded under CONFLICTS below and has
       deliberately NOT been auto-resolved. Both dates are kept because a single
       "last checked" date would hide the fact that the two reads disagreed. */
    rulesRecheckedOn: '2026-10-05',
    rulesSource: 'NEA — List of items that are recyclable and not',
    rulesSourceUrl: 'https://www.nea.gov.sg/docs/default-source/our-services/waste-management/list-of-items-that-are-recyclable-and-not.pdf',

    /* ⚠ THE ONE FLAG THAT MATTERS.
       Masses and CO2e below are assumed demonstration figures, not Lirich's.
       When Lirich's SEFR-derived factors and weighed densities go in, set this to
       'LIRICH' and update factorsBasis. Every game reads this to decide what its
       footer says, so the disclaimer cannot be forgotten in one file and not another. */
    factorsStatus: 'INDICATIVE',
    factorsBasis: 'Assumed unit masses and avoided-emissions figures for demonstration only. ' +
                  'Do not present as measured environmental impact. Replace with approved Lirich factors before reporting impact.'
  };

  /* ---- CONFLICTS THIS FILE RESOLVED ------------------------------------------------
     Consolidating four copies of the rules exposed two places where the same thing was
     stated two different ways. Both are recorded here rather than quietly fixed, so the
     change is reviewable and can be reversed if the other value was the right one.

     1. STREAM COLOURS. Sort It! drew plastic #3E86D8, metal #9AA6B5 and glass #4FA37A.
        On Route and Pick Line drew the same three streams #4E86C8, #8C93A0 and #3FA46B.
        The same stream rendered two ways inside one set of games.
        RESOLVED to the On Route / Pick Line values, which two games already shared.

     2. DRINKING STRAW — WAS AN OPEN CONFLICT. CLOSED 18 Sep 2026, RULING UNCHANGED.
        The games treat a straw as NOT recyclable, recorded from NEA's list on 13 Aug
        2026. One automated re-read of the same published list on 18 Sep 2026 placed
        "Drinking straw" under RECYCLABLE plastics, which raised the conflict. Three
        further checks the same day all point the other way:

          (a) A second read of the same PDF placed item 43, "PLASTIC DRINKING STRAW",
              in the column headed CANNOT BE PLACED IN THE BLUE RECYCLING BINS.
          (b) The numbering settles it structurally. In that summary table the plastics
              run 31-38 in the CAN column and 39-46 in the CANNOT column. Items 39, 40,
              41, 42, 44, 45 and 46 are all agreed to be CANNOT. Item 43 sits inside
              that block, so it belongs to the same column as its neighbours.
          (c) A DIFFERENT NEA document — the Recycling Guide — independently lists
              "DRINKING STRAW" under items that cannot go in the blue bin.

        DIAGNOSIS: the disagreement was almost certainly a column mis-assignment when
        reading a two-column table, not a change in NEA's position. Nothing was wrong
        with the ruling in this file.

        The straw therefore REMAINS a blocker, on the evidence rather than by default.
        → Residual check for anyone who wants certainty rather than corroboration: open
          the PDF, find item 43 in the summary table, and confirm which column it is in.
          If it is in the CAN column, change ok:0 to ok:1 HERE and it corrects in every
          game at once. That is what this file is for.
        → The wider lesson is kept on purpose: a single automated read of a table is not
          evidence. Two independent documents, or a structural argument, or a person.

     3. FOOD WASTE MASS. Sort It! assumed 0.20 kg. Bin or Not? assumed 0.30 kg.
        RESOLVED to 0.30 kg, from the Bin or Not? deck — the larger and later-checked
        list. Sort It! scores will read marginally higher than before for food tiles.
        ⚠ Both figures are indicative either way. This is settled properly when Lirich's
        weighed figures replace the placeholders, not by choosing between two guesses.
     -------------------------------------------------------------------------------- */

  /* ---- STREAMS ------------------------------------------------------------------
     One colour per stream across the whole basket. Before this file, Sort It! used a
     different blue for plastic, a different grey for metal and a different green for
     glass than On Route and Pick Line did — the same stream rendered three ways in
     one set of games. These are now the canonical values.                          */
  var STREAMS = {
    paper   : { key:'paper',   name:'Paper',    colour:'#C08A4A', bin:'blue'    },
    plastic : { key:'plastic', name:'Plastic',  colour:'#4E86C8', bin:'blue'    },
    metal   : { key:'metal',   name:'Metal',    colour:'#8C93A0', bin:'blue'    },
    glass   : { key:'glass',   name:'Glass',    colour:'#3FA46B', bin:'blue'    },
    food    : { key:'food',    name:'Digester', colour:'#8E9C3F', bin:'digester'},
    ewaste  : { key:'ewaste',  name:'E-waste',  colour:'#8C6BB1', bin:'scheme'  },
    general : { key:'general', name:'General',  colour:'#5A6376', bin:'general' },
    reject  : { key:'reject',  name:'Reject',   colour:'#C0455F', bin:'general' }
  };

  /* ---- THE MASTER LIST -----------------------------------------------------------
     Every item any game uses, ruled once.
       name  display name
       ok    1 = goes in the blue bin, 0 = does not
       s     stream key (see STREAMS). Items with ok:0 carry the stream they are
             mistaken for, which is what makes them teachable, and sort to 'reject'
             in games that need a reject lane.
       g     glyph group — which shape the drawing routines use
       kg    assumed unit mass, kilograms          ⚠ INDICATIVE
       co2   assumed kgCO2e avoided vs disposal    ⚠ INDICATIVE, null where not modelled
       rule  the ruling, in the words used on screen
       tag   optional grouping used by individual games                             */
  var ITEMS = [

    /* ---------- YES — blue bin ---------- */
    { name:'Newspaper',             ok:1, s:'paper',   g:'paper',  kg:0.20,  co2:null, rule:'Printed paper of all kinds goes in. Flatten it first.' },
    { name:'Cardboard box',         ok:1, s:'paper',   g:'box',    kg:0.30,  co2:0.22, rule:'Carton and cardboard boxes are recyclable — flatten them.' },
    { name:'Egg tray',              ok:1, s:'paper',   g:'box',    kg:0.05,  co2:null, rule:'Egg trays are on the recyclable paper list.' },
    { name:'Beverage carton',       ok:1, s:'paper',   g:'box',    kg:0.03,  co2:null, rule:'Drink cartons are recyclable. Empty and rinse first.' },
    { name:'Paper towel tube',      ok:1, s:'paper',   g:'paper',  kg:0.01,  co2:null, rule:'The tube is recyclable. The towel itself is not.' },
    { name:'Envelope',              ok:1, s:'paper',   g:'paper',  kg:0.005, co2:null, rule:'Envelopes are recyclable, windows and all.' },
    { name:'Magazine',              ok:1, s:'paper',   g:'paper',  kg:0.25,  co2:null, rule:'Magazines and brochures are recyclable.' },
    { name:'Tissue box',            ok:1, s:'paper',   g:'box',    kg:0.03,  co2:null, rule:'The box is recyclable. The tissues are not.' },

    { name:'PET bottle',            ok:1, s:'plastic', g:'bottle', kg:0.03,  co2:0.05, rule:'Empty and rinse. One of the easiest wins there is.' },
    { name:'Shampoo bottle',        ok:1, s:'plastic', g:'bottle', kg:0.06,  co2:null, rule:'Empty and rinse, then in it goes.' },
    { name:'Bubble wrap',           ok:1, s:'plastic', g:'film',   kg:0.02,  co2:null, rule:'Surprising but true — plastic film and bubble wrap are recyclable here.' },
    { name:'Plastic film',          ok:1, s:'plastic', g:'film',   kg:0.01,  co2:null, rule:'Plastic film is on the recyclable list. Most people bin it.' },
    { name:'Ziplock bag',           ok:1, s:'plastic', g:'film',   kg:0.01,  co2:null, rule:'Recyclable, as long as it is clean and empty.' },
    { name:'Plastic clothes hanger',ok:1, s:'plastic', g:'other',  kg:0.05,  co2:null, rule:'Hangers are on the recyclable plastics list.' },
    { name:'Rinsed takeaway box',   ok:1, s:'plastic', g:'box',    kg:0.04,  co2:null, rule:'Recyclable only once it is empty and rinsed. Unrinsed, it is not.' },

    { name:'Drink can',             ok:1, s:'metal',   g:'can',    kg:0.015, co2:0.14, rule:'Aluminium cans are among the most valuable things in the bin.' },
    { name:'Food can',              ok:1, s:'metal',   g:'can',    kg:0.06,  co2:null, rule:'Empty and rinse. Then yes.' },
    { name:'Metal bottle cap',      ok:1, s:'metal',   g:'other',  kg:0.005, co2:null, rule:'Metal caps are recyclable.' },
    { name:'Empty aerosol can',     ok:1, s:'metal',   g:'can',    kg:0.05,  co2:null, rule:'Recyclable when completely empty.' },
    { name:'Clean aluminium foil',  ok:1, s:'metal',   g:'other',  kg:0.01,  co2:null, rule:'Clean foil yes. Greasy foil no — that is the whole difference.' },

    { name:'Glass bottle',          ok:1, s:'glass',   g:'bottle', kg:0.35,  co2:0.11, rule:'Rinse and recycle. Glass is endlessly recyclable.' },
    { name:'Glass jar',             ok:1, s:'glass',   g:'bottle', kg:0.25,  co2:null, rule:'Rinse and recycle.' },
    { name:'Drinking glass',        ok:1, s:'glass',   g:'glass',  kg:0.20,  co2:null, rule:'Ordinary glassware is recyclable — but Pyrex, tempered and crystal are not.' },

    { name:'Small e-waste',         ok:0, s:'ewaste',  g:'other',  kg:0.12,  co2:0.30, rule:'Small electronics route through the national e-waste scheme, not the blue bin.' },

    /* ---------- NO — general waste, or another channel ---------- */
    { name:'Pizza box',             ok:0, s:'paper',   g:'box',    kg:0.25,  co2:null, tag:'blocker',
      rule:'<b>Pizza boxes are not recyclable.</b> Food and oil soak into the cardboard, and NEA lists them under paper that cannot be recycled.' },
    { name:'Paper cup',             ok:0, s:'paper',   g:'cup',    kg:0.01,  co2:null, tag:'blocker',
      rule:'<b>Paper cups and plates are not recyclable</b> in Singapore, along with tissue paper and paper towels — even when they look clean.' },
    { name:'Styrofoam box',         ok:0, s:'plastic', g:'box',    kg:0.05,  co2:null, tag:'blocker',
      rule:'<b>Polystyrene foam and styrofoam are not recyclable.</b> They go into general waste, not the blue bin.' },
    { name:'Drinking straw',        ok:0, s:'plastic', g:'other',  kg:0.001, co2:null, tag:'blocker',
      rule:'<b>Drinking straws are not recyclable.</b> Neither are plastic packaging with foil, such as potato chip bags and blister packs.' },
    { name:'Oily tray',             ok:0, s:'metal',   g:'other',  kg:0.02,  co2:null, tag:'blocker',
      rule:'<b>Dirty aluminium foil and trays are not recyclable.</b> Clean ones are. Empty and rinse containers before they go in the bin.' },

    { name:'Tissue paper',          ok:0, s:'paper',   g:'paper',  kg:0.002, co2:null, rule:'Tissue, paper towels and toilet paper are all out.' },
    { name:'Paper plate',           ok:0, s:'paper',   g:'cup',    kg:0.01,  co2:null, rule:'Paper disposables are not recyclable.' },
    { name:'Wooden chopsticks',     ok:0, s:'general', g:'other',  kg:0.01,  co2:null, rule:'Disposable wooden chopsticks are not recyclable.' },
    { name:'Potato chip bag',       ok:0, s:'plastic', g:'film',   kg:0.01,  co2:null, rule:'Plastic packaging with foil layers cannot be recycled.' },
    { name:'Blister pack',          ok:0, s:'plastic', g:'other',  kg:0.01,  co2:null, rule:'Foil-and-plastic blister packs are not recyclable.' },
    { name:'Expired credit card',   ok:0, s:'plastic', g:'other',  kg:0.005, co2:null, rule:'Not recyclable — general waste.' },
    { name:'Melamine plate',        ok:0, s:'plastic', g:'other',  kg:0.15,  co2:null, rule:'Melamine products are not recyclable.' },
    { name:'Oily food container',   ok:0, s:'plastic', g:'box',    kg:0.04,  co2:null, rule:'Oil-stained plastic packaging is out. Rinse it and it would have been in.' },
    { name:'Pyrex dish',            ok:0, s:'glass',   g:'glass',  kg:0.40,  co2:null, rule:'Pyrex, borosilicate and oven-safe glass are not recyclable.' },
    { name:'Ceramic mug',           ok:0, s:'glass',   g:'glass',  kg:0.30,  co2:null, rule:'Ceramics are not recyclable — general waste.' },
    { name:'Mirror',                ok:0, s:'glass',   g:'glass',  kg:1.00,  co2:null, rule:'Mirrors, windows and glass with metal wires are all out.' },
    { name:'Light bulb',            ok:0, s:'ewaste',  g:'other',  kg:0.03,  co2:null, rule:'Not the blue bin — bulbs go through the e-waste channel.' },
    { name:'Rusty tin can',         ok:0, s:'metal',   g:'can',    kg:0.06,  co2:null, rule:'Rusty metal cans are not recyclable. Clean ones are.' },
    { name:'Dirty aluminium tray',  ok:0, s:'metal',   g:'other',  kg:0.02,  co2:null, rule:'Dirty foil and trays are out. Clean ones are in.' },
    { name:'Metal fork',            ok:0, s:'metal',   g:'other',  kg:0.04,  co2:null, rule:'Metal cutlery is not recyclable through the blue bin.' },
    { name:'Steel wool',            ok:0, s:'metal',   g:'other',  kg:0.02,  co2:null, rule:'Steel wool is not recyclable.' },
    { name:'Old T-shirt',           ok:0, s:'general', g:'other',  kg:0.15,  co2:null, rule:'Textiles are not blue-bin items. Donate them if they are still good.' },
    { name:'Food waste',            ok:0, s:'food',    g:'other',  kg:0.30,  co2:0.09, rule:'Food waste is not a blue-bin item — it needs its own stream.' },
    { name:'Used diaper',           ok:0, s:'general', g:'other',  kg:0.20,  co2:null, rule:'General waste, always.' },
    { name:'Leftover medicine',     ok:0, s:'general', g:'other',  kg:0.05,  co2:null, rule:'Not recyclable. Return unused medicine rather than binning it loose.' },
    { name:'Old refrigerator',      ok:0, s:'ewaste',  g:'other',  kg:60.0,  co2:null, rule:'Large appliances are regulated e-waste — they go through the national e-waste scheme, not the blue bin.' },
    /* ---------- added 18 Sep 2026, checked against the NEA list the same day ----------
       Singapore-specific items a class will recognise, and the surprises that teach
       most: a red packet is recyclable, a biodegradable bag is not.               */
    { name:'Red packet',            ok:1, s:'paper',   g:'paper',  kg:0.005, co2:null, rule:'Red packets are ordinary printed paper. Recyclable — but reuse them first.' },
    { name:'Paper bag',             ok:1, s:'paper',   g:'paper',  kg:0.03,  co2:null, rule:'Paper bags are recyclable. Flatten them.' },
    { name:'Shredded paper',        ok:1, s:'paper',   g:'paper',  kg:0.05,  co2:null, rule:'Shredded paper is on the recyclable list.' },
    { name:'Paper receipt',         ok:1, s:'paper',   g:'paper',  kg:0.002, co2:null, rule:'Receipts are recyclable paper.' },
    { name:'Greeting card',         ok:1, s:'paper',   g:'paper',  kg:0.02,  co2:null, rule:'Greeting cards and calendars are recyclable — the glittery ones are not.' },
    { name:'Gift wrapping paper',   ok:1, s:'paper',   g:'paper',  kg:0.02,  co2:null, rule:'Wrapping paper is recyclable. Glitter paper is not.' },

    { name:'Plastic bag',           ok:1, s:'plastic', g:'film',   kg:0.01,  co2:null, rule:'Plastic bags are recyclable here, along with bread bags and magazine wrappers.' },
    { name:'Bubble tea cup',        ok:1, s:'plastic', g:'cup',    kg:0.03,  co2:null, rule:'Plastic cups are recyclable once empty and rinsed — including the bubble tea one.' },
    { name:'Plastic cutlery',       ok:1, s:'plastic', g:'other',  kg:0.005, co2:null, rule:'Plastic cutlery and crockery are recyclable when clean. Most people bin them.' },
    { name:'CD or DVD',             ok:1, s:'plastic', g:'other',  kg:0.02,  co2:null, rule:'Discs and their cases are recyclable.' },
    { name:'Detergent bottle',      ok:1, s:'plastic', g:'bottle', kg:0.08,  co2:null, rule:'Detergent, soap and cleaner bottles go in — empty the contents first.' },

    { name:'Perfume bottle',        ok:1, s:'glass',   g:'bottle', kg:0.12,  co2:null, rule:'Cosmetic and perfume glass bottles are recyclable. Empty and rinse.' },
    { name:'Jam jar',               ok:1, s:'glass',   g:'bottle', kg:0.30,  co2:null, rule:'Food glass jars are recyclable. Empty and rinse.' },
    { name:'Paint tin',             ok:1, s:'metal',   g:'can',    kg:0.30,  co2:null, rule:'Non-food metal containers including paint tins are recyclable — empty the contents.' },
    { name:'Biscuit tin',           ok:1, s:'metal',   g:'can',    kg:0.15,  co2:null, rule:'Food metal tins are recyclable. Clean them first.' },

    { name:'Glitter paper',         ok:0, s:'paper',   g:'paper',  kg:0.01,  co2:null, rule:'Glitter paper is not recyclable. Nor are crayon drawings or wax paper.' },
    { name:'Wax paper',             ok:0, s:'paper',   g:'paper',  kg:0.01,  co2:null, rule:'Wax paper is not recyclable — the coating cannot be separated from the fibre.' },
    { name:'Biodegradable bag',     ok:0, s:'plastic', g:'film',   kg:0.01,  co2:null, rule:'<b>Biodegradable and oxo-degradable bags are NOT recyclable.</b> They contaminate the plastic stream — the label sounds greener than the bin it belongs in.' },
    { name:'Styrofoam cup',         ok:0, s:'plastic', g:'cup',    kg:0.01,  co2:null, rule:'All polystyrene foam is out — cups, clamshells and boxes alike.' },
    { name:'Video tape',            ok:0, s:'plastic', g:'other',  kg:0.08,  co2:null, rule:'Cassettes and video tapes are not recyclable.' },
    { name:'Sanitary pad',          ok:0, s:'general', g:'other',  kg:0.02,  co2:null, rule:'General waste, always.' },
    { name:'Household battery',     ok:0, s:'ewaste',  g:'other',  kg:0.02,  co2:null, rule:'Batteries never go in the blue bin. They go to an e-waste collection point — a leaking one should be sealed first.' },
    { name:'Mobile phone',          ok:0, s:'ewaste',  g:'other',  kg:0.18,  co2:null, rule:'Phones, tablets and laptops are regulated e-waste. E-waste bin, not blue bin.' },
    { name:'Pair of shoes',         ok:0, s:'general', g:'other',  kg:0.60,  co2:null, rule:'Shoes are not a blue-bin item. Sports shoes have their own collection points; anything still wearable should be donated.' }

  ];

  /* ---- TEACHING FACTS -------------------------------------------------------------
     Level-end and round-end cards. Kept here so a fact corrected once is corrected
     in every game that shows it.                                                    */
  var FACTS = {
    rinse:    '<b>Empty and rinse first.</b> NEA asks for containers to be emptied and rinsed. One unrinsed sauce bottle can contaminate the paper around it.',
    film:     '<b>Plastic film and bubble wrap ARE recyclable</b> in Singapore — a surprise to most people. Ziplock bags and fruit boxes count too.',
    chlorine: '<b>Chlorine is the enemy of fuel quality.</b> PVC in the mix pushes RDF out of specification, which is why sorting before shredding matters.',
    ewaste:   '<b>Fridges, washing machines and TVs are regulated e-waste.</b> They do not go in the blue bin — they route through the national e-waste scheme.',
    glassNo:  '<b>Not all glass is glass.</b> Pyrex, ceramics and mirrors look recyclable and are not — they melt at different temperatures and ruin a batch.',
    paperNo:  '<b>Paper that has touched food is out.</b> Pizza boxes, cups, plates, tissue and paper towels all go to general waste.'
  };

  /* ---- HELPERS ------------------------------------------------------------------ */
  function find(name) {
    for (var i = 0; i < ITEMS.length; i++) if (ITEMS[i].name === name) return ITEMS[i];
    throw new Error('LirichRules: no item named "' + name + '". Check the spelling against the master list.');
  }
  function pick(names) { return names.map(find); }
  function recyclable()    { return ITEMS.filter(function (i) { return i.ok === 1; }); }
  function notRecyclable() { return ITEMS.filter(function (i) { return i.ok === 0; }); }
  function byStream(s)     { return ITEMS.filter(function (i) { return i.s === s; }); }
  function blockers()      { return ITEMS.filter(function (i) { return i.tag === 'blocker'; }); }
  function colour(s)       { return (STREAMS[s] || STREAMS.general).colour; }

  /* ---- WHICH INK GOES ON EACH STREAM COLOUR --------------------------------------
     Lane headers, sort buttons and belt tiles are drawn ON these colours, and several
     of them were white on everything. Measured contrast ratios against the actual hex
     values, white first, navy ink second:

         paper   #C08A4A   3.01   4.72      navy   ← white failed normal-text 4.5:1
         plastic #4E86C8   3.77   3.77      white  ← neither reaches 4.5; bold/large only
         metal   #8C93A0   3.09   4.60      navy
         glass   #3FA46B   3.12   4.56      navy
         food    #8E9C3F   3.01   4.73      navy
         ewaste  #8C6BB1   4.33   3.29      white  ← bold/large only
         general #5A6376   6.03   2.36      white
         reject  #C0455F   4.93   2.88      white

     WCAG AA asks 4.5:1 for normal text, 3:1 for large or bold. Four streams were
     carrying white small text at barely 3:1, which is a label that some readers simply
     cannot read — on a stream button, the label IS the interface.

     Two streams — plastic and e-waste — cannot reach 4.5:1 with either ink. Their
     labels must stay BOLD and reasonably large, or the colour itself has to change.
     That is recorded rather than quietly accepted.                                 */
  var INK = { paper:'#1B2A4A', plastic:'#FFFFFF', metal:'#1B2A4A', glass:'#1B2A4A',
              food:'#1B2A4A', ewaste:'#FFFFFF', general:'#FFFFFF', reject:'#FFFFFF' };
  /* streams where no ink reaches 4.5:1 — keep the label bold and large */
  var INK_WEAK = { plastic:1, ewaste:1 };
  function ink(s)          { return INK[s] || '#FFFFFF'; }
  function inkIsWeak(s)    { return !!INK_WEAK[s]; }

  /* inkFor(hex) — the same decision for any colour, not only a named stream.
     Several games colour their own tiles (merge tiers, bale colours, flash banners) and
     drew white text on all of them, including on a gold that gives white about 2.2:1.
     This computes the WCAG relative luminance and returns whichever of white or navy
     ink has the higher contrast, so a new colour cannot quietly arrive with an
     unreadable label on it.
     It returns the BETTER of two inks — it does not promise either one passes. Check
     with tests/palette.mjs when adding a colour, and change the colour if neither does. */
  function srgbLin(c) { c = c / 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
  function luminance(hex) {
    var h = String(hex).replace('#', '');
    if (h.length === 3) h = h[0]+h[0]+h[1]+h[1]+h[2]+h[2];
    var r = srgbLin(parseInt(h.slice(0,2),16)), g = srgbLin(parseInt(h.slice(2,4),16)),
        b = srgbLin(parseInt(h.slice(4,6),16));
    return 0.2126*r + 0.7152*g + 0.0722*b;
  }
  function contrastWith(hex, other) {
    var a = luminance(hex), b = luminance(other);
    var hi = Math.max(a,b), lo = Math.min(a,b);
    return (hi + 0.05) / (lo + 0.05);
  }
  var NAVY_INK = '#1B2A4A';
  function inkFor(hex) {
    if (!hex || String(hex).charAt(0) !== '#') return '#FFFFFF';
    return contrastWith(hex, '#FFFFFF') >= contrastWith(hex, NAVY_INK) ? '#FFFFFF' : NAVY_INK;
  }
  /* the contrast the chosen ink actually achieves — so a game can widen or embolden text
     when it is below 4.5, instead of pretending the label is fine */
  function inkContrast(hex) { return Math.round(contrastWith(hex, inkFor(hex)) * 100) / 100; }
  function shuffled(a) {
    var b = a.slice();
    for (var i = b.length - 1; i > 0; i--) { var j = Math.floor(Math.random() * (i + 1)); var t = b[i]; b[i] = b[j]; b[j] = t; }
    return b;
  }
  /* A round of n items, balanced so a round is never all-yes or all-no. */
  function deck(n) {
    var yes = shuffled(recyclable()), no = shuffled(notRecyclable()), out = [], wantYes = Math.round(n / 2);
    for (var i = 0; i < n; i++) out.push((i < wantYes ? yes : no)[i < wantYes ? i : i - wantYes] || (i % 2 ? no[0] : yes[0]));
    return shuffled(out);
  }

  /* ---- PER-GAME VIEWS -------------------------------------------------------------
     Each game gets back exactly the shape it already used, built from the master list.
     Game logic is untouched — only where the data comes from has changed. Adding a
     game means adding a view here, not another copy of the rules.                   */
  var VIEWS = {

    /* Sort It! — six tile types and five blockers */
    sortItTypes: function () {
      return pick(['PET bottle','Drink can','Cardboard box','Glass bottle','Food waste','Small e-waste'])
        .map(function (it, n) {
          return { k:['pet','can','card','glass','food','ewst'][n], name:it.name,
                   stream:STREAMS[it.s].name, col:colour(it.s), kg:it.kg, co2:it.co2 };
        });
    },
    sortItContaminants: function () {
      var keys = { 'Pizza box':['pizza','PIZZA'], 'Paper cup':['cup','CUP'], 'Styrofoam box':['foam','FOAM'],
                   'Drinking straw':['straw','STRAW'], 'Oily tray':['dirty','OILY'] };
      return blockers().map(function (it) {
        var k = keys[it.name] || [it.name.toLowerCase(), it.name.toUpperCase()];
        return { k:k[0], label:it.name === 'Styrofoam box' ? 'Styrofoam' : it.name, short:k[1], fact:it.rule };
      });
    },

    /* Bin or Not? — the full deck, in that game's field names */
    binOrNotItems: function () {
      return ITEMS.map(function (it) { return { n:it.name, y:it.ok, g:it.g, w:it.kg, r:it.rule }; });
    },

    /* Pick Line — belt items, reject lane for anything not recyclable */
    pickLineKinds: function () {
      return pick(['Newspaper','Cardboard box','Beverage carton','PET bottle','Shampoo bottle','Bubble wrap',
                   'Drink can','Food can','Clean aluminium foil','Glass bottle','Glass jar',
                   'Pizza box','Paper cup','Styrofoam box','Drinking straw','Oily tray','Ceramic mug'])
        .map(function (it) { return { n:it.name, s:it.ok ? it.s : 'reject', kg:it.kg }; });
    },
    pickLineColours: function () {
      return { paper:colour('paper'), plastic:colour('plastic'), metal:colour('metal'),
               glass:colour('glass'), reject:colour('reject') };
    },

    /* On Route — bulk bin contents in kg, not unit masses */
    onRouteStreams: function () {
      return { paper  :{ n:STREAMS.paper.name,   c:colour('paper')   },
               plastic:{ n:STREAMS.plastic.name, c:colour('plastic') },
               metal  :{ n:STREAMS.metal.name,   c:colour('metal')   },
               glass  :{ n:STREAMS.glass.name,   c:colour('glass')   },
               general:{ n:STREAMS.general.name, c:colour('general') } };
    },
    onRouteItems: function () {
      /* bin-load masses, not unit masses — a bin of newspaper, not one newspaper */
      return [ {n:'Newspaper',s:'paper',kg:12},    {n:'Cardboard',s:'paper',kg:18},
               {n:'PET bottles',s:'plastic',kg:7}, {n:'HDPE bottles',s:'plastic',kg:9},
               {n:'Drink cans',s:'metal',kg:6},    {n:'Food cans',s:'metal',kg:11},
               {n:'Bottles',s:'glass',kg:24},      {n:'Jars',s:'glass',kg:19},
               {n:'Food waste',s:'general',kg:15}, {n:'Mixed rubbish',s:'general',kg:21} ];
    }
  };

  /* ---- EXPORT ------------------------------------------------------------------- */
  var API = {
    meta: META, streams: STREAMS, items: ITEMS, facts: FACTS,
    find: find, pick: pick, recyclable: recyclable, notRecyclable: notRecyclable,
    byStream: byStream, blockers: blockers, colour: colour, ink: ink, inkIsWeak: inkIsWeak, inkFor: inkFor, inkContrast: inkContrast,
    deck: deck, shuffled: shuffled,
    views: VIEWS,
    /* the disclaimer every game footer should print, so it can never drift between files */
    disclaimer: function () {
      return META.factorsStatus === 'INDICATIVE'
        ? 'Masses and CO₂e figures are indicative and for demonstration only. Sorting rules from ' +
          META.rulesSource + ', checked ' + META.rulesCheckedOn + '.'
        : 'Masses and CO₂e from Lirich SEFR-derived factors. Sorting rules from ' +
          META.rulesSource + ', checked ' + META.rulesCheckedOn + '.';
    },
    /* quick self-check — run in the console, or see games/selftest */
    selfTest: function () {
      var errs = [], seen = {};
      ITEMS.forEach(function (it) {
        if (seen[it.name]) errs.push('duplicate item: ' + it.name);
        seen[it.name] = 1;
        if (!STREAMS[it.s]) errs.push(it.name + ': unknown stream "' + it.s + '"');
        if (typeof it.kg !== 'number' || it.kg <= 0) errs.push(it.name + ': bad mass');
        if (it.ok !== 0 && it.ok !== 1) errs.push(it.name + ': ok must be 0 or 1');
        if (!it.rule) errs.push(it.name + ': no ruling');
      });
      Object.keys(VIEWS).forEach(function (v) {
        try { VIEWS[v](); } catch (e) { errs.push('view ' + v + ' failed: ' + e.message); }
      });
      return errs;
    }
  };

  root.LirichRules = API;
  if (typeof module !== 'undefined' && module.exports) module.exports = API;

})(typeof window !== 'undefined' ? window : globalThis);
