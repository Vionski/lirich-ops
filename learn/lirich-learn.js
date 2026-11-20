/* =====================================================================================
   lirich-learn.js — the player layer shared by the Lirich Learn games.
   Added 4 Oct 2026.

   What it does
     1. PROGRESS, on this device only: stars per level, best run per game, the
        Recyclopedia (items a player has ruled correctly), a daily streak and a rank.
     2. FEEDBACK: particle bursts, floating "+kg" labels, shake, confetti, optional sound
        and vibration.
     3. Small UI helpers the games share: the star stamp on a results card, the
        "new card" toast and a short post-game learning debrief.

   What it does NOT do — the boundaries from the education plan still hold
     - Nothing is sent anywhere. No network call is made from this file.
     - Nothing personal is stored. The store holds item names, star counts and kilograms.
       No name, no class code, no team label, no device id.
     - Storage is browser localStorage under one key, 'lirich-learn-v1'. Clearing site
       data, a private window or a locked-down school browser simply means progress
       starts fresh. Every call is wrapped so a blocked store never breaks a game.
     - No timers that punish absence, no notifications, no loot boxes.
     - CREDITS (added 21 Nov 2026): a balance on this device, earned by learning (new stars,
       the daily item, a 7-day streak) and spent on one Continue per level in games that
       can be lost. Nothing is random: a credit always buys exactly what it says. Buying
       credits is shown in the shop behind a grown-up check, but no payment is taken until
       a payment provider and a server-side ledger exist (see lirich-wallet.js).
       A streak survives one missed day per week (a "rest day"), so it rewards habit
       without punishing a weekend.

   Sound is OFF by default (schools mute devices). The player turns it on from the hub.
   Motion respects prefers-reduced-motion.

   Games call:
     LirichLearn.learn(itemName, correct, {cat, rule})   -> true when a NEW card unlocked
     LirichLearn.level(game, levelIndex, stars, kg)
     LirichLearn.run(game, kg, alreadyBanked)             a finished run / round
     LirichLearn.daily()                                  counts today toward the streak
     LirichLearn.stamp(cardEl, stars, caption)
     LirichLearn.fx.burst(x, y, colour, n) / pop(text, x, y, colour) / shake(el) / confetti()
     LirichLearn.sfx('match'|'good'|'bad'|'win'|'star', step)
     LirichLearn.credits() / earn(n, why) / spend(n, why) -> balance / spend returns false if short
   ===================================================================================== */
(function (root) {
  'use strict';
  var KEY = 'lirich-learn-v1';

  /* Hazards live in Spot the Contaminant, not in the shared rules file, because they are
     not things anyone puts in a bin. The hub needs the count to show "x of 10". If a
     hazard is added there, raise this number. */
  var HAZARD_COUNT = 10;

  /* One learning close for every game. The score tells a player how they performed;
     this tells them why the skill matters and where it appears in Lirich's real work. */
  var DEBRIEFS = {
    threer: { skill: 'The 3R ladder', real: 'Lirich handles what is left after reduce and reuse. The less that reaches a Lirich truck, the better the system is working — and what does arrive is worth more when it is clean.', check: 'Name one thing you could refuse or reuse this week instead of throwing away.', next: ['Now check the blue bin', 'Lirich_BinOrNot_Game.html'] },
    binornot: { skill: 'Source separation', real: 'Clean recycling starts before collection. One wrong item can contaminate material that could otherwise be recovered.', check: 'Name one item you will keep out of the blue recycling bin next time.', next: ['Continue to On Route', 'Lirich_OnRoute_Game.html'] },
    onroute: { skill: 'Clean collection', real: 'Collection crews protect each stream by matching the right bin, vehicle and route before anything reaches the yard.', check: 'What can happen to a clean load when the wrong bin is collected?', next: ['Inspect the load at the yard', 'Lirich_SpotTheContaminant_Game.html'] },
    spot: { skill: 'Hazard inspection', real: 'Incoming loads must be checked before processing. Batteries, cylinders and other hazards can injure people or damage equipment.', check: 'Which hazard would you stop first, and what could it harm?', next: ['Sort the safe material', 'Lirich_SortIt_Game.html'] },
    sortit: { skill: 'Material recognition', real: 'Lirich teams separate mixed material into cleaner streams so more can move to recovery instead of disposal.', check: 'Which two materials were easiest to confuse, and how can you tell them apart?', next: ['Try the sorting line', 'Lirich_PickLine_Game.html'] },
    pickline: { skill: 'Accuracy under pressure', real: 'A fast line only works when picks stay accurate. Missed items lower bale quality and can cause a load to be rejected.', check: 'Why can slowing down briefly produce a better result?', next: ['Design the whole line', 'Lirich_BuildTheLine_Game.html'] },
    buildtheline: { skill: 'Process design', real: 'Screens, magnets and separators must be placed in a useful order. Equipment alone does not create recovery—the process does.', check: 'Which machine depends most on a machine before it?', next: ['Build material into larger loads', 'Lirich_UpgradeStream_Game.html'] },
    upgrade: { skill: 'Material aggregation', real: 'Loose items become economical to store and move only after they are bundled, baled or combined into shipment-scale loads.', check: 'Why is the same material more useful after it is baled or combined?', next: ['Load a real container', 'Lirich_LoadTheContainer_Game.html'] },
    loadcontainer: { skill: 'Weight and volume planning', real: 'A shipment can run out of payload or space first. Lirich planners need both numbers before a container moves.', check: 'Did your container run out of weight or space first, and why?', next: ['Build the recovery yard', 'Lirich_PlantBuilder_Game.html'] },
    plantbuilder: { skill: 'Investment planning', real: 'Every machine changes throughput, labour and material value. Good investment follows the next bottleneck, not the biggest machine.', check: 'Which upgrade solved your biggest bottleneck?', next: ['Run the city system', 'Lirich_ZeroWasteCity_Game.html'] },
    zerowastecity: { skill: 'Systems thinking', real: 'Collection, recovery, cost and public participation move together. A waste system succeeds only when the whole chain works.', check: 'Which decision helped one target but made another harder?', next: ['Return to the journey', 'index.html'] },
    dispatch: { skill: 'Operational coordination', real: 'Lirich dispatchers balance vehicles, empty bins, customer timing, tipping-floor space, documentation and cash every day.', check: 'Which constraint caused the biggest knock-on effect in your week?', next: ['Explore all Lirich Learn missions', 'index.html'] }
  };

  /* Rank ladder — Lirich's own job titles, earned by kilograms diverted across the
     flagship games on this device. Thresholds set so a first full Sort It! run (~650 kg)
     reaches Line Lead, and Plant Manager needs a few sessions across all three games. */
  var RANKS = [
    { kg: 0,    t: 'Trainee',       d: 'Everyone starts at the gate.' },
    { kg: 40,   t: 'Collector',     d: 'You know what goes in the truck.' },
    { kg: 200,  t: 'Sorter',        d: 'You can read a mixed load.' },
    { kg: 600,  t: 'Line Lead',     d: 'You keep a sorting line clean.' },
    { kg: 1500, t: 'Plant Manager', d: 'You run the whole yard.' },
    { kg: 4000, t: 'Lirich Legend', d: 'Enrichment of resources, in person.' }
  ];

  /* ------------------------------------------------------------------ store ------- */
  function blank() {
    return { v: 1, kg: 0, games: {}, dex: {}, streak: { last: '', n: 0, best: 0, rest: 1 },
             sound: false, dailyDone: '', credits: WELCOME_CREDITS };
  }
  var mem = null;
  /* every player, new or existing, starts with enough for one Continue and a bit over */
  var WELCOME_CREDITS = 5;
  function load() {
    if (mem) return mem;
    try { mem = JSON.parse(root.localStorage.getItem(KEY)) || blank(); }
    catch (e) { mem = blank(); }
    var b = blank();
    for (var k in b) if (mem[k] === undefined) mem[k] = b[k];
    return mem;
  }
  function save() { try { root.localStorage.setItem(KEY, JSON.stringify(mem)); } catch (e) {} }
  function game(id) { var s = load(); return s.games[id] || (s.games[id] = { best: 0, runs: 0, stars: {} }); }

  function today(d) {
    d = d || new Date();
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }
  function dayDiff(a, b) { return Math.round((new Date(b) - new Date(a)) / 864e5); }

  /* ------------------------------------------------------------------ progress ---- */
  function learn(name, correct, opt) {
    if (!name) return false;
    var s = load(), e = s.dex[name], isNew = false;
    if (!e) e = s.dex[name] = { seen: 0, ok: 0 };
    e.seen++;
    if (opt && opt.cat) e.cat = opt.cat;
    if (opt && opt.rule) e.r = opt.rule;
    if (correct) { if (!e.ok) isNew = true; e.ok++; }
    save();
    if (isNew) unlockToast(name, opt && opt.cat);
    return isNew;
  }
  /* kilograms go into the device total as they are earned, so a run abandoned half way
     still counts toward rank. level() banks a level's kg; run() banks only when told the
     kg was not already banked level by level. */
  function addKg(kg) {
    var s = load(), before = rankOf(s.kg);
    s.kg += Math.max(0, Number(kg) || 0); save();
    var after = rankOf(s.kg);
    if (after.i > before.i) setTimeout(function () { rankToast(after); }, 1100);
  }
  function level(id, idx, stars, kg) {
    var g = game(id), before = g.stars[idx] || 0;
    g.stars[idx] = Math.max(before, stars || 0);
    save();
    /* one credit per star earned for the first time on this level — replaying a level
       you already three-starred earns nothing, so credits cannot be farmed by grinding */
    if (g.stars[idx] > before) earn(g.stars[idx] - before, 'new star' + (g.stars[idx] - before > 1 ? 's' : ''));
    if (kg) addKg(kg);
  }
  function run(id, kg, alreadyBanked) {
    var g = game(id);
    kg = Math.max(0, Number(kg) || 0);
    g.runs++; g.best = Math.max(g.best, kg); save();
    if (!alreadyBanked) addKg(kg);
    if (!debrief(id)) setTimeout(function () { debrief(id); }, 0);
  }
  function daily() {
    var s = load(), t = today(), st = s.streak;
    if (st.last === t) return st.n;
    var gap = st.last ? dayDiff(st.last, t) : 99;
    if (gap === 1) st.n++;
    else if (gap === 2 && st.rest > 0) { st.rest--; st.n++; }   // one rest day forgiven
    else st.n = 1;
    if (st.n % 7 === 0) st.rest = Math.min(2, st.rest + 1);       // a rest day earned weekly
    st.last = t; st.best = Math.max(st.best, st.n);
    save();
    if (st.n % 7 === 0) earn(5, st.n + '-day streak');
    return st.n;
  }
  function rankOf(kg) {
    var i = 0; while (i < RANKS.length - 1 && kg >= RANKS[i + 1].kg) i++;
    var next = RANKS[i + 1] || null;
    return { i: i, t: RANKS[i].t, d: RANKS[i].d, kg: kg, next: next,
             pct: next ? (kg - RANKS[i].kg) / (next.kg - RANKS[i].kg) : 1 };
  }
  function starsTotal(id) {
    var g = load().games[id]; if (!g) return 0;
    var n = 0; for (var k in g.stars) n += g.stars[k]; return n;
  }

  /* ------------------------------------------------------------------ feedback ---- */
  var reduce = root.matchMedia && root.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var fxc = null, fxx = null, parts = [], running = false;
  function layer() {
    if (fxc) return;
    fxc = document.createElement('canvas');
    fxc.className = 'll-fx'; fxc.setAttribute('aria-hidden', 'true');
    document.body.appendChild(fxc); fxx = fxc.getContext('2d'); size();
    root.addEventListener('resize', size);
  }
  function size() {
    if (!fxc) return;
    var d = Math.min(2, root.devicePixelRatio || 1);
    fxc.width = innerWidth * d; fxc.height = innerHeight * d;
    fxx.setTransform(d, 0, 0, d, 0, 0);
  }
  function tick() {
    fxx.clearRect(0, 0, innerWidth, innerHeight);
    for (var i = parts.length - 1; i >= 0; i--) {
      var p = parts[i];
      p.vy += p.g; p.x += p.vx; p.y += p.vy; p.r += p.vr; p.life -= p.decay;
      if (p.life <= 0) { parts.splice(i, 1); continue; }
      fxx.save(); fxx.globalAlpha = Math.min(1, p.life * 1.6);
      fxx.translate(p.x, p.y); fxx.rotate(p.r); fxx.fillStyle = p.c;
      if (p.sq) fxx.fillRect(-p.s / 2, -p.s / 4, p.s, p.s / 2);
      else { fxx.beginPath(); fxx.arc(0, 0, p.s / 2, 0, 7); fxx.fill(); }
      fxx.restore();
    }
    if (parts.length) requestAnimationFrame(tick); else running = false;
  }
  function kick() { if (!running) { running = true; requestAnimationFrame(tick); } }

  function burst(x, y, c, n) {
    if (reduce) return; layer();
    n = Math.min(n || 10, 40);
    for (var i = 0; i < n; i++) {
      var a = Math.random() * Math.PI * 2, v = 1.5 + Math.random() * 3.2;
      parts.push({ x: x, y: y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 1.4, g: 0.16,
        r: 0, vr: (Math.random() - .5) * .3, s: 4 + Math.random() * 5, c: c || '#D6A93A',
        life: 1, decay: 0.022 + Math.random() * 0.015, sq: Math.random() < .5 });
    }
    if (parts.length > 400) parts.splice(0, parts.length - 400);
    kick();
  }
  function confetti() {
    if (reduce) return; layer();
    var cols = ['#D6A93A', '#E8772E', '#4E86C8', '#3FA46B', '#C08A4A', '#F2D27A'];
    for (var i = 0; i < 90; i++) {
      parts.push({ x: Math.random() * innerWidth, y: -10 - Math.random() * innerHeight * .3,
        vx: (Math.random() - .5) * 2, vy: 1 + Math.random() * 2.5, g: 0.05,
        r: Math.random() * 6, vr: (Math.random() - .5) * .25, s: 6 + Math.random() * 6,
        c: cols[i % cols.length], life: 1.4, decay: 0.006 + Math.random() * 0.004, sq: true });
    }
    kick();
  }
  function pop(text, x, y, c) {
    var d = document.createElement('div');
    d.className = 'll-pop'; d.textContent = text;
    x = Math.max(80, Math.min(innerWidth - 80, x)); y = Math.max(40, y);
    d.style.left = x + 'px'; d.style.top = y + 'px'; if (c) d.style.color = c;
    document.body.appendChild(d);
    setTimeout(function () { d.remove(); }, reduce ? 700 : 1000);
  }
  function shake(el) {
    if (!el || reduce) return;
    el.classList.remove('ll-shake'); void el.offsetWidth; el.classList.add('ll-shake');
  }

  /* sound — synthesised, so there are no audio files to ship and nothing to fetch */
  var ac = null;
  function sfx(kind, step) {
    var s = load(); if (!s.sound) return;
    try {
      ac = ac || new (root.AudioContext || root.webkitAudioContext)();
      var notes = { match: [523 * Math.pow(1.122, step || 0)], good: [660, 880], bad: [196, 165],
                    win: [523, 659, 784, 1047], star: [988 + (step || 0) * 120] }[kind] || [440];
      notes.forEach(function (f, i) {
        var o = ac.createOscillator(), g = ac.createGain(), t = ac.currentTime + i * 0.085;
        o.type = kind === 'bad' ? 'square' : 'triangle'; o.frequency.value = f;
        g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(kind === 'bad' ? .05 : .11, t + .012);
        g.gain.exponentialRampToValueAtTime(0.0001, t + .18);
        o.connect(g); g.connect(ac.destination); o.start(t); o.stop(t + .2);
      });
      if (navigator.vibrate) navigator.vibrate(kind === 'bad' ? [30, 40, 30] : 12);
    } catch (e) {}
  }
  /* ------------------------------------------------------------------ credits ----- */
  function credits() { var c = Number(load().credits); return isFinite(c) && c > 0 ? Math.floor(c) : 0; }
  var earnQ = [], earnT = 0;
  function earn(n, why) {
    n = Math.floor(Number(n) || 0); if (n <= 0) return credits();
    var s = load(); s.credits = credits() + n; save();
    /* several earnings in one moment (stars + streak) become one toast, not a stack */
    earnQ.push(n); clearTimeout(earnT);
    earnT = setTimeout(function () {
      var tot = earnQ.reduce(function (a, b) { return a + b; }, 0); earnQ = [];
      if (root.document) showToast('<span class="ll-rank-ic" aria-hidden="true">◆</span><span><small>' +
        esc(why || 'Credits earned') + '</small>+' + tot + ' credit' + (tot === 1 ? '' : 's') + ' · ' + credits() + ' total</span>');
      try { root.dispatchEvent(new CustomEvent('lirich-credits', { detail: { credits: credits() } })); } catch (e) {}
    }, 350);
    return s.credits;
  }
  function spend(n, why) {
    n = Math.floor(Number(n) || 0); if (n <= 0) return true;
    var c = credits(); if (c < n) return false;
    var s = load(); s.credits = c - n; save();
    try { root.dispatchEvent(new CustomEvent('lirich-credits', { detail: { credits: s.credits, spent: n, why: why } })); } catch (e) {}
    return true;
  }

  function setSound(on) { load().sound = !!on; save(); if (on) sfx('good'); }

  /* ------------------------------------------------------------------ UI bits ----- */
  function toastEl() {
    var t = document.querySelector('.ll-toast');
    if (!t) { t = document.createElement('div'); t.className = 'll-toast'; t.setAttribute('role', 'status'); document.body.appendChild(t); }
    return t;
  }
  function showToast(html) {
    var t = toastEl(); t.innerHTML = html; t.classList.add('on');
    clearTimeout(showToast.h); showToast.h = setTimeout(function () { t.classList.remove('on'); }, 2200);
  }
  function unlockToast(name, cat) {
    var n = Object.keys(load().dex).filter(function (k) { return load().dex[k].ok; }).length;
    showToast('<span class="ll-card-ic" aria-hidden="true"></span><span><small>New Recyclopedia card · ' + n + ' collected</small>' + esc(name) + '</span>');
  }
  function rankToast(r) {
    showToast('<span class="ll-rank-ic" aria-hidden="true">★</span><span><small>Promoted</small>' + esc(r.t) + '</span>');
    confetti(); sfx('win');
  }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  function debrief(id, card) {
    var d = DEBRIEFS[id];
    if (!d || !root.document) return false;
    if (!card) {
      var cards = root.document.querySelectorAll('.ov:not(.hide) .card');
      card = cards.length ? cards[cards.length - 1] : null;
    }
    if (!card) return false;
    var box = card.querySelector('.ll-debrief');
    if (!box) { box = root.document.createElement('div'); box.className = 'll-debrief'; box.setAttribute('role', 'note'); }
    box.innerHTML = '<small>What you mastered</small><b>' + esc(d.skill) + '</b>' +
      '<p><strong>At Lirich:</strong> ' + esc(d.real) + '</p>' +
      '<p class="ll-reflect"><strong>Think back:</strong> ' + esc(d.check) + '</p>' +
      '<a class="ll-next" href="' + esc(d.next[1]) + '">' + esc(d.next[0]) + ' <span aria-hidden="true">→</span></a>';
    if (!box.parentNode) {
      var buttons = card.querySelectorAll('button,.btn');
      var anchor = buttons.length ? buttons[buttons.length - 1] : null;
      if (anchor && anchor.parentNode === card) card.insertBefore(box, anchor); else card.appendChild(box);
    }
    return true;
  }

  /* The star stamp on a results card. Inserted once per card, refilled each time. */
  function stamp(card, stars, caption) {
    if (!card) return;
    var el = card.querySelector('.ll-stamp');
    if (!el) {
      el = document.createElement('div'); el.className = 'll-stamp';
      var h = card.querySelector('h1,h2');
      if (h && h.nextSibling) card.insertBefore(el, h.nextSibling); else card.appendChild(el);
    }
    el.setAttribute('aria-label', stars + ' of 3 stars');
    el.innerHTML = [0, 1, 2].map(function (i) {
      return '<span class="ll-star' + (i < stars ? ' on' : '') + '" style="--d:' + (i * 0.22 + 0.15) + 's">★</span>';
    }).join('') + (caption ? '<em>' + esc(caption) + '</em>' : '');
    el.style.display = stars < 0 ? 'none' : '';
    for (var i = 0; i < stars; i++) (function (i) { setTimeout(function () { sfx('star', i); }, 150 + i * 220); })(i);
    if (stars === 3) setTimeout(confetti, 600);
  }

  /* centre of an element in viewport coordinates, for bursts and pops */
  function centre(el) { var r = el.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; }

  root.LirichLearn = {
    store: load, save: save, ranks: RANKS, rankOf: rankOf, hazardCount: HAZARD_COUNT,
    learn: learn, level: level, run: run, daily: daily, starsTotal: starsTotal, today: today,
    setSound: setSound, sfx: sfx, credits: credits, earn: earn, spend: spend, welcomeCredits: WELCOME_CREDITS, stamp: stamp, debrief: debrief, toast: showToast, centre: centre,
    fx: { burst: burst, pop: pop, shake: shake, confetti: confetti },
    reset: function () { mem = blank(); save(); }
  };
})(typeof window !== 'undefined' ? window : globalThis);
