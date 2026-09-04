const CACHE = 'lirich-ops-v72';
const ASSETS = ['./', './index.html', './app.js', './manifest.json',
  './logo.png', './icon-192.png', './icon-512.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

/* Network-first with cache fallback.
   ⚠⚠ Michelle, 1 Sep 2026: GitHub Pages serves index.html and app.js with
   `Cache-Control: max-age=600`. A plain fetch(e.request) HONOURS that, so for up to 10 minutes
   after a deploy the browser answered from its OWN http cache and this worker never reached the
   network — the driver kept seeing the old build no matter how many times the app was reopened.
   The app SHELL is therefore fetched with {cache:'reload'}, which forces a network revalidation
   and ignores the http cache. Everything else (photos etc.) keeps normal caching so mobile data
   is not wasted. */
const SHELL = /\/(index\.html|app\.js|sw\.js)(\?|$)|\/$/;
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  const shell = SHELL.test(new URL(e.request.url).pathname);
  const req = shell ? new Request(e.request, { cache: 'reload' }) : e.request;
  e.respondWith(
    fetch(req)
      .then(res => {
        const copy = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy));
        return res;
      })
      .catch(() => caches.match(e.request).then(r => r || caches.match('./index.html')))
  );
});
