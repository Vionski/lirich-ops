/* =====================================================================================
   LIRICH LEARN — SHARED SCORE LAYER
   One small module. Every game plugs into it. One backend table behind it.

   ⚠ CHANGED 21 Nov 2026 — PLAYERS AND SCHOOLS (Michelle: "player can compete with other
     players … schools competing with other schools with points"). The row is now:
       player       a GENERATED nickname, e.g. "Green Otter 42" — picked from fixed word
                    lists, never typed, so it cannot carry a real name or a rude word
       school       a code from lirich-schools.js (MOE list, chosen by the player), or null
       game         which game
       score        the game's own score (kg, or t for the city-scale games)
       points       the score on one shared 0–150 scale, so different games can be added
                    up for a school (POINTS below)
       week_key / month_key, seed, nonce — unchanged
     Backend: lirich-competition.sql (table learn_runs, views learn_board_players and
     learn_board_schools). The older team-label table in lirich-supabase.sql is left as
     it was and is no longer written to.
     ⚠ Michelle chose "pick your school from a list" over teacher codes (21 Nov 2026).
     That is easier for pupils, but anyone can pick any school, so a school board is a
     friendly ranking, not proof. A teacher-issued class code is the upgrade path if a
     competition with prizes is ever run (see also the prize note below).

   WHAT IT SENT BEFORE 21 Nov 2026 (kept for the record)
       team_code    a label the players choose, e.g. "4E TAMPINES" or "YARD CREW"
       game, kg, period_key, nonce

   WHAT IT NEVER SENDS
       No real names. No emails. No accounts. No logins. No ages. No class.
       No device identifiers. No analytics. No third-party calls of any kind.
       (A school is sent only if the player picks one, and a school is not a person.)

   WHY IT IS BUILT THIS WAY
       Minors' data is a hard boundary. The design that avoids the problem entirely is
       better than the design that manages it: a team code is a LABEL, not an account.
       Nobody can be identified from this table, so there is nothing to protect.
       Keep it that way. Adding a name field is not a small change — it changes what
       this file is, and it drags PDPA obligations in behind it.

   ⚠ NOT A PRIZE MECHANIC
       This ranks teams. It does not select winners by chance, and it must not be used
       to. Under the Gambling Control Act 2022 a prize distributed by chance at ANY
       stage is a lottery, including a random tie-break. If a competition is ever run
       off this leaderboard, read lirich-rng.js first — comparable scores need every
       team to play the identical board, which is what the seeded mode is for.

   LOADING
       Classic script, no modules, no build step, no dependencies — so the games keep
       working by double-clicking the HTML from a folder or a USB stick.
           <script src="lirich-scores.js"></script>
       Load it AFTER lirich-rules.js and BEFORE the game's own script.

   IF IT IS NOT CONFIGURED, OR THE NETWORK IS DOWN
       Everything still works. Scores queue locally and flush later. A game never
       breaks because a leaderboard is unreachable — in a school it usually is.
   ===================================================================================== */
"use strict";
(function (root) {

  /* ================================================================================
     CONFIG — the only block anyone needs to edit
     ================================================================================
     Fill these in from the Supabase project, then set enabled to true.
     The anon key is designed to be public. It is safe in a page BECAUSE the row-level
     security policy in lirich-supabase.sql only permits inserts that pass the column
     checks, and permits reads only through the aggregated view. Do not put the
     service_role key here, or anywhere near a browser.                             */
  var CONFIG = {
    enabled: false,
    url: '',                 // e.g. 'https://xxxxxxxx.supabase.co'
    anonKey: '',             // the anon / publishable key, never the service key
    table: 'learn_runs',                 // lirich-competition.sql (21 Nov 2026)
    view: 'learn_board_players',
    schoolView: 'learn_board_schools',
    timeoutMs: 6000          // a school's wifi is slow; fail fast and queue
  };

  /* ---- The games, and a sane ceiling for each ------------------------------------
     ⚠⚠ THREE games have now shipped with a cap below an ordinary score:
         Bin or Not?          50 kg      — one normal round exceeded it
         Upgrade the Stream   20,000 kg  — eight runs in twelve exceeded it
         Zero Waste City      5,000,000 t — EVERY run exceeded it, by about four times
     All three discarded real scores in silence, and all three were found by PLAYING, not
     by reading. The pattern is the same each time: a game whose unit accumulates faster
     than whoever set the cap expected. Any cap here without a measured playthrough behind
     it should be assumed wrong. tests/capaudit.mjs is the check.

     A cap is not security — it is a typo filter. Anything over the cap is almost
     certainly a bug or a tampered value, and it is better to reject it here than to
     have one absurd row sit at the top of a class leaderboard all term.
     These were set by PLAYING each game and multiplying the best observed run, not by
     guessing. Bin or Not? originally had a cap of 50 kg, which a single round carrying
     the old refrigerator exceeds — every such round was being silently discarded.
     If a cap is ever changed, play the game first.                                 */
  var GAMES = {
    sortit:        { name: 'Sort It!',             unit: 'kg', cap: 2000,    realtime: false, deterministic: true  },
    binornot:      { name: 'Bin or Not?',          unit: 'kg', cap: 1000,    realtime: false, deterministic: true  },
    /* added 21 Nov 2026. A perfect round keeps 0.33–1.65 kg from the bin depending on the
       deck (20,000 simulated perfect rounds); the cap is three times the best. Random
       deck, so not deterministic and not for a scored competition. */
    threer:        { name: 'Reduce, Reuse or Recycle?', unit: 'kg', cap: 5, realtime: false, deterministic: false },
    buildtheline:  { name: 'Build the Line',       unit: 'kg', cap: 5000,    realtime: false, deterministic: true  },
    spot:          { name: 'Spot the Contaminant', unit: 'kg', cap: 3000,    realtime: false, deterministic: true  },
    /* A weighed-out run stops at the 28 t payload plus whatever the last piece added —
       measured at 28,825 kg, which left the old 30,000 cap with almost no margin. */
    loadcontainer: { name: 'Load the Container',   unit: 'kg', cap: 50000,   realtime: false, deterministic: true  },
    /* ⚠ 20000 until 18 Sep 2026, and it was discarding two runs in three.
       A merge game accumulates: every merge adds the kilograms of the tier it produced,
       so reaching a single Container adds about 26 tonnes on its own and a Shipment run
       passes 100. Measured over twelve bot runs: median 35,629 kg, max 154,793 kg —
       eight of the twelve were over the old cap and were silently never sent.
       This is the SECOND game found with this fault. See tests/upgradebot.mjs. */
    upgrade:       { name: 'Upgrade the Stream',   unit: 'kg', cap: 1000000, realtime: false, deterministic: true  },
    /* ⚠ 5,000,000 until 18 Sep 2026, and EVERY run exceeded it. This game scores at city
       scale — a measured playthrough to 2038 diverted 21,377,301 tonnes, four times the
       old cap, so no Zero Waste City score had ever been sent. Third game found with this
       fault. See tests/citybot.mjs. */
    zerowastecity: { name: 'Zero Waste City',      unit: 't',  cap: 200000000, realtime: false, deterministic: true  },
    /* ⚠ real-time games. Reaction speed and the device's frame rate both affect the
       score, and frame rate is not skill. They are fine to play and fine to rank for
       fun — they must NOT carry a scored competition. See lirich-rng.js. */
    /* ⚠ 5,000 until 18 Sep 2026. A careful driver collects about 650 kg a MINUTE — an
       estimate made by reading the code had put it near 54, out by more than tenfold —
       so the old cap was about eight minutes of play, which a good player can reach.
       Raised to roughly an hour. Measured in tests/onroutebot.mjs. */
    onroute:       { name: 'On Route',             unit: 'kg', cap: 40000,   realtime: true,  deterministic: false },
    /* Measured at about 27 kg a minute of flawless picking, so this cap is roughly 110
       minutes. Left as it is. See tests/picklinebot.mjs. */
    pickline:      { name: 'Pick Line',            unit: 'kg', cap: 3000,    realtime: true,  deterministic: false },
    plantbuilder:  { name: 'Plant Builder',        unit: 't',  cap: 500000,  realtime: true,  deterministic: false },
    dispatch:      { name: 'Dispatch',             unit: 't',  cap: 200000,  realtime: true,  deterministic: false }
  };

  /* Only these games may carry a scored competition: the board is identical for
     everyone under a fixed seed, so the outcome turns on skill alone. */
  function competitionEligible() {
    return Object.keys(GAMES).filter(function (k) { return GAMES[k].deterministic && !GAMES[k].realtime; });
  }

  /* ---- Storage keys. Local only, and only ever these three. --------------------- */
  var K_TEAM = 'lirich.learn.team';
  var K_QUEUE = 'lirich.learn.queue';
  var K_LOCAL = 'lirich.learn.localbest';

  /* ---- localStorage, defensively ------------------------------------------------
     A school device may be locked down, in private mode, or have storage disabled.
     Every read and write is wrapped: the games must work regardless.              */
  function lsGet(k, fallback) {
    try { var v = root.localStorage.getItem(k); return v === null ? fallback : JSON.parse(v); }
    catch (e) { return fallback; }
  }
  function lsSet(k, v) {
    try { root.localStorage.setItem(k, JSON.stringify(v)); return true; } catch (e) { return false; }
  }

  /* ================================================================================
     TEAM CODE
     A label, chosen by the class or the crew. Not an account, no password, no
     uniqueness guarantee. Two classes may pick the same label; that is a social
     problem, not a technical one, and solving it would mean accounts.
     ================================================================================ */
  var TEAM_MIN = 3, TEAM_MAX = 24;

  /* Blocked because a public leaderboard in a school should not carry them, and
     because a team code that looks like a person's name defeats the purpose of not
     collecting names. This is a light filter, not moderation — see moderation note
     in lirich-supabase.sql. */
  var BLOCKED = /\b(fuck|shit|cunt|bitch|nigg|rape|kill yourself|kys)\b/i;

  function cleanTeam(raw) {
    var s = String(raw == null ? '' : raw).toUpperCase()
      .replace(/[^A-Z0-9 \-]/g, '')      // letters, digits, space, hyphen only
      .replace(/\s+/g, ' ')
      .trim();
    return s.slice(0, TEAM_MAX);
  }
  function validateTeam(raw) {
    var s = cleanTeam(raw);
    if (s.length < TEAM_MIN) return { ok: false, value: s, why: 'Use at least ' + TEAM_MIN + ' characters.' };
    if (BLOCKED.test(s))     return { ok: false, value: s, why: 'Please choose a different name.' };
    if (/^\d+$/.test(s))     return { ok: false, value: s, why: 'Add a word, not only numbers.' };
    return { ok: true, value: s, why: '' };
  }
  function getTeam() { var t = lsGet(K_TEAM, ''); return typeof t === 'string' ? t : ''; }
  function setTeam(raw) {
    var v = validateTeam(raw);
    if (v.ok) lsSet(K_TEAM, v.value);
    return v;
  }
  function clearTeam() { lsSet(K_TEAM, ''); }

  /* ================================================================================
     PLAYER — a generated nickname and an optional school (21 Nov 2026)
     The nickname is built from these lists only. Nothing is typed, so nothing personal
     or rude can reach the board. Word lists: Singapore nature and plain colours; every
     word checked by hand. 30 x 30 x 90 = 81,000 combinations, so two players sharing a
     name is possible and harmless — the board ranks names, it does not identify anyone.
     ================================================================================ */
  var K_PLAYER = 'lirich.learn.player';
  var NICK_A = ['Green','Blue','Golden','Silver','Swift','Clever','Brave','Bright','Calm','Busy',
                'Lucky','Happy','Sunny','Mighty','Quick','Gentle','Bold','Keen','Jolly','Steady',
                'Sparkly','Leafy','Rainy','Breezy','Starry','Cosy','Tidy','Zippy','Plucky','Merry'];
  var NICK_B = ['Otter','Hornbill','Pangolin','Kingfisher','Turtle','Heron','Gecko','Squirrel','Dolphin','Orchid',
                'Mangrove','Seahorse','Firefly','Sparrow','Egret','Myna','Bulbul','Tamarind','Durian','Rambutan',
                'Banyan','Coral','Starfish','Crab','Butterfly','Dragonfly','Lotus','Frangipani','Tembusu','Mudskipper'];
  var NICK_RE = /^[A-Z][a-z]+ [A-Z][a-z]+ [1-9][0-9]$/;
  function pick(a) { return a[Math.floor(rand() * a.length)]; }
  function rand() {
    try { var u = new Uint32Array(1); root.crypto.getRandomValues(u); return u[0] / 4294967296; }
    catch (e) { return Math.random(); }
  }
  function newNick() { return pick(NICK_A) + ' ' + pick(NICK_B) + ' ' + (10 + Math.floor(rand() * 90)); }
  function validNick(n) {
    if (!NICK_RE.test(String(n || ''))) return false;
    var p = String(n).split(' ');
    return NICK_A.indexOf(p[0]) >= 0 && NICK_B.indexOf(p[1]) >= 0;
  }
  function schoolOk(code) { return code == null || code === '' || !!(root.LirichSchools && root.LirichSchools.get(code)); }
  function getPlayer() {
    var p = lsGet(K_PLAYER, null);
    return p && validNick(p.nick) && schoolOk(p.school) ? { nick: p.nick, school: p.school || null } : null;
  }
  function setPlayer(nick, school) {
    if (!validNick(nick)) return { ok: false, why: 'That name is not from the name list.' };
    if (!schoolOk(school)) return { ok: false, why: 'Choose your school from the list.' };
    lsSet(K_PLAYER, { nick: nick, school: school || null });
    return { ok: true, why: '' };
  }
  function clearPlayer() { lsSet(K_PLAYER, null); }
  function schoolName(code) { var s = code && root.LirichSchools && root.LirichSchools.get(code); return s ? s.name : ''; }

  /* POINTS — one scale for every game, so a school's total means something.
     The games score in very different units (Sort It! in kg, Zero Waste City in millions
     of tonnes), so adding raw scores would let one city run outweigh a term of sorting.
     points = 100 x score / REF, capped at 150. REF is about two-thirds of the best run
     MEASURED for each game (tests/capaudit.mjs table, 21 Nov 2026), so a good run is about
     100 and a perfect one about 150:
         sortit 650 kg best -> 450      binornot 8 kg -> 5.5        buildtheline 960 -> 650
         threer: a perfect round's median 0.975 kg (simulated decks) -> 0.65
         spot 192 -> 130                loadcontainer 28,825 -> 20,000
         upgrade median 35,629 -> 35,000 (best 154,793 hits the cap)
         zerowastecity measured playthrough 21.4 Mt -> 21,000,000 t
         plantbuilder 200,100 t at the last milestone -> 130,000
         dispatch 108.5 t a plain week, 140 t "a good week" on its end card -> 100
         onroute ~650 kg a minute -> 2,000 (about 3 good minutes); endless, so the cap of
         150 a run is what stops one very long round outweighing everything
         pickline ~27 kg a minute flawless -> 50 (about 2 good minutes), endless likewise
     If a game changes, re-measure its best run and move its REF with it.          */
  var REF = {
    sortit: 450, binornot: 5.5, threer: 0.65, buildtheline: 650, spot: 130, loadcontainer: 20000, upgrade: 35000,
    zerowastecity: 21000000, onroute: 2000, pickline: 50, plantbuilder: 130000, dispatch: 100
  };
  var POINTS_MAX = 150;
  function points(game, score) {
    var r = REF[game]; score = Number(score);
    if (!r || !isFinite(score) || score <= 0) return 0;
    return Math.max(1, Math.min(POINTS_MAX, Math.round(100 * score / r)));
  }

  /* ================================================================================
     PERIOD KEYS
     Scores belong to a week and a month so a leaderboard can reset without deleting
     anything. ISO week, computed locally — no library, no timezone service.
     ================================================================================ */
  function isoWeek(d) {
    var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    var day = t.getUTCDay() || 7;
    t.setUTCDate(t.getUTCDate() + 4 - day);
    var y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
    return { year: t.getUTCFullYear(), week: Math.ceil((((t - y0) / 86400000) + 1) / 7) };
  }
  function weekKey(d) { d = d || new Date(); var w = isoWeek(d); return w.year + '-W' + String(w.week).padStart(2, '0'); }
  function monthKey(d) { d = d || new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0'); }

  /* ================================================================================
     LOCAL PERSONAL BEST
     Works with no backend at all, and is what most players actually care about.
     ================================================================================ */
  function localBest(game) { var m = lsGet(K_LOCAL, {}); return (m && m[game]) || 0; }
  function setLocalBest(game, kg) {
    var m = lsGet(K_LOCAL, {}) || {};
    if (!(kg > (m[game] || 0))) return false;
    m[game] = kg; lsSet(K_LOCAL, m); return true;
  }

  /* ================================================================================
     THE QUEUE
     Offline-first. A score is written locally the instant it happens, then sent.
     Nothing is ever lost because the wifi dropped, and nothing blocks the game.
     ================================================================================ */
  var MAX_QUEUE = 200;
  function queue() { var q = lsGet(K_QUEUE, []); return Array.isArray(q) ? q : []; }
  function pushQueue(row) {
    var q = queue(); q.push(row);
    if (q.length > MAX_QUEUE) q = q.slice(q.length - MAX_QUEUE);
    lsSet(K_QUEUE, q); return q.length;
  }
  function setQueue(q) { lsSet(K_QUEUE, q.slice(0, MAX_QUEUE)); }

  function nonce() {
    try {
      var a = new Uint8Array(12); root.crypto.getRandomValues(a);
      return Array.from(a).map(function (b) { return b.toString(16).padStart(2, '0'); }).join('');
    } catch (e) {
      return String(Date.now()) + Math.random().toString(16).slice(2, 10);
    }
  }

  /* ================================================================================
     SENDING
     Plain fetch against PostgREST. No SDK, no bundle, no third-party script.
     ================================================================================ */
  function configured() { return !!(CONFIG.enabled && CONFIG.url && CONFIG.anonKey); }

  /* ---- configure() — set the backend without editing this file --------------------
     Added because the leaderboard could previously ONLY be configured by editing the
     CONFIG block above, which meant the network path could not be exercised until it
     was switched on for real. A thing that cannot be tested before it goes live gets
     tested by the first class that uses it.

     Hosting uses it too: the same folder can be pointed at a staging project and a
     live one without two copies of the file.

     It changes nothing about what is sent. There is no field here for a name, an
     account or an identifier, and there must not be. */
  function configure(next) {
    if (!next || typeof next !== 'object') return summary();
    ['enabled','url','anonKey','table','view','schoolView','timeoutMs'].forEach(function (k) {
      if (Object.prototype.hasOwnProperty.call(next, k)) CONFIG[k] = next[k];
    });
    return summary();
  }
  /* What state is this in? Deliberately never returns the key itself. */
  function summary() {
    return { enabled: !!CONFIG.enabled, configured: configured(),
             url: CONFIG.url ? String(CONFIG.url).replace(/^(https?:\/\/[^/]{0,12}).*$/, '$1…') : '',
             hasKey: !!CONFIG.anonKey, table: CONFIG.table, view: CONFIG.view,
             queued: queue().length };
  }
  /* How many rows are waiting to be sent. Used by the tests, and useful in a console. */
  function queued() { return queue().length; }

  function postRows(rows) {
    if (!configured()) return Promise.reject(new Error('not-configured'));
    var ctrl = typeof AbortController !== 'undefined' ? new AbortController() : null;
    var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, CONFIG.timeoutMs) : null;
    return fetch(CONFIG.url.replace(/\/+$/, '') + '/rest/v1/' + CONFIG.table, {
      method: 'POST',
      headers: {
        'apikey': CONFIG.anonKey,
        'Authorization': 'Bearer ' + CONFIG.anonKey,
        'Content-Type': 'application/json',
        /* return=minimal is NOT cosmetic. Anything else makes PostgREST add a RETURNING
           clause, and RETURNING needs SELECT rights the anon role deliberately does not
           have — every insert would fail with 'permission denied for table'. */
        'Prefer': 'return=minimal'
      },
      body: JSON.stringify(rows),
      signal: ctrl ? ctrl.signal : undefined
    }).then(function (res) {
      if (timer) clearTimeout(timer);
      /* 409 means a nonce is already in the table: the row landed on an earlier attempt
         and the acknowledgement was lost. Treat it as delivered — otherwise a dropped
         connection mid-flush jams the queue permanently, which is exactly the failure a
         school's wifi produces. */
      if (res.status === 409) return true;
      if (!res.ok) throw new Error('http-' + res.status);
      return true;
    }, function (e) { if (timer) clearTimeout(timer); throw e; });
  }

  /* Send everything queued. Safe to call often — it no-ops when there is nothing to do. */
  var flushing = false;
  function flush() {
    if (flushing || !configured()) return Promise.resolve(0);
    var q = queue();
    if (!q.length) return Promise.resolve(0);
    flushing = true;
    var batch = q.slice(0, 25);
    return postRows(batch).then(function () {
      setQueue(queue().slice(batch.length));
      flushing = false;
      return batch.length;
    }, function () { flushing = false; return 0; });
  }

  /* ================================================================================
     RECORD — the one call a game makes
       LirichScores.record('sortit', kgDiverted)
     Returns { accepted, queued, personalBest, reason }.
     Never throws. Never blocks. Never breaks the game.
     ================================================================================ */
  function record(game, kg, opts) {
    opts = opts || {};
    var out = { accepted: false, queued: false, personalBest: false, reason: '' };
    var g = GAMES[game];
    if (!g) { out.reason = 'unknown-game'; return out; }

    kg = Number(kg);
    if (!isFinite(kg) || kg < 0) { out.reason = 'bad-score'; return out; }
    kg = Math.round(kg * 1000) / 1000;
    if (kg > g.cap) { out.reason = 'over-cap'; return out; }   /* typo filter, see GAMES */
    if (kg === 0)   { out.reason = 'zero'; return out; }

    out.personalBest = setLocalBest(game, kg);
    out.accepted = true;

    out.points = points(game, kg);
    /* A board-off beta should feel private, not like an unfinished registration flow.
       The join prompt only appears once a real board is configured. */
    var pl = configured() ? getPlayer() : null;
    if (!pl) { out.reason = 'not-joined'; return out; }        /* played solo — nothing to send */

    var now = new Date();
    pushQueue({
      player: pl.nick,
      school: pl.school,
      game: game,
      score: kg,
      points: out.points,
      week_key: weekKey(now),
      month_key: monthKey(now),
      /* Seed is recorded automatically when the run was on a challenge board. Only
         rows with a seed are comparable between teams — a competition must filter on it. */
      seed: opts.seed || (root.LirichChallenge && root.LirichChallenge.seed()) || null,
      nonce: nonce()
    });
    out.queued = true;
    flush();
    return out;
  }

  /* ================================================================================
     READING THE LEADERBOARD
     Reads the aggregated VIEWS, never the raw table. They expose a nickname, a school,
     period and a total — and nothing that could identify anyone.
     ================================================================================ */
  /* top(kind, period, limit)
       kind 'players' -> rows {player, school, period_key, points, runs}
       kind 'schools' -> rows {school, period_key, points, players, runs}
     (Before 21 Nov 2026 the first argument was a game; game-by-game team boards went with
     the team table. A string that is not 'schools' is read as 'players'.) */
  function top(kind, period, limit) {
    if (!configured()) return Promise.resolve({ ok: false, reason: 'not-configured', rows: [] });
    var schools = kind === 'schools';
    period = period || weekKey();
    limit = Math.min(Math.max(parseInt(limit || 20, 10), 1), 100);
    var qs = '?select=' + (schools ? 'school,period_key,points,players,runs' : 'player,school,period_key,points,runs') +
             '&period_key=eq.' + encodeURIComponent(period) +
             '&order=points.desc&limit=' + limit;
    var ctrl = typeof AbortController !== 'undefined' ? new AbortController() : null;
    var timer = ctrl ? setTimeout(function () { ctrl.abort(); }, CONFIG.timeoutMs) : null;
    return fetch(CONFIG.url.replace(/\/+$/, '') + '/rest/v1/' + (schools ? CONFIG.schoolView : CONFIG.view) + qs, {
      headers: { 'apikey': CONFIG.anonKey, 'Authorization': 'Bearer ' + CONFIG.anonKey },
      signal: ctrl ? ctrl.signal : undefined
    }).then(function (r) {
      if (timer) clearTimeout(timer);
      if (!r.ok) throw new Error('http-' + r.status);
      return r.json();
    }).then(function (rows) { return { ok: true, reason: '', rows: rows || [] }; })
      .catch(function (e) { if (timer) clearTimeout(timer); return { ok: false, reason: String(e.message || e), rows: [] }; });
  }

  /* ================================================================================
     THE END-OF-GAME PANEL
     One call mounts a consistent block into any game's end overlay: personal best,
     team, and an honest status line. Identical in all eleven games, defined once.
     ================================================================================ */
  var CSS = [
    '.lrs{margin:14px 0 2px;padding:12px 14px;border-radius:10px;background:rgba(43,59,85,.06);',
      'font:13px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif;color:#2B3B55;text-align:left}',
    '.lrs b{font-weight:650}',
    '.lrs-row{display:flex;justify-content:space-between;gap:12px;align-items:baseline}',
    '.lrs-row+.lrs-row{margin-top:5px}',
    '.lrs-pb{color:#1F7A4D;font-weight:650}',
    '.lrs-muted{color:#5E6B82}',
    '.lrs-team{display:flex;gap:8px;margin-top:9px;flex-wrap:wrap}',
    '.lrs-team input{flex:1 1 130px;min-width:0;font:inherit;padding:7px 9px;border:1px solid #B9C4D4;',
      'border-radius:8px;background:#fff;color:inherit;text-transform:uppercase}',
    '.lrs-team button{font:inherit;font-weight:600;padding:7px 13px;border:0;border-radius:8px;',
      'background:#2B3B55;color:#fff;cursor:pointer}',
    '.lrs-team button:disabled{opacity:.45;cursor:default}',
    '.lrs-team input#lrsS{text-transform:none}',
    '.lrs-why{color:#A8324A;margin-top:6px}',
    '.lrs-link{font:inherit;font-size:12px;font-weight:700;background:none;border:0;color:#2B5BA8;text-decoration:underline;cursor:pointer;padding:0 0 0 6px}',
    '.lrs-join{margin-top:8px;padding-top:8px;border-top:1px solid rgba(43,59,85,.15)}',
    '.lrs-sug{display:flex;flex-direction:column;margin-top:4px;border:1px solid #B9C4D4;border-radius:8px;overflow:hidden;background:#fff}',
    '.lrs-sug button{font:inherit;text-align:left;padding:8px 10px;border:0;border-top:1px solid #E6EAF2;background:#fff;color:#2B3B55;cursor:pointer}',
    '.lrs-sug button:first-child{border-top:0}.lrs-sug button:hover,.lrs-sug button:focus-visible{background:#F1F4FA}',
    '@media (prefers-color-scheme:dark){.lrs{background:rgba(255,255,255,.07);color:#E7EDF6}',
      '.lrs-muted{color:#A9B6CC}.lrs-team input{background:#1B2537;border-color:#3A4A63;color:#E7EDF6}}'
  ].join('');

  function injectCss() {
    if (root.document.getElementById('lrs-css')) return;
    var s = root.document.createElement('style');
    s.id = 'lrs-css';
    s.textContent = CSS;
    root.document.head.appendChild(s);
  }

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  /* mount(container, game, kg, result) — container is any element, usually the end overlay */
  function mount(container, game, kg, result) {
    if (!container) return null;
    injectCss();
    var wrap = container.querySelector('.lrs');
    if (!wrap) { wrap = root.document.createElement('div'); wrap.className = 'lrs'; container.appendChild(wrap); }

    var g = GAMES[game] || { name: game };
    var pb = localBest(game);
    var pl = getPlayer();

    function status() {
      if (!result) return '';
      if (!configured()) return 'Saved on this device. The leaderboard is off for this beta.';
      if (result.reason === 'not-joined') return 'Join the leaderboard to put this run on it.';
      if (result.queued) return queue().length > 1
        ? 'Saved. ' + queue().length + ' results waiting to send.'
        : 'Sent to the leaderboard.';
      if (result.reason === 'over-cap') return 'That score looks wrong, so it was not sent.';
      return '';
    }

    var html = '';
    var U = g.unit || 'kg';
    html += '<div class="lrs-row"><span>This run</span><span><b>' + (Math.round(kg * 100) / 100) + ' ' + U + '</b></span></div>';
    html += '<div class="lrs-row"><span class="lrs-muted">Your best on this device</span><span class="' +
            (result && result.personalBest ? 'lrs-pb' : 'lrs-muted') + '">' +
            (Math.round(pb * 100) / 100) + ' ' + U + (result && result.personalBest ? ' — new best' : '') + '</span></div>';
    if (configured() && result && result.points) {
      html += '<div class="lrs-row"><span class="lrs-muted">Leaderboard points</span><span><b>+' + result.points + '</b></span></div>';
    }
    if (pl) {
      html += '<div class="lrs-row"><span class="lrs-muted">Playing as</span><span><b>' + esc(pl.nick) + '</b>' +
              (pl.school ? '<br><span class="lrs-muted">' + esc(schoolName(pl.school)) + '</span>' : '') + '</span></div>';
    }
    var st = status();
    if (st) html += '<div class="lrs-row"><span class="lrs-muted">' + esc(st) + '</span></div>';
    var nick = newNick();
    if (configured() && !pl) {
      html += '<div class="lrs-join">' +
              '<div class="lrs-row"><span class="lrs-muted">Your leaderboard name</span>' +
              '<span><b id="lrsN">' + esc(nick) + '</b> <button id="lrsR" type="button" class="lrs-link">New name</button></span></div>' +
              '<div class="lrs-team"><input id="lrsS" autocomplete="off" placeholder="Your school (optional)" aria-label="Your school">' +
              '<button id="lrsB" type="button">Join</button></div>' +
              '<div class="lrs-sug" id="lrsL" role="listbox" hidden></div>' +
              '<div class="lrs-why" id="lrsW" hidden></div>' +
              '<div class="lrs-row" style="margin-top:7px"><span class="lrs-muted">' +
              'A made-up name and your school. No real names, no sign-up, nothing personal.</span></div></div>';
    }
    wrap.innerHTML = html;

    var inp = wrap.querySelector('#lrsS');
    if (inp) {
      var chosen = null;
      var btn = wrap.querySelector('#lrsB'), why = wrap.querySelector('#lrsW'), sug = wrap.querySelector('#lrsL');
      wrap.querySelector('#lrsR').onclick = function () { nick = newNick(); wrap.querySelector('#lrsN').textContent = nick; };
      inp.addEventListener('input', function () {
        chosen = null;
        var hits = root.LirichSchools ? root.LirichSchools.search(inp.value, 6) : [];
        sug.innerHTML = hits.map(function (h) { return '<button type="button" role="option" data-c="' + esc(h.code) + '">' + esc(h.name) + '</button>'; }).join('');
        sug.hidden = !hits.length;
      });
      sug.addEventListener('click', function (e) {
        var o = e.target.closest('button'); if (!o) return;
        chosen = o.getAttribute('data-c'); inp.value = schoolName(chosen); sug.hidden = true;
      });
      var save = function () {
        if (inp.value.trim() && !chosen) { why.textContent = 'Choose your school from the list, or leave it empty.'; why.hidden = false; return; }
        var v = setPlayer(nick, chosen);
        if (!v.ok) { why.textContent = v.why; why.hidden = false; return; }
        why.hidden = true;
        /* re-record so this run counts now that there is a player to attach it to */
        var again = record(game, kg);
        mount(container, game, kg, again);
      };
      btn.onclick = save;
      inp.addEventListener('keydown', function (e) { if (e.key === 'Enter') save(); });
    }
    return wrap;
  }

  /* record + mount in one call — what a game's end function actually uses */
  function finish(game, kg, container, opts) {
    var r = record(game, kg, opts);
    try { mount(container, game, kg, r); } catch (e) { /* a broken panel must not break a game */ }
    return r;
  }

  /* ---- flush opportunistically -------------------------------------------------- */
  if (typeof root.addEventListener === 'function') {
    root.addEventListener('load', function () { setTimeout(flush, 1200); });
    root.addEventListener('online', function () { setTimeout(flush, 400); });
  }

  root.LirichScores = {
    config: CONFIG, games: GAMES,
    getTeam: getTeam, setTeam: setTeam, clearTeam: clearTeam, validateTeam: validateTeam, cleanTeam: cleanTeam,
    getPlayer: getPlayer, setPlayer: setPlayer, clearPlayer: clearPlayer, newNick: newNick, validNick: validNick,
    schoolName: schoolName, points: points, pointsRef: REF, pointsMax: POINTS_MAX,
    record: record, finish: finish, mount: mount,
    top: top, flush: flush, queue: queue, competitionEligible: competitionEligible,
    localBest: localBest, weekKey: weekKey, monthKey: monthKey, configured: configured,
    configure: configure, status: summary, queued: queued,
    /* run in the console to check the module without a backend */
    selfTest: function () {
      var errs = [];
      if (!validateTeam('4E TAMPINES').ok) errs.push('valid team rejected');
      if (validateTeam('ab').ok) errs.push('too-short team accepted');
      if (validateTeam('12345').ok) errs.push('numeric-only team accepted');
      if (cleanTeam('  4e  <b>tampines</b> ') !== '4E BTAMPINESB') {
        /* tags are stripped to letters, which is the point — record what it does produce */
        if (/[<>]/.test(cleanTeam('<b>x</b>'))) errs.push('markup survived cleaning');
      }
      if (record('nope', 5).accepted) errs.push('unknown game accepted');
      if (record('sortit', -1).accepted) errs.push('negative score accepted');
      if (record('sortit', 1e9).accepted) errs.push('absurd score accepted');
      if (!/^\d{4}-W\d{2}$/.test(weekKey())) errs.push('bad week key');
      if (!/^\d{4}-\d{2}$/.test(monthKey())) errs.push('bad month key');
      return errs;
    }
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = root.LirichScores;

})(typeof window !== 'undefined' ? window : globalThis);
