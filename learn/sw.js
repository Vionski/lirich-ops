/* Lirich Learn — minimal offline cache.
   Place next to the game files when hosting over HTTPS.
   Does nothing at all when the folder is opened from disk, which is intended:
   from a USB stick the games already work without it. */
const CACHE = 'lirich-learn-v28';

/* The shared modules must be cached. Every game reads its sorting rules from
   lirich-rules.js and its scoring from lirich-scores.js, so a cached game with an
   uncached module is a broken game the moment the wifi drops — which in a school is
   most of the time. Bump CACHE whenever this list changes, or browsers keep the old
   set indefinitely. */
const ASSETS = [
  './',
  './index.html',
  './staff.html',
  './beta-guide.html',
  './beta-feedback.html',
  './lirich-learn.js',
  './lirich-learn.css',
  './lirich-sprites.js',
  './spot-photos.js',
  './assets/lirich-mark.png',
  './assets/nunito-latin-400-normal.woff2',
  './assets/nunito-latin-700-normal.woff2',
  './assets/nunito-latin-800-normal.woff2',
  './assets/nunito-latin-900-normal.woff2',
  './assets/cinzel-latin-700-normal.woff2',
  './leaderboard.html',
  './lirich-rules.js',
  './lirich-scores.js',
  './lirich-rng.js',
  './lirich-challenge.js',
  /* added 21 Nov 2026: credits, the school list, the app file and its icons */
  './lirich-wallet.js',
  './lirich-schools.js',
  './manifest.webmanifest',
  './assets/icon-192.png',
  './assets/icon-512.png',
  './assets/icon-maskable-512.png',
  './assets/apple-touch-icon.png',
  './Lirich_SortIt_Game.html',
  './Lirich_BinOrNot_Game.html',
  './Lirich_BuildTheLine_Game.html',
  './Lirich_SpotTheContaminant_Game.html',
  './Lirich_LoadTheContainer_Game.html',
  './Lirich_UpgradeStream_Game.html',
  './Lirich_OnRoute_Game.html',
  './Lirich_PlantBuilder_Game.html',
  './Lirich_ZeroWasteCity_Game.html',
  './Lirich_PickLine_Game.html',
  './Lirich_Dispatch_Game.html'
];

self.addEventListener('install', e => {
  /* addAll fails the whole install if any one file 404s — cache them individually so a
     renamed or missing game degrades to online-only instead of killing offline entirely */
  e.waitUntil(
    caches.open(CACHE)
      /* {cache:'reload'}: GitHub Pages sends max-age=600, so a plain add() within ten minutes of
         an upload could store the OLD file under the NEW cache name. */
      .then(c => Promise.all(ASSETS.map(a => c.add(new Request(a, { cache: 'reload' })).catch(() => {}))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks =>
    /* Only our own old caches. These files may share an origin with other Lirich apps (on
       GitHub Pages, the driver app's 'lirich-ops-*' cache lives on the same origin); deleting
       every other cache would wipe the driver app's offline copy. 22 Oct 2026. */
    Promise.all(ks.filter(k => k.indexOf('lirich-learn-') === 0 && k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    caches.match(e.request).then(hit => hit || fetch(e.request).then(res => {
      const copy = res.clone();
      caches.open(CACHE).then(c => c.put(e.request, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match('./index.html')))
  );
});
