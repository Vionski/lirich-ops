/* =====================================================================================
   lirich-sprites.js — glossy item art for Lirich Learn, drawn in code. Added 4 Oct 2026.

   Why drawn and not images: no files to fetch (the basket makes zero external requests
   and runs from a USB stick), nothing to license, crisp at every size and pixel density,
   and one consistent light source across every item. Each sprite is drawn once per
   size into an offscreen canvas and then reused, so a full board costs a copy per tile.

   LirichSprites.draw(ctx, key, x, y, size)   — draws the item centred in that square
   Keys: pet can card glass food ewst  (Sort It! tiles)
         pizza cup foam straw dirty    (contamination)
         plus one per rules item, added 10 Oct 2026 — LirichSprites.forItem(name) finds it
   Light comes from the upper left on every item. Keep it that way if adding one.
   ===================================================================================== */
(function (root) {
  'use strict';
  var cache = {};
  var DPR = Math.min(2, root.devicePixelRatio || 1);

  function lin(g, x0, y0, x1, y1, stops) {
    var gr = g.createLinearGradient(x0, y0, x1, y1);
    stops.forEach(function (s) { gr.addColorStop(s[0], s[1]); }); return gr;
  }
  function rad(g, x, y, r, stops) {
    var gr = g.createRadialGradient(x, y, 0, x, y, r);
    stops.forEach(function (s) { gr.addColorStop(s[0], s[1]); }); return gr;
  }
  function rr(g, x, y, w, h, r) {
    g.beginPath(); g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r);
    g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath();
  }
  function shadow(g, cx, cy, w) {           // soft contact shadow under every item
    g.save(); g.fillStyle = 'rgba(20,40,80,.18)';
    g.beginPath(); g.ellipse(cx, cy, w, w * 0.22, 0, 0, 7); g.fill(); g.restore();
  }
  function shine(g, x, y, w, h, a) {        // the white highlight stroke that makes it glossy
    g.save(); g.globalAlpha = a || .75; g.fillStyle = '#fff';
    rr(g, x, y, w, h, Math.min(w, h) / 2); g.fill(); g.restore();
  }
  function recycleMark(g, cx, cy, r, col) {  // three chasing arrows
    g.save(); g.translate(cx, cy); g.strokeStyle = col; g.fillStyle = col; g.lineWidth = r * 0.3; g.lineCap = 'round';
    for (var i = 0; i < 3; i++) {
      var a0 = i * 2.094 - 1.4, a1 = a0 + 1.45;
      g.beginPath(); g.arc(0, 0, r, a0, a1); g.stroke();
      var ex = r * Math.cos(a1), ey = r * Math.sin(a1), tx = -Math.sin(a1), ty = Math.cos(a1);   // tangent, direction of travel
      var nx = Math.cos(a1), ny = Math.sin(a1), h = r * 0.5;
      g.beginPath(); g.moveTo(ex + tx * h, ey + ty * h); g.lineTo(ex + nx * h * .7, ey + ny * h * .7); g.lineTo(ex - nx * h * .7, ey - ny * h * .7); g.closePath(); g.fill();
    }
    g.restore();
  }

  /* every drawer works in a 100 × 100 box */
  var ART = {
    pet: function (g) {                     // blue PET water bottle
      shadow(g, 50, 92, 20);
      g.fillStyle = lin(g, 30, 0, 70, 0, [[0, '#1E63C8'], [.35, '#5FA8F5'], [.6, '#3A86E6'], [1, '#174E9E']]);
      g.beginPath(); g.moveTo(42, 22); g.lineTo(58, 22); g.quadraticCurveTo(70, 30, 70, 44);
      g.lineTo(70, 86); g.quadraticCurveTo(70, 92, 63, 92); g.lineTo(37, 92); g.quadraticCurveTo(30, 92, 30, 86);
      g.lineTo(30, 44); g.quadraticCurveTo(30, 30, 42, 22); g.fill();
      g.fillStyle = 'rgba(255,255,255,.25)'; g.fillRect(30, 58, 40, 3); g.fillRect(30, 74, 40, 3);   // ribs
      g.fillStyle = lin(g, 0, 50, 0, 70, [[0, '#E9F3FF'], [1, '#B9D6F7']]); g.fillRect(30, 50, 40, 16); // label
      g.fillStyle = '#2F78D6'; g.font = '900 9px sans-serif'; g.textAlign = 'center'; g.fillText('PET', 50, 61);
      g.fillStyle = lin(g, 40, 0, 60, 0, [[0, '#0F3F86'], [.5, '#3E7FD8'], [1, '#0F3F86']]);
      rr(g, 40, 8, 20, 15, 3); g.fill();                                   // cap
      g.fillStyle = 'rgba(255,255,255,.35)'; g.fillRect(43, 10, 3, 11);
      shine(g, 35, 30, 6, 52, .65);
    },
    can: function (g) {                     // aluminium drink can
      shadow(g, 50, 92, 22);
      g.fillStyle = lin(g, 28, 0, 72, 0, [[0, '#7D8592'], [.25, '#F4F6F9'], [.45, '#C3C9D2'], [.8, '#8A93A0'], [1, '#5E6672']]);
      rr(g, 28, 18, 44, 72, 8); g.fill();
      g.fillStyle = lin(g, 28, 0, 72, 0, [[0, '#B23A3A'], [.3, '#F06A55'], [1, '#9E2C2C']]); g.fillRect(28, 44, 44, 18);  // band
      g.fillStyle = '#fff'; g.font = '900 9px sans-serif'; g.textAlign = 'center'; g.fillText('ALU', 50, 56);
      g.fillStyle = lin(g, 28, 0, 72, 0, [[0, '#9AA2AE'], [.4, '#FFFFFF'], [1, '#8A93A0']]);
      g.beginPath(); g.ellipse(50, 18, 22, 7, 0, 0, 7); g.fill();
      g.strokeStyle = '#7D8592'; g.lineWidth = 1.5; g.stroke();
      g.fillStyle = '#9AA2AE'; rr(g, 44, 14, 12, 6, 3); g.fill();                     // ring pull
      shine(g, 34, 24, 5, 58, .8);
    },
    card: function (g) {                    // cardboard box, three-quarter view
      shadow(g, 50, 91, 32);
      g.fillStyle = lin(g, 0, 40, 0, 90, [[0, '#F2A04A'], [1, '#C46A1E']]);           // front
      g.beginPath(); g.moveTo(16, 40); g.lineTo(60, 48); g.lineTo(60, 90); g.lineTo(16, 82); g.closePath(); g.fill();
      g.fillStyle = lin(g, 60, 0, 86, 0, [[0, '#B85F17'], [1, '#8E4710']]);            // side
      g.beginPath(); g.moveTo(60, 48); g.lineTo(86, 36); g.lineTo(86, 76); g.lineTo(60, 90); g.closePath(); g.fill();
      g.fillStyle = lin(g, 16, 22, 86, 48, [[0, '#FFC27A'], [1, '#E8913A']]);           // top
      g.beginPath(); g.moveTo(16, 40); g.lineTo(42, 28); g.lineTo(86, 36); g.lineTo(60, 48); g.closePath(); g.fill();
      g.strokeStyle = '#D9B98A'; g.lineWidth = 4; g.beginPath(); g.moveTo(29, 34); g.lineTo(73, 42); g.stroke();      // tape
      recycleMark(g, 38, 66, 9, '#FFF3E0');
    },
    glass: function (g) {                   // green glass bottle
      shadow(g, 50, 93, 18);
      g.fillStyle = lin(g, 32, 0, 68, 0, [[0, '#0E5B33'], [.35, '#38B56E'], [.6, '#1F8A4E'], [1, '#0B4A29']]);
      g.beginPath(); g.moveTo(45, 8); g.lineTo(55, 8); g.lineTo(55, 32); g.quadraticCurveTo(68, 40, 68, 52);
      g.lineTo(68, 88); g.quadraticCurveTo(68, 93, 62, 93); g.lineTo(38, 93); g.quadraticCurveTo(32, 93, 32, 88);
      g.lineTo(32, 52); g.quadraticCurveTo(32, 40, 45, 32); g.closePath(); g.fill();
      g.fillStyle = '#E8D9A8'; g.fillRect(34, 58, 32, 18);                                 // paper label
      g.fillStyle = '#9C7B2E'; g.fillRect(38, 64, 24, 2.5); g.fillRect(38, 69, 16, 2.5);
      g.fillStyle = '#C9A227'; rr(g, 43, 5, 14, 6, 2); g.fill();                         // cap
      shine(g, 37, 44, 5, 44, .55); shine(g, 47, 12, 3, 16, .45);
    },
    food: function (g) {                    // apple core + banana peel = food waste
      shadow(g, 50, 91, 30);
      g.fillStyle = lin(g, 0, 50, 0, 90, [[0, '#FFE066'], [1, '#E0A800']]);              // banana peel
      g.beginPath(); g.moveTo(22, 86); g.quadraticCurveTo(14, 60, 34, 52); g.quadraticCurveTo(30, 66, 40, 84); g.closePath(); g.fill();
      g.beginPath(); g.moveTo(40, 86); g.quadraticCurveTo(46, 62, 38, 52); g.quadraticCurveTo(54, 62, 52, 86); g.closePath(); g.fill();
      g.fillStyle = '#6B4E12'; g.beginPath(); g.arc(36, 52, 3, 0, 7); g.fill();
      g.fillStyle = rad(g, 62, 42, 26, [[0, '#FF8A7A'], [.6, '#E23B3B'], [1, '#9E1B1B']]);  // apple core
      g.beginPath(); g.ellipse(66, 34, 14, 10, 0, 0, 7); g.fill();
      g.beginPath(); g.ellipse(66, 80, 13, 9, 0, 0, 7); g.fill();
      g.fillStyle = lin(g, 58, 0, 74, 0, [[0, '#F7E9C4'], [1, '#E6CF95']]);
      g.beginPath(); g.moveTo(56, 36); g.quadraticCurveTo(64, 58, 56, 80); g.lineTo(76, 80); g.quadraticCurveTo(68, 58, 76, 36); g.closePath(); g.fill();
      g.fillStyle = '#4A2C10'; g.beginPath(); g.ellipse(64, 56, 2, 3.5, .3, 0, 7); g.fill(); g.beginPath(); g.ellipse(69, 60, 2, 3.5, -.3, 0, 7); g.fill();
      g.strokeStyle = '#5B3A12'; g.lineWidth = 3; g.lineCap = 'round'; g.beginPath(); g.moveTo(66, 24); g.lineTo(68, 14); g.stroke();
      g.fillStyle = '#3FA046'; g.beginPath(); g.ellipse(76, 16, 8, 4, -.5, 0, 7); g.fill();
      shine(g, 58, 28, 8, 4, .7);
    },
    ewst: function (g) {                    // old phone + cable = small e-waste
      shadow(g, 50, 92, 22);
      g.fillStyle = lin(g, 30, 0, 70, 0, [[0, '#3B2E5A'], [.5, '#6C5A99'], [1, '#2C2246']]);
      rr(g, 30, 12, 40, 76, 8); g.fill();
      g.fillStyle = lin(g, 0, 18, 0, 72, [[0, '#9BD1FF'], [1, '#4C7FD6']]); rr(g, 34, 20, 32, 52, 3); g.fill();
      g.strokeStyle = 'rgba(255,255,255,.75)'; g.lineWidth = 1.6;                        // screen crack
      g.beginPath(); g.moveTo(40, 26); g.lineTo(50, 40); g.lineTo(46, 48); g.lineTo(60, 64); g.moveTo(50, 40); g.lineTo(62, 34); g.stroke();
      g.fillStyle = '#AFA2D6'; g.beginPath(); g.arc(50, 80, 3.5, 0, 7); g.fill();
      g.strokeStyle = '#2B2B2B'; g.lineWidth = 3.5; g.lineCap = 'round';                // cable
      g.beginPath(); g.moveTo(68, 70); g.bezierCurveTo(90, 74, 88, 92, 74, 92); g.stroke();
      shine(g, 33, 16, 4, 60, .35);
    },

    /* --- more items, for Bin or Not?, Pick Line and On Route --- */
    paper: function (g) {                   // folded newspaper
      shadow(g, 50, 88, 32);
      g.fillStyle = lin(g, 0, 22, 0, 86, [[0, '#FFFFFF'], [1, '#D9DDE3']]);
      g.beginPath(); g.moveTo(18, 30); g.lineTo(78, 22); g.lineTo(84, 80); g.lineTo(24, 88); g.closePath(); g.fill();
      g.fillStyle = '#2B3B55'; g.save(); g.translate(22, 30); g.rotate(-0.13);
      g.fillRect(6, 6, 50, 7);
      g.fillStyle = '#9AA5B6'; for (var i = 0; i < 6; i++) { g.fillRect(6, 20 + i * 7, 24, 3); g.fillRect(34, 20 + i * 7, 22, 3); }
      g.fillStyle = '#C9D3E2'; g.fillRect(34, 20, 22, 17); g.restore();
    },
    carton: function (g) {                  // drink carton
      shadow(g, 50, 92, 20);
      g.fillStyle = lin(g, 32, 0, 68, 0, [[0, '#E9EEF4'], [.4, '#FFFFFF'], [1, '#C9D2DD']]);
      g.beginPath(); g.moveTo(32, 34); g.lineTo(50, 18); g.lineTo(68, 34); g.lineTo(68, 92); g.lineTo(32, 92); g.closePath(); g.fill();
      g.fillStyle = '#E9EEF4'; g.fillRect(44, 10, 12, 10);
      g.fillStyle = lin(g, 32, 0, 68, 0, [[0, '#2F9A5E'], [1, '#1E6E40']]); g.fillRect(32, 50, 36, 26);
      g.fillStyle = '#fff'; g.beginPath(); g.ellipse(50, 63, 8, 6, 0, 0, 7); g.fill();
      g.fillStyle = '#F2B233'; g.beginPath(); g.arc(50, 63, 3.5, 0, 7); g.fill();
      shine(g, 35, 38, 4, 48, .6);
    },
    hdpe: function (g) {                    // shampoo bottle
      shadow(g, 50, 92, 20);
      g.fillStyle = lin(g, 30, 0, 70, 0, [[0, '#B0367A'], [.35, '#F07AB8'], [1, '#86235A']]);
      rr(g, 30, 30, 40, 62, 12); g.fill();
      g.fillStyle = lin(g, 40, 0, 60, 0, [[0, '#E9EEF4'], [.5, '#FFFFFF'], [1, '#B9C2CE']]);
      rr(g, 40, 14, 20, 18, 4); g.fill(); rr(g, 44, 8, 10, 8, 2); g.fill();
      g.fillStyle = 'rgba(255,255,255,.85)'; rr(g, 36, 50, 28, 22, 4); g.fill();
      g.fillStyle = '#B0367A'; g.fillRect(40, 56, 20, 3); g.fillRect(40, 62, 14, 3);
      shine(g, 34, 34, 5, 52, .55);
    },
    film: function (g) {                    // bubble wrap / plastic film
      shadow(g, 50, 88, 32);
      g.fillStyle = lin(g, 0, 20, 0, 86, [[0, 'rgba(210,235,255,.95)'], [1, 'rgba(150,195,235,.95)']]);
      g.beginPath(); g.moveTo(14, 30); g.quadraticCurveTo(50, 18, 86, 28); g.lineTo(82, 82); g.quadraticCurveTo(50, 92, 18, 84); g.closePath(); g.fill();
      for (var y = 0; y < 5; y++) for (var x = 0; x < 6; x++) {
        var cx = 22 + x * 11 + (y % 2) * 5, cy = 36 + y * 10;
        if (cx > 80) continue;
        g.fillStyle = 'rgba(255,255,255,.9)'; g.beginPath(); g.arc(cx, cy, 4, 0, 7); g.fill();
        g.fillStyle = 'rgba(80,140,200,.45)'; g.beginPath(); g.arc(cx + 1, cy + 1, 2.4, 0, 7); g.fill();
      }
    },
    tin: function (g) {                     // food can with a label
      shadow(g, 50, 90, 24);
      g.fillStyle = lin(g, 26, 0, 74, 0, [[0, '#7D8592'], [.3, '#EEF1F5'], [1, '#6B7380']]);
      rr(g, 26, 26, 48, 62, 4); g.fill();
      g.fillStyle = lin(g, 26, 0, 74, 0, [[0, '#B23A1E'], [.3, '#F27B3A'], [1, '#9E2F14']]); g.fillRect(26, 38, 48, 38);
      g.fillStyle = '#FFE08A'; g.beginPath(); g.ellipse(50, 57, 12, 9, 0, 0, 7); g.fill();
      g.fillStyle = '#B23A1E'; g.beginPath(); g.arc(50, 57, 5, 0, 7); g.fill();
      g.fillStyle = lin(g, 26, 0, 74, 0, [[0, '#9AA2AE'], [.4, '#FFFFFF'], [1, '#8A93A0']]);
      g.beginPath(); g.ellipse(50, 26, 24, 7, 0, 0, 7); g.fill();
      g.strokeStyle = '#8A93A0'; g.lineWidth = 1.2; g.beginPath(); g.ellipse(50, 26, 18, 4.5, 0, 0, 7); g.stroke();
      shine(g, 31, 30, 4, 52, .7);
    },
    foil: function (g) {                    // clean aluminium foil, scrunched
      shadow(g, 50, 86, 28);
      g.fillStyle = rad(g, 40, 40, 44, [[0, '#FFFFFF'], [.5, '#C9D0DA'], [1, '#7E8794']]);
      g.beginPath(); g.moveTo(22, 52); g.lineTo(30, 30); g.lineTo(48, 24); g.lineTo(70, 30); g.lineTo(80, 50); g.lineTo(72, 74); g.lineTo(50, 82); g.lineTo(28, 74); g.closePath(); g.fill();
      g.strokeStyle = 'rgba(110,120,135,.6)'; g.lineWidth = 1.4;
      g.beginPath(); g.moveTo(30, 30); g.lineTo(46, 50); g.lineTo(70, 30); g.moveTo(46, 50); g.lineTo(50, 82); g.moveTo(46, 50); g.lineTo(22, 52); g.moveTo(46, 50); g.lineTo(80, 50); g.stroke();
      shine(g, 34, 34, 10, 4, .9);
    },
    jar: function (g) {                     // glass jar with lid
      shadow(g, 50, 92, 22);
      g.fillStyle = lin(g, 28, 0, 72, 0, [[0, 'rgba(150,200,190,.9)'], [.4, 'rgba(225,245,240,.95)'], [1, 'rgba(120,175,165,.9)']]);
      rr(g, 28, 30, 44, 62, 10); g.fill();
      g.fillStyle = lin(g, 28, 0, 72, 0, [[0, '#B8860B'], [.4, '#F2C94C'], [1, '#9C7208']]); rr(g, 30, 18, 40, 14, 3); g.fill();
      g.fillStyle = 'rgba(120,60,20,.45)'; rr(g, 32, 62, 36, 26, 6); g.fill();     // jam left at the bottom: rinse it
      shine(g, 33, 36, 5, 46, .7);
    },
    mug: function (g) {                     // ceramic mug
      shadow(g, 46, 90, 24);
      g.strokeStyle = '#D9DEE6'; g.lineWidth = 8; g.beginPath(); g.arc(72, 58, 12, -1.2, 1.2); g.stroke();
      g.fillStyle = lin(g, 22, 0, 70, 0, [[0, '#C9D0DA'], [.35, '#FFFFFF'], [1, '#B3BCC8']]);
      rr(g, 22, 30, 48, 58, 6); g.fill();
      g.fillStyle = '#4E86C8'; g.fillRect(22, 46, 48, 8);
      g.fillStyle = '#6B4325'; g.beginPath(); g.ellipse(46, 31, 22, 5, 0, 0, 7); g.fill();
      shine(g, 28, 36, 4, 44, .7);
    },
    bag: function (g) {                     // tied black rubbish bag
      shadow(g, 50, 90, 30);
      g.fillStyle = rad(g, 40, 50, 46, [[0, '#5E6676'], [.6, '#2E3440'], [1, '#161A21']]);
      g.beginPath(); g.moveTo(46, 30); g.quadraticCurveTo(14, 40, 20, 72); g.quadraticCurveTo(26, 92, 50, 90); g.quadraticCurveTo(76, 92, 80, 72); g.quadraticCurveTo(86, 40, 54, 30); g.closePath(); g.fill();
      g.fillStyle = '#2E3440'; g.beginPath(); g.moveTo(44, 30); g.lineTo(38, 14); g.lineTo(50, 24); g.lineTo(62, 14); g.lineTo(56, 30); g.closePath(); g.fill();
      shine(g, 30, 50, 4, 22, .35);
    },

    /* --- contamination: what makes each one not recyclable is visible on it --- */
    pizza: function (g) {                   // pizza box with a grease stain and a crust
      shadow(g, 50, 88, 34);
      g.fillStyle = lin(g, 0, 40, 0, 84, [[0, '#E9C58F'], [1, '#C79A5E']]);
      g.beginPath(); g.moveTo(10, 56); g.lineTo(50, 44); g.lineTo(90, 56); g.lineTo(90, 70); g.lineTo(50, 84); g.lineTo(10, 70); g.closePath(); g.fill();
      g.fillStyle = lin(g, 0, 30, 0, 70, [[0, '#F7DEB4'], [1, '#E3BC82']]);
      g.beginPath(); g.moveTo(10, 56); g.lineTo(50, 44); g.lineTo(90, 56); g.lineTo(50, 68); g.closePath(); g.fill();
      g.fillStyle = 'rgba(140,80,20,.55)'; g.beginPath(); g.ellipse(46, 56, 12, 5, -.2, 0, 7); g.fill();   // grease
      g.beginPath(); g.ellipse(62, 59, 6, 2.5, .2, 0, 7); g.fill();
      g.fillStyle = '#D8892C'; g.beginPath(); g.moveTo(50, 36); g.lineTo(72, 30); g.lineTo(60, 46); g.closePath(); g.fill();   // crust
      g.fillStyle = '#E04A2A'; g.beginPath(); g.arc(61, 37, 2.8, 0, 7); g.fill();
      g.fillStyle = '#B2271A'; g.font = '900 8px sans-serif'; g.textAlign = 'center'; g.fillText('PIZZA', 50, 79);
    },
    cup: function (g) {                     // paper coffee cup: plastic-lined
      shadow(g, 50, 92, 18);
      g.fillStyle = lin(g, 32, 0, 68, 0, [[0, '#D8D2C6'], [.35, '#FFFFFF'], [1, '#BFB7A8']]);
      g.beginPath(); g.moveTo(32, 26); g.lineTo(68, 26); g.lineTo(62, 92); g.lineTo(38, 92); g.closePath(); g.fill();
      g.fillStyle = lin(g, 34, 0, 66, 0, [[0, '#7A4B26'], [.4, '#B57940'], [1, '#6B3E1E']]);      // sleeve
      g.beginPath(); g.moveTo(35, 46); g.lineTo(65, 46); g.lineTo(63, 70); g.lineTo(37, 70); g.closePath(); g.fill();
      g.fillStyle = lin(g, 28, 0, 72, 0, [[0, '#2A2F3A'], [.4, '#5A6272'], [1, '#22262F']]);      // lid
      rr(g, 28, 16, 44, 12, 4); g.fill(); rr(g, 34, 10, 32, 8, 3); g.fill();
      g.fillStyle = '#7A4B26'; g.beginPath(); g.ellipse(44, 13, 4, 1.6, 0, 0, 7); g.fill();
      shine(g, 38, 30, 4, 14, .7);
    },
    foam: function (g) {                    // styrofoam clamshell
      shadow(g, 50, 88, 34);
      g.fillStyle = lin(g, 0, 56, 0, 86, [[0, '#FFFFFF'], [1, '#D7DCE3']]);
      g.beginPath(); g.moveTo(12, 58); g.lineTo(88, 58); g.lineTo(80, 84); g.lineTo(20, 84); g.closePath(); g.fill();
      g.fillStyle = lin(g, 0, 22, 0, 56, [[0, '#FFFFFF'], [1, '#E3E7ED']]);                      // open lid
      g.beginPath(); g.moveTo(12, 56); g.lineTo(22, 24); g.lineTo(78, 24); g.lineTo(88, 56); g.closePath(); g.fill();
      g.strokeStyle = '#C3CAD4'; g.lineWidth = 1.6;
      g.beginPath(); g.moveTo(26, 34); g.lineTo(74, 34); g.moveTo(22, 70); g.lineTo(78, 70); g.stroke();
      g.fillStyle = 'rgba(200,120,40,.5)'; g.beginPath(); g.ellipse(52, 64, 14, 4, 0, 0, 7); g.fill();  // leftover sauce
      g.fillStyle = '#8E9AAB'; for (var i = 0; i < 9; i++) { g.beginPath(); g.arc(24 + (i % 5) * 13, 40 + Math.floor(i / 5) * 8, 1, 0, 7); g.fill(); }
    },
    straw: function (g) {                   // bent plastic straw, striped
      shadow(g, 50, 90, 24);
      var path = function () { g.beginPath(); g.moveTo(36, 88); g.lineTo(58, 36); g.lineTo(76, 14); };
      g.lineWidth = 11; g.lineJoin = 'round'; g.lineCap = 'round';
      g.strokeStyle = '#C9D6EA'; path(); g.stroke();
      g.lineWidth = 9; g.strokeStyle = '#FFFFFF'; path(); g.stroke();
      g.setLineDash([5, 6]); g.lineCap = 'butt'; g.strokeStyle = '#E8423A'; path(); g.stroke(); g.setLineDash([]);
      g.lineWidth = 2; g.strokeStyle = 'rgba(255,255,255,.8)'; g.beginPath(); g.moveTo(35, 84); g.lineTo(55, 37); g.stroke();
    },
    dirty: function (g) {                   // oily aluminium tray
      shadow(g, 50, 86, 36);
      g.fillStyle = lin(g, 0, 40, 0, 82, [[0, '#E8ECF1'], [1, '#9AA3AF']]);
      g.beginPath(); g.moveTo(8, 46); g.lineTo(92, 46); g.lineTo(80, 82); g.lineTo(20, 82); g.closePath(); g.fill();
      g.fillStyle = lin(g, 0, 50, 0, 76, [[0, '#B9C1CC'], [1, '#D8DEE6']]);
      g.beginPath(); g.moveTo(18, 52); g.lineTo(82, 52); g.lineTo(74, 76); g.lineTo(26, 76); g.closePath(); g.fill();
      g.fillStyle = rad(g, 46, 62, 22, [[0, 'rgba(120,70,10,.85)'], [1, 'rgba(180,120,30,.25)']]);   // oil pool
      g.beginPath(); g.ellipse(48, 63, 20, 7, 0, 0, 7); g.fill();
      g.fillStyle = '#C08A1E'; [[30, 40], [66, 38], [74, 44]].forEach(function (p) {             // drips
        g.beginPath(); g.moveTo(p[0], p[1] - 6); g.quadraticCurveTo(p[0] + 4, p[1], p[0], p[1] + 3); g.quadraticCurveTo(p[0] - 4, p[1], p[0], p[1] - 6); g.fill(); });
      shine(g, 16, 47, 30, 2.5, .8);
    }
  };

  /* =================================================================================
     Added 10 Oct 2026 — one picture for every item in lirich-rules.js.
     Before this, 21 items had no picture and about 30 more borrowed their group's
     picture (a jam jar drew as a PET bottle, a mirror as a jar). In a game that teaches
     by showing, the wrong picture teaches the wrong thing. Same rules as above: a
     100 × 100 box, light from the upper left, and whatever makes an item recyclable or
     not is visible on it.
     ================================================================================= */
  function poly(g, pts) {
    g.beginPath(); for (var i = 0; i < pts.length; i++) { if (i) g.lineTo(pts[i][0], pts[i][1]); else g.moveTo(pts[i][0], pts[i][1]); }
    g.closePath();
  }
  function dot(g, x, y, r) { g.beginPath(); g.arc(x, y, r, 0, 7); g.fill(); }
  function oval(g, x, y, rx, ry, rot) { g.beginPath(); g.ellipse(x, y, rx, ry, rot || 0, 0, 7); }
  function sparkle(g, x, y, r, col) {           // four-point star, for glitter and clean shine
    g.save(); g.fillStyle = col || '#fff'; g.beginPath();
    g.moveTo(x, y - r); g.quadraticCurveTo(x, y, x + r, y); g.quadraticCurveTo(x, y, x, y + r);
    g.quadraticCurveTo(x, y, x - r, y); g.quadraticCurveTo(x, y, x, y - r); g.fill(); g.restore();
  }

  /* --- paper and card --- */
  ART.eggtray = function (g) {                // moulded pulp egg tray, 2 × 3 cups
    shadow(g, 50, 88, 36);
    g.fillStyle = lin(g, 0, 40, 0, 88, [[0, '#D9CDB8'], [1, '#A89878']]);
    poly(g, [[10, 52], [34, 34], [90, 44], [70, 66]]); g.fill();
    g.fillStyle = lin(g, 0, 60, 0, 86, [[0, '#B8A98C'], [1, '#8E7F62']]);
    poly(g, [[10, 52], [70, 66], [70, 84], [10, 68]]); g.fill();
    g.fillStyle = '#9C8D70'; poly(g, [[70, 66], [90, 44], [90, 60], [70, 84]]); g.fill();
    for (var r = 0; r < 2; r++) for (var c = 0; c < 3; c++) {
      var cx = 31 + c * 18.5 - r * 10, cy = 43 + c * 3.2 + r * 9.5;
      g.fillStyle = rad(g, cx - 2, cy - 2, 9, [[0, '#7E6F54'], [.7, '#A39478'], [1, '#CFC2AB']]);
      oval(g, cx, cy, 7.5, 4.6, .17); g.fill();
    }
    g.fillStyle = 'rgba(255,255,255,.5)'; poly(g, [[14, 51], [34, 36], [38, 37], [18, 52]]); g.fill();
  };
  ART.tube = function (g) {                   // cardboard tube from a paper towel roll
    shadow(g, 50, 88, 30);
    g.save(); g.translate(50, 52); g.rotate(-0.42);
    g.fillStyle = lin(g, 0, -15, 0, 15, [[0, '#E0B27A'], [.35, '#C8935A'], [1, '#8A5E30']]);
    g.fillRect(-34, -14, 68, 28);
    oval(g, -34, 0, 6, 14); g.fill();
    g.fillStyle = '#D9AA72'; oval(g, 34, 0, 6, 14); g.fill();
    g.fillStyle = rad(g, 35, 1, 12, [[0, '#4A2F14'], [1, '#7A5228']]); oval(g, 34, 0, 4, 10.5); g.fill();
    g.save(); g.beginPath(); g.rect(-34, -14, 66, 28); g.clip();
    g.strokeStyle = 'rgba(110,70,30,.55)'; g.lineWidth = 1.4;      // the spiral seam
    for (var i = -2; i < 3; i++) { g.beginPath(); g.moveTo(i * 17 - 8, -14); g.lineTo(i * 17 + 8, 14); g.stroke(); }
    g.restore();
    g.fillStyle = 'rgba(255,255,255,.4)'; rr(g, -30, -11, 56, 3.5, 1.7); g.fill();
    g.restore();
  };
  ART.envelope = function (g) {               // envelope with a window and a stamp
    shadow(g, 50, 86, 36);
    g.fillStyle = lin(g, 0, 26, 0, 82, [[0, '#FFFFFF'], [1, '#D5DBE4']]);
    poly(g, [[10, 30], [88, 24], [92, 76], [14, 82]]); g.fill();
    g.strokeStyle = '#AEB8C6'; g.lineWidth = 1.6; g.lineJoin = 'round';
    g.beginPath(); g.moveTo(10, 30); g.lineTo(51, 56); g.lineTo(88, 24); g.stroke();
    g.fillStyle = 'rgba(120,190,235,.75)'; g.save(); g.translate(22, 60); g.rotate(-0.075); rr(g, 0, 0, 28, 13, 3); g.fill();
    g.fillStyle = '#5E7896'; g.fillRect(4, 4, 18, 2); g.fillRect(4, 8, 12, 2); g.restore();
    g.fillStyle = '#E0483A'; g.save(); g.translate(72, 32); g.rotate(-0.075); g.fillRect(0, 0, 12, 14);
    g.fillStyle = '#FFE1A8'; dot(g, 6, 7, 3.4); g.restore();
  };
  ART.magazine = function (g) {               // glossy magazine, slightly open
    shadow(g, 50, 90, 32);
    g.fillStyle = '#E8ECF2'; poly(g, [[22, 20], [80, 16], [86, 86], [28, 90]]); g.fill();
    g.fillStyle = lin(g, 18, 14, 80, 88, [[0, '#FF7A59'], [.55, '#E0358A'], [1, '#7B3FD1']]);
    poly(g, [[18, 18], [76, 13], [82, 83], [24, 88]]); g.fill();
    g.save(); g.translate(21, 18); g.rotate(-0.085);
    g.fillStyle = '#fff'; g.font = '900 13px sans-serif'; g.textAlign = 'left'; g.fillText('MAG', 6, 16);
    g.fillStyle = 'rgba(255,255,255,.92)'; dot(g, 30, 40, 13);
    g.fillStyle = '#FFC93C'; dot(g, 30, 40, 8);
    g.fillStyle = 'rgba(255,255,255,.85)'; g.fillRect(6, 58, 36, 3); g.fillRect(6, 64, 26, 3);
    g.restore();
    g.fillStyle = 'rgba(255,255,255,.28)'; poly(g, [[18, 18], [34, 16.5], [52, 86], [34, 87.5], [24, 88]]); g.fill();
  };
  ART.tissuebox = function (g) {              // tissue box: the box goes in, the tissue does not
    shadow(g, 50, 90, 34);
    g.fillStyle = lin(g, 34, 0, 68, 0, [[0, '#FFFFFF'], [.5, '#F1F4F8'], [1, '#C9D1DC']]); g.beginPath(); g.moveTo(38, 46); g.quadraticCurveTo(28, 20, 46, 10);
    g.quadraticCurveTo(50, 24, 60, 12); g.quadraticCurveTo(72, 26, 62, 46); g.closePath(); g.fill();
    g.strokeStyle = '#AEB8C6'; g.lineWidth = 1.3; g.stroke(); g.beginPath(); g.moveTo(46, 12); g.quadraticCurveTo(44, 30, 50, 44); g.stroke();
    g.fillStyle = lin(g, 0, 50, 0, 90, [[0, '#4FB7C9'], [1, '#2A7F96']]);
    poly(g, [[12, 50], [64, 56], [64, 90], [12, 82]]); g.fill();
    g.fillStyle = lin(g, 64, 0, 90, 0, [[0, '#23708A'], [1, '#17556B']]);
    poly(g, [[64, 56], [90, 46], [90, 78], [64, 90]]); g.fill();
    g.fillStyle = lin(g, 12, 38, 90, 56, [[0, '#8FDDEA'], [1, '#5EC2D4']]);
    poly(g, [[12, 50], [40, 40], [90, 46], [64, 56]]); g.fill();
    g.fillStyle = '#1D5F75'; oval(g, 51, 48, 13, 3.2, .1); g.fill();
    g.fillStyle = '#fff'; g.beginPath(); g.moveTo(40, 48); g.quadraticCurveTo(50, 40, 62, 48); g.quadraticCurveTo(51, 51, 40, 48); g.fill();
    g.fillStyle = 'rgba(255,255,255,.85)'; dot(g, 26, 66, 3); dot(g, 38, 72, 3); dot(g, 50, 70, 3);
  };
  ART.takeaway = function (g) {               // clear takeaway box, rinsed: empty and sparkling
    shadow(g, 50, 88, 36);
    g.fillStyle = lin(g, 0, 50, 0, 86, [[0, 'rgba(215,238,250,.95)'], [1, 'rgba(150,200,230,.95)']]);
    poly(g, [[10, 50], [90, 50], [80, 84], [20, 84]]); g.fill();
    g.fillStyle = 'rgba(255,255,255,.55)'; poly(g, [[18, 55], [82, 55], [75, 78], [25, 78]]); g.fill();
    g.fillStyle = lin(g, 0, 20, 0, 50, [[0, 'rgba(235,248,255,.95)'], [1, 'rgba(180,220,242,.9)']]);
    poly(g, [[10, 48], [22, 22], [78, 22], [90, 48]]); g.fill();
    g.strokeStyle = 'rgba(70,130,180,.6)'; g.lineWidth = 1.5;
    poly(g, [[10, 50], [90, 50], [80, 84], [20, 84]]); g.stroke(); poly(g, [[10, 48], [22, 22], [78, 22], [90, 48]]); g.stroke();
    g.beginPath(); g.moveTo(28, 30); g.lineTo(72, 30); g.moveTo(24, 40); g.lineTo(76, 40); g.stroke();
    sparkle(g, 70, 64, 8, '#fff'); sparkle(g, 34, 68, 5, '#fff'); sparkle(g, 82, 30, 5, '#FFE88A');
  };
  ART.redpacket = function (g) {              // red packet (ang bao)
    shadow(g, 50, 92, 22);
    g.save(); g.translate(50, 52); g.rotate(0.1);
    g.fillStyle = lin(g, -24, 0, 24, 0, [[0, '#B5121B'], [.35, '#F0343C'], [1, '#A30F18']]); rr(g, -24, -40, 48, 80, 4); g.fill();
    g.fillStyle = '#C91A24'; g.beginPath(); g.moveTo(-24, -40); g.lineTo(24, -40); g.lineTo(24, -22); g.quadraticCurveTo(0, -6, -24, -22); g.closePath(); g.fill();
    g.strokeStyle = '#F5C542'; g.lineWidth = 1.4; g.beginPath(); g.moveTo(-24, -22); g.quadraticCurveTo(0, -6, 24, -22); g.stroke();
    g.fillStyle = rad(g, -2, 6, 14, [[0, '#FFE58A'], [1, '#D9A21B']]); dot(g, 0, 10, 12);
    g.fillStyle = '#B5121B'; g.fillRect(-4, 6, 8, 8);
    g.fillStyle = 'rgba(255,255,255,.3)'; rr(g, -20, -36, 4, 70, 2); g.fill();
    g.restore();
  };
  ART.paperbag = function (g) {               // brown paper carrier bag with twisted handles
    shadow(g, 50, 92, 26);
    g.strokeStyle = '#8A5E30'; g.lineWidth = 3; g.beginPath(); g.arc(46, 28, 11, 3.14, 0); g.stroke();
    g.fillStyle = lin(g, 0, 28, 0, 92, [[0, '#E3B783'], [1, '#B98549']]);
    poly(g, [[22, 30], [70, 30], [72, 92], [20, 92]]); g.fill();
    g.fillStyle = lin(g, 70, 0, 86, 0, [[0, '#A8743C'], [1, '#8A5E30']]);
    poly(g, [[70, 30], [84, 26], [86, 86], [72, 92]]); g.fill();
    g.strokeStyle = 'rgba(120,80,35,.5)'; g.lineWidth = 1.2; g.beginPath(); g.moveTo(77, 28); g.lineTo(79, 89); g.stroke();
    g.strokeStyle = '#6E4720'; g.lineWidth = 3; g.beginPath(); g.arc(46, 34, 11, 3.14, 0); g.stroke();
    recycleMark(g, 46, 64, 10, 'rgba(255,243,224,.9)');
    g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(25, 34, 4, 54);
  };
  ART.shred = function (g) {                  // a heap of shredded paper strips
    shadow(g, 50, 88, 36);
    var cols = ['#FFFFFF', '#E6EAF0', '#F7F3E6', '#D9E4F2', '#FFFFFF', '#EDE7D8'];
    var seed = 7; function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
    for (var i = 0; i < 46; i++) {
      var a = rnd() * 3.14, d = rnd(), x = 50 + (rnd() - .5) * 62 * (1 - d * .35), y = 82 - d * 44 * (1 - Math.abs(x - 50) / 46);
      g.save(); g.translate(x, y); g.rotate(a - 1.57 + (rnd() - .5));
      g.fillStyle = cols[i % 6]; g.fillRect(-11, -1.6, 22, 3.2);
      g.fillStyle = 'rgba(70,90,120,.35)'; g.fillRect(-8, -.5, 5, 1); g.fillRect(1, -.5, 6, 1);
      g.restore();
    }
  };
  ART.receipt = function (g) {                // long till receipt with a torn end
    shadow(g, 50, 92, 20);
    g.fillStyle = lin(g, 30, 0, 72, 0, [[0, '#E3E7ED'], [.3, '#FFFFFF'], [1, '#D3D9E2']]);
    g.beginPath(); g.moveTo(32, 10); g.quadraticCurveTo(40, 6, 68, 12); g.lineTo(70, 86);
    for (var x = 70; x > 30; x -= 5) { g.lineTo(x - 2.5, 91); g.lineTo(x - 5, 86); }
    g.closePath(); g.fill();
    g.fillStyle = '#3B4A63'; g.fillRect(40, 18, 22, 4);
    g.fillStyle = '#8D99AB'; for (var i = 0; i < 7; i++) { g.fillRect(36, 30 + i * 6, 16, 2); g.fillRect(58, 30 + i * 6, 8, 2); }
    g.fillStyle = '#3B4A63'; g.fillRect(36, 74, 12, 3.5); g.fillRect(54, 74, 12, 3.5);
  };
  ART.greeting = function (g) {               // standing greeting card with a heart
    shadow(g, 52, 90, 30);
    g.fillStyle = lin(g, 50, 0, 90, 0, [[0, '#D9DEE6'], [1, '#F4F6F9']]); poly(g, [[52, 22], [88, 30], [88, 84], [52, 90]]); g.fill();
    g.fillStyle = lin(g, 14, 0, 54, 0, [[0, '#FFF6DA'], [1, '#FFE49A']]); poly(g, [[14, 28], [52, 22], [52, 90], [14, 84]]); g.fill();
    g.strokeStyle = '#F2B233'; g.lineWidth = 1.5; poly(g, [[18, 32], [48, 27.5], [48, 85], [18, 80]]); g.stroke();
    g.fillStyle = '#E8423A'; g.beginPath(); g.moveTo(33, 66); g.bezierCurveTo(14, 52, 24, 38, 33, 48); g.bezierCurveTo(42, 38, 52, 52, 33, 66); g.fill();
    g.fillStyle = 'rgba(255,255,255,.6)'; dot(g, 28, 48, 2.2);
    g.fillStyle = '#9AA5B6'; g.fillRect(58, 46, 22, 2.5); g.fillRect(58, 53, 22, 2.5); g.fillRect(58, 60, 14, 2.5);
  };
  ART.giftwrap = function (g) {               // roll of plain printed wrapping paper
    shadow(g, 50, 88, 34);
    g.fillStyle = lin(g, 0, 50, 0, 88, [[0, '#57C4A0'], [1, '#2F9273']]);
    g.beginPath(); g.moveTo(40, 52); g.lineTo(90, 62); g.quadraticCurveTo(84, 80, 88, 86); g.lineTo(34, 78); g.closePath(); g.fill();
    g.fillStyle = '#fff'; [[52, 64], [66, 70], [78, 68], [48, 74], [62, 80], [76, 80]].forEach(function (p) { dot(g, p[0], p[1], 2.2); });
    g.save(); g.translate(42, 44); g.rotate(-0.5);
    g.fillStyle = lin(g, 0, -11, 0, 11, [[0, '#8BE3C4'], [.4, '#4DBE99'], [1, '#237A5E']]); g.fillRect(-34, -10, 68, 20);
    oval(g, -34, 0, 4.5, 10); g.fill();
    g.fillStyle = '#fff'; for (var i = 0; i < 5; i++) { dot(g, -24 + i * 13, -3 + (i % 2) * 6, 2.2); }
    g.fillStyle = '#E9F7F2'; oval(g, 34, 0, 4.5, 10); g.fill();
    g.fillStyle = '#B98549'; oval(g, 34, 0, 2.4, 5.5); g.fill();
    g.fillStyle = 'rgba(255,255,255,.4)'; rr(g, -30, -8, 58, 2.6, 1.3); g.fill();
    g.restore();
  };
  ART.tissue = function (g) {                 // used, crumpled tissue
    shadow(g, 50, 86, 30);
    g.fillStyle = rad(g, 40, 40, 46, [[0, '#FFFFFF'], [.6, '#EEF1F5'], [1, '#C5CCD6']]);
    g.beginPath(); g.moveTo(20, 60); g.quadraticCurveTo(12, 40, 30, 34); g.quadraticCurveTo(34, 18, 52, 26);
    g.quadraticCurveTo(70, 16, 74, 36); g.quadraticCurveTo(92, 44, 80, 62); g.quadraticCurveTo(84, 82, 62, 80);
    g.quadraticCurveTo(46, 92, 34, 78); g.quadraticCurveTo(16, 78, 20, 60); g.fill();
    g.strokeStyle = 'rgba(140,150,165,.65)'; g.lineWidth = 1.3;
    g.beginPath(); g.moveTo(30, 36); g.quadraticCurveTo(44, 46, 40, 62); g.moveTo(52, 28); g.quadraticCurveTo(56, 44, 70, 50);
    g.moveTo(40, 62); g.quadraticCurveTo(54, 60, 62, 78); g.moveTo(70, 50); g.quadraticCurveTo(66, 62, 78, 62); g.moveTo(40, 62); g.lineTo(24, 64); g.stroke();
    g.fillStyle = 'rgba(190,170,90,.35)'; oval(g, 56, 58, 9, 6, .3); g.fill();          // it has been used
  };
  ART.plate = function (g) {                  // paper plate with fluted rim and a food smear
    shadow(g, 50, 82, 38);
    g.fillStyle = lin(g, 0, 36, 0, 80, [[0, '#FFFFFF'], [1, '#CDD4DE']]); oval(g, 50, 58, 42, 22); g.fill();
    g.strokeStyle = '#B9C2CE'; g.lineWidth = 1;
    for (var i = 0; i < 28; i++) { var a = i * 6.2832 / 28; g.beginPath(); g.moveTo(50 + Math.cos(a) * 31, 57 + Math.sin(a) * 15.5); g.lineTo(50 + Math.cos(a) * 41, 58 + Math.sin(a) * 21.4); g.stroke(); }
    g.fillStyle = lin(g, 0, 44, 0, 72, [[0, '#E6EAF0'], [1, '#FFFFFF']]); oval(g, 50, 57, 30, 15); g.fill();
    g.fillStyle = 'rgba(214,120,40,.7)'; g.beginPath(); g.moveTo(36, 56); g.quadraticCurveTo(48, 46, 62, 54); g.quadraticCurveTo(70, 62, 54, 64); g.quadraticCurveTo(40, 66, 36, 56); g.fill();
    g.fillStyle = '#7FB04A'; oval(g, 44, 60, 3, 1.6, .5); g.fill(); g.fillStyle = '#B2271A'; dot(g, 58, 57, 2);
    g.fillStyle = 'rgba(255,255,255,.7)'; oval(g, 30, 46, 10, 2.4, -.35); g.fill();
  };
  ART.glitter = function (g) {                // sheet of glitter paper, corner curled
    shadow(g, 50, 88, 34);
    g.fillStyle = lin(g, 16, 18, 86, 86, [[0, '#B455E8'], [.5, '#E94FA5'], [1, '#FF9A4D']]);
    poly(g, [[16, 24], [82, 18], [86, 66], [68, 86], [20, 88]]); g.fill();
    g.fillStyle = '#F7D9EE'; poly(g, [[86, 66], [68, 86], [68, 68]]); g.fill();
    var seed = 11; function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
    for (var i = 0; i < 60; i++) {
      var x = 20 + rnd() * 62, y = 24 + rnd() * 60; if (x + y > 150) continue;
      g.fillStyle = ['#FFFFFF', '#FFE88A', '#C9F3FF'][i % 3]; g.globalAlpha = .55 + rnd() * .45; dot(g, x, y, .7 + rnd() * .9);
    }
    g.globalAlpha = 1; sparkle(g, 34, 38, 8); sparkle(g, 60, 56, 10, '#FFF3B0'); sparkle(g, 38, 70, 6); sparkle(g, 70, 32, 5);
  };
  ART.wax = function (g) {                    // wax paper off a roll: translucent, with beaded water
    shadow(g, 50, 88, 34);
    g.fillStyle = lin(g, 0, 30, 0, 86, [[0, 'rgba(250,240,205,.98)'], [1, 'rgba(226,206,150,.98)']]);
    g.beginPath(); g.moveTo(18, 34); g.lineTo(84, 34); g.quadraticCurveTo(80, 60, 86, 84); g.quadraticCurveTo(50, 92, 16, 82); g.quadraticCurveTo(22, 58, 18, 34); g.fill();
    g.fillStyle = lin(g, 0, 18, 0, 38, [[0, '#FFF9E3'], [.5, '#EBD9A6'], [1, '#B79B55']]); rr(g, 12, 20, 78, 16, 8); g.fill();
    g.fillStyle = '#8A7238'; oval(g, 86, 28, 3, 6); g.fill();
    g.fillStyle = 'rgba(255,255,255,.6)'; g.save(); g.translate(28, 46); g.rotate(.5); g.fillRect(0, 0, 4, 38); g.fillRect(12, -4, 2, 40); g.restore();
    [[40, 58, 4.5], [58, 68, 3.6], [66, 52, 3], [46, 76, 2.6]].forEach(function (p) {     // water beads on the coating
      g.fillStyle = 'rgba(120,190,235,.85)'; dot(g, p[0], p[1], p[2]); g.fillStyle = '#fff'; dot(g, p[0] - p[2] * .3, p[1] - p[2] * .35, p[2] * .3); });
  };

  /* --- plastics --- */
  ART.pfilm = function (g) {                  // roll of clear plastic film, a sheet pulled out
    shadow(g, 50, 88, 34);
    g.fillStyle = lin(g, 0, 44, 0, 88, [[0, 'rgba(205,232,250,.9)'], [1, 'rgba(140,195,235,.75)']]);
    g.beginPath(); g.moveTo(24, 44); g.lineTo(78, 44); g.quadraticCurveTo(86, 66, 80, 86); g.quadraticCurveTo(52, 80, 20, 88); g.quadraticCurveTo(28, 64, 24, 44); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.9)'; g.lineWidth = 2; g.beginPath(); g.moveTo(34, 50); g.quadraticCurveTo(40, 66, 32, 82); g.moveTo(60, 50); g.quadraticCurveTo(70, 64, 64, 80); g.stroke();
    g.fillStyle = lin(g, 0, 22, 0, 46, [[0, '#F4FAFF'], [.45, '#A9D3F2'], [1, '#5C97C9']]); rr(g, 14, 24, 72, 22, 11); g.fill();
    g.fillStyle = '#E9D9B8'; oval(g, 80, 35, 5, 10); g.fill(); g.fillStyle = '#9C7B46'; oval(g, 80, 35, 2.4, 5.5); g.fill();
    shine(g, 22, 28, 50, 3.5, .8);
  };
  ART.ziplock = function (g) {                // empty zip bag with a coloured seal
    shadow(g, 50, 90, 30);
    g.fillStyle = lin(g, 20, 0, 80, 0, [[0, 'rgba(190,225,248,.92)'], [.4, 'rgba(235,247,255,.95)'], [1, 'rgba(165,208,240,.92)']]);
    rr(g, 20, 16, 60, 74, 5); g.fill();
    g.strokeStyle = 'rgba(70,130,180,.65)'; g.lineWidth = 1.5; rr(g, 20, 16, 60, 74, 5); g.stroke();
    g.fillStyle = '#E8423A'; g.fillRect(20, 26, 60, 3.2); g.fillStyle = '#2F78D6'; g.fillRect(20, 30.5, 60, 3.2);
    g.fillStyle = '#fff'; rr(g, 66, 23, 9, 13, 2); g.fill(); g.strokeStyle = '#8D99AB'; g.lineWidth = 1; g.stroke();
    g.fillStyle = 'rgba(255,255,255,.75)'; g.save(); g.translate(30, 44); g.rotate(.35); g.fillRect(0, 0, 5, 34); g.fillRect(10, -2, 2.5, 30); g.restore();
  };
  ART.hanger = function (g) {                 // plastic clothes hanger
    shadow(g, 50, 88, 34);
    g.lineCap = 'round'; g.lineJoin = 'round';
    function body() { g.beginPath(); g.moveTo(50, 40); g.lineTo(12, 66); g.quadraticCurveTo(8, 74, 16, 74); g.lineTo(84, 74); g.quadraticCurveTo(92, 74, 88, 66); g.closePath(); }
    function hook() { g.beginPath(); g.moveTo(50, 40); g.lineTo(50, 31); g.quadraticCurveTo(50, 26, 55, 24); g.arc(52, 17, 8, .9, 3.6, true); }
    g.strokeStyle = '#1B8F7A'; g.lineWidth = 9; body(); g.stroke(); hook(); g.stroke();
    g.strokeStyle = '#3FD0B4'; g.lineWidth = 6; body(); g.stroke(); hook(); g.stroke();
    g.strokeStyle = 'rgba(255,255,255,.7)'; g.lineWidth = 1.6; g.beginPath(); g.moveTo(47, 40); g.lineTo(17, 61); g.stroke();
  };
  ART.chips = function (g) {                  // crisp packet, opened: the silver foil lining shows
    shadow(g, 50, 92, 26);
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#C98A00'], [.3, '#FFD23F'], [.7, '#F5B800'], [1, '#B07600']]);
    g.beginPath(); g.moveTo(24, 24); g.quadraticCurveTo(50, 30, 76, 22); g.quadraticCurveTo(84, 56, 78, 90); g.lineTo(22, 90); g.quadraticCurveTo(16, 56, 24, 24); g.fill();
    g.fillStyle = lin(g, 0, 8, 0, 28, [[0, '#F4F6F9'], [.5, '#AEB6C2'], [1, '#7D8592']]);                // foil inside
    g.beginPath(); g.moveTo(24, 24); g.lineTo(28, 10); g.lineTo(36, 16); g.lineTo(44, 8); g.lineTo(52, 15); g.lineTo(62, 7); g.lineTo(68, 14); g.lineTo(76, 22); g.quadraticCurveTo(50, 30, 24, 24); g.fill();
    g.fillStyle = '#D6321F'; oval(g, 50, 54, 20, 13, -.12); g.fill();
    g.fillStyle = '#fff'; g.font = '900 10px sans-serif'; g.textAlign = 'center'; g.fillText('CHIPS', 50, 58);
    g.fillStyle = '#F2C879'; oval(g, 40, 78, 7, 4, .3); g.fill(); oval(g, 58, 76, 7, 4, -.3); g.fill();
    g.fillStyle = '#7D8592'; g.fillRect(22, 86, 56, 4);
    shine(g, 28, 32, 4, 46, .6);
  };
  ART.blister = function (g) {                // foil-backed blister pack, two pills pushed out
    shadow(g, 50, 86, 34);
    g.save(); g.translate(50, 54); g.rotate(-0.12);
    g.fillStyle = lin(g, -36, -24, 36, 24, [[0, '#F4F6F9'], [.5, '#B9C1CC'], [1, '#8A93A0']]); rr(g, -36, -24, 72, 48, 5); g.fill();
    for (var r = 0; r < 2; r++) for (var c = 0; c < 4; c++) {
      var x = -25.5 + c * 17, y = -11 + r * 22, out = (r === 0 && c === 3) || (r === 1 && c === 0);
      if (out) { g.fillStyle = '#6E7785'; oval(g, x, y, 6, 6); g.fill(); g.fillStyle = '#D5DBE4'; poly(g, [[x - 5, y - 2], [x + 1, y - 6], [x + 3, y + 1]]); g.fill(); }
      else { g.fillStyle = rad(g, x - 2, y - 2, 8, [[0, '#FFFFFF'], [.5, '#FF9DB5'], [1, '#D9486E']]); oval(g, x, y, 6.5, 6.5); g.fill();
        g.fillStyle = 'rgba(255,255,255,.85)'; oval(g, x - 2, y - 2.5, 2.4, 1.4, -.6); g.fill(); }
    }
    g.fillStyle = 'rgba(255,255,255,.55)'; g.fillRect(-36, -24, 72, 3);
    g.restore();
  };
  ART.ccard = function (g) {                  // expired bank card, cut corner
    shadow(g, 50, 82, 36);
    g.save(); g.translate(50, 52); g.rotate(-0.16);
    g.fillStyle = lin(g, -38, -24, 38, 24, [[0, '#2F78D6'], [.6, '#1B4E9E'], [1, '#12356E']]);
    g.beginPath(); g.moveTo(-34, -24); g.lineTo(38, -24); g.lineTo(38, 10); g.lineTo(22, 24); g.lineTo(-34, 24); g.arcTo(-38, 24, -38, 20, 4); g.lineTo(-38, -20); g.arcTo(-38, -24, -34, -24, 4); g.fill();
    g.fillStyle = lin(g, -30, -10, -14, 2, [[0, '#FFE58A'], [1, '#C9971A']]); rr(g, -30, -12, 16, 12, 2.5); g.fill();
    g.strokeStyle = '#8A6A10'; g.lineWidth = .8; g.beginPath(); g.moveTo(-30, -6); g.lineTo(-14, -6); g.moveTo(-22, -12); g.lineTo(-22, 0); g.stroke();
    g.fillStyle = 'rgba(255,255,255,.9)'; for (var i = 0; i < 4; i++) g.fillRect(-30 + i * 14, 7, 10, 3);
    g.fillStyle = 'rgba(255,255,255,.6)'; g.fillRect(-30, 15, 22, 2.4);
    g.fillStyle = '#E8423A'; dot(g, 22, -12, 7); g.fillStyle = 'rgba(255,190,60,.9)'; dot(g, 30, -12, 7);
    g.fillStyle = 'rgba(255,255,255,.22)'; poly(g, [[-38, -24], [-8, -24], [-30, 24], [-38, 24]]); g.fill();
    g.restore();
  };
  ART.melamine = function (g) {               // hard patterned melamine plate
    shadow(g, 50, 84, 38);
    g.fillStyle = lin(g, 0, 34, 0, 82, [[0, '#FFD9E6'], [1, '#E58AAE']]); oval(g, 50, 58, 42, 24); g.fill();
    g.fillStyle = lin(g, 0, 40, 0, 76, [[0, '#F7A8C4'], [1, '#FFE6EF']]); oval(g, 50, 57, 30, 16); g.fill();
    g.fillStyle = '#fff'; for (var i = 0; i < 12; i++) { var a = i * 6.2832 / 12; dot(g, 50 + Math.cos(a) * 36, 58 + Math.sin(a) * 20, 2.3); }
    g.fillStyle = '#E0457B'; for (var k = 0; k < 5; k++) { var b = k * 1.2566; oval(g, 50 + Math.cos(b) * 7, 57 + Math.sin(b) * 4, 5, 3, b); g.fill(); }
    g.fillStyle = '#FFD23F'; oval(g, 50, 57, 3.4, 2.2); g.fill();
    g.fillStyle = 'rgba(255,255,255,.75)'; oval(g, 28, 46, 11, 2.6, -.4); g.fill();
  };
  ART.oilybox = function (g) {                // plastic food container, unrinsed: oil and scraps
    shadow(g, 50, 88, 36);
    g.fillStyle = lin(g, 0, 44, 0, 86, [[0, 'rgba(215,238,250,.95)'], [1, 'rgba(150,200,230,.95)']]);
    poly(g, [[8, 44], [92, 44], [80, 86], [20, 86]]); g.fill();
    g.strokeStyle = 'rgba(70,130,180,.6)'; g.lineWidth = 1.5; poly(g, [[8, 44], [92, 44], [80, 86], [20, 86]]); g.stroke();
    g.fillStyle = 'rgba(255,255,255,.5)'; poly(g, [[18, 50], [82, 50], [74, 80], [26, 80]]); g.fill();
    g.fillStyle = rad(g, 48, 66, 26, [[0, 'rgba(150,80,10,.9)'], [1, 'rgba(214,140,40,.45)']]); oval(g, 50, 67, 24, 9); g.fill();
    g.fillStyle = '#E04A2A'; dot(g, 40, 64, 3); g.fillStyle = '#7FB04A'; oval(g, 60, 68, 4.5, 2, .4); g.fill(); g.fillStyle = '#F7E9C4'; oval(g, 50, 71, 5, 2, -.2); g.fill();
    g.fillStyle = '#C08A1E'; [[26, 38], [70, 36], [84, 42]].forEach(function (p) {
      g.beginPath(); g.moveTo(p[0], p[1] - 6); g.quadraticCurveTo(p[0] + 4, p[1], p[0], p[1] + 3); g.quadraticCurveTo(p[0] - 4, p[1], p[0], p[1] - 6); g.fill(); });
    shine(g, 14, 45.5, 30, 2.5, .8);
  };
  ART.pbag = function (g) {                   // plastic carrier bag with handle loops
    shadow(g, 50, 92, 28);
    g.fillStyle = lin(g, 20, 0, 80, 0, [[0, '#3F8FE0'], [.35, '#9CCBFA'], [.7, '#5FA8F5'], [1, '#2A6CBE']]);
    g.beginPath(); g.moveTo(26, 36); g.lineTo(26, 16); g.quadraticCurveTo(26, 8, 32, 8); g.quadraticCurveTo(38, 8, 38, 16); g.lineTo(38, 30);
    g.quadraticCurveTo(50, 36, 62, 30); g.lineTo(62, 16); g.quadraticCurveTo(62, 8, 68, 8); g.quadraticCurveTo(74, 8, 74, 16); g.lineTo(74, 36);
    g.quadraticCurveTo(84, 62, 78, 90); g.quadraticCurveTo(50, 96, 22, 90); g.quadraticCurveTo(16, 62, 26, 36); g.fill();
    g.strokeStyle = 'rgba(20,70,140,.45)'; g.lineWidth = 1.4; g.beginPath(); g.moveTo(34, 40); g.quadraticCurveTo(30, 64, 36, 88); g.moveTo(64, 40); g.quadraticCurveTo(72, 62, 66, 88); g.stroke();
    recycleMark(g, 50, 62, 10, 'rgba(255,255,255,.9)');
    shine(g, 28, 40, 3.5, 40, .6);
  };
  ART.bubbletea = function (g) {              // empty bubble tea cup, dome lid and fat straw
    shadow(g, 50, 93, 18);
    g.strokeStyle = '#E8423A'; g.lineWidth = 6; g.lineCap = 'round'; g.beginPath(); g.moveTo(56, 30); g.lineTo(64, 4); g.stroke();
    g.fillStyle = lin(g, 30, 0, 70, 0, [[0, 'rgba(175,215,245,.92)'], [.4, 'rgba(240,249,255,.95)'], [1, 'rgba(150,198,236,.92)']]);
    poly(g, [[30, 30], [70, 30], [64, 92], [36, 92]]); g.fill();
    g.strokeStyle = 'rgba(70,130,180,.6)'; g.lineWidth = 1.4; poly(g, [[30, 30], [70, 30], [64, 92], [36, 92]]); g.stroke();
    g.fillStyle = 'rgba(190,140,90,.35)'; poly(g, [[35.4, 80], [64.6, 80], [64, 92], [36, 92]]); g.fill();     // last drops
    g.fillStyle = '#3A2A20'; dot(g, 44, 87, 3); dot(g, 54, 88, 3); dot(g, 49, 83, 2.6);
    g.fillStyle = 'rgba(225,242,253,.95)'; g.beginPath(); g.moveTo(28, 30); g.quadraticCurveTo(50, 8, 72, 30); g.closePath(); g.fill();
    g.strokeStyle = 'rgba(70,130,180,.6)'; g.stroke(); g.fillStyle = '#7FB4DE'; rr(g, 27, 28, 46, 5, 2.5); g.fill();
    shine(g, 37, 38, 4, 40, .75);
  };
  ART.cutlery = function (g) {                // white plastic fork and spoon
    shadow(g, 50, 90, 28);
    function tool(x, rot, spoon) {
      g.save(); g.translate(x, 54); g.rotate(rot);
      var fill = lin(g, -9, 0, 9, 0, [[0, '#CBD3DE'], [.4, '#FFFFFF'], [1, '#B9C2CE']]);
      g.strokeStyle = '#8D99AB'; g.lineWidth = 1.4; g.fillStyle = fill;
      rr(g, -3.5, -8, 7, 44, 3.5); g.fill(); g.stroke();
      if (spoon) { oval(g, 0, -24, 10, 15); g.fill(); g.stroke(); g.fillStyle = 'rgba(140,153,171,.45)'; oval(g, 1, -23, 6, 10.5); g.fill(); }
      else {
        g.beginPath(); g.moveTo(-9, -40); g.lineTo(-9, -18); g.quadraticCurveTo(-9, -8, 0, -8); g.quadraticCurveTo(9, -8, 9, -18); g.lineTo(9, -40);
        g.lineTo(5.6, -40); g.lineTo(5.6, -22); g.lineTo(2.2, -22); g.lineTo(2.2, -40); g.lineTo(-2.2, -40); g.lineTo(-2.2, -22); g.lineTo(-5.6, -22); g.lineTo(-5.6, -40); g.closePath();
        g.fill(); g.stroke();
      }
      g.fillStyle = 'rgba(255,255,255,.9)'; g.fillRect(-1.8, -4, 1.6, 34);
      g.restore();
    }
    tool(36, -0.3, false); tool(64, 0.3, true);
  };
  ART.disc = function (g) {                   // CD / DVD with rainbow sheen
    shadow(g, 50, 90, 32);
    g.fillStyle = lin(g, 12, 14, 88, 86, [[0, '#F4F6F9'], [.5, '#C3CAD4'], [1, '#8A93A0']]); dot(g, 50, 50, 38);
    var cg = g.createConicGradient ? g.createConicGradient(0.6, 50, 50) : null;
    if (cg) { [[0, 'rgba(255,90,120,.55)'], [.17, 'rgba(255,210,80,.55)'], [.33, 'rgba(120,230,150,.55)'], [.5, 'rgba(90,190,255,.55)'], [.67, 'rgba(170,120,255,.55)'], [.83, 'rgba(255,255,255,.3)'], [1, 'rgba(255,90,120,.55)']].forEach(function (s) { cg.addColorStop(s[0], s[1]); });
      g.fillStyle = cg; dot(g, 50, 50, 36); }
    g.fillStyle = 'rgba(255,255,255,.75)'; g.beginPath(); g.moveTo(50, 50); g.arc(50, 50, 36, -2.5, -1.9); g.closePath(); g.fill();
    g.beginPath(); g.moveTo(50, 50); g.arc(50, 50, 36, .64, 1.24); g.closePath(); g.fill();
    g.fillStyle = '#E3E7ED'; dot(g, 50, 50, 12); g.strokeStyle = '#9AA5B6'; g.lineWidth = 1; g.stroke();
    g.fillStyle = '#EAF3FB'; g.globalCompositeOperation = 'destination-out'; dot(g, 50, 50, 5); g.globalCompositeOperation = 'source-over';
    g.strokeStyle = '#8A93A0'; g.lineWidth = 1; g.beginPath(); g.arc(50, 50, 5, 0, 7); g.stroke(); g.beginPath(); g.arc(50, 50, 38, 0, 7); g.stroke();
  };
  ART.detergent = function (g) {              // detergent jug with a handle and screw cap
    shadow(g, 50, 93, 26);
    g.fillStyle = lin(g, 20, 0, 80, 0, [[0, '#C75A00'], [.35, '#FFA53D'], [.7, '#F07F0A'], [1, '#A84A00']]);
    g.beginPath(); g.moveTo(34, 26); g.lineTo(50, 26); g.quadraticCurveTo(78, 28, 80, 48); g.lineTo(80, 86); g.quadraticCurveTo(80, 93, 73, 93);
    g.lineTo(27, 93); g.quadraticCurveTo(20, 93, 20, 86); g.lineTo(20, 46); g.quadraticCurveTo(20, 30, 34, 26); g.fill();
    g.globalCompositeOperation = 'destination-out'; g.beginPath(); g.moveTo(60, 40); g.quadraticCurveTo(72, 40, 72, 50); g.lineTo(72, 60); g.quadraticCurveTo(72, 66, 66, 66); g.quadraticCurveTo(60, 66, 60, 60); g.closePath(); g.fill();
    g.globalCompositeOperation = 'source-over';
    g.fillStyle = lin(g, 28, 0, 52, 0, [[0, '#1B4E9E'], [.4, '#5FA8F5'], [1, '#12356E']]); rr(g, 28, 10, 24, 17, 3); g.fill();
    g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(32, 12, 3, 13);
    g.fillStyle = '#fff'; rr(g, 25, 58, 30, 26, 4); g.fill();
    g.fillStyle = '#2F78D6'; dot(g, 34, 68, 4.5); g.fillStyle = '#5FA8F5'; dot(g, 43, 73, 6); g.fillStyle = '#9CCBFA'; dot(g, 36, 77, 3.4);
    shine(g, 24, 36, 4, 20, .6);
  };
  ART.biobag = function (g) {                 // green "biodegradable" bag: looks virtuous, still a contaminant
    shadow(g, 50, 92, 28);
    g.fillStyle = lin(g, 20, 0, 80, 0, [[0, '#4C9A3A'], [.35, '#A6E08D'], [.7, '#74C45A'], [1, '#3A7A2C']]);
    g.beginPath(); g.moveTo(26, 36); g.lineTo(26, 16); g.quadraticCurveTo(26, 8, 32, 8); g.quadraticCurveTo(38, 8, 38, 16); g.lineTo(38, 30);
    g.quadraticCurveTo(50, 36, 62, 30); g.lineTo(62, 16); g.quadraticCurveTo(62, 8, 68, 8); g.quadraticCurveTo(74, 8, 74, 16); g.lineTo(74, 36);
    g.quadraticCurveTo(84, 62, 78, 90); g.quadraticCurveTo(50, 96, 22, 90); g.quadraticCurveTo(16, 62, 26, 36); g.fill();
    g.fillStyle = '#fff'; g.beginPath(); g.moveTo(36, 70); g.quadraticCurveTo(36, 44, 64, 44); g.quadraticCurveTo(66, 72, 36, 70); g.fill();   // leaf
    g.strokeStyle = '#3A7A2C'; g.lineWidth = 1.6; g.beginPath(); g.moveTo(34, 74); g.quadraticCurveTo(46, 60, 60, 48); g.stroke();
    g.fillStyle = '#fff'; g.font = '900 9px sans-serif'; g.textAlign = 'center'; g.fillText('BIO', 50, 85);
    shine(g, 28, 40, 3.5, 30, .5);
  };
  ART.sfcup = function (g) {                  // white foam cup, pitted, with a bite out of the rim
    shadow(g, 50, 93, 18);
    g.fillStyle = lin(g, 28, 0, 72, 0, [[0, '#D3D9E2'], [.35, '#FFFFFF'], [1, '#BFC7D2']]);
    poly(g, [[28, 22], [72, 22], [64, 92], [36, 92]]); g.fill();
    g.fillStyle = '#E9EDF2'; oval(g, 50, 22, 22, 6); g.fill(); g.strokeStyle = '#AEB8C6'; g.lineWidth = 1.2; g.stroke();
    g.fillStyle = '#C9D0DA'; oval(g, 50, 23, 17, 4); g.fill();
    g.globalCompositeOperation = 'destination-out'; dot(g, 70, 24, 6); g.globalCompositeOperation = 'source-over';
    g.fillStyle = '#9AA5B6'; var seed = 5; function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
    for (var i = 0; i < 26; i++) { var y = 32 + rnd() * 56, hw = 20 - (y - 22) * .11; dot(g, 50 + (rnd() - .5) * 2 * hw, y, .9); }
    g.strokeStyle = '#C3CAD4'; g.lineWidth = 1.2; g.beginPath(); g.moveTo(30, 40); g.lineTo(70, 40); g.stroke();
    shine(g, 35, 30, 4, 50, .5);
  };
  ART.vtape = function (g) {                  // video cassette
    shadow(g, 50, 84, 38);
    g.fillStyle = lin(g, 0, 28, 0, 80, [[0, '#4A5263'], [1, '#1E232D']]); rr(g, 8, 28, 84, 52, 5); g.fill();
    g.fillStyle = '#F4F6F9'; rr(g, 16, 34, 68, 12, 2); g.fill();
    g.fillStyle = '#E8423A'; g.fillRect(16, 34, 68, 3.5); g.fillStyle = '#8D99AB'; g.fillRect(20, 40, 34, 2.4);
    g.fillStyle = 'rgba(200,225,245,.85)'; rr(g, 20, 52, 60, 20, 4); g.fill();
    [34, 66].forEach(function (x) { g.fillStyle = '#12151B'; dot(g, x, 62, 8.5); g.fillStyle = '#F4F6F9'; dot(g, x, 62, 4.6);
      g.fillStyle = '#12151B'; for (var i = 0; i < 6; i++) { dot(g, x + Math.cos(i * 1.047) * 3.2, 62 + Math.sin(i * 1.047) * 3.2, .9); } });
    g.fillStyle = '#3A2A20'; g.fillRect(42, 58, 16, 8);
    g.fillStyle = 'rgba(255,255,255,.25)'; g.fillRect(10, 29, 80, 2.4);
  };

  /* --- metal --- */
  ART.cap = function (g) {                    // crown bottle cap
    shadow(g, 50, 82, 30);
    g.fillStyle = lin(g, 0, 50, 0, 78, [[0, '#B9C1CC'], [1, '#6B7380']]);
    g.beginPath(); for (var i = 0; i <= 42; i++) { var a = i * 6.2832 / 42, r = (i % 2 ? 34 : 30.5); var x = 50 + Math.cos(a) * r, y = 60 + Math.sin(a) * r * .5; if (i) g.lineTo(x, y); else g.moveTo(x, y); } g.closePath(); g.fill();
    g.fillStyle = lin(g, 20, 30, 80, 66, [[0, '#F4514A'], [.5, '#D6321F'], [1, '#9E1B1B']]); oval(g, 50, 50, 30, 15); g.fill();
    g.fillStyle = lin(g, 0, 50, 0, 62, [[0, '#B5271B'], [1, '#8A93A0']]);
    g.beginPath(); g.moveTo(20, 50); g.lineTo(20.5, 60); g.quadraticCurveTo(50, 76, 79.5, 60); g.lineTo(80, 50); g.quadraticCurveTo(50, 66, 20, 50); g.fill();
    g.fillStyle = '#fff'; g.beginPath(); for (var k = 0; k < 10; k++) { var b = k * .6283 - 1.571, q = (k % 2 ? 4.5 : 10); var sx = 50 + Math.cos(b) * q * 1.25, sy = 50 + Math.sin(b) * q * .62; if (k) g.lineTo(sx, sy); else g.moveTo(sx, sy); } g.closePath(); g.fill();
    g.fillStyle = 'rgba(255,255,255,.6)'; oval(g, 36, 43, 10, 2.4, -.25); g.fill();
  };
  ART.aerosol = function (g) {                // spray can, empty
    shadow(g, 50, 93, 20);
    g.fillStyle = lin(g, 30, 0, 70, 0, [[0, '#7D8592'], [.3, '#F4F6F9'], [.55, '#C3C9D2'], [1, '#5E6672']]);
    rr(g, 30, 30, 40, 63, 6); g.fill();
    g.beginPath(); g.moveTo(30, 34); g.quadraticCurveTo(32, 22, 42, 20); g.lineTo(58, 20); g.quadraticCurveTo(68, 22, 70, 34); g.closePath(); g.fill();
    g.fillStyle = lin(g, 30, 0, 70, 0, [[0, '#1B8F7A'], [.3, '#5FE0C4'], [1, '#12695A']]); g.fillRect(30, 46, 40, 30);
    g.fillStyle = '#fff'; dot(g, 50, 61, 9); g.fillStyle = '#1B8F7A';
    for (var i = 0; i < 6; i++) dot(g, 50 + Math.cos(i * 1.047) * 5, 61 + Math.sin(i * 1.047) * 5, 1.5);
    g.fillStyle = lin(g, 42, 0, 58, 0, [[0, '#D5DBE4'], [.4, '#FFFFFF'], [1, '#AEB8C6']]); rr(g, 43, 8, 14, 13, 3); g.fill();
    g.fillStyle = '#3B4A63'; dot(g, 44, 13, 1.6);
    shine(g, 35, 34, 4, 54, .75);
  };
  ART.rusty = function (g) {                  // food can eaten by rust, lid bent open
    shadow(g, 50, 90, 24);
    g.fillStyle = lin(g, 26, 0, 74, 0, [[0, '#6B5140'], [.3, '#B9A698'], [1, '#5A4334']]); rr(g, 26, 28, 48, 60, 4); g.fill();
    g.strokeStyle = 'rgba(70,45,30,.5)'; g.lineWidth = 1.2; [42, 52, 62, 72].forEach(function (y) { g.beginPath(); g.moveTo(26, y); g.lineTo(74, y); g.stroke(); });
    [[36, 44, 9, 6], [60, 58, 11, 8], [42, 76, 10, 6], [68, 80, 6, 5], [30, 62, 5, 7], [64, 38, 6, 4]].forEach(function (p, i) {
      g.fillStyle = rad(g, p[0], p[1], p[2], [[0, '#7A2E0C'], [.6, '#B5521B'], [1, 'rgba(214,120,50,.0)']]); oval(g, p[0], p[1], p[2], p[3], i * .7); g.fill(); });
    g.fillStyle = '#4A2410'; dot(g, 58, 57, 2.2); dot(g, 38, 45, 1.6); dot(g, 43, 77, 1.8);
    g.fillStyle = '#3A2A20'; oval(g, 50, 28, 24, 7); g.fill();
    g.fillStyle = lin(g, 30, 6, 70, 26, [[0, '#C9B8A8'], [1, '#8A6A52']]); oval(g, 56, 17, 21, 8, -.5); g.fill();
    g.fillStyle = rad(g, 60, 14, 9, [[0, '#8A3A12'], [1, 'rgba(181,82,27,0)']]); oval(g, 60, 15, 9, 4, -.5); g.fill();
  };
  ART.fork = function (g) {                   // stainless steel fork
    shadow(g, 50, 90, 26);
    g.save(); g.translate(50, 52); g.rotate(0.5);
    var st = lin(g, -9, 0, 9, 0, [[0, '#7D8592'], [.3, '#FFFFFF'], [.55, '#C3C9D2'], [1, '#5E6672']]);
    g.fillStyle = st; g.strokeStyle = '#5E6672'; g.lineWidth = 1;
    g.beginPath(); g.moveTo(-3, -8); g.quadraticCurveTo(-4.5, 20, -5, 40); g.quadraticCurveTo(0, 46, 5, 40); g.quadraticCurveTo(4.5, 20, 3, -8); g.closePath(); g.fill(); g.stroke();
    g.beginPath(); g.moveTo(-9, -44); g.lineTo(-9, -22); g.quadraticCurveTo(-9, -8, 0, -6); g.quadraticCurveTo(9, -8, 9, -22); g.lineTo(9, -44);
    g.lineTo(6, -44); g.lineTo(6, -24); g.lineTo(3.2, -24); g.lineTo(1.5, -44); g.lineTo(-1.5, -44); g.lineTo(-3.2, -24); g.lineTo(-6, -24); g.lineTo(-6, -44); g.closePath(); g.fill(); g.stroke();
    g.fillStyle = 'rgba(255,255,255,.85)'; g.fillRect(-2, 0, 1.6, 36);
    g.restore();
  };
  ART.swool = function (g) {                  // steel wool pad: a tangle of fine wire
    shadow(g, 50, 84, 34);
    g.fillStyle = rad(g, 42, 46, 40, [[0, '#C3C9D2'], [.7, '#8A93A0'], [1, '#5E6672']]); oval(g, 50, 56, 36, 24); g.fill();
    var seed = 3; function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
    g.lineWidth = .9;
    for (var i = 0; i < 70; i++) {
      var a = rnd() * 6.283, d = Math.sqrt(rnd()), x = 50 + Math.cos(a) * d * 32, y = 56 + Math.sin(a) * d * 21;
      g.strokeStyle = ['rgba(255,255,255,.85)', 'rgba(60,68,80,.7)', 'rgba(190,198,210,.9)'][i % 3];
      g.beginPath(); g.arc(x, y, 3 + rnd() * 5, rnd() * 6.283, rnd() * 6.283 + 3.6); g.stroke();
    }
  };
  ART.paint = function (g) {                  // paint tin with a wire handle, lid off and empty
    shadow(g, 50, 92, 28);
    g.strokeStyle = '#6B7380'; g.lineWidth = 2.2; g.beginPath(); g.moveTo(22, 40); g.quadraticCurveTo(50, 2, 78, 40); g.stroke();
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#7D8592'], [.3, '#F4F6F9'], [.55, '#C3C9D2'], [1, '#5E6672']]); rr(g, 22, 36, 56, 56, 5); g.fill();
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#1B4E9E'], [.3, '#5FA8F5'], [1, '#12356E']]); g.fillRect(22, 52, 56, 28);
    g.fillStyle = '#fff'; g.font = '900 10px sans-serif'; g.textAlign = 'center'; g.fillText('PAINT', 50, 70);
    g.fillStyle = '#E3E7ED'; oval(g, 50, 36, 28, 8); g.fill(); g.strokeStyle = '#8A93A0'; g.lineWidth = 1.2; g.stroke();
    g.fillStyle = '#4A5263'; oval(g, 50, 37, 23, 5.6); g.fill();
    g.fillStyle = '#5FA8F5'; g.beginPath(); g.moveTo(30, 40); g.quadraticCurveTo(30, 52, 33, 52); g.quadraticCurveTo(36, 52, 36, 42); g.closePath(); g.fill();
    g.fillStyle = '#4A5263'; dot(g, 22, 41, 2.6); dot(g, 78, 41, 2.6);
    shine(g, 27, 44, 4, 44, .6);
  };
  ART.biscuit = function (g) {                // round biscuit tin with a patterned lid
    shadow(g, 50, 88, 36);
    g.fillStyle = lin(g, 12, 0, 88, 0, [[0, '#8A1A2B'], [.3, '#E0455F'], [.6, '#B5273F'], [1, '#6E1220']]);
    g.beginPath(); g.moveTo(12, 46); g.lineTo(12, 74); g.quadraticCurveTo(50, 98, 88, 74); g.lineTo(88, 46); g.closePath(); g.fill();
    g.fillStyle = '#F5C542'; g.beginPath(); g.moveTo(12, 60); g.quadraticCurveTo(50, 84, 88, 60); g.lineTo(88, 64); g.quadraticCurveTo(50, 88, 12, 64); g.closePath(); g.fill();
    g.fillStyle = lin(g, 12, 28, 88, 64, [[0, '#F7D774'], [.5, '#E0A82A'], [1, '#B07A10']]); oval(g, 50, 46, 38, 19); g.fill();
    g.fillStyle = lin(g, 0, 30, 0, 62, [[0, '#F0607A'], [1, '#B5273F']]); oval(g, 50, 46, 32, 15.5); g.fill();
    g.fillStyle = '#F5C542'; for (var i = 0; i < 8; i++) { var a = i * .7854; oval(g, 50 + Math.cos(a) * 17, 46 + Math.sin(a) * 8.2, 4.4, 2.2, a * .5); g.fill(); }
    g.fillStyle = '#FFF3C4'; oval(g, 50, 46, 8, 4); g.fill();
    g.fillStyle = 'rgba(255,255,255,.55)'; oval(g, 32, 38, 12, 2.6, -.3); g.fill();
  };

  /* --- glass --- */
  ART.dglass = function (g) {                 // plain drinking tumbler, empty
    shadow(g, 50, 93, 20);
    g.fillStyle = lin(g, 28, 0, 72, 0, [[0, 'rgba(150,200,235,.75)'], [.4, 'rgba(235,247,255,.9)'], [1, 'rgba(130,185,225,.75)']]);
    poly(g, [[28, 18], [72, 18], [66, 92], [34, 92]]); g.fill();
    g.strokeStyle = 'rgba(60,120,175,.75)'; g.lineWidth = 1.6; poly(g, [[28, 18], [72, 18], [66, 92], [34, 92]]); g.stroke();
    g.fillStyle = 'rgba(120,180,225,.6)'; poly(g, [[33.2, 82], [66.8, 82], [66, 92], [34, 92]]); g.fill();
    g.fillStyle = 'rgba(245,251,255,.9)'; oval(g, 50, 18, 22, 5); g.fill(); g.stroke();
    shine(g, 35, 26, 4.5, 50, .85); shine(g, 62, 30, 2.5, 30, .5);
  };
  ART.pyrex = function (g) {                  // oven-safe glass dish with handles, amber-tinted
    shadow(g, 50, 86, 40);
    g.fillStyle = lin(g, 0, 42, 0, 84, [[0, 'rgba(250,225,170,.92)'], [1, 'rgba(214,165,80,.92)']]);
    poly(g, [[14, 44], [86, 44], [76, 84], [24, 84]]); g.fill();
    g.strokeStyle = 'rgba(150,100,30,.7)'; g.lineWidth = 1.6; poly(g, [[14, 44], [86, 44], [76, 84], [24, 84]]); g.stroke();
    g.fillStyle = 'rgba(255,245,215,.95)'; rr(g, 4, 40, 92, 8, 4); g.fill(); g.stroke();
    g.fillStyle = 'rgba(255,255,255,.4)'; poly(g, [[24, 52], [76, 52], [70, 78], [30, 78]]); g.fill();
    g.strokeStyle = '#E8423A'; g.lineWidth = 2.2; g.lineCap = 'round';                       // heat marks: it is oven glass
    [38, 50, 62].forEach(function (x) { g.beginPath(); g.moveTo(x, 34); g.quadraticCurveTo(x - 5, 28, x, 22); g.quadraticCurveTo(x + 5, 16, x, 10); g.stroke(); });
    shine(g, 20, 50, 3.5, 26, .7);
  };
  ART.mirror = function (g) {                 // hand mirror with a reflection streak
    shadow(g, 50, 93, 20);
    g.fillStyle = lin(g, 44, 0, 56, 0, [[0, '#B07A10'], [.4, '#F7D774'], [1, '#8A5E08']]); rr(g, 44, 62, 12, 30, 5); g.fill();
    g.fillStyle = lin(g, 20, 8, 80, 68, [[0, '#F7D774'], [1, '#B07A10']]); oval(g, 50, 38, 30, 32); g.fill();
    g.fillStyle = lin(g, 26, 10, 74, 66, [[0, '#EAF6FF'], [.5, '#A9D3F2'], [1, '#6FA4D6']]); oval(g, 50, 38, 24.5, 26.5); g.fill();
    g.save(); oval(g, 50, 38, 24.5, 26.5); g.clip();
    g.fillStyle = 'rgba(255,255,255,.8)'; poly(g, [[22, 40], [50, 8], [60, 8], [28, 48]]); g.fill(); poly(g, [[36, 58], [70, 20], [74, 24], [42, 60]]); g.fill();
    g.restore();
    sparkle(g, 66, 24, 6);
  };
  ART.bulb = function (g) {                   // light bulb with screw base
    shadow(g, 50, 93, 16);
    g.fillStyle = rad(g, 42, 30, 34, [[0, '#FFFFFF'], [.5, '#FFF3B0'], [1, '#F2C94C']]);
    g.beginPath(); g.moveTo(40, 66); g.quadraticCurveTo(38, 56, 30, 48); g.arc(50, 34, 26, 2.55, .59); g.quadraticCurveTo(62, 56, 60, 66); g.closePath(); g.fill();
    g.strokeStyle = '#C9971A'; g.lineWidth = 1.4; g.stroke();
    g.strokeStyle = '#B5521B'; g.lineWidth = 1.6; g.beginPath(); g.moveTo(44, 66); g.lineTo(44, 46); g.lineTo(47, 40); g.lineTo(50, 46); g.lineTo(53, 40); g.lineTo(56, 46); g.lineTo(56, 66); g.stroke();
    g.fillStyle = lin(g, 38, 0, 62, 0, [[0, '#7D8592'], [.35, '#F4F6F9'], [1, '#5E6672']]); rr(g, 39, 66, 22, 18, 3); g.fill();
    g.strokeStyle = '#5E6672'; g.lineWidth = 1.3; [71, 76, 81].forEach(function (y) { g.beginPath(); g.moveTo(39, y); g.lineTo(61, y - 2); g.stroke(); });
    g.fillStyle = '#3B4A63'; poly(g, [[43, 84], [57, 84], [53, 91], [47, 91]]); g.fill();
    g.fillStyle = 'rgba(255,255,255,.9)'; oval(g, 38, 24, 5, 9, .5); g.fill();
  };
  ART.perfume = function (g) {                // glass perfume bottle with an atomiser
    shadow(g, 50, 93, 22);
    g.fillStyle = lin(g, 26, 0, 74, 0, [[0, 'rgba(225,150,190,.9)'], [.4, 'rgba(255,225,238,.95)'], [1, 'rgba(205,120,165,.9)']]);
    poly(g, [[34, 42], [66, 42], [76, 58], [76, 86], [70, 92], [30, 92], [24, 86], [24, 58]]); g.fill();
    g.strokeStyle = 'rgba(160,70,115,.7)'; g.lineWidth = 1.5; poly(g, [[34, 42], [66, 42], [76, 58], [76, 86], [70, 92], [30, 92], [24, 86], [24, 58]]); g.stroke();
    g.fillStyle = 'rgba(240,120,170,.55)'; poly(g, [[25, 70], [75, 70], [75, 86], [70, 91], [30, 91], [25, 86]]); g.fill();
    g.fillStyle = lin(g, 40, 0, 60, 0, [[0, '#B07A10'], [.4, '#F7D774'], [1, '#8A5E08']]); rr(g, 42, 30, 16, 13, 2); g.fill(); rr(g, 38, 18, 24, 13, 3); g.fill();
    g.fillStyle = '#8A5E08'; g.fillRect(36, 22, 4, 4);
    g.fillStyle = 'rgba(255,255,255,.85)'; rr(g, 40, 60, 20, 8, 2); g.fill();
    shine(g, 29, 58, 4, 26, .8);
  };

  /* --- general waste and special streams --- */
  ART.chopsticks = function (g) {             // disposable wooden chopsticks, snapped apart, sauce on the tips
    shadow(g, 50, 90, 34);
    function stick(x0, y0, x1, y1) {
      var dx = x1 - x0, dy = y1 - y0, L = Math.sqrt(dx * dx + dy * dy);
      g.save(); g.translate(x0, y0); g.rotate(Math.atan2(dy, dx));
      g.fillStyle = lin(g, 0, -3, 0, 3, [[0, '#F7E3B5'], [.5, '#E3C383'], [1, '#B8935A']]);
      poly(g, [[0, -3.4], [L, -1.8], [L, 1.8], [0, 3.4]]); g.fill();
      g.fillStyle = 'rgba(140,60,20,.75)'; poly(g, [[L - 14, -2.1], [L, -1.8], [L, 1.8], [L - 14, 2.1]]); g.fill();
      g.fillStyle = 'rgba(255,255,255,.5)'; g.fillRect(4, -2.4, L - 22, 1.2);
      g.restore();
    }
    stick(14, 26, 84, 80); stick(22, 16, 90, 62);
    g.fillStyle = '#F4F6F9'; g.save(); g.translate(26, 30); g.rotate(.62); rr(g, -8, -11, 22, 22, 2); g.fill();
    g.fillStyle = '#E8423A'; g.fillRect(-4, -5, 14, 3); g.fillRect(-4, 1, 9, 3); g.restore();
  };
  ART.tshirt = function (g) {                 // old T-shirt with a patch
    shadow(g, 50, 90, 32);
    g.fillStyle = lin(g, 10, 0, 90, 0, [[0, '#2E9E86'], [.4, '#63D6BC'], [1, '#237A68']]);
    g.beginPath(); g.moveTo(36, 16); g.quadraticCurveTo(50, 28, 64, 16); g.lineTo(90, 30); g.lineTo(80, 48); g.lineTo(70, 43); g.lineTo(72, 88); g.lineTo(28, 88); g.lineTo(30, 43); g.lineTo(20, 48); g.lineTo(10, 30); g.closePath(); g.fill();
    g.strokeStyle = '#1B6657'; g.lineWidth = 1.6; g.beginPath(); g.moveTo(36, 16); g.quadraticCurveTo(50, 28, 64, 16); g.stroke();
    g.beginPath(); g.moveTo(40, 14.5); g.quadraticCurveTo(50, 22, 60, 14.5); g.stroke();
    g.fillStyle = '#F5C542'; g.save(); g.translate(56, 64); g.rotate(.2); g.fillRect(-7, -7, 14, 14);
    g.strokeStyle = '#8A5E08'; g.lineWidth = 1; g.setLineDash([2, 2]); g.strokeRect(-5, -5, 10, 10); g.setLineDash([]); g.restore();
    g.strokeStyle = 'rgba(20,80,68,.5)'; g.lineWidth = 1.2; g.beginPath(); g.moveTo(34, 60); g.quadraticCurveTo(40, 66, 36, 76); g.moveTo(62, 44); g.quadraticCurveTo(58, 50, 64, 54); g.stroke();
    g.fillStyle = 'rgba(255,255,255,.3)'; poly(g, [[31, 44], [36, 44], [34, 86], [29.5, 86]]); g.fill();
  };
  ART.diaper = function (g) {                 // disposable diaper, rolled and taped shut
    shadow(g, 50, 88, 32);
    g.fillStyle = lin(g, 0, 28, 0, 86, [[0, '#FFFFFF'], [1, '#CBD3DE']]);
    g.beginPath(); g.moveTo(18, 40); g.quadraticCurveTo(50, 22, 82, 40); g.quadraticCurveTo(90, 62, 80, 80); g.quadraticCurveTo(50, 92, 20, 80); g.quadraticCurveTo(10, 62, 18, 40); g.fill();
    g.strokeStyle = '#AEB8C6'; g.lineWidth = 1.3; g.stroke();
    g.fillStyle = '#9CCBFA'; g.beginPath(); g.moveTo(16, 52); g.quadraticCurveTo(50, 40, 84, 52); g.lineTo(85, 60); g.quadraticCurveTo(50, 48, 15, 60); g.closePath(); g.fill();
    g.fillStyle = '#5FA8F5'; rr(g, 26, 47, 14, 9, 2); g.fill(); rr(g, 60, 47, 14, 9, 2); g.fill();
    g.fillStyle = '#F5C542'; sparkle(g, 42, 70, 4, '#F5C542'); sparkle(g, 58, 74, 4, '#F28AB0'); sparkle(g, 50, 64, 3, '#7FD0A0');
    g.strokeStyle = 'rgba(140,150,165,.6)'; g.lineWidth = 1.1; g.beginPath(); g.moveTo(24, 78); g.quadraticCurveTo(50, 84, 76, 78); g.stroke();
  };
  ART.medicine = function (g) {               // amber pill bottle, tipped pills beside it
    shadow(g, 50, 92, 30);
    g.fillStyle = lin(g, 24, 0, 62, 0, [[0, '#B5521B'], [.35, '#F5A04A'], [1, '#8A3A12']]); rr(g, 24, 32, 38, 60, 6); g.fill();
    g.fillStyle = lin(g, 22, 0, 64, 0, [[0, '#D5DBE4'], [.4, '#FFFFFF'], [1, '#AEB8C6']]); rr(g, 22, 16, 42, 18, 4); g.fill();
    g.strokeStyle = '#AEB8C6'; g.lineWidth = 1; for (var x = 27; x < 62; x += 5) { g.beginPath(); g.moveTo(x, 19); g.lineTo(x, 31); g.stroke(); }
    g.fillStyle = '#fff'; g.fillRect(24, 50, 38, 26);
    g.fillStyle = '#E8423A'; g.fillRect(40, 54, 6, 18); g.fillRect(34, 60, 18, 6);
    shine(g, 28, 36, 3.5, 50, .55);
    g.save(); g.translate(78, 84); g.rotate(-.5);
    g.fillStyle = '#E8423A'; rr(g, -11, -5, 22, 10, 5); g.fill(); g.fillStyle = '#FFE58A'; g.beginPath(); g.moveTo(0, -5); g.lineTo(6, -5); g.arc(6, 0, 5, -1.571, 1.571); g.lineTo(0, 5); g.closePath(); g.fill();
    g.fillStyle = 'rgba(255,255,255,.6)'; g.fillRect(-7, -3.2, 12, 1.6); g.restore();
    g.fillStyle = '#F4F6F9'; oval(g, 76, 66, 7, 5); g.fill(); g.strokeStyle = '#AEB8C6'; g.lineWidth = 1; g.stroke(); g.beginPath(); g.moveTo(70, 66); g.lineTo(82, 66); g.stroke();
  };
  ART.fridge = function (g) {                 // old two-door refrigerator
    shadow(g, 50, 94, 24);
    g.fillStyle = lin(g, 26, 0, 74, 0, [[0, '#C3CAD4'], [.3, '#FFFFFF'], [.7, '#E3E7ED'], [1, '#9AA5B6']]); rr(g, 26, 6, 48, 86, 5); g.fill();
    g.strokeStyle = '#8D99AB'; g.lineWidth = 1.4; rr(g, 26, 6, 48, 86, 5); g.stroke(); g.beginPath(); g.moveTo(26, 36); g.lineTo(74, 36); g.stroke();
    g.fillStyle = lin(g, 0, 0, 6, 0, [[0, '#5E6672'], [1, '#8A93A0']]); g.save(); g.translate(64, 0); rr(g, 0, 16, 4, 14, 2); g.fill(); rr(g, 0, 42, 4, 22, 2); g.fill(); g.restore();
    g.fillStyle = '#F5C542'; g.save(); g.translate(40, 22); g.rotate(-.15); g.fillRect(-6, -5, 12, 10); g.restore();
    g.fillStyle = '#E8423A'; dot(g, 36, 50, 2.6); g.fillStyle = '#5FA8F5'; dot(g, 44, 56, 2.6);
    g.fillStyle = 'rgba(181,82,27,.55)'; oval(g, 34, 86, 6, 3); g.fill(); oval(g, 68, 78, 3, 5); g.fill();           // rust: it is old
    g.fillStyle = '#3B4A63'; g.fillRect(30, 92, 6, 3); g.fillRect(64, 92, 6, 3);
    shine(g, 30, 10, 3.5, 22, .7); shine(g, 30, 40, 3.5, 44, .7);
  };
  ART.pad = function (g) {                    // sanitary pad in its wrapper, drawn plainly
    shadow(g, 50, 86, 34);
    g.save(); g.translate(50, 54); g.rotate(-0.2);
    g.fillStyle = lin(g, -36, 0, 36, 0, [[0, '#E58AAE'], [.4, '#FFD9E6'], [1, '#D96A96']]); rr(g, -36, -20, 72, 40, 8); g.fill();
    g.fillStyle = '#fff'; g.beginPath(); g.moveTo(-24, -8); g.quadraticCurveTo(-30, 0, -24, 8); g.lineTo(24, 8); g.quadraticCurveTo(30, 0, 24, -8); g.closePath(); g.fill();
    g.strokeStyle = '#C9D0DA'; g.lineWidth = 1; g.setLineDash([3, 3]); g.beginPath(); g.moveTo(-20, 0); g.lineTo(20, 0); g.stroke(); g.setLineDash([]);
    g.fillStyle = '#D96A96'; for (var i = 0; i < 9; i++) { g.fillRect(-36, -18 + i * 4.2, 3, 2); g.fillRect(33, -18 + i * 4.2, 3, 2); }
    g.fillStyle = 'rgba(255,255,255,.5)'; rr(g, -30, -17, 56, 3, 1.5); g.fill();
    g.restore();
  };
  ART.battery = function (g) {                // AA battery, leaking at the base
    shadow(g, 50, 93, 18);
    g.fillStyle = lin(g, 34, 0, 66, 0, [[0, '#7D8592'], [.35, '#F4F6F9'], [1, '#5E6672']]); rr(g, 43, 8, 14, 8, 2); g.fill(); rr(g, 34, 14, 32, 78, 5); g.fill();
    g.fillStyle = lin(g, 34, 0, 66, 0, [[0, '#12695A'], [.35, '#3FD0B4'], [1, '#0E4F44']]); g.fillRect(34, 24, 32, 52);
    g.fillStyle = lin(g, 34, 0, 66, 0, [[0, '#8A5E08'], [.35, '#F5C542'], [1, '#6E4A06']]); g.fillRect(34, 24, 32, 12);
    g.fillStyle = '#fff'; g.fillRect(47, 44, 6, 16); g.fillRect(42, 49, 16, 6);
    g.fillStyle = 'rgba(245,250,255,.95)'; g.beginPath(); g.moveTo(34, 86); g.quadraticCurveTo(24, 88, 22, 94); g.lineTo(60, 94); g.quadraticCurveTo(58, 88, 50, 90); g.quadraticCurveTo(44, 84, 34, 86); g.fill();
    g.fillStyle = '#9ED9C9'; dot(g, 30, 91, 2); dot(g, 44, 91, 1.6); dot(g, 54, 92, 1.3);
    shine(g, 38, 18, 3.5, 60, .7);
  };
  ART.phone = function (g) {                  // smartphone, screen dark and cracked
    shadow(g, 50, 93, 22);
    g.fillStyle = lin(g, 28, 0, 72, 0, [[0, '#2B3140'], [.5, '#5A6376'], [1, '#1B202B']]); rr(g, 28, 6, 44, 86, 8); g.fill();
    g.fillStyle = lin(g, 0, 12, 0, 86, [[0, '#26344F'], [1, '#0F1626']]); rr(g, 32, 12, 36, 74, 4); g.fill();
    g.fillStyle = '#0B0F18'; rr(g, 44, 14, 12, 3.5, 1.7); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.8)'; g.lineWidth = 1.3;
    g.beginPath(); g.moveTo(60, 14); g.lineTo(52, 34); g.lineTo(58, 46); g.lineTo(40, 70); g.moveTo(52, 34); g.lineTo(34, 30); g.moveTo(58, 46); g.lineTo(68, 56); g.moveTo(47, 60); g.lineTo(34, 62); g.stroke();
    g.fillStyle = '#E8423A'; rr(g, 40, 76, 20, 6, 2); g.fill(); g.fillStyle = '#fff'; g.fillRect(42, 78, 3, 2);         // battery empty
    shine(g, 30, 10, 2.5, 70, .35);
  };
  ART.shoes = function (g) {                  // a worn pair of trainers
    function shoe(ox, oy, s, body, dark) {
      g.save(); g.translate(ox, oy); g.scale(s, s);
      g.fillStyle = '#F4F6F9'; g.beginPath(); g.moveTo(-30, 8); g.lineTo(32, 8); g.quadraticCurveTo(36, 16, 30, 16); g.lineTo(-28, 16); g.quadraticCurveTo(-34, 16, -30, 8); g.fill();
      g.fillStyle = lin(g, 0, -22, 0, 10, [[0, body], [1, dark]]);
      g.beginPath(); g.moveTo(-30, 8); g.quadraticCurveTo(-32, -18, -22, -20); g.quadraticCurveTo(-14, -20, -10, -12); g.quadraticCurveTo(4, -6, 18, -2); g.quadraticCurveTo(32, 0, 32, 8); g.closePath(); g.fill();
      g.fillStyle = 'rgba(255,255,255,.9)'; poly(g, [[-6, -9], [10, -3], [6, 4], [-10, -2]]); g.fill();
      g.strokeStyle = dark; g.lineWidth = 1.6; [[-6, -5], [-1, -3], [4, -1]].forEach(function (p) { g.beginPath(); g.moveTo(p[0] - 2, p[1] - 4); g.lineTo(p[0] + 2, p[1] + 4); g.stroke(); });
      g.fillStyle = '#fff'; g.beginPath(); g.moveTo(-26, 2); g.quadraticCurveTo(-16, -6, -12, 4); g.lineTo(-26, 6); g.closePath(); g.fill();
      g.fillStyle = 'rgba(90,70,50,.45)'; oval(g, 22, 6, 6, 2.4); g.fill(); oval(g, -20, 12, 5, 1.6); g.fill();              // scuffs
      g.restore();
    }
    shadow(g, 50, 88, 38);
    shoe(56, 44, 1, '#F0607A', '#B5273F'); shoe(44, 68, 1.08, '#F0607A', '#B5273F');
  };

  /* =================================================================================
     Added 10 Oct 2026 — the yard set: how material is aggregated, and the machines.
     Used by Upgrade the Stream, Build the Line, Plant Builder and Load the Container,
     which until now drew flat colour blocks with a word on them. These are not rules
     items, so LirichSprites.forItem never returns them; games ask for them by key.
     ================================================================================= */
  var STEEL = [[0, '#7D8592'], [.3, '#F4F6F9'], [.55, '#C3C9D2'], [1, '#5E6672']];
  function wheel(g, x, y, r) {
    g.fillStyle = '#1E232D'; dot(g, x, y, r); g.fillStyle = '#8D99AB'; dot(g, x, y, r * .5); g.fillStyle = '#3B4A63'; dot(g, x, y, r * .2);
  }
  function belt(g, x, y, w) {                 // a short run of conveyor, seen from the side
    g.fillStyle = '#2B3140'; rr(g, x, y, w, 9, 4.5); g.fill();
    g.fillStyle = '#8D99AB'; dot(g, x + 4.5, y + 4.5, 2.6); dot(g, x + w - 4.5, y + 4.5, 2.6); dot(g, x + w / 2, y + 4.5, 2.6);
    g.fillStyle = 'rgba(255,255,255,.25)'; g.fillRect(x + 5, y + 1, w - 10, 1.4);
  }
  function legs(g, x0, x1, y0, y1) {
    g.strokeStyle = '#5E6672'; g.lineWidth = 3; g.lineCap = 'butt';
    g.beginPath(); g.moveTo(x0, y0); g.lineTo(x0, y1); g.moveTo(x1, y0); g.lineTo(x1, y1); g.stroke();
  }

  /* --- aggregation tiers: bottle → bundle → sack → bale → pallet → lorry → container → ship --- */
  ART.bundle = function (g) {                 // a handful of bottles held by a band
    shadow(g, 50, 91, 32);
    [[24, '#3A86E6', '#174E9E'], [40, '#5FA8F5', '#1E63C8'], [56, '#3A86E6', '#174E9E'], [72, '#5FA8F5', '#1E63C8']].forEach(function (b, i) {
      var x = b[0], y = 24 + (i % 2) * 4;
      g.fillStyle = lin(g, x - 8, 0, x + 8, 0, [[0, b[2]], [.4, b[1]], [1, b[2]]]);
      g.beginPath(); g.moveTo(x - 3, y); g.lineTo(x + 3, y); g.quadraticCurveTo(x + 8, y + 6, x + 8, y + 14); g.lineTo(x + 8, 86); g.quadraticCurveTo(x + 8, 90, x + 4, 90);
      g.lineTo(x - 4, 90); g.quadraticCurveTo(x - 8, 90, x - 8, 86); g.lineTo(x - 8, y + 14); g.quadraticCurveTo(x - 8, y + 6, x - 3, y); g.fill();
      g.fillStyle = '#0F3F86'; rr(g, x - 4, y - 8, 8, 8, 2); g.fill();
      g.fillStyle = 'rgba(255,255,255,.55)'; rr(g, x - 6, y + 14, 2.4, 50, 1.2); g.fill();
    });
    g.fillStyle = lin(g, 0, 52, 0, 68, [[0, '#FFE58A'], [1, '#D9A21B']]); rr(g, 12, 52, 76, 14, 4); g.fill();
    g.fillStyle = '#8A5E08'; g.font = '900 9px sans-serif'; g.textAlign = 'center'; g.fillText('× 10', 50, 62.5);
  };
  ART.sack = function (g) {                   // clear collection sack, tied, full of bottles
    shadow(g, 50, 92, 32);
    g.fillStyle = lin(g, 14, 0, 86, 0, [[0, 'rgba(120,200,170,.92)'], [.4, 'rgba(215,245,232,.95)'], [1, 'rgba(95,175,145,.92)']]);
    g.beginPath(); g.moveTo(44, 26); g.quadraticCurveTo(10, 36, 14, 70); g.quadraticCurveTo(18, 94, 50, 92); g.quadraticCurveTo(82, 94, 86, 70); g.quadraticCurveTo(90, 36, 56, 26); g.closePath(); g.fill();
    g.strokeStyle = 'rgba(30,110,80,.6)'; g.lineWidth = 1.5; g.stroke();
    [[34, 58, -.5, '#3A86E6'], [56, 50, .4, '#5FA8F5'], [64, 70, -.2, '#3A86E6'], [40, 76, .7, '#5FA8F5'], [50, 64, 1.3, '#1E63C8']].forEach(function (b) {
      g.save(); g.translate(b[0], b[1]); g.rotate(b[2]); g.globalAlpha = .8; g.fillStyle = b[3]; rr(g, -5, -11, 10, 22, 4); g.fill();
      g.fillStyle = '#0F3F86'; g.fillRect(-2.5, -15, 5, 4.5); g.restore();
    });
    g.fillStyle = '#2E9E76'; poly(g, [[42, 28], [36, 10], [47, 20], [50, 8], [53, 20], [64, 10], [58, 28]]); g.fill();
    g.fillStyle = '#F5C542'; rr(g, 41, 24, 18, 5, 2.5); g.fill();
    shine(g, 22, 44, 4, 30, .6);
  };
  ART.bale = function (g) {                   // compressed bale, two steel straps
    shadow(g, 50, 90, 38);
    g.fillStyle = lin(g, 0, 40, 0, 90, [[0, '#E2A64A'], [1, '#A86A14']]); poly(g, [[10, 42], [64, 50], [64, 90], [10, 80]]); g.fill();
    g.fillStyle = lin(g, 64, 0, 92, 0, [[0, '#9A5E10'], [1, '#70420A']]); poly(g, [[64, 50], [92, 38], [92, 76], [64, 90]]); g.fill();
    g.fillStyle = lin(g, 10, 26, 92, 50, [[0, '#F7CB7E'], [1, '#D9962E']]); poly(g, [[10, 42], [40, 30], [92, 38], [64, 50]]); g.fill();
    var seed = 9; function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
    for (var i = 0; i < 26; i++) {                                    // crushed material showing in the face
      var x = 13 + rnd() * 47, y = 47 + (x - 10) * .15 + rnd() * 34;
      g.fillStyle = ['rgba(95,168,245,.85)', 'rgba(255,255,255,.75)', 'rgba(63,164,107,.8)', 'rgba(120,70,10,.5)'][i % 4];
      g.save(); g.translate(x, y); g.rotate(rnd() * 3); g.fillRect(-3.5, -1.2, 7, 2.4); g.restore();
    }
    g.strokeStyle = '#E3E7ED'; g.lineWidth = 2.6;
    [[26, 0], [48, 0]].forEach(function (s) { var x = s[0]; g.beginPath(); g.moveTo(x + 14.6, 36 + (x - 10) * .01 - 2); g.lineTo(x, 44.4 + (x - 10) * .148); g.lineTo(x, 83 + (x - 10) * .185); g.stroke(); });
    g.strokeStyle = '#8D99AB'; g.lineWidth = 2.6; [72, 84].forEach(function (x) { g.beginPath(); g.moveTo(x, 46.6 - (x - 64) * .43); g.lineTo(x, 86.6 - (x - 64) * .5); g.stroke(); });
  };
  ART.pallet = function (g) {                 // four bales on a timber pallet
    shadow(g, 50, 92, 40);
    g.fillStyle = '#B98549'; g.fillRect(8, 80, 84, 5); g.fillRect(8, 90, 84, 4);
    g.fillStyle = '#8A5E30'; [10, 46, 82].forEach(function (x) { g.fillRect(x, 85, 8, 5); });
    [[10, 46], [51, 46], [10, 12], [51, 12]].forEach(function (b, i) {
      g.fillStyle = lin(g, 0, b[1], 0, b[1] + 33, [[0, i % 3 ? '#E2A64A' : '#EDB65C'], [1, '#A86A14']]); rr(g, b[0], b[1], 39, 33, 3); g.fill();
      g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(b[0] + 2, b[1] + 2, 35, 3);
      g.strokeStyle = '#E3E7ED'; g.lineWidth = 2; g.beginPath(); g.moveTo(b[0] + 12, b[1]); g.lineTo(b[0] + 12, b[1] + 33); g.moveTo(b[0] + 27, b[1]); g.lineTo(b[0] + 27, b[1] + 33); g.stroke();
      g.fillStyle = 'rgba(95,168,245,.8)'; g.fillRect(b[0] + 16, b[1] + 12, 6, 2.2); g.fillStyle = 'rgba(255,255,255,.7)'; g.fillRect(b[0] + 30, b[1] + 22, 5, 2.2); g.fillRect(b[0] + 4, b[1] + 20, 5, 2.2);
    });
  };
  ART.lorry = function (g) {                  // tipper lorry, half loaded
    shadow(g, 50, 90, 42);
    g.fillStyle = lin(g, 0, 30, 0, 78, [[0, '#F0607A'], [1, '#B5273F']]); poly(g, [[6, 34], [62, 34], [62, 76], [6, 76]]); g.fill();
    g.fillStyle = '#1E232D'; poly(g, [[10, 38], [58, 38], [58, 56], [10, 56]]); g.fill();
    [[12, '#E2A64A'], [28, '#D9962E'], [44, '#E2A64A']].forEach(function (b) { g.fillStyle = b[1]; rr(g, b[0], 42, 14, 14, 2); g.fill(); g.strokeStyle = '#E3E7ED'; g.lineWidth = 1.4; g.beginPath(); g.moveTo(b[0] + 7, 42); g.lineTo(b[0] + 7, 56); g.stroke(); });
    g.strokeStyle = 'rgba(255,255,255,.35)'; g.lineWidth = 1.4; [20, 34, 48].forEach(function (x) { g.beginPath(); g.moveTo(x, 58); g.lineTo(x, 74); g.stroke(); });
    g.fillStyle = lin(g, 64, 0, 96, 0, [[0, '#F4F6F9'], [1, '#C3CAD4']]);
    g.beginPath(); g.moveTo(64, 44); g.lineTo(82, 44); g.quadraticCurveTo(92, 46, 95, 60); g.lineTo(95, 76); g.lineTo(64, 76); g.closePath(); g.fill();
    g.fillStyle = '#7FC4F2'; poly(g, [[70, 48], [81, 48], [88, 50], [91, 60], [70, 60]]); g.fill();
    g.fillStyle = '#F5C542'; g.fillRect(92, 66, 3, 5);
    g.fillStyle = '#3B4A63'; g.fillRect(4, 76, 92, 5);
    wheel(g, 22, 84, 8); wheel(g, 44, 84, 8); wheel(g, 80, 84, 8);
    g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(8, 35, 52, 2);
  };
  ART.container = function (g) {              // 20-foot shipping container, three-quarter view
    shadow(g, 50, 90, 42);
    g.fillStyle = lin(g, 0, 34, 0, 88, [[0, '#A58BD0'], [1, '#6A4C9A']]); poly(g, [[6, 36], [68, 44], [68, 88], [6, 78]]); g.fill();
    g.fillStyle = lin(g, 68, 0, 94, 0, [[0, '#5B3F88'], [1, '#43306A']]); poly(g, [[68, 44], [94, 32], [94, 74], [68, 88]]); g.fill();
    g.fillStyle = lin(g, 6, 22, 94, 44, [[0, '#C9B6EA'], [1, '#9C82C8']]); poly(g, [[6, 36], [34, 24], [94, 32], [68, 44]]); g.fill();
    g.strokeStyle = 'rgba(55,35,95,.55)'; g.lineWidth = 1.6;
    for (var x = 12; x < 68; x += 7) { g.beginPath(); g.moveTo(x, 37 + (x - 6) * .129 + 2); g.lineTo(x, 78 + (x - 6) * .161 - 2); g.stroke(); }
    g.strokeStyle = 'rgba(255,255,255,.3)'; g.lineWidth = 1.2; g.beginPath(); g.moveTo(81, 39); g.lineTo(81, 80); g.stroke();
    g.fillStyle = '#E3E7ED'; g.fillRect(76, 50, 1.8, 22); g.fillRect(85, 46, 1.8, 22);
    g.fillStyle = '#fff'; g.save(); g.translate(22, 56); g.rotate(.13); g.font = '900 9px sans-serif'; g.textAlign = 'left'; g.fillText('20 FT', 0, 0); g.restore();
    g.fillStyle = 'rgba(255,255,255,.35)'; poly(g, [[8, 37.5], [34, 26], [38, 26.6], [12, 38]]); g.fill();
  };
  ART.ship = function (g) {                   // container ship with a stack on deck
    g.fillStyle = 'rgba(95,168,245,.35)'; oval(g, 50, 88, 46, 8); g.fill();
    [[20, 34, '#A58BD0'], [36, 34, '#F0607A'], [52, 34, '#5FA8F5'], [20, 46, '#F5C542'], [36, 46, '#54C8A0'], [52, 46, '#A58BD0'], [36, 22, '#5FA8F5'], [52, 22, '#F5C542']].forEach(function (c) {
      g.fillStyle = c[2]; g.fillRect(c[0], c[1], 15, 11); g.fillStyle = 'rgba(0,0,0,.18)'; g.fillRect(c[0], c[1] + 9, 15, 2);
      g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(c[0] + 1, c[1] + 1, 13, 1.6); });
    g.fillStyle = '#F4F6F9'; g.fillRect(72, 28, 14, 30); g.fillStyle = '#5FA8F5'; g.fillRect(74, 32, 10, 4); g.fillRect(74, 40, 10, 4);
    g.fillStyle = '#E8423A'; g.fillRect(76, 18, 6, 10); g.fillStyle = '#1E232D'; g.fillRect(76, 18, 6, 3);
    g.fillStyle = lin(g, 0, 58, 0, 84, [[0, '#1B4E9E'], [1, '#12356E']]); poly(g, [[4, 58], [96, 58], [88, 84], [14, 84]]); g.fill();
    g.fillStyle = '#E8423A'; poly(g, [[11.4, 78], [89.8, 78], [88, 84], [14, 84]]); g.fill();
    g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(8, 60, 84, 2);
    g.strokeStyle = '#fff'; g.lineWidth = 2; g.lineCap = 'round'; g.beginPath(); g.moveTo(6, 90); g.quadraticCurveTo(16, 85, 26, 90); g.quadraticCurveTo(36, 95, 46, 90); g.quadraticCurveTo(56, 85, 66, 90); g.quadraticCurveTo(76, 95, 86, 90); g.stroke();
  };

  /* --- machines. Each shows the one thing it does to the material. --- */
  ART.m_loader = function (g) {               // wheel loader, bucket raised and full
    shadow(g, 50, 92, 40);
    g.strokeStyle = '#8A5E08'; g.lineWidth = 6; g.lineCap = 'round'; g.beginPath(); g.moveTo(50, 60); g.lineTo(24, 44); g.stroke();
    g.fillStyle = lin(g, 0, 26, 0, 56, [[0, '#8D99AB'], [1, '#4A5263']]); g.beginPath(); g.moveTo(4, 30); g.lineTo(26, 32); g.lineTo(28, 54); g.quadraticCurveTo(10, 56, 4, 30); g.fill();
    g.fillStyle = '#B98549'; g.beginPath(); g.moveTo(6, 31); g.quadraticCurveTo(14, 18, 25, 32); g.closePath(); g.fill();
    g.fillStyle = lin(g, 0, 40, 0, 80, [[0, '#FFD23F'], [1, '#D99A00']]); rr(g, 40, 52, 54, 26, 6); g.fill();
    g.fillStyle = lin(g, 0, 22, 0, 54, [[0, '#FFD23F'], [1, '#E6AC0A']]); poly(g, [[56, 24], [80, 24], [86, 54], [52, 54]]); g.fill();
    g.fillStyle = '#7FC4F2'; poly(g, [[59, 28], [77, 28], [81, 46], [57, 46]]); g.fill();
    g.fillStyle = 'rgba(255,255,255,.5)'; poly(g, [[60, 29], [66, 29], [61, 45], [58, 45]]); g.fill();
    g.fillStyle = '#3B4A63'; g.fillRect(84, 40, 5, 12);
    wheel(g, 52, 80, 12); wheel(g, 84, 80, 12);
  };
  ART.m_bag = function (g) {                  // bag opener: toothed drum tearing a sack
    shadow(g, 50, 92, 36);
    legs(g, 22, 78, 70, 92);
    g.fillStyle = lin(g, 10, 0, 90, 0, STEEL); poly(g, [[10, 30], [90, 30], [80, 72], [20, 72]]); g.fill();
    g.fillStyle = '#2B3140'; poly(g, [[18, 36], [82, 36], [75, 66], [25, 66]]); g.fill();
    g.fillStyle = '#E07C2E'; dot(g, 50, 52, 13); g.fillStyle = '#B5521B';
    for (var i = 0; i < 8; i++) { var a = i * .785; poly(g, [[50 + Math.cos(a - .2) * 12, 52 + Math.sin(a - .2) * 12], [50 + Math.cos(a) * 19, 52 + Math.sin(a) * 19], [50 + Math.cos(a + .2) * 12, 52 + Math.sin(a + .2) * 12]]); g.fill(); }
    g.fillStyle = '#F4F6F9'; dot(g, 50, 52, 4);
    g.fillStyle = 'rgba(120,200,170,.95)'; g.beginPath(); g.moveTo(34, 8); g.quadraticCurveTo(22, 14, 26, 28); g.lineTo(34, 24); g.lineTo(38, 30); g.lineTo(44, 22); g.lineTo(48, 28); g.quadraticCurveTo(54, 12, 42, 8); g.closePath(); g.fill();
    g.fillStyle = '#5FA8F5'; rr(g, 60, 12, 6, 12, 2); g.fill(); g.fillStyle = '#F5C542'; dot(g, 72, 22, 3.4); g.fillStyle = '#C3CAD4'; rr(g, 64, 26, 8, 5, 2); g.fill();
  };
  ART.m_trom = function (g) {                 // trommel: a tilted, perforated drum, fines dropping out
    shadow(g, 50, 92, 38);
    legs(g, 22, 80, 60, 92);
    g.save(); g.translate(50, 42); g.rotate(-0.16);
    g.fillStyle = lin(g, 0, -20, 0, 20, [[0, '#F0C48A'], [.4, '#C08A4A'], [1, '#7A5228']]); g.fillRect(-36, -19, 72, 38);
    oval(g, -36, 0, 7, 19); g.fill(); g.fillStyle = '#5A3A18'; oval(g, 36, 0, 7, 19); g.fill(); g.fillStyle = '#2B1A08'; oval(g, 36, 0, 4.5, 14); g.fill();
    g.fillStyle = 'rgba(40,24,8,.6)';
    for (var r = 0; r < 4; r++) for (var c = 0; c < 8; c++) dot(g, -30 + c * 8 + (r % 2) * 4, -12 + r * 8, 2);
    g.fillStyle = 'rgba(255,255,255,.4)'; rr(g, -32, -16, 60, 3, 1.5); g.fill();
    g.restore();
    g.fillStyle = '#8A6A3E'; [[30, 68, 2], [38, 74, 1.6], [46, 70, 2.2], [54, 76, 1.6], [62, 68, 2], [42, 82, 1.8], [56, 84, 1.5]].forEach(function (p) { dot(g, p[0], p[1], p[2]); });
    g.fillStyle = '#A8825A'; g.beginPath(); g.moveTo(28, 92); g.quadraticCurveTo(48, 78, 68, 92); g.closePath(); g.fill();
  };
  ART.m_mag = function (g) {                  // overband magnet: steel jumps up off the belt
    shadow(g, 50, 93, 36);
    legs(g, 16, 84, 20, 92);
    g.fillStyle = lin(g, 0, 12, 0, 40, [[0, '#B79BE0'], [1, '#6A4C9A']]); rr(g, 12, 12, 76, 26, 6); g.fill();
    g.fillStyle = 'rgba(255,255,255,.35)'; g.fillRect(16, 14, 68, 3);
    g.lineCap = 'butt'; g.lineWidth = 9; g.strokeStyle = '#E8423A'; g.beginPath(); g.arc(50, 22, 12, 3.14, 0, true); g.stroke();
    g.fillStyle = '#F4F6F9'; g.fillRect(33.5, 22, 9, 6); g.fillRect(57.5, 22, 9, 6);
    g.strokeStyle = 'rgba(183,155,224,.9)'; g.lineWidth = 1.6; g.setLineDash([3, 3]);
    [34, 50, 66].forEach(function (x) { g.beginPath(); g.moveTo(x, 42); g.lineTo(x, 66); g.stroke(); }); g.setLineDash([]);
    g.fillStyle = lin(g, 0, 0, 12, 0, STEEL);
    [[30, 46, .4], [52, 52, -.3], [66, 44, .8]].forEach(function (p) { g.save(); g.translate(p[0], p[1]); g.rotate(p[2]); g.fillStyle = '#8D99AB'; rr(g, -5, -3, 10, 6, 1.5); g.fill(); g.fillStyle = '#F4F6F9'; g.fillRect(-4, -2, 8, 1.4); g.restore(); });
    belt(g, 8, 72, 84);
    g.fillStyle = '#5FA8F5'; rr(g, 20, 65, 6, 8, 2); g.fill(); g.fillStyle = '#E2A64A'; g.fillRect(74, 66, 8, 7);
  };
  ART.m_eddy = function (g) {                 // eddy current: aluminium is flung clear of the belt end
    shadow(g, 46, 93, 36);
    legs(g, 14, 50, 62, 92);
    belt(g, 4, 54, 56);
    g.fillStyle = lin(g, 46, 46, 70, 70, [[0, '#9CCBFA'], [1, '#1B4E9E']]); dot(g, 58, 58, 12);
    g.fillStyle = '#F4F6F9'; for (var i = 0; i < 6; i++) { var a = i * 1.047; g.save(); g.translate(58, 58); g.rotate(a); g.fillStyle = i % 2 ? '#E8423A' : '#F4F6F9'; g.fillRect(-2, -11, 4, 7); g.restore(); }
    g.fillStyle = '#12356E'; dot(g, 58, 58, 3.4);
    g.strokeStyle = 'rgba(95,168,245,.9)'; g.lineWidth = 1.8; g.setLineDash([3, 3]); g.beginPath(); g.moveTo(62, 44); g.quadraticCurveTo(84, 24, 94, 54); g.stroke(); g.setLineDash([]);
    [[72, 32, .5], [88, 40, 1.1], [94, 60, 1.6]].forEach(function (p) { g.save(); g.translate(p[0], p[1]); g.rotate(p[2]); g.fillStyle = lin(g, -4, 0, 4, 0, STEEL); rr(g, -4, -6.5, 8, 13, 2.5); g.fill(); g.fillStyle = '#E8423A'; g.fillRect(-4, -2, 8, 4); g.restore(); });
    g.fillStyle = '#B98549'; g.fillRect(16, 47, 8, 7); g.fillStyle = '#8A6A3E'; dot(g, 34, 51, 3.2);
    g.fillStyle = '#5E6672'; poly(g, [[62, 74], [70, 74], [74, 92], [66, 92]]); g.fill();                    // splitter
  };
  ART.m_air = function (g) {                  // air classifier: a fan lifts film and paper, heavy items stay
    shadow(g, 50, 93, 36);
    g.fillStyle = lin(g, 20, 0, 80, 0, [[0, '#2E8A58'], [.4, '#7FD9A6'], [1, '#1E6E40']]); poly(g, [[30, 12], [70, 12], [78, 70], [22, 70]]); g.fill();
    g.fillStyle = 'rgba(15,60,35,.75)'; poly(g, [[34, 18], [66, 18], [72, 64], [28, 64]]); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.85)'; g.lineWidth = 2.2; g.lineCap = 'round';
    [38, 50, 62].forEach(function (x, i) { g.beginPath(); g.moveTo(x, 60); g.quadraticCurveTo(x - 5, 48, x, 38); g.quadraticCurveTo(x + 4, 30, x, 24); g.stroke(); poly(g, [[x - 4, 27], [x, 19], [x + 4, 27]]); g.fillStyle = '#fff'; g.fill(); });
    g.fillStyle = 'rgba(210,235,255,.95)'; g.save(); g.translate(44, 34); g.rotate(.4); g.fillRect(-5, -4, 10, 8); g.restore(); g.save(); g.translate(58, 46); g.rotate(-.5); g.fillRect(-4, -3, 8, 6); g.restore();
    g.fillStyle = '#F4F6F9'; dot(g, 50, 80, 11); g.fillStyle = '#2E8A58';
    for (var i = 0; i < 4; i++) { g.save(); g.translate(50, 80); g.rotate(i * 1.571 + .4); g.beginPath(); g.moveTo(0, 0); g.quadraticCurveTo(7, -3, 9, 3); g.quadraticCurveTo(4, 4, 0, 0); g.fill(); g.restore(); }
    g.fillStyle = '#1E6E40'; dot(g, 50, 80, 2.4);
    g.fillStyle = '#8D99AB'; rr(g, 14, 86, 10, 6, 2); g.fill(); g.fillStyle = '#B98549'; g.fillRect(78, 85, 8, 7);
  };
  ART.m_nir = function (g) {                  // optical sorter: a light bar reads each item, an air jet ejects it
    shadow(g, 50, 93, 36);
    legs(g, 16, 84, 18, 92);
    g.fillStyle = lin(g, 0, 8, 0, 30, [[0, '#F7D774'], [1, '#B07A10']]); rr(g, 10, 8, 80, 20, 5); g.fill();
    g.fillStyle = '#1E232D'; rr(g, 18, 13, 26, 10, 3); g.fill(); g.fillStyle = '#54E0A0'; dot(g, 24, 18, 2); g.fillStyle = '#F0607A'; dot(g, 31, 18, 2); g.fillStyle = '#5FA8F5'; dot(g, 38, 18, 2);
    g.fillStyle = 'rgba(255,255,255,.4)'; g.fillRect(14, 10, 72, 2.4);
    var beam = lin(g, 0, 28, 0, 70, [[0, 'rgba(255,90,120,.75)'], [1, 'rgba(255,210,80,.12)']]); g.fillStyle = beam; poly(g, [[56, 28], [72, 28], [86, 68], [42, 68]]); g.fill();
    belt(g, 6, 68, 88);
    g.fillStyle = '#3A86E6'; rr(g, 56, 52, 10, 17, 4); g.fill(); g.fillStyle = '#0F3F86'; g.fillRect(58.5, 48, 5, 4.5);
    g.fillStyle = '#F07AB8'; rr(g, 22, 56, 9, 13, 4); g.fill(); g.fillStyle = '#B98549'; g.fillRect(38, 61, 8, 7);
    g.strokeStyle = '#fff'; g.lineWidth = 1.4; g.beginPath(); g.arc(61, 60, 12, 0, 6.3); g.stroke(); g.fillStyle = '#54E0A0'; dot(g, 72, 50, 5.5);
    g.strokeStyle = '#fff'; g.lineWidth = 1.8; g.lineCap = 'round'; g.beginPath(); g.moveTo(69.5, 50); g.lineTo(71.5, 52.2); g.lineTo(75, 48); g.stroke();
  };
  ART.m_robot = function (g) {                // robot picker: an arm lifting one item off the belt
    shadow(g, 50, 93, 36);
    belt(g, 6, 76, 88);
    g.fillStyle = '#B98549'; g.fillRect(14, 69, 8, 7); g.fillStyle = '#8D99AB'; rr(g, 74, 70, 10, 6, 2); g.fill();
    g.fillStyle = lin(g, 0, 6, 0, 18, [[0, '#8D99AB'], [1, '#4A5263']]); rr(g, 22, 6, 56, 10, 4); g.fill();
    g.strokeStyle = '#B5521B'; g.lineWidth = 11; g.lineCap = 'round'; g.lineJoin = 'round'; g.beginPath(); g.moveTo(50, 16); g.lineTo(68, 34); g.lineTo(48, 50); g.stroke();
    g.strokeStyle = '#F59A4A'; g.lineWidth = 7; g.beginPath(); g.moveTo(50, 16); g.lineTo(68, 34); g.lineTo(48, 50); g.stroke();
    g.fillStyle = '#F4F6F9'; dot(g, 50, 16, 5); dot(g, 68, 34, 5); g.fillStyle = '#3B4A63'; dot(g, 50, 16, 2); dot(g, 68, 34, 2);
    g.fillStyle = '#3B4A63'; rr(g, 41, 48, 14, 6, 2); g.fill();
    g.strokeStyle = '#3B4A63'; g.lineWidth = 3; g.beginPath(); g.moveTo(43, 54); g.lineTo(40, 62); g.moveTo(53, 54); g.lineTo(56, 62); g.stroke();
    g.fillStyle = '#3A86E6'; rr(g, 43, 56, 10, 16, 4); g.fill(); g.fillStyle = 'rgba(255,255,255,.6)'; g.fillRect(45, 59, 2, 10);
    g.fillStyle = '#54E0A0'; dot(g, 30, 11, 2);
  };
  ART.m_baler = function (g) {                // baler: a ram presses loose material into a strapped bale
    shadow(g, 50, 93, 40);
    g.fillStyle = lin(g, 0, 30, 0, 90, [[0, '#E2A64A'], [1, '#8A5A0E']]); rr(g, 6, 34, 56, 56, 5); g.fill();
    g.fillStyle = '#2B1A08'; rr(g, 12, 42, 44, 40, 3); g.fill();
    g.fillStyle = lin(g, 0, 0, 0, 1, STEEL); g.fillStyle = '#C3CAD4'; g.fillRect(30, 12, 8, 34); g.fillStyle = lin(g, 12, 0, 56, 0, STEEL); g.fillRect(14, 44, 40, 9);
    g.fillStyle = '#E8423A'; poly(g, [[26, 6], [42, 6], [38, 14], [30, 14]]); g.fill();
    [['#5FA8F5', 18, 60], ['#F4F6F9', 30, 64], ['#54C8A0', 42, 60], ['#F4F6F9', 22, 72], ['#5FA8F5', 36, 74], ['#C08A4A', 46, 70]].forEach(function (c) { g.fillStyle = c[0]; g.fillRect(c[1], c[2], 8, 5); });
    g.fillStyle = lin(g, 0, 58, 0, 90, [[0, '#F7CB7E'], [1, '#C4862A']]); rr(g, 66, 60, 28, 30, 3); g.fill();
    g.strokeStyle = '#E3E7ED'; g.lineWidth = 2.2; g.beginPath(); g.moveTo(75, 60); g.lineTo(75, 90); g.moveTo(86, 60); g.lineTo(86, 90); g.stroke();
    g.fillStyle = 'rgba(95,168,245,.8)'; g.fillRect(78, 70, 5, 2.2); g.fillStyle = 'rgba(255,255,255,.7)'; g.fillRect(68, 80, 5, 2.2);
    g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(9, 36, 50, 3);
  };
  ART.m_wb = function (g) {                   // weighbridge with a digital record: every tonne becomes evidence
    shadow(g, 50, 93, 44);
    g.fillStyle = lin(g, 0, 78, 0, 92, [[0, '#8D99AB'], [1, '#4A5263']]); poly(g, [[4, 80], [96, 80], [90, 92], [10, 92]]); g.fill();
    g.fillStyle = '#F5C542'; for (var x = 8; x < 92; x += 12) poly(g, [[x, 80], [x + 6, 80], [x + 3, 84], [x - 3, 84]]), g.fill();
    g.fillStyle = lin(g, 0, 44, 0, 74, [[0, '#54C8A0'], [1, '#1E7A5A']]); rr(g, 10, 46, 44, 26, 3); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.35)'; g.lineWidth = 1.4; [20, 30, 40].forEach(function (x) { g.beginPath(); g.moveTo(x, 49); g.lineTo(x, 69); g.stroke(); });
    g.fillStyle = '#F4F6F9'; g.beginPath(); g.moveTo(56, 54); g.lineTo(68, 54); g.quadraticCurveTo(76, 56, 78, 66); g.lineTo(78, 72); g.lineTo(56, 72); g.closePath(); g.fill();
    g.fillStyle = '#7FC4F2'; poly(g, [[60, 57], [68, 57], [73, 59], [75, 65], [60, 65]]); g.fill();
    g.fillStyle = '#3B4A63'; g.fillRect(8, 72, 72, 4); wheel(g, 22, 77, 5.5); wheel(g, 40, 77, 5.5); wheel(g, 68, 77, 5.5);
    g.fillStyle = '#5E6672'; g.fillRect(84, 38, 4, 42);
    g.fillStyle = '#12213F'; rr(g, 58, 8, 38, 30, 5); g.fill(); g.strokeStyle = '#54E0A0'; g.lineWidth = 1.5; g.stroke();
    g.fillStyle = '#54E0A0'; g.font = '900 11px sans-serif'; g.textAlign = 'center'; g.fillText('12.4 t', 77, 22);
    g.strokeStyle = '#54E0A0'; g.lineWidth = 2.2; g.lineCap = 'round'; g.beginPath(); g.moveTo(70, 30); g.lineTo(74, 33.5); g.lineTo(84, 26); g.stroke();
  };
  ART.m_shred = function (g) {                // shredder: twin toothed shafts under a feed hopper
    shadow(g, 50, 93, 38);
    legs(g, 20, 80, 74, 92);
    g.fillStyle = lin(g, 6, 0, 94, 0, [[0, '#B5521B'], [.4, '#F59A4A'], [1, '#8A3A12']]); poly(g, [[6, 14], [94, 14], [80, 46], [20, 46]]); g.fill();
    g.fillStyle = '#3A1A08'; poly(g, [[14, 19], [86, 19], [76, 42], [24, 42]]); g.fill();
    g.fillStyle = '#B98549'; g.save(); g.translate(40, 22); g.rotate(.3); g.fillRect(-9, -7, 18, 14); g.restore(); g.fillStyle = '#8A6A3E'; g.save(); g.translate(62, 26); g.rotate(-.4); g.fillRect(-12, -3, 24, 6); g.restore();
    g.fillStyle = lin(g, 0, 44, 0, 78, [[0, '#8D99AB'], [1, '#3B4A63']]); rr(g, 14, 44, 72, 32, 4); g.fill();
    [36, 64].forEach(function (cx0, n) {
      g.fillStyle = '#C3CAD4'; dot(g, cx0, 60, 10); g.fillStyle = '#F4F6F9';
      for (var i = 0; i < 7; i++) { var a = i * .898 + n * .45; poly(g, [[cx0 + Math.cos(a - .22) * 9.5, 60 + Math.sin(a - .22) * 9.5], [cx0 + Math.cos(a + .1) * 15.5, 60 + Math.sin(a + .1) * 15.5], [cx0 + Math.cos(a + .3) * 9.5, 60 + Math.sin(a + .3) * 9.5]]); g.fill(); }
      g.fillStyle = '#3B4A63'; dot(g, cx0, 60, 3.4);
    });
    g.fillStyle = '#B98549'; [[38, 82], [46, 86], [54, 82], [62, 87], [50, 90]].forEach(function (p) { g.fillRect(p[0], p[1], 4, 2.4); });
  };
  ART.m_rdf = function (g) {                  // RDF line: light fraction in, fuel bale out
    shadow(g, 50, 93, 42);
    g.fillStyle = lin(g, 0, 24, 0, 78, [[0, '#B98A5A'], [1, '#5E4222']]); rr(g, 6, 30, 58, 48, 5); g.fill();
    g.fillStyle = 'rgba(255,255,255,.25)'; g.fillRect(9, 32, 52, 3);
    g.fillStyle = '#8D99AB'; g.fillRect(16, 12, 9, 20); g.fillRect(42, 18, 7, 14);
    g.fillStyle = 'rgba(255,255,255,.75)'; dot(g, 22, 8, 5); dot(g, 29, 4, 3.6);
    g.fillStyle = '#12213F'; rr(g, 14, 42, 42, 26, 4); g.fill();
    g.fillStyle = rad(g, 35, 62, 14, [[0, '#FFE58A'], [.5, '#F59A4A'], [1, '#E8423A']]);
    g.beginPath(); g.moveTo(35, 44); g.quadraticCurveTo(48, 54, 44, 62); g.quadraticCurveTo(42, 67, 35, 67); g.quadraticCurveTo(26, 67, 26, 60); g.quadraticCurveTo(26, 54, 31, 52); g.quadraticCurveTo(31, 48, 35, 44); g.fill();
    g.fillStyle = '#FFF3B0'; g.beginPath(); g.moveTo(35, 55); g.quadraticCurveTo(40, 60, 38, 64); g.quadraticCurveTo(35, 66, 32, 64); g.quadraticCurveTo(31, 59, 35, 55); g.fill();
    belt(g, 4, 78, 92);
    g.fillStyle = lin(g, 0, 54, 0, 78, [[0, '#9AA86A'], [1, '#5E6E32']]); rr(g, 70, 54, 24, 24, 3); g.fill();
    g.strokeStyle = '#E3E7ED'; g.lineWidth = 2; g.beginPath(); g.moveTo(78, 54); g.lineTo(78, 78); g.moveTo(87, 54); g.lineTo(87, 78); g.stroke();
    g.fillStyle = '#3B4A63'; g.font = '900 8px sans-serif'; g.textAlign = 'center'; g.fillText('RDF', 82, 50);
  };

  /* --- bulk materials for Load the Container that are not rules items --- */
  ART.timber = function (g) {                 // timber offcuts, stacked
    shadow(g, 50, 90, 38);
    [[12, 66, 76, '#B98549', '#8A5E30'], [20, 50, 66, '#C9975A', '#96693A'], [10, 34, 70, '#B98549', '#8A5E30']].forEach(function (b, i) {
      g.fillStyle = lin(g, 0, b[1], 0, b[1] + 15, [[0, b[3]], [1, b[4]]]); rr(g, b[0], b[1], b[2], 15, 2); g.fill();
      g.strokeStyle = 'rgba(90,55,20,.45)'; g.lineWidth = 1; g.beginPath(); g.moveTo(b[0] + 6, b[1] + 5); g.quadraticCurveTo(b[0] + b[2] / 2, b[1] + 2 + i, b[0] + b[2] - 12, b[1] + 6); g.moveTo(b[0] + 10, b[1] + 11); g.lineTo(b[0] + b[2] - 16, b[1] + 10); g.stroke();
      g.fillStyle = '#E8CFA0'; rr(g, b[0] + b[2] - 9, b[1] + 1.5, 8, 12, 2); g.fill();
      g.strokeStyle = '#B98549'; g.lineWidth = .9; g.beginPath(); g.arc(b[0] + b[2] - 5, b[1] + 7.5, 3.4, 0, 7); g.stroke(); g.beginPath(); g.arc(b[0] + b[2] - 5, b[1] + 7.5, 1.4, 0, 7); g.stroke();
      g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(b[0] + 2, b[1] + 1.5, b[2] - 13, 2);
    });
    g.fillStyle = '#C9975A'; g.save(); g.translate(48, 24); g.rotate(-.25); rr(g, -24, -6, 48, 12, 2); g.fill(); g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(-22, -5, 40, 2); g.restore();
  };
  ART.scrap = function (g) {                  // scrap steel: beam, plate and a gear
    shadow(g, 50, 90, 38);
    g.fillStyle = lin(g, 0, 60, 0, 88, [[0, '#8D99AB'], [1, '#4A5263']]); poly(g, [[8, 70], [70, 62], [92, 74], [88, 88], [14, 88]]); g.fill();
    g.save(); g.translate(40, 52); g.rotate(-.35);
    g.fillStyle = lin(g, 0, -10, 0, 10, STEEL); g.fillRect(-32, -10, 64, 4); g.fillRect(-32, 6, 64, 4); g.fillRect(-32, -6, 64, 12);
    g.fillStyle = '#5E6672'; g.fillRect(-32, -6, 64, 3); g.fillStyle = 'rgba(181,82,27,.6)'; oval(g, 10, 2, 8, 3); g.fill();
    g.restore();
    g.fillStyle = '#6E747F'; dot(g, 70, 58, 14);
    for (var i = 0; i < 8; i++) { g.save(); g.translate(70, 58); g.rotate(i * .785); g.fillRect(-3, -19, 6, 7); g.restore(); }
    g.fillStyle = '#C3CAD4'; dot(g, 70, 58, 9); g.fillStyle = '#3B4A63'; dot(g, 70, 58, 4);
    g.fillStyle = 'rgba(255,255,255,.6)'; oval(g, 65, 52, 4, 1.6, -.6); g.fill();
    g.fillStyle = 'rgba(181,82,27,.55)'; oval(g, 30, 78, 9, 3); g.fill(); oval(g, 76, 80, 6, 2.4); g.fill();
  };
  ART.cullet = function (g) {                 // glass cullet: a heap of broken glass
    shadow(g, 50, 90, 38);
    g.fillStyle = lin(g, 0, 40, 0, 90, [[0, 'rgba(120,205,175,.95)'], [1, 'rgba(40,130,100,.95)']]);
    g.beginPath(); g.moveTo(8, 88); g.quadraticCurveTo(30, 40, 52, 36); g.quadraticCurveTo(76, 44, 92, 88); g.closePath(); g.fill();
    var seed = 13; function rnd() { seed = (seed * 16807) % 2147483647; return seed / 2147483647; }
    for (var i = 0; i < 30; i++) {
      var t = rnd(), y = 44 + t * 42, half = 6 + t * 34, x = 50 + (rnd() - .5) * 2 * half, r = 3 + rnd() * 4, a = rnd() * 6.28;
      g.fillStyle = ['rgba(225,250,240,.9)', 'rgba(56,181,110,.9)', 'rgba(150,225,200,.9)', 'rgba(184,134,11,.75)'][i % 4];
      poly(g, [[x + Math.cos(a) * r, y + Math.sin(a) * r], [x + Math.cos(a + 2.3) * r, y + Math.sin(a + 2.3) * r], [x + Math.cos(a + 4.1) * r * .8, y + Math.sin(a + 4.1) * r * .8]]); g.fill();
    }
    sparkle(g, 40, 54, 6); sparkle(g, 64, 66, 5); sparkle(g, 52, 44, 4);
  };

  /* --- Zero Waste City: one picture per thing a city can fund --- */
  ART.c_drive = function (g) {                // recycling drive: a megaphone and a blue bin
    shadow(g, 50, 92, 36);
    g.fillStyle = lin(g, 50, 0, 90, 0, [[0, '#1E63C8'], [.4, '#5FA8F5'], [1, '#174E9E']]); poly(g, [[54, 46], [90, 46], [86, 92], [58, 92]]); g.fill();
    g.fillStyle = '#12356E'; rr(g, 51, 40, 42, 8, 3); g.fill();
    recycleMark(g, 72, 70, 9, '#fff');
    g.save(); g.translate(30, 40); g.rotate(-.35);
    g.fillStyle = lin(g, 0, -18, 0, 18, [[0, '#FFB15C'], [1, '#D9601A']]); poly(g, [[-18, -6], [14, -20], [14, 20], [-18, 6]]); g.fill();
    g.fillStyle = '#F4F6F9'; oval(g, 14, 0, 5, 20); g.fill(); g.fillStyle = '#8A3A12'; oval(g, 14, 0, 2.6, 13); g.fill();
    g.fillStyle = '#3B4A63'; rr(g, -24, -6, 8, 12, 2); g.fill(); g.fillRect(-12, 6, 6, 14);
    g.restore();
    g.strokeStyle = '#F5C542'; g.lineWidth = 2.6; g.lineCap = 'round';
    [[52, 16, 60, 10], [56, 26, 66, 24], [46, 8, 50, 0]].forEach(function (l) { g.beginPath(); g.moveTo(l[0], l[1]); g.lineTo(l[2], l[3]); g.stroke(); });
  };
  ART.c_mrf = function (g) {                  // sorting facility: a shed with a saw-tooth roof and a loading door
    shadow(g, 50, 92, 44);
    g.fillStyle = lin(g, 0, 30, 0, 90, [[0, '#7FD9A6'], [1, '#2E8A58']]); g.fillRect(8, 40, 84, 50);
    g.fillStyle = '#1E6E40'; [[8, 0], [36, 0], [64, 0]].forEach(function (r) { poly(g, [[r[0], 40], [r[0], 22], [r[0] + 28, 40]]); g.fill(); });
    g.fillStyle = '#C9F3FF'; [[11, 0], [39, 0], [67, 0]].forEach(function (r) { poly(g, [[r[0], 38], [r[0], 28], [r[0] + 14, 38]]); g.fill(); });
    g.fillStyle = '#12213F'; rr(g, 16, 60, 30, 30, 3); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.3)'; g.lineWidth = 1.2; [66, 72, 78, 84].forEach(function (y) { g.beginPath(); g.moveTo(16, y); g.lineTo(46, y); g.stroke(); });
    g.fillStyle = '#fff'; dot(g, 70, 66, 14); recycleMark(g, 70, 66, 8, '#2E8A58');
    g.fillStyle = 'rgba(255,255,255,.3)'; g.fillRect(8, 40, 84, 3);
  };
  ART.c_food = function (g) {                 // food waste digesters: two domed tanks and a pipe
    shadow(g, 50, 92, 42);
    [[30, '#A9C24A', '#5E7A1E'], [70, '#BFD45E', '#6E8A26']].forEach(function (t) {
      g.fillStyle = lin(g, t[0] - 22, 0, t[0] + 22, 0, [[0, t[2]], [.4, t[1]], [1, t[2]]]);
      g.beginPath(); g.moveTo(t[0] - 22, 90); g.lineTo(t[0] - 22, 48); g.quadraticCurveTo(t[0], 22, t[0] + 22, 48); g.lineTo(t[0] + 22, 90); g.closePath(); g.fill();
      g.strokeStyle = 'rgba(255,255,255,.35)'; g.lineWidth = 1.4; [58, 70, 82].forEach(function (y) { g.beginPath(); g.moveTo(t[0] - 22, y); g.lineTo(t[0] + 22, y); g.stroke(); });
      g.fillStyle = 'rgba(255,255,255,.4)'; rr(g, t[0] - 17, 50, 4, 36, 2); g.fill();
    });
    g.strokeStyle = '#8D99AB'; g.lineWidth = 4; g.lineCap = 'round'; g.beginPath(); g.moveTo(30, 34); g.lineTo(30, 24); g.lineTo(70, 24); g.lineTo(70, 34); g.stroke();
    g.fillStyle = rad(g, 48, 10, 10, [[0, '#FF8A7A'], [1, '#C42B2B']]); dot(g, 50, 12, 8);
    g.strokeStyle = '#5B3A12'; g.lineWidth = 2; g.beginPath(); g.moveTo(50, 5); g.lineTo(52, 0); g.stroke(); g.fillStyle = '#3FA046'; oval(g, 57, 2, 5, 2.4, -.5); g.fill();
  };
  ART.c_wte = function (g) {                  // incineration plant: big hall, tall banded stack, a wisp of vapour
    shadow(g, 50, 92, 44);
    g.fillStyle = 'rgba(255,255,255,.8)'; dot(g, 78, 10, 7); dot(g, 86, 5, 5); dot(g, 70, 6, 4.5);
    g.fillStyle = lin(g, 68, 0, 84, 0, [[0, '#C3CAD4'], [.4, '#FFFFFF'], [1, '#8D99AB']]); poly(g, [[70, 16], [82, 16], [84, 90], [68, 90]]); g.fill();
    g.fillStyle = '#E8423A'; g.fillRect(69.6, 24, 12.8, 6); g.fillRect(69.2, 40, 13.6, 6);
    g.fillStyle = lin(g, 0, 40, 0, 90, [[0, '#8D99AB'], [1, '#4A5263']]); poly(g, [[6, 52], [34, 36], [62, 52], [62, 90], [6, 90]]); g.fill();
    g.fillStyle = '#12213F'; rr(g, 14, 62, 40, 20, 3); g.fill();
    g.fillStyle = rad(g, 34, 78, 14, [[0, '#FFE58A'], [.5, '#F59A4A'], [1, '#E8423A']]);
    g.beginPath(); g.moveTo(34, 64); g.quadraticCurveTo(44, 72, 41, 78); g.quadraticCurveTo(39, 82, 34, 82); g.quadraticCurveTo(27, 82, 27, 76); g.quadraticCurveTo(28, 71, 31, 70); g.quadraticCurveTo(31, 67, 34, 64); g.fill();
    g.fillStyle = 'rgba(255,255,255,.3)'; poly(g, [[6, 52], [34, 36], [37, 37.7], [9, 54]]); g.fill();
  };
  ART.c_ash = function (g) {                  // ash reuse: a grey heap becomes paving blocks
    shadow(g, 50, 92, 42);
    g.fillStyle = lin(g, 0, 50, 0, 90, [[0, '#B9C1CC'], [1, '#6B7380']]); g.beginPath(); g.moveTo(4, 90); g.quadraticCurveTo(22, 44, 40, 90); g.closePath(); g.fill();
    g.fillStyle = '#4A5263'; [[14, 78], [22, 68], [28, 82], [18, 86]].forEach(function (p) { dot(g, p[0], p[1], 1.6); });
    g.strokeStyle = '#F5C542'; g.lineWidth = 5; g.lineCap = 'round'; g.lineJoin = 'round'; g.beginPath(); g.moveTo(40, 52); g.lineTo(54, 52); g.stroke();
    g.fillStyle = '#F5C542'; poly(g, [[52, 44], [62, 52], [52, 60]]); g.fill();
    [[62, 72, '#C9D0DA'], [78, 72, '#AEB8C6'], [70, 56, '#D5DBE4'], [62, 40, '#C9D0DA'], [78, 40, '#B9C2CE']].forEach(function (b) {
      g.fillStyle = lin(g, 0, b[1], 0, b[1] + 15, [[0, b[2]], [1, '#7D8592']]); rr(g, b[0], b[1], 15, 15, 2); g.fill();
      g.fillStyle = 'rgba(255,255,255,.5)'; g.fillRect(b[0] + 1.5, b[1] + 1.5, 12, 2); });
    g.fillStyle = '#3FA046'; oval(g, 84, 30, 7, 3.4, -.5); g.fill(); oval(g, 72, 28, 6, 3, .6); g.fill();
    g.strokeStyle = '#2E7A36'; g.lineWidth = 1.6; g.beginPath(); g.moveTo(78, 40); g.lineTo(78, 30); g.stroke();
  };
  ART.c_depo = function (g) {                 // container deposit: a return machine takes a bottle, gives a coin
    shadow(g, 46, 92, 34);
    g.fillStyle = lin(g, 14, 0, 70, 0, [[0, '#1B8F7A'], [.4, '#5FE0C4'], [1, '#12695A']]); rr(g, 14, 8, 56, 84, 6); g.fill();
    g.fillStyle = '#12213F'; rr(g, 22, 16, 40, 22, 4); g.fill();
    g.fillStyle = '#54E0A0'; g.font = '900 12px sans-serif'; g.textAlign = 'center'; g.fillText('+10¢', 42, 32);
    g.fillStyle = '#0B2A26'; dot(g, 42, 58, 13); g.fillStyle = '#3A86E6'; rr(g, 36, 46, 12, 22, 5); g.fill(); g.fillStyle = '#0F3F86'; g.fillRect(39.5, 42, 5, 5);
    g.fillStyle = '#12213F'; rr(g, 26, 78, 32, 7, 3); g.fill();
    g.fillStyle = rad(g, 82, 68, 13, [[0, '#FFF3B0'], [.6, '#F5C542'], [1, '#B07A10']]); dot(g, 84, 70, 12);
    g.fillStyle = '#8A5E08'; g.font = '900 13px sans-serif'; g.fillText('$', 84, 75);
    shine(g, 18, 12, 3.5, 70, .5);
  };

  /* =================================================================================
     Added 21 Oct 2026 — the tipping-floor set, for Spot the Contaminant.
     Ten hazards and the everyday load they hide in, asked for by key (f_*). They are
     not rules items, so forItem never returns them. Two rules pictures look similar
     but mean something different here, so the floor has its own: a FULL aerosol pack
     with its caps on (the rules "Empty aerosol can" is a blue-bin item) and a SOLVENT
     paint tin with a flammable mark (the rules "Paint tin" is about the empty tin).
     Hazards carry the markings the real object carries — no badges added for the game.
     ================================================================================= */
  function diamond(g, x, y, r, col) {          // GHS-style hazard diamond with a flame
    g.save(); g.translate(x, y); g.rotate(Math.PI / 4);
    g.fillStyle = '#fff'; g.fillRect(-r, -r, 2 * r, 2 * r);
    g.strokeStyle = col || '#D7261E'; g.lineWidth = r * 0.22; g.strokeRect(-r, -r, 2 * r, 2 * r);
    g.restore();
    g.fillStyle = '#1B1B1B'; g.beginPath(); g.moveTo(x, y - r * .75); g.quadraticCurveTo(x + r * .55, y - r * .05, x + r * .3, y + r * .5);
    g.lineTo(x - r * .3, y + r * .5); g.quadraticCurveTo(x - r * .55, y - r * .05, x, y - r * .75); g.fill();
  }
  ART.f_lpg = function (g) {                  // LPG gas cylinder, the kind under a hawker stove
    shadow(g, 50, 93, 26);
    g.fillStyle = lin(g, 26, 0, 74, 0, [[0, '#7E1E1E'], [.32, '#E2524A'], [.55, '#C23A33'], [1, '#6E1717']]);
    rr(g, 26, 26, 48, 64, 16); g.fill();
    g.fillStyle = 'rgba(0,0,0,.18)'; g.fillRect(26, 44, 48, 3); g.fillRect(26, 74, 48, 3);
    g.fillStyle = lin(g, 34, 0, 66, 0, [[0, '#6E747F'], [.4, '#E9ECF1'], [1, '#5E6672']]);  // collar
    rr(g, 34, 12, 32, 16, 4); g.fill();
    g.fillStyle = '#2B2F38'; rr(g, 40, 6, 20, 9, 3); g.fill();                            // valve
    g.fillStyle = '#C9A227'; dot(g, 50, 10, 3);
    g.fillStyle = '#fff'; g.font = '900 11px sans-serif'; g.textAlign = 'center'; g.fillText('LPG', 50, 64);
    g.fillStyle = lin(g, 30, 0, 70, 0, [[0, '#5E6672'], [.5, '#AEB5C0'], [1, '#5E6672']]); g.fillRect(30, 88, 40, 5);
    shine(g, 31, 32, 5, 50, .55);
  };
  ART.f_liion = function (g) {                // e-scooter / power-tool lithium battery pack
    shadow(g, 50, 88, 36);
    g.fillStyle = lin(g, 0, 34, 0, 84, [[0, '#3A4458'], [1, '#141A26']]); rr(g, 12, 38, 76, 44, 8); g.fill();
    g.fillStyle = lin(g, 0, 30, 0, 42, [[0, '#566177'], [1, '#2E3648']]); rr(g, 12, 32, 76, 12, 6); g.fill();
    g.fillStyle = '#3A86E6'; rr(g, 20, 50, 30, 14, 3); g.fill();
    g.fillStyle = '#fff'; g.font = '900 8px sans-serif'; g.textAlign = 'center'; g.fillText('Li-ion', 35, 60);
    g.fillStyle = '#9AA2AE'; g.fillRect(58, 52, 22, 3); g.fillRect(58, 58, 22, 3); g.fillRect(58, 64, 14, 3);
    g.fillStyle = '#D7261E'; rr(g, 18, 26, 10, 8, 2); g.fill(); g.fillStyle = '#1B1B1B'; rr(g, 72, 26, 10, 8, 2); g.fill();
    g.strokeStyle = '#D7261E'; g.lineWidth = 2.4; g.beginPath(); g.moveTo(23, 26); g.bezierCurveTo(20, 12, 40, 10, 44, 20); g.stroke();
    g.strokeStyle = '#1B1B1B'; g.beginPath(); g.moveTo(77, 26); g.bezierCurveTo(80, 12, 60, 10, 56, 20); g.stroke();
    g.fillStyle = 'rgba(255,170,60,.85)';                                                // swollen seam: a damaged pack
    oval(g, 50, 82, 22, 3.2); g.fill();
    shine(g, 16, 41, 3.5, 36, .35);
  };
  ART.f_carbat = function (g) {               // lead-acid car battery
    shadow(g, 50, 90, 38);
    g.fillStyle = lin(g, 0, 36, 0, 88, [[0, '#2A3140'], [1, '#0D1119']]); rr(g, 10, 38, 80, 50, 5); g.fill();
    g.fillStyle = lin(g, 0, 28, 0, 40, [[0, '#4A5366'], [1, '#2A3140']]); rr(g, 10, 30, 80, 12, 4); g.fill();
    g.fillStyle = lin(g, 0, 18, 0, 30, [[0, '#E6E9EE'], [1, '#8A93A0']]); rr(g, 20, 20, 12, 12, 2); g.fill(); rr(g, 68, 20, 12, 12, 2); g.fill();
    g.fillStyle = '#D7261E'; rr(g, 18, 18, 16, 5, 2); g.fill(); g.fillStyle = '#1B1B1B'; rr(g, 66, 18, 16, 5, 2); g.fill();
    g.fillStyle = '#D7261E'; g.font = '900 12px sans-serif'; g.textAlign = 'center'; g.fillText('+', 26, 52);
    g.fillStyle = '#C9D0DA'; g.fillText('−', 74, 52);
    g.fillStyle = '#F2B233'; rr(g, 28, 58, 44, 18, 3); g.fill();
    g.fillStyle = '#1B1B1B'; g.font = '900 9px sans-serif'; g.fillText('12V Pb', 50, 70);
    shine(g, 14, 42, 3.5, 40, .3);
  };
  ART.f_aero = function (g) {                 // a pack of FULL aerosols, caps still on
    shadow(g, 50, 92, 34);
    [[22, '#3FA46B', '#1F6E44', 30], [54, '#E8772E', '#B95514', 24], [38, '#4E86C8', '#2B5A96', 36]].forEach(function (a) {
      var x = a[0], top = a[3];
      g.fillStyle = lin(g, x, 0, x + 26, 0, [[0, '#8A93A0'], [.35, '#F4F6F9'], [1, '#6E7783']]);
      rr(g, x, top + 10, 26, 88 - top - 10, 6); g.fill();
      g.fillStyle = lin(g, x, 0, x + 26, 0, [[0, a[2]], [.4, a[1]], [1, a[2]]]); g.fillRect(x, top + 26, 26, 30);
      g.fillStyle = lin(g, x + 3, 0, x + 23, 0, [[0, a[2]], [.5, a[1]], [1, a[2]]]); rr(g, x + 3, top, 20, 13, 5); g.fill();
      shine(g, x + 4, top + 14, 3, 60 - top, .7);
    });
    diamond(g, 51, 58, 7);
  };
  ART.f_paint = function (g) {                // solvent paint tin, lid lifted, drip down the side
    shadow(g, 50, 92, 30);
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#7D8592'], [.3, '#EEF1F5'], [1, '#6B7380']]); rr(g, 22, 34, 56, 56, 5); g.fill();
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#7A2E0E'], [.35, '#C8571E'], [1, '#6B270B']]); g.fillRect(22, 46, 56, 32);
    diamond(g, 38, 62, 9);
    g.fillStyle = '#fff'; g.font = '900 6.5px sans-serif'; g.textAlign = 'left'; g.fillText('SOLVENT', 48, 66); g.fillText('ENAMEL', 48, 74);
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#9AA2AE'], [.4, '#FFFFFF'], [1, '#8A93A0']]); oval(g, 50, 34, 28, 7); g.fill();
    g.fillStyle = '#2F6E9C'; oval(g, 50, 34, 22, 5); g.fill();                               // the paint, open
    g.fillStyle = '#2F6E9C'; g.beginPath(); g.moveTo(70, 36); g.quadraticCurveTo(74, 52, 71, 58); g.quadraticCurveTo(68, 52, 70, 36); g.fill();
    g.fillStyle = lin(g, 0, 10, 0, 20, [[0, '#E9ECF1'], [1, '#9AA2AE']]); g.save(); g.translate(30, 18); g.rotate(-0.5); oval(g, 0, 0, 20, 5); g.fill(); g.restore();
    g.strokeStyle = '#7D8592'; g.lineWidth = 2; g.beginPath(); g.arc(50, 34, 30, Math.PI, 0); g.stroke();
    shine(g, 26, 38, 3.5, 46, .55);
  };
  ART.f_tube = function (g) {                 // a bundle of fluorescent tubes, one cracked
    shadow(g, 50, 82, 42);
    [[42, .0], [52, .04], [62, -.03]].forEach(function (t, i) {
      g.save(); g.translate(50, t[0]); g.rotate(t[1] - .12);
      g.fillStyle = lin(g, 0, -5, 0, 5, [[0, '#FFFFFF'], [.5, '#E4ECF6'], [1, '#B9C6D6']]); rr(g, -44, -5, 88, 10, 5); g.fill();
      g.fillStyle = lin(g, 0, -5, 0, 5, [[0, '#C9D0DA'], [1, '#6E7783']]); rr(g, -46, -5.5, 8, 11, 2); g.fill(); rr(g, 38, -5.5, 8, 11, 2); g.fill();
      g.fillStyle = '#5E6672'; g.fillRect(-49, -2, 3, 1.5); g.fillRect(-49, 1, 3, 1.5); g.fillRect(46, -2, 3, 1.5); g.fillRect(46, 1, 3, 1.5);
      if (i === 1) { g.strokeStyle = 'rgba(80,95,120,.8)'; g.lineWidth = 1.2;
        g.beginPath(); g.moveTo(4, -5); g.lineTo(8, 0); g.lineTo(5, 5); g.moveTo(8, 0); g.lineTo(14, -2); g.stroke(); }
      g.restore();
    });
    g.fillStyle = 'rgba(255,255,255,.9)'; [[60, 72], [66, 76], [56, 77]].forEach(function (p) { poly(g, [[p[0], p[1]], [p[0] + 3, p[1] - 2], [p[0] + 2, p[1] + 2]]); g.fill(); });
  };
  ART.f_sharps = function (g) {               // yellow clinical sharps bin, biohazard mark
    shadow(g, 50, 92, 26);
    g.fillStyle = lin(g, 24, 0, 76, 0, [[0, '#B8960E'], [.35, '#FFE04A'], [1, '#A88A0C']]);
    poly(g, [[28, 34], [72, 34], [76, 90], [24, 90]]); g.fill();
    g.fillStyle = lin(g, 0, 22, 0, 36, [[0, '#E8C31F'], [1, '#B8960E']]); rr(g, 22, 24, 56, 13, 4); g.fill();
    g.fillStyle = '#7A6208'; rr(g, 38, 27, 24, 5, 2); g.fill();                            // the posting slot
    g.save(); g.translate(50, 62); g.strokeStyle = '#1B1B1B'; g.fillStyle = '#1B1B1B'; g.lineWidth = 2.6;
    for (var i = 0; i < 3; i++) { g.rotate(Math.PI * 2 / 3); g.beginPath(); g.arc(0, -7, 7, 0.3, Math.PI * 2 - 0.3); g.stroke(); }
    dot(g, 0, 0, 2.6); g.restore();
    g.fillStyle = '#1B1B1B'; g.font = '900 6.5px sans-serif'; g.textAlign = 'center'; g.fillText('SHARPS', 50, 84);
    shine(g, 30, 38, 3.5, 44, .6);
  };
  ART.f_ext = function (g) {                  // fire extinguisher
    shadow(g, 46, 93, 24);
    g.fillStyle = lin(g, 28, 0, 64, 0, [[0, '#7E1414'], [.32, '#F04A3A'], [.6, '#C82A1E'], [1, '#6E1010']]);
    rr(g, 28, 26, 36, 66, 12); g.fill();
    g.fillStyle = '#EFE7DA'; rr(g, 32, 48, 28, 22, 2); g.fill();
    g.fillStyle = '#C82A1E'; g.fillRect(35, 52, 22, 3); g.fillStyle = '#5E6672'; g.fillRect(35, 58, 16, 2.5); g.fillRect(35, 63, 20, 2.5);
    g.fillStyle = lin(g, 0, 10, 0, 28, [[0, '#2B2F38'], [1, '#111']]); rr(g, 38, 14, 16, 14, 3); g.fill();
    g.fillStyle = '#2B2F38'; g.beginPath(); g.moveTo(40, 14); g.lineTo(26, 8); g.lineTo(28, 5); g.lineTo(44, 11); g.fill();   // handle
    dot(g, 54, 17, 4); g.fillStyle = '#C9D0DA'; dot(g, 54, 17, 2.6);                        // gauge
    g.strokeStyle = '#111'; g.lineWidth = 3.6; g.lineCap = 'round';
    g.beginPath(); g.moveTo(52, 22); g.bezierCurveTo(78, 26, 82, 60, 70, 78); g.stroke();  // hose
    g.fillStyle = '#111'; rr(g, 66, 76, 8, 10, 2); g.fill();
    shine(g, 33, 32, 4.5, 52, .5);
  };
  ART.f_oil = function (g) {                  // 200 L waste-oil drum, leaking
    shadow(g, 50, 92, 34);
    g.fillStyle = 'rgba(30,24,10,.75)'; oval(g, 62, 91, 26, 4.5); g.fill();                   // the leak
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#123C22'], [.35, '#3E8C5A'], [.6, '#2A6B42'], [1, '#0E2F1A']]);
    rr(g, 22, 16, 56, 74, 4); g.fill();
    g.fillStyle = 'rgba(0,0,0,.28)'; g.fillRect(22, 38, 56, 4); g.fillRect(22, 66, 56, 4);
    g.fillStyle = lin(g, 22, 0, 78, 0, [[0, '#2A6B42'], [.4, '#6BC28C'], [1, '#1E5434']]); oval(g, 50, 16, 28, 6); g.fill();
    g.fillStyle = '#123C22'; dot(g, 62, 15, 3);
    g.fillStyle = '#F2B233'; rr(g, 32, 46, 36, 14, 2); g.fill();
    g.fillStyle = '#1B1B1B'; g.font = '900 7.5px sans-serif'; g.textAlign = 'center'; g.fillText('USED OIL', 50, 56);
    g.fillStyle = 'rgba(20,16,6,.85)'; g.beginPath(); g.moveTo(66, 70); g.quadraticCurveTo(70, 82, 66, 90); g.quadraticCurveTo(62, 82, 66, 70); g.fill();
    shine(g, 27, 22, 4, 62, .45);
  };
  ART.f_asb = function (g) {                  // old corrugated fibre-cement sheet, broken corner
    shadow(g, 50, 84, 42);
    g.save(); g.translate(50, 56); g.rotate(-0.08);
    g.beginPath(); g.moveTo(-44, -20); g.lineTo(44, -20); g.lineTo(44, 14); g.lineTo(30, 22); g.lineTo(22, 16); g.lineTo(-44, 22); g.closePath(); g.save(); g.clip();
    for (var i = 0; i < 9; i++) {
      var x = -44 + i * 11;
      g.fillStyle = lin(g, x, 0, x + 11, 0, [[0, '#8E948A'], [.5, '#D2D6CC'], [1, '#8E948A']]);
      g.fillRect(x, -22, 11, 46);
    }
    g.fillStyle = 'rgba(90,80,40,.28)'; oval(g, -18, 4, 14, 8); g.fill(); oval(g, 20, -10, 9, 5); g.fill();   // weathering
    g.restore();
    g.strokeStyle = '#6E746A'; g.lineWidth = 1.4; g.beginPath(); g.moveTo(44, 14); g.lineTo(30, 22); g.lineTo(22, 16); g.stroke();
    g.fillStyle = '#C6CABE'; [[26, 26], [34, 28], [20, 28]].forEach(function (p) { poly(g, [[p[0], p[1]], [p[0] + 4, p[1] - 2], [p[0] + 5, p[1] + 2]]); g.fill(); });
    g.restore();
  };

  /* --- the everyday load the hazards hide in --- */
  ART.f_pallet = function (g) {               // an empty timber pallet, three-quarter view
    shadow(g, 50, 80, 42);
    var A=[10,52], B=[58,62], C=[90,46], D=[42,38], h=14;          // top deck corners, deck thickness
    g.fillStyle = lin(g, 0, 52, 0, 76, [[0, '#9C6E34'], [1, '#6E4C22']]); poly(g, [A, B, [B[0], B[1] + h], [A[0], A[1] + h]]); g.fill();
    g.fillStyle = lin(g, 58, 0, 90, 0, [[0, '#7E5A2A'], [1, '#5A3E1A']]); poly(g, [B, C, [C[0], C[1] + h], [B[0], B[1] + h]]); g.fill();
    g.fillStyle = '#2E2010';                                          // the fork openings
    [[.18, .42], [.58, .82]].forEach(function (t) {
      var x0 = A[0] + (B[0] - A[0]) * t[0], y0 = A[1] + (B[1] - A[1]) * t[0], x1 = A[0] + (B[0] - A[0]) * t[1], y1 = A[1] + (B[1] - A[1]) * t[1];
      poly(g, [[x0, y0 + 4], [x1, y1 + 4], [x1, y1 + h - 3], [x0, y0 + h - 3]]); g.fill(); });
    [[.22, .46], [.6, .84]].forEach(function (t) {
      var x0 = B[0] + (C[0] - B[0]) * t[0], y0 = B[1] + (C[1] - B[1]) * t[0], x1 = B[0] + (C[0] - B[0]) * t[1], y1 = B[1] + (C[1] - B[1]) * t[1];
      poly(g, [[x0, y0 + 4], [x1, y1 + 4], [x1, y1 + h - 3], [x0, y0 + h - 3]]); g.fill(); });
    g.fillStyle = '#3A2812'; poly(g, [A, B, C, D]); g.fill();         // gaps between the boards
    for (var k = 0; k < 5; k++) {                                     // five deck boards
      var t0 = k / 5 + 0.02, t1 = (k + 1) / 5 - 0.03;
      var p0 = [A[0] + (D[0] - A[0]) * t0, A[1] + (D[1] - A[1]) * t0], p1 = [A[0] + (D[0] - A[0]) * t1, A[1] + (D[1] - A[1]) * t1];
      var q0 = [B[0] + (C[0] - B[0]) * t0, B[1] + (C[1] - B[1]) * t0], q1 = [B[0] + (C[0] - B[0]) * t1, B[1] + (C[1] - B[1]) * t1];
      g.fillStyle = lin(g, p0[0], p0[1], q1[0], q1[1], [[0, '#EAC48A'], [1, '#B98A48']]); poly(g, [p0, q0, q1, p1]); g.fill();
    }
    g.fillStyle = 'rgba(255,255,255,.35)'; poly(g, [[12, 51.5], [56, 61], [56, 62.5], [12, 53]]); g.fill();
  };
  ART.f_film = function (g) {                 // a strapped bale of clear stretch film
    shadow(g, 50, 88, 40);
    g.fillStyle = lin(g, 0, 36, 0, 88, [[0, 'rgba(210,232,250,.95)'], [1, 'rgba(140,180,215,.95)']]);
    poly(g, [[12, 40], [60, 48], [60, 88], [12, 80]]); g.fill();
    g.fillStyle = 'rgba(120,160,200,.95)'; poly(g, [[60, 48], [88, 38], [88, 76], [60, 88]]); g.fill();
    g.fillStyle = 'rgba(232,244,255,.98)'; poly(g, [[12, 40], [40, 30], [88, 38], [60, 48]]); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.75)'; g.lineWidth = 1.2;
    for (var i = 0; i < 6; i++) { g.beginPath(); g.moveTo(14, 46 + i * 6); g.quadraticCurveTo(36, 50 + i * 6, 58, 54 + i * 6); g.stroke(); }
    g.fillStyle = '#3E7FD8'; [[24, 24], [44, 44]].forEach(function (s) { poly(g, [[s[0], 44 - (s[0] - 24) * .15], [s[0] + 4, 45 - (s[0] - 24) * .15], [s[0] + 4, 85 - (s[0] - 24) * .1], [s[0], 84 - (s[0] - 24) * .1]]); g.fill(); });
    shine(g, 16, 46, 2.5, 30, .6);
  };
  ART.f_drum = function (g) {                 // empty blue plastic drum, bungs closed
    shadow(g, 50, 92, 30);
    g.fillStyle = lin(g, 24, 0, 76, 0, [[0, '#123E78'], [.35, '#4E92E2'], [.6, '#2F6EBF'], [1, '#0F3466']]);
    rr(g, 24, 18, 52, 72, 10); g.fill();
    g.fillStyle = 'rgba(0,0,0,.18)'; g.fillRect(24, 40, 52, 4); g.fillRect(24, 66, 52, 4);
    g.fillStyle = lin(g, 24, 0, 76, 0, [[0, '#2F6EBF'], [.4, '#8EC0F5'], [1, '#205AA0']]); oval(g, 50, 18, 26, 6); g.fill();
    g.fillStyle = '#0F3466'; dot(g, 40, 17, 3); dot(g, 60, 17, 3);
    shine(g, 29, 24, 4.5, 58, .55);
  };
  ART.f_chair = function (g) {                // a broken office chair
    shadow(g, 50, 92, 32);
    g.strokeStyle = '#5E6672'; g.lineWidth = 3.4; g.lineCap = 'round';
    [[22, 86], [50, 90], [78, 86], [34, 80], [66, 80]].forEach(function (p) { g.beginPath(); g.moveTo(50, 74); g.lineTo(p[0], p[1]); g.stroke(); });
    g.fillStyle = '#1B1B1B'; [[22, 86], [50, 90], [78, 86], [34, 80], [66, 80]].forEach(function (p) { dot(g, p[0], p[1], 3); });
    g.fillStyle = lin(g, 46, 0, 54, 0, [[0, '#5E6672'], [.5, '#C9D0DA'], [1, '#5E6672']]); g.fillRect(47, 56, 6, 20);
    g.fillStyle = lin(g, 0, 48, 0, 62, [[0, '#4A5366'], [1, '#232A36']]); rr(g, 22, 48, 56, 12, 6); g.fill();
    g.save(); g.translate(52, 30); g.rotate(0.22);                                          // the back hangs loose
    g.fillStyle = lin(g, -18, 0, 18, 0, [[0, '#232A36'], [.4, '#4A5366'], [1, '#1B2029']]); rr(g, -18, -22, 36, 34, 8); g.fill();
    g.fillStyle = 'rgba(255,255,255,.18)'; rr(g, -14, -18, 4, 26, 2); g.fill();
    g.restore();
    g.fillStyle = '#C9A227'; poly(g, [[40, 46], [46, 44], [44, 50]]); g.fill();               // torn foam
  };
  ART.f_reel = function (g) {                 // an empty timber cable reel on its side
    shadow(g, 50, 90, 36);
    g.fillStyle = lin(g, 0, 40, 0, 70, [[0, '#9C6E34'], [1, '#6E4C22']]); g.fillRect(30, 42, 44, 30);
    g.fillStyle = '#3A3A3A'; for (var i = 0; i < 4; i++) g.fillRect(34 + i * 10, 42, 5, 30);
    g.fillStyle = rad(g, 30, 52, 32, [[0, '#E2B878'], [.8, '#B0803E'], [1, '#8A5E2A']]); oval(g, 30, 57, 16, 33); g.fill();
    g.strokeStyle = 'rgba(80,50,20,.45)'; g.lineWidth = 1; for (var r = 0; r < 4; r++) { g.beginPath(); g.ellipse(30, 57, 5 + r * 3, 10 + r * 6.5, 0, 0, 7); g.stroke(); }
    g.fillStyle = '#4A3214'; oval(g, 30, 57, 4, 8); g.fill();
    g.fillStyle = lin(g, 70, 0, 86, 0, [[0, '#B0803E'], [1, '#6E4C22']]); oval(g, 74, 57, 14, 31); g.fill();
    shine(g, 22, 34, 3, 18, .4);
  };
  ART.f_crate = function (g) {                // stackable plastic crate
    shadow(g, 50, 88, 38);
    g.fillStyle = lin(g, 0, 36, 0, 88, [[0, '#3FA46B'], [1, '#1F6E44']]); poly(g, [[12, 42], [62, 50], [62, 88], [12, 80]]); g.fill();
    g.fillStyle = '#18583A'; poly(g, [[62, 50], [88, 40], [88, 78], [62, 88]]); g.fill();
    g.fillStyle = '#6BC28C'; poly(g, [[12, 42], [38, 32], [88, 40], [62, 50]]); g.fill();
    g.fillStyle = '#123F28'; poly(g, [[18, 42], [38, 35], [82, 41], [62, 48]]); g.fill();
    g.fillStyle = 'rgba(10,40,24,.65)';
    for (var c = 0; c < 4; c++) for (var r = 0; r < 3; r++) { rr(g, 16 + c * 11.5, 55 + r * 9 + c * 1.6, 7, 5, 1.5); g.fill(); }
    g.fillStyle = 'rgba(10,40,24,.65)'; rr(g, 26, 47, 18, 4, 2); g.fill();
    shine(g, 14, 48, 2.5, 28, .45);
  };
  ART.f_mat = function (g) {                  // an old mattress, slumped
    shadow(g, 50, 86, 44);
    g.fillStyle = lin(g, 0, 44, 0, 82, [[0, '#F2EEE2'], [1, '#C8C2B0']]);
    g.beginPath(); g.moveTo(8, 56); g.quadraticCurveTo(50, 40, 92, 48); g.lineTo(92, 70); g.quadraticCurveTo(50, 64, 8, 80); g.closePath(); g.fill();
    g.fillStyle = '#B9B19C'; g.beginPath(); g.moveTo(8, 72); g.quadraticCurveTo(50, 56, 92, 64); g.lineTo(92, 70); g.quadraticCurveTo(50, 64, 8, 80); g.closePath(); g.fill();
    g.fillStyle = '#9C9480'; for (var i = 0; i < 6; i++) { var x = 20 + i * 13; dot(g, x, 56 - i * 1.2 + (i % 2) * 2, 1.6); }
    g.fillStyle = 'rgba(160,120,40,.35)'; oval(g, 62, 54, 10, 4, -.1); g.fill();              // stain
    g.strokeStyle = '#4E86C8'; g.lineWidth = 2; g.beginPath(); g.moveTo(8, 64); g.quadraticCurveTo(50, 48, 92, 56); g.stroke();
  };
  ART.f_pipe = function (g) {                 // offcut lengths of grey PVC pipe
    shadow(g, 50, 82, 40);
    [[48, -0.18, 1], [62, -0.1, 0.9]].forEach(function (p) {
      g.save(); g.translate(50, p[0]); g.rotate(p[1]);
      g.fillStyle = lin(g, 0, -9, 0, 9, [[0, '#E9ECF1'], [.4, '#B9C0CA'], [1, '#7E8794']]); rr(g, -42 * p[2], -9, 84 * p[2], 18, 3); g.fill();
      g.fillStyle = '#9AA2AE'; oval(g, 42 * p[2], 0, 4.5, 9); g.fill(); g.fillStyle = '#4A5160'; oval(g, 42 * p[2], 0, 2.8, 6.5); g.fill();
      g.fillStyle = 'rgba(255,255,255,.75)'; rr(g, -38 * p[2], -6, 70 * p[2], 2.5, 1); g.fill();
      g.fillStyle = '#5E6672'; g.font = '700 5px sans-serif'; g.textAlign = 'center'; g.fillText('PVC  110mm', -6, 5);
      g.restore();
    });
  };

  /* =================================================================================
     Added 21 Oct 2026 — Dispatch map pieces: Lirich's own two truck types and the yard.
     Side view, facing right, drawn to read at 24–32 px on a phone map.
     ================================================================================= */
  function dWheel(g, x, y, r) {
    g.fillStyle = '#14181F'; dot(g, x, y, r);
    g.fillStyle = lin(g, x - r, y - r, x + r, y + r, [[0, '#E9ECF1'], [1, '#7E8794']]); dot(g, x, y, r * .5);
  }
  ART.d_hook = function (g) {                 // hooklift truck carrying a roll-on bin
    shadow(g, 50, 86, 44);
    g.fillStyle = lin(g, 0, 30, 0, 70, [[0, '#4FA37A'], [1, '#22603F']]);              // the bin it carries
    poly(g, [[8, 38], [62, 38], [66, 72], [8, 72]]); g.fill();
    g.fillStyle = 'rgba(0,0,0,.18)'; for (var i = 0; i < 4; i++) g.fillRect(14 + i * 13, 40, 3, 30);
    g.fillStyle = '#5E6672'; rr(g, 6, 72, 66, 6, 2); g.fill();                         // chassis
    g.fillStyle = '#3A4150'; poly(g, [[60, 38], [70, 22], [74, 24], [66, 40]]); g.fill();  // the hook arm
    g.fillStyle = lin(g, 0, 36, 0, 76, [[0, '#FF9A4A'], [1, '#C25A12']]);                // cab
    poly(g, [[70, 40], [86, 40], [94, 54], [94, 76], [70, 76]]); g.fill();
    g.fillStyle = lin(g, 0, 42, 0, 56, [[0, '#D6ECFF'], [1, '#7FB2E6']]); poly(g, [[74, 44], [85, 44], [90, 54], [74, 54]]); g.fill();
    g.fillStyle = '#D6A93A'; g.fillRect(70, 64, 24, 3);                                // gold stripe
    dWheel(g, 20, 80, 7); dWheel(g, 36, 80, 7); dWheel(g, 82, 80, 7);
    shine(g, 10, 41, 2.5, 26, .45);
  };
  ART.d_tanker = function (g) {               // vacuum tanker for marine liquid waste
    shadow(g, 50, 86, 44);
    g.fillStyle = lin(g, 0, 34, 0, 72, [[0, '#9CC6F2'], [.4, '#4E86C8'], [1, '#1E4E8A']]);
    rr(g, 6, 36, 60, 34, 16); g.fill();
    g.fillStyle = 'rgba(0,0,0,.18)'; g.fillRect(24, 36, 3, 34); g.fillRect(46, 36, 3, 34);
    g.fillStyle = '#C9D0DA'; rr(g, 30, 28, 14, 9, 3); g.fill();                         // manway
    g.strokeStyle = '#2B2F38'; g.lineWidth = 3; g.beginPath(); g.moveTo(10, 66); g.quadraticCurveTo(2, 74, 12, 78); g.stroke();  // hose
    g.fillStyle = '#5E6672'; rr(g, 6, 72, 66, 6, 2); g.fill();
    g.fillStyle = lin(g, 0, 36, 0, 76, [[0, '#F2F4F7'], [1, '#AEB5C0']]);                // cab
    poly(g, [[68, 40], [84, 40], [94, 54], [94, 76], [68, 76]]); g.fill();
    g.fillStyle = lin(g, 0, 42, 0, 56, [[0, '#D6ECFF'], [1, '#7FB2E6']]); poly(g, [[72, 44], [83, 44], [89, 54], [72, 54]]); g.fill();
    g.fillStyle = '#D6A93A'; g.fillRect(68, 64, 26, 3);
    dWheel(g, 20, 80, 7); dWheel(g, 36, 80, 7); dWheel(g, 82, 80, 7);
    shine(g, 14, 40, 40, 3.5, .6);
  };
  ART.d_yard = function (g) {                 // the Gul Drive yard: a shed, a bin row and the weighbridge
    shadow(g, 50, 88, 46);
    g.fillStyle = lin(g, 0, 30, 0, 84, [[0, '#2B4778'], [1, '#13274B']]); poly(g, [[8, 40], [58, 40], [58, 84], [8, 84]]); g.fill();
    g.fillStyle = lin(g, 0, 18, 0, 42, [[0, '#F2D27A'], [1, '#B98C22']]); poly(g, [[4, 42], [33, 20], [62, 42]]); g.fill();
    g.fillStyle = '#0B1630'; rr(g, 20, 56, 26, 28, 2); g.fill();
    g.fillStyle = 'rgba(255,255,255,.18)'; for (var i = 0; i < 4; i++) g.fillRect(21, 59 + i * 6, 24, 2);
    [['#4FA37A', 62], ['#4E86C8', 76]].forEach(function (b) {                          // roll-on bins waiting
      g.fillStyle = lin(g, 0, 60, 0, 84, [[0, b[0]], [1, '#1B2A4A']]); poly(g, [[b[1], 62], [b[1] + 12, 62], [b[1] + 13, 84], [b[1], 84]]); g.fill(); });
    g.fillStyle = '#E8B923'; g.fillRect(60, 84, 32, 4);
  };

  /* =================================================================================
     Added 21 Oct 2026 — shared plant scenes, so the belt games sit in the same bright,
     glossy world as Sort It! and Spot the Contaminant instead of a dark flat panel.
       LirichSprites.scene.hall(ctx, w, h)        a lit sorting-hall backdrop (cached)
       LirichSprites.scene.belt(ctx, x, y, w, h, offset)   a rubber conveyor with rails,
                                                  cleats that move with offset, and rollers
     Neither function reads or changes any game state.
     ================================================================================= */
  var hallCache = {};
  function hall(ctx, w, h) {
    var id = w + 'x' + h, c = hallCache[id];
    if (!c) {
      c = document.createElement('canvas'); c.width = Math.round(w * DPR); c.height = Math.round(h * DPR);
      var g = c.getContext('2d'); g.scale(DPR, DPR);
      g.fillStyle = lin(g, 0, 0, 0, h, [[0, '#DCE8F4'], [.55, '#C9D7E6'], [.56, '#B9C0C9'], [1, '#9EA6B0']]); g.fillRect(0, 0, w, h);
      g.fillStyle = 'rgba(255,255,255,.75)';                                       // high windows
      for (var x = 14; x < w; x += 70) { rr(g, x, h * .06, 50, h * .12, 4); g.fill(); }
      g.fillStyle = 'rgba(120,150,190,.25)'; for (var x2 = 14; x2 < w; x2 += 70) g.fillRect(x2 + 24, h * .06, 2, h * .12);
      for (var k = 0; k < w; k += 140) {                                             // steel columns
        g.fillStyle = lin(g, k, 0, k + 12, 0, [[0, '#7E8B9C'], [.5, '#C3CDD8'], [1, '#6E7B8C']]); g.fillRect(k + 60, 0, 12, h * .56);
      }
      g.fillStyle = 'rgba(0,0,0,.06)'; for (var y = h * .6; y < h; y += 18) g.fillRect(0, y, w, 1);
      g.fillStyle = '#E8B923'; g.fillRect(0, h - 7, w, 7);
      g.fillStyle = '#1B1B1B'; for (var s = -10; s < w; s += 22) { g.beginPath(); g.moveTo(s, h); g.lineTo(s + 9, h - 7); g.lineTo(s + 18, h - 7); g.lineTo(s + 9, h); g.fill(); }
      hallCache[id] = c;
    }
    ctx.drawImage(c, 0, 0, w, h);
  }
  function sceneBelt(ctx, x, y, w, h, off) {
    var g = ctx; off = off || 0;
    g.save();
    g.fillStyle = 'rgba(20,30,50,.22)'; g.fillRect(x, y + h + 4, w, 8);                 // shadow on the floor
    g.fillStyle = '#5E6672'; for (var lx = x + 30; lx < x + w; lx += 110) g.fillRect(lx, y + h, 6, 14);   // legs
    g.fillStyle = lin(g, 0, y, 0, y + h, [[0, '#3A414D'], [.5, '#2B3039'], [1, '#22262E']]); g.fillRect(x, y, w, h);
    g.beginPath(); g.rect(x, y, w, h); g.clip();
    g.strokeStyle = 'rgba(255,255,255,.10)'; g.lineWidth = 3;                          // cleats
    var step = 36, o = ((off % step) + step) % step;
    for (var cx0 = x - step; cx0 < x + w + step; cx0 += step) {
      g.beginPath(); g.moveTo(cx0 - o, y + 3); g.lineTo(cx0 - o - 10, y + h / 2); g.lineTo(cx0 - o, y + h - 3); g.stroke();
    }
    g.fillStyle = 'rgba(255,255,255,.08)'; g.fillRect(x, y + 2, w, h * .18);            // sheen
    g.restore();
    g.fillStyle = lin(g, 0, y - 7, 0, y, [[0, '#E6EBF1'], [1, '#8E99A6']]); g.fillRect(x, y - 7, w, 7);       // top rail
    g.fillStyle = lin(g, 0, y + h, 0, y + h + 8, [[0, '#9AA5B2'], [1, '#5E6672']]); g.fillRect(x, y + h, w, 8); // bottom rail
    g.fillStyle = '#C9D0DA'; for (var bx = x + 10; bx < x + w; bx += 26) { g.beginPath(); g.arc(bx, y + h + 4, 2, 0, 7); g.fill(); }
  }

  var errors = [];                            // any picture that throws while drawing (tests read this)
  function sprite(key, size) {
    var px = Math.max(8, Math.round(size * DPR)), id = key + '@' + px;
    if (cache[id]) return cache[id];
    var c = document.createElement('canvas'); c.width = c.height = px;
    var g = c.getContext('2d'); g.scale(px / 100, px / 100);
    g.lineJoin = 'round'; g.lineCap = 'round';
    try { (ART[key] || ART.food)(g); } catch (e) { errors.push(key + ': ' + e.message); }
    return (cache[id] = c);
  }
  function draw(ctx, key, x, y, size) { ctx.drawImage(sprite(key, size), x, y, size, size); }

  /* which picture to use for an item, by its name in lirich-rules.js, then by its glyph
     group. Returns null when no picture fits, and the game keeps its own icon. */
  var BY_NAME = {
    'pet bottle':'pet', 'pet bottles':'pet', 'drink can':'can', 'drink cans':'can', 'cardboard box':'card', 'cardboard':'card',
    'glass bottle':'glass', 'bottles':'glass', 'food waste':'food', 'small e-waste':'ewst', 'newspaper':'paper',
    'beverage carton':'carton', 'shampoo bottle':'hdpe', 'hdpe bottles':'hdpe', 'bubble wrap':'film',
    'food can':'tin', 'food cans':'tin', 'clean aluminium foil':'foil', 'glass jar':'jar', 'jars':'jar',
    'ceramic mug':'mug', 'mixed rubbish':'bag', 'pizza box':'pizza', 'paper cup':'cup', 'styrofoam box':'foam',
    'drinking straw':'straw', 'oily tray':'dirty',
    /* 10 Oct 2026: every remaining rules item, by its exact name */
    'egg tray':'eggtray', 'paper towel tube':'tube', 'envelope':'envelope', 'magazine':'magazine', 'tissue box':'tissuebox',
    'rinsed takeaway box':'takeaway', 'red packet':'redpacket', 'paper bag':'paperbag', 'shredded paper':'shred',
    'paper receipt':'receipt', 'greeting card':'greeting', 'gift wrapping paper':'giftwrap', 'tissue paper':'tissue',
    'paper plate':'plate', 'glitter paper':'glitter', 'wax paper':'wax',
    'plastic film':'pfilm', 'ziplock bag':'ziplock', 'plastic clothes hanger':'hanger', 'potato chip bag':'chips',
    'blister pack':'blister', 'expired credit card':'ccard', 'melamine plate':'melamine', 'oily food container':'oilybox',
    'plastic bag':'pbag', 'bubble tea cup':'bubbletea', 'plastic cutlery':'cutlery', 'cd or dvd':'disc',
    'detergent bottle':'detergent', 'biodegradable bag':'biobag', 'styrofoam cup':'sfcup', 'video tape':'vtape',
    'metal bottle cap':'cap', 'empty aerosol can':'aerosol', 'rusty tin can':'rusty', 'dirty aluminium tray':'dirty',
    'metal fork':'fork', 'steel wool':'swool', 'paint tin':'paint', 'biscuit tin':'biscuit',
    'drinking glass':'dglass', 'pyrex dish':'pyrex', 'mirror':'mirror', 'light bulb':'bulb', 'perfume bottle':'perfume',
    'jam jar':'jar', 'wooden chopsticks':'chopsticks', 'old t-shirt':'tshirt', 'used diaper':'diaper',
    'leftover medicine':'medicine', 'old refrigerator':'fridge', 'sanitary pad':'pad', 'household battery':'battery',
    'mobile phone':'phone', 'pair of shoes':'shoes'
  };
  var BY_GROUP = { bottle:'pet', can:'tin', box:'card', paper:'paper', cup:'cup', film:'film', glass:'jar' };
  function forItem(name, group) {
    var k = BY_NAME[String(name || '').toLowerCase()];
    return k || BY_GROUP[group] || null;
  }

  root.LirichSprites = { draw: draw, sprite: sprite, forItem: forItem, keys: Object.keys(ART), scene: { hall: hall, belt: sceneBelt }, errors: errors };
})(typeof window !== 'undefined' ? window : globalThis);
