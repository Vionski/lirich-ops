/* =====================================================================================
   LIRICH LEARN — CHALLENGE MODE
   Makes every player face the identical board, so a score means skill and nothing else.

   HOW IT IS TURNED ON
       Open any eligible game with ?challenge=week  (or =day, or =SOMETHING-FIXED)
           Lirich_SortIt_Game.html?challenge=week
       That is all. This file installs the seeded generator before the game's own
       script runs, so the game needs no changes of its own.

   WHY IT MATTERS, AND IT IS NOT A GAMEPLAY REASON
       Gambling Control Act 2022, s 7(6): a "game of chance" includes a game involving
       BOTH skill and chance. Not a dominant-factor test — any chance contaminates the
       whole thing. And s 9(1)(b): a prize distribution is a lottery where it depends
       on chance "at any stage ... even if the arrangement involves a genuine or
       purported exercise of skill".

       Every one of these games shuffles or spawns randomly. Fixing the seed removes
       the chance: two players on the same board who score differently did so because
       one played better.

   ⚠ WHAT THIS FILE DOES NOT DO — READ BEFORE RUNNING ANY COMPETITION
       1. It does not make a competition lawful. s 9(4) also requires the skill element
          to be hard enough to actually filter people out, at entry and at winning.
       2. It cannot help the real-time games. On Route, Pick Line, Plant Builder and
          Dispatch depend on the device's frame rate, and frame rate is not skill. They
          are excluded here on purpose — see ELIGIBLE below.
       3. A random TIE-BREAK re-introduces chance and undoes all of it. Break ties on
          the earlier submission, or on a further skill criterion. Never on a draw.
       4. s 7(6)(c) catches a game merely PRESENTED as involving chance. Do not wrap
          this in the language of luck, draws, spins or winning tickets.
       Counsel signs a competition off. This file only removes one obstacle to it.
   ===================================================================================== */
"use strict";
(function (root) {

  /* Only games whose outcome is fully determined by the player's choices.
     This list was produced by TESTING each game, not by reading the code:
     each was run twice under the same seed and the resulting board compared.
     The four excluded games all draw timing entropy from performance.now(). */
  var ELIGIBLE = ['sortit', 'binornot', 'buildtheline', 'spot', 'loadcontainer', 'upgrade', 'zerowastecity'];

  /* Which game is this page? Derived from the filename so no game has to declare it. */
  var FILE_TO_GAME = {
    'lirich_sortit_game': 'sortit',
    'lirich_binornot_game': 'binornot',
    'lirich_buildtheline_game': 'buildtheline',
    'lirich_spotthecontaminant_game': 'spot',
    'lirich_loadthecontainer_game': 'loadcontainer',
    'lirich_upgradestream_game': 'upgrade',
    'lirich_zerowastecity_game': 'zerowastecity',
    'lirich_onroute_game': 'onroute',
    'lirich_pickline_game': 'pickline',
    'lirich_plantbuilder_game': 'plantbuilder',
    'lirich_dispatch_game': 'dispatch'
  };

  function currentGame() {
    var f = (root.location && root.location.pathname || '').split('/').pop().replace(/\.html?$/i, '').toLowerCase();
    return FILE_TO_GAME[f] || null;
  }

  function param(name) {
    try {
      var m = new RegExp('[?&]' + name + '=([^&#]*)').exec(root.location.search);
      return m ? decodeURIComponent(m[1]) : null;
    } catch (e) { return null; }
  }

  var state = { on: false, seed: null, game: null, cadence: null, reason: '' };

  function start() {
    var raw = param('challenge');
    if (!raw) { state.reason = 'not requested'; return state; }

    var game = currentGame();
    state.game = game;
    if (!game) { state.reason = 'unknown page'; return state; }

    if (ELIGIBLE.indexOf(game) === -1) {
      /* Refusing is the correct behaviour. A challenge on a real-time game would
         produce scores that look comparable and are not. */
      state.reason = 'this game runs in real time, so scores are not comparable';
      return state;
    }
    if (!root.LirichRNG) { state.reason = 'lirich-rng.js not loaded'; return state; }

    var cadence = (raw === 'day' || raw === 'daily') ? 'day'
                : (raw === 'week' || raw === 'weekly' || raw === '1' || raw === 'true') ? 'week'
                : 'fixed';
    state.cadence = cadence;
    state.seed = cadence === 'fixed'
      ? String(raw).replace(/[^A-Za-z0-9._\-]/g, '').slice(0, 40)
      : root.LirichRNG.challengeSeed(game, cadence);

    if (!state.seed) { state.reason = 'empty seed'; return state; }

    root.LirichRNG.install(state.seed);
    state.on = true;
    state.reason = '';
    return state;
  }

  /* ---- the banner ---------------------------------------------------------------
     Deliberately plain. No "win", no "lucky", no countdown, no prize language —
     s 7(6)(c) catches a game merely presented as involving chance, and the reverse
     discipline is what keeps this defensible.                                      */
  var CSS =
    '.lrc{position:fixed;left:0;right:0;top:0;z-index:9999;padding:7px 12px;text-align:center;' +
      'font:600 12.5px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif;letter-spacing:.01em;' +
      'background:#C9A227;color:#20160A}' +
    '.lrc.off{background:#5A6376;color:#fff;font-weight:500}' +
    '.lrc span{opacity:.8;font-weight:500}' +
    'body.lrc-pad{padding-top:30px}';

  function banner() {
    if (!root.document || !root.document.body) return;
    if (root.document.getElementById('lrc')) return;
    var st = root.document.createElement('style'); st.textContent = CSS;
    root.document.head.appendChild(st);
    var d = root.document.createElement('div');
    d.id = 'lrc';
    d.className = 'lrc' + (state.on ? '' : ' off');
    d.textContent = state.on
      ? 'Challenge board — everyone plays this same board this ' + (state.cadence === 'day' ? 'day' : 'week')
      : 'Challenge not available here — ' + state.reason;
    if (state.on) {
      var s = root.document.createElement('span');
      s.textContent = '  ·  ' + state.seed;
      d.appendChild(s);
    }
    root.document.body.appendChild(d);
    root.document.body.classList.add('lrc-pad');
  }

  /* Install as early as possible — before the game's own script runs. */
  start();

  if (param('challenge')) {
    if (root.document.readyState === 'loading') {
      root.document.addEventListener('DOMContentLoaded', banner);
    } else { banner(); }
  }

  root.LirichChallenge = {
    eligible: ELIGIBLE,
    isEligible: function (g) { return ELIGIBLE.indexOf(g) !== -1; },
    currentGame: currentGame,
    on: function () { return state.on; },
    seed: function () { return state.on ? state.seed : null; },
    cadence: function () { return state.cadence; },
    reason: function () { return state.reason; },
    state: function () { return state; },
    /* build the link the hub uses */
    url: function (file, cadence) { return file + '?challenge=' + (cadence || 'week'); }
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = root.LirichChallenge;

})(typeof window !== 'undefined' ? window : globalThis);
