/* =====================================================================================
   spot-photos.js — real tipping-floor photographs for Spot the Contaminant.
   Added 21 Oct 2026. EMPTY until Lirich's cleared photographs exist.

   One entry per load, in game order (1 builder's skip, 2 factory clear-out, 3 mixed
   commercial load, 4 school science block). A load with an entry plays on the photograph;
   a load without one plays on the drawn floor exactly as before. If a photograph fails to
   load, that load falls back to the drawn floor too, so a wrong path never breaks a lesson.

   Each entry:
     photo     path to the web copy, relative to the game folder,
               e.g. 'assets/spot/spot-01-builders-skip.jpg'
     hotspots  one per hazard visible in the photo:
                 k   hazard key — lpg, liion, carbat, aero, paint, tube, sharps, ext, oil, asb
                 x,y centre of the item, as a PERCENTAGE of the image width / height
                 w,h size of the tap area, as a PERCENTAGE of the image width / height

   Do not type the numbers by hand. Open spot-hotspots.html (in this folder), load the
   photo, drag a box around each hazard, and copy the entry it prints into this file.
   Then run tests/runall.mjs — spotphoto.mjs checks every entry before anyone plays it.

   In photo mode, a tap on the photograph that is not on a hazard counts as a harmless item
   and costs eight seconds, the same rule as the drawn floor. Tap areas are enlarged by 15%
   when checking a tap, so a near-miss on a small item still counts.

   The photo brief, including the safety and privacy clearance every image needs before
   it goes in here, is Lirich_SpotTheContaminant_Photo_Brief.md.

   Example — delete the leading // marks on all lines of an entry to use it:

   window.LIRICH_SPOT_PHOTOS = [
   //  { photo: 'assets/spot/spot-01-builders-skip.jpg',
   //    hotspots: [ { k:'lpg',   x:23.4, y:61.8, w:9,  h:16 },
   //                { k:'liion', x:58.0, y:40.2, w:11, h:9  },
   //                { k:'aero',  x:80.5, y:70.0, w:8,  h:12 } ] },
   ];
   ===================================================================================== */
window.LIRICH_SPOT_PHOTOS = [
  /* load 1 — builder's skip        */ null,
  /* load 2 — factory clear-out     */ null,
  /* load 3 — mixed commercial load */ null,
  /* load 4 — school science block  */ null
];
