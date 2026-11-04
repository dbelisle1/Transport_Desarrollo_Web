const CACHE = 'transport-public-v2';
const PUBLIC_ASSETS = ['/', '/css/site.css', '/js/site.js', '/manifest.webmanifest', '/images/icon.svg', '/images/icon-192.png', '/images/icon-512.png'];
const PUBLIC_PATHS = new Set(PUBLIC_ASSETS);
const PRIVATE_PREFIXES = ['/acceso', '/admin', '/gestion', '/cliente', '/portal'];
self.addEventListener('install', event => event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(PUBLIC_ASSETS)).then(() => self.skipWaiting())));
self.addEventListener('activate', event => event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim())));
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin || PRIVATE_PREFIXES.some(prefix => url.pathname.startsWith(prefix)) || !PUBLIC_PATHS.has(url.pathname)) return;
  if (url.pathname === '/') {
    event.respondWith(fetch(event.request).catch(() => caches.match('/')));
    return;
  }
  event.respondWith(caches.match(url.pathname).then(cached => cached || fetch(event.request)));
});
