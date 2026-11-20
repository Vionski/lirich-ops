/* =====================================================================================
   LIRICH LEARN — SEEDED RANDOMNESS
   Turns any of the eleven games into a game everyone plays identically.

   WHY THIS EXISTS, AND IT IS NOT A GAMEPLAY REASON
   -----------------------------------------------------------------------------------
   Singapore's Gambling Control Act 2022 does not use a "mostly skill" test. Section
   7(6) says a "game of chance" INCLUDES:

       "(a) a game that involves both an element of chance and an element of skill;
        (b) a game that involves an element of chance that can be eliminated by
            superlative skill;
        (c) a game that is presented as involving an element of chance"

   So any random element contaminates the whole thing. And s 9(1)(b) says a
   distribution of prizes is a lottery where it depends "at any stage" on chance,
   "even if the arrangement ... involves a genuine or purported exercise of skill".

   Every one of these games randomises. Sort It! seeds its board randomly. Pick Line
   spawns randomly. On Route randomises lanes. Bin or Not? shuffles its deck. As
   built, they are games of chance, and any prize attached to a score from them
   would be a prize distributed by chance.

   FIXING THE SEED FIXES THAT. When every player in a challenge gets the identical
   board in the identical order, the outcome turns on skill alone. Two players who
   play the same board and score differently did so because one played better.

   ⚠ WHAT THIS FILE DOES NOT DO
   It does not make a competition lawful on its own. Section 9(4) also requires the
   skill element to be hard enough to actually filter people out — both at the entry
   stage and at the winning stage. And a random TIE-BREAK re-introduces chance and
   undoes everything. Ties must break on an earlier timestamp or a further skill
   criterion. Never on a draw. Counsel signs this off, not this comment.

   Also: s 7(6)(c) catches a game merely PRESENTED as involving chance. If a
   challenge runs off this, the wording around it must not say "lucky", "draw",
   "spin" or "win"; and no dice, cards or wheel imagery anywhere near it.

   LOADING
       <script src="lirich-rng.js"></script>
   before the game's own script. Classic script, no modules — so the games keep
   working from a folder or a USB stick.
   ===================================================================================== */
"use strict";
(function (root) {

  /* ================================================================================
     THE GENERATOR
     mulberry32. Small, fast, well-distributed, and identical on every browser and
     every device — which is the whole requirement. Math.random() is not specified
     to be reproducible; this is.
     ================================================================================ */
  function mulberry32(a) {
    return function () {
      a |= 0; a = (a + 0x6D2B79F5) | 0;
      var t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  /* FNV-1a — turns a seed string into the 32-bit integer the generator needs.
     Deterministic across browsers, unlike anything involving hashCode or JSON order. */
  function hash32(str) {
    var h = 2166136261 >>> 0;
    str = String(str);
    for (var i = 0; i < str.length; i++) {
      h ^= str.charCodeAt(i);
      h = Math.imul(h, 16777619) >>> 0;
    }
    return h >>> 0;
  }

  /* A generator from any seed string. Same string in, same sequence out, always. */
  function from(seed) { return mulberry32(hash32(seed)); }

  /* ================================================================================
     CHALLENGE SEEDS
     A seed string anyone can reproduce and nobody can choose. Derived from the
     period and the game, so:
       - every team in a week plays the identical board
       - the board changes when the week does
       - nobody can fish for an easy seed, because they do not pick it
     ================================================================================ */
  function isoWeek(d) {
    var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    var day = t.getUTCDay() || 7;
    t.setUTCDate(t.getUTCDate() + 4 - day);
    var y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
    return { year: t.getUTCFullYear(), week: Math.ceil((((t - y0) / 86400000) + 1) / 7) };
  }
  function weekKey(d) { d = d || new Date(); var w = isoWeek(d); return w.year + '-W' + String(w.week).padStart(2, '0'); }
  function dayKey(d) {
    d = d || new Date();
    return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
  }

  /* challengeSeed('sortit')            -> this week's seed for Sort It!
     challengeSeed('binornot','day')    -> today's seed for Bin or Not?
     The string is short, printable and safe for the seed column in the scores table. */
  function challengeSeed(game, cadence, when) {
    var period = (cadence === 'day') ? dayKey(when) : weekKey(when);
    return String(game || 'all') + '.' + period;
  }

  /* ================================================================================
     INSTALL — the part that makes this usable on games already written
     ================================================================================
     Replaces Math.random for the page with a seeded generator. Every existing call
     inside a game then becomes reproducible with no change to the game's own code.

     This is deliberate and it is reversible. It is the difference between
     "retrofit determinism into eleven games" being an afternoon and being a rewrite.

     ⚠ Two honest caveats.
     1. It only covers Math.random. A game using crypto.getRandomValues, Date.now as
        an entropy source, or performance.now for spawn timing is NOT made
        deterministic by this. Check each game before running a competition on it —
        see verifyDeterminism() below, which tests rather than assumes.
     2. It is page-wide while installed. Nothing else on the page should be relying
        on unpredictable randomness at the time. In these games nothing does.
  */
  var _saved = null, _gen = null, _seed = null, _calls = 0;

  function install(seed) {
    if (_saved) restore();
    _seed = String(seed);
    _gen = from(_seed);
    _calls = 0;
    _saved = Math.random;
    Math.random = function () { _calls++; return _gen(); };
    return _seed;
  }

  function restore() {
    if (_saved) { Math.random = _saved; _saved = null; }
    _gen = null; _seed = null;
    return true;
  }

  function active() { return !!_saved; }
  function seed() { return _seed; }
  function calls() { return _calls; }

  /* Reset the sequence without reinstalling — for a "retry the same board" button. */
  function reset() {
    if (!_saved) return false;
    _gen = from(_seed); _calls = 0; return true;
  }

  /* ================================================================================
     VERIFY — do not assume a game is deterministic, prove it
     ================================================================================
     Runs fn twice under the same seed and compares what it produced. Use it in a
     console, or in a test page, before a game is ever used for a competition.

       LirichRNG.verifyDeterminism('sortit.2026-W38', function () {
         // set up a board and return something that describes it
         return JSON.stringify(boardState());
       });

     A FALSE result means that game draws entropy from somewhere this file does not
     cover, and it must not be used for a scored competition until that is found.  */
  function verifyDeterminism(seedStr, fn) {
    install(seedStr); var a;
    try { a = fn(); } finally { restore(); }
    install(seedStr); var b;
    try { b = fn(); } finally { restore(); }
    return { deterministic: a === b, first: a, second: b };
  }

  /* ================================================================================
     SMALL HELPERS
     Games that want an explicit generator rather than the global override.
     ================================================================================ */
  function shuffleWith(gen, arr) {
    var b = arr.slice();
    for (var i = b.length - 1; i > 0; i--) {
      var j = Math.floor(gen() * (i + 1));
      var t = b[i]; b[i] = b[j]; b[j] = t;
    }
    return b;
  }
  function intWith(gen, min, max) { return min + Math.floor(gen() * (max - min + 1)); }
  function pickWith(gen, arr) { return arr[Math.floor(gen() * arr.length)]; }

  root.LirichRNG = {
    from: from, hash32: hash32,
    challengeSeed: challengeSeed, weekKey: weekKey, dayKey: dayKey,
    install: install, restore: restore, reset: reset,
    active: active, seed: seed, calls: calls,
    verifyDeterminism: verifyDeterminism,
    shuffleWith: shuffleWith, intWith: intWith, pickWith: pickWith,

    selfTest: function () {
      var errs = [];
      var a = from('x'), b = from('x'), c = from('y');
      var sa = [a(), a(), a()].join(','), sb = [b(), b(), b()].join(','), sc = [c(), c(), c()].join(',');
      if (sa !== sb) errs.push('same seed produced different sequences');
      if (sa === sc) errs.push('different seeds produced the same sequence');

      var g = from('dist'), n = 60000, buckets = [0, 0, 0, 0, 0], v;
      for (var i = 0; i < n; i++) { v = g(); if (v < 0 || v >= 1) { errs.push('value out of [0,1)'); break; }
        buckets[Math.floor(v * 5)]++; }
      buckets.forEach(function (x) { if (Math.abs(x - n / 5) > n / 5 * 0.06) errs.push('distribution skewed: ' + buckets.join('/')); });

      install('seedcheck');
      var r1 = [Math.random(), Math.random()].join(',');
      reset();
      var r2 = [Math.random(), Math.random()].join(',');
      restore();
      if (r1 !== r2) errs.push('reset did not reproduce the sequence');
      if (active()) errs.push('restore left the override in place');

      var vd = verifyDeterminism('vd', function () { return [Math.random(), Math.random()].join(','); });
      if (!vd.deterministic) errs.push('verifyDeterminism failed on a trivially deterministic function');

      if (challengeSeed('sortit') !== 'sortit.' + weekKey()) errs.push('challengeSeed shape wrong');
      if (hash32('a') === hash32('b')) errs.push('hash collision on trivial input');
      return errs;
    }
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = root.LirichRNG;

})(typeof window !== 'undefined' ? window : globalThis);
