/* =====================================================================================
   lirich-wallet.js — credits, Continue and the shop. Added 21 Nov 2026.
   Load AFTER lirich-learn.js (the balance lives in its store, under the same one key).

   WHAT A CREDIT DOES
     - One Continue costs 3 credits and buys exactly what the offer says (5 more moves,
       20 more seconds, one more chance). Nothing is random. There are no loot boxes,
       no mystery rewards, no timers that drain while the app is closed.
     - One Continue per level or round, so a credit buys a second chance, not a win.

   HOW CREDITS ARE EARNED (free, by learning — lirich-learn.js)
     - 5 welcome credits · +1 per star earned for the first time on a level
     - +2 for answering Today's item correctly, +1 for answering it at all
     - +5 at every 7-day streak

   ⚠⚠ GRANT EDITION (default, 21 Nov 2026): CONFIG.sellCredits = false
     Michelle asked for the app to align with the grants. The research (21 Nov 2026):
       - SG Eco Fund (MSE, best fit): "main objective … should not be commercial or
         profit-making"; selling products/services is listed as ineligible.
       - NEA Partnership Fund: must "not generate net profits"; excludes
         "commercialisation costs (e.g. mobile applications)".
       - NEA 3R Fund: needs >= 100 t actually reduced/recycled — the app alone cannot
         qualify; only as the engagement layer of a measured school collection programme.
     So the grant-funded school edition has NO prices and NO buy buttons: credits are
     earned free by learning and spent on Continue. The pack code below stays, behind
     sellCredits, for a separately funded commercial edition. Do not switch it on in a
     build that a grant pays for.

   BUYING CREDITS — ONLY WHEN sellCredits IS TRUE, AND STILL NOT SWITCHED ON
     The shop lists the packs Michelle set (21 Nov 2026): 20 for S$0.99, 75 for S$2.99,
     150 for S$4.99. Every buy button sits behind a grown-up check (a multiplication a
     P4 pupil is unlikely to do on the spot, typed, two tries). After the check the shop
     says plainly that buying is coming soon and NO payment is taken.
     ⚠ Before payments are switched on, three things must exist, and none is in this file:
       1. a payment provider account in Lirich's name (e.g. Stripe / PayNow),
       2. a server-side credit ledger — a balance on the device can be edited by anyone,
          which is fine for earned credits and NOT fine for paid ones,
       3. a decision on accounts / parental consent for under-18 buyers (PDPA).
     CONFIG.payments stays false until then.

   PUBLIC API
     LirichWallet.offerContinue({ title, what, cost, use, decline })
         Shows the Continue offer. use() runs only if the credits were spent; decline()
         runs if the player ends the round. Exactly one of the two runs, once.
     LirichWallet.openShop(onClose)
     LirichWallet.chip()            -> an element showing the live balance
     LirichWallet.config            -> { payments, continueCost, packs }
   ===================================================================================== */
(function (root) {
  'use strict';
  var L = function () { return root.LirichLearn; };

  var CONFIG = {
    sellCredits: false,   // grant edition: earn-only. See the note above before changing.
    payments: false,
    continueCost: 3,
    currency: 'S$',
    packs: [
      { id: 'p20',  credits: 20,  price: 0.99, label: 'Handful' },
      { id: 'p75',  credits: 75,  price: 2.99, label: 'Bag',   tag: 'Popular' },
      { id: 'p150', credits: 150, price: 4.99, label: 'Bale',  tag: 'Best value' }
    ]
  };

  function bal() { try { return L().credits(); } catch (e) { return 0; } }
  function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

  /* ---------------------------------------------------------------- modal frame ----- */
  var open = null;   // the one modal on screen
  function modal(html, onKey) {
    close();
    var ov = document.createElement('div');
    ov.className = 'lw-ov'; ov.setAttribute('role', 'dialog'); ov.setAttribute('aria-modal', 'true');
    ov.innerHTML = '<div class="lw-card">' + html + '</div>';
    document.body.appendChild(ov);
    var prevFocus = document.activeElement;
    function key(e) {
      if (e.key === 'Escape' && onKey) { e.preventDefault(); onKey('esc'); }
      if (e.key === 'Tab') {                         // keep focus inside the dialog
        var f = ov.querySelectorAll('button:not([disabled]),input,a[href]');
        if (!f.length) return;
        var first = f[0], last = f[f.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
        else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
      }
      e.stopPropagation();
    }
    ov.addEventListener('keydown', key, true);
    open = { el: ov, restore: prevFocus };
    setTimeout(function () { var b = ov.querySelector('[data-focus]') || ov.querySelector('button:not([disabled]),input'); if (b) b.focus(); }, 30);
    return ov;
  }
  function close() {
    if (!open) return;
    var o = open; open = null;
    o.el.remove();
    try { if (o.restore && o.restore.focus) o.restore.focus(); } catch (e) {}
  }
  function coin(n) { return '<span class="lw-coin" aria-hidden="true">◆</span>' + n; }

  /* ---------------------------------------------------------------- Continue -------- */
  function offerContinue(o) {
    o = o || {};
    var cost = o.cost || CONFIG.continueCost, done = false;
    function finish(used) {
      if (done) return; done = true; close();
      try { (used ? o.use : o.decline || function () {})(); } catch (e) { if (root.console) console.error(e); }
    }
    if (!root.document || !root.LirichLearn) { finish(false); return; }
    function render() {
      var have = bal(), can = have >= cost;
      var ov = modal(
        '<span class="lw-tag">' + esc(o.tag || 'Second chance') + '</span>' +
        '<h2>' + esc(o.title || 'Keep going?') + '</h2>' +
        '<p>Use <b>' + cost + ' credits</b> for <b>' + esc(o.what || 'one more chance') + '</b>. One Continue per round.</p>' +
        '<div class="lw-bal">You have ' + coin('<b>' + have + '</b>') + (have === 1 ? ' credit' : ' credits') + '</div>' +
        '<button class="lw-btn" data-act="use"' + (can ? ' data-focus' : ' disabled') + '>Continue · ' + coin(cost) + '</button>' +
        (can ? '' : '<p class="lw-short">Not enough credits yet. Earn them free: new stars, Today\'s item, streaks.</p>' +
          '<button class="lw-btn alt" data-act="shop" data-focus>' + (CONFIG.sellCredits ? 'Get credits' : 'How to earn credits') + '</button>') +
        '<button class="lw-btn ghost" data-act="end">End the round</button>',
        function () { finish(false); });
      ov.querySelector('[data-act=use]').onclick = function () {
        if (!L().spend(cost, 'continue')) { render(); return; }
        try { L().sfx('good'); } catch (e) {}
        finish(true);
      };
      var sh = ov.querySelector('[data-act=shop]');
      if (sh) sh.onclick = function () { openShop(render); };
      ov.querySelector('[data-act=end]').onclick = function () { finish(false); };
    }
    render();
  }

  /* ---------------------------------------------------------------- the shop -------- */
  function openShop(onClose) {
    var back = function () { close(); if (onClose) onClose(); };
    var ov = modal(
      '<span class="lw-tag">Credits</span><h2>Your credits</h2>' +
      '<div class="lw-big">' + coin(bal()) + '</div>' +
      '<p class="lw-sub">Spend 3 credits to continue a round you would otherwise lose.</p>' +
      '<h3>Earn free credits</h3>' +
      '<ul class="lw-earn">' +
        '<li><span>A new star on any level</span><b>+1 each</b></li>' +
        '<li><span>Answer Today\'s item on the home page</span><b>+1 · +2 if right</b></li>' +
        '<li><span>Every 7 days in a row</span><b>+5</b></li></ul>' +
      (CONFIG.sellCredits ? '<h3>Buy credits <small>for grown-ups</small></h3>' +
      '<div class="lw-packs">' + CONFIG.packs.map(function (p) {
        return '<button class="lw-pack" data-pack="' + p.id + '">' + (p.tag ? '<i>' + esc(p.tag) + '</i>' : '') +
          '<span class="lw-pc">' + coin(p.credits) + '</span><span class="lw-pl">' + esc(p.label) + '</span>' +
          '<b>' + CONFIG.currency + p.price.toFixed(2) + '</b></button>';
      }).join('') + '</div>' +
      (CONFIG.payments ? '' : '<p class="lw-soon">Buying is coming soon. Nothing can be bought yet and no payment is ever taken here.</p>')
      : '<p class="lw-soon">Credits cannot be bought. Every credit here is earned by playing and learning.</p>') +
      '<button class="lw-btn alt" data-act="back" data-focus>Done</button>',
      back);
    ov.querySelector('[data-act=back]').onclick = back;
    Array.prototype.forEach.call(ov.querySelectorAll('[data-pack]'), function (b) {
      b.onclick = function () { gate(b.dataset.pack, function () { openShop(onClose); }); };
    });
  }

  /* A grown-up check in front of anything to do with money. Not security — a speed bump
     so a child does not reach a payment screen by tapping around. */
  function gate(packId, onDone) {
    var a = 6 + Math.floor(Math.random() * 7), b = 12 + Math.floor(Math.random() * 8), tries = 0;
    var p = CONFIG.packs.filter(function (x) { return x.id === packId; })[0] || CONFIG.packs[0];
    var ov = modal(
      '<span class="lw-tag">For grown-ups</span><h2>Ask a grown-up</h2>' +
      '<p>To continue, a parent or teacher answers:</p>' +
      '<label class="lw-q"><span>' + a + ' × ' + b + ' =</span><input inputmode="numeric" autocomplete="off" maxlength="4" aria-label="Answer"></label>' +
      '<p class="lw-short" hidden></p>' +
      '<button class="lw-btn" data-act="ok">Check</button>' +
      '<button class="lw-btn ghost" data-act="cancel">Cancel</button>', function () { onDone(); });
    var inp = ov.querySelector('input'), why = ov.querySelector('.lw-short');
    function check() {
      if (parseInt(inp.value, 10) === a * b) return grown();
      tries++;
      if (tries >= 2) return onDone();
      why.hidden = false; why.textContent = 'Not quite. One more try.'; inp.value = ''; inp.focus();
    }
    ov.querySelector('[data-act=ok]').onclick = check;
    inp.addEventListener('keydown', function (e) { if (e.key === 'Enter') check(); });
    ov.querySelector('[data-act=cancel]').onclick = function () { onDone(); };
    function grown() {
      var o2 = modal(
        '<span class="lw-tag">For grown-ups</span><h2>' + coin(p.credits) + ' credits · ' + CONFIG.currency + p.price.toFixed(2) + '</h2>' +
        (CONFIG.payments
          ? '<p>Payments are switched on in config, but no payment handler is installed in this build.</p>'
          : '<p><b>Buying is coming soon.</b> Lirich Learn does not take payments yet, so nothing has been charged.</p>' +
            '<p class="lw-sub">Credits can be earned free by playing and learning. Schools and companies: ask Lirich about class passes.</p>') +
        '<button class="lw-btn alt" data-act="back" data-focus>Back to credits</button>', function () { onDone(); });
      o2.querySelector('[data-act=back]').onclick = function () { onDone(); };
    }
  }

  /* ---------------------------------------------------------------- balance chip ---- */
  function chip() {
    var b = document.createElement('button');
    b.type = 'button'; b.className = 'lw-chip'; b.title = 'Credits';
    function paint() { b.innerHTML = coin('<b>' + bal() + '</b>'); b.setAttribute('aria-label', bal() + ' credits. Open the credits shop.'); }
    paint();
    root.addEventListener('lirich-credits', paint);
    b.onclick = function () { openShop(paint); };
    return b;
  }

  root.LirichWallet = { config: CONFIG, offerContinue: offerContinue, openShop: openShop, chip: chip,
                        isOpen: function () { return !!open; }, close: close };
})(typeof window !== 'undefined' ? window : globalThis);
