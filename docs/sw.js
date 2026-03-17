const CACHE_NAME = 'securechat-v2';
const ASSETS = [
  './',
  './index.html',
  './manifest.json'
];

// Install: cache core assets
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

// Activate: clean old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch: cache-first for same-origin, network-first for API
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // Never cache ntfy.sh requests (SSE/push relay)
  if (url.hostname === 'ntfy.sh') return;

  // For navigation and same-origin assets: cache-first with network fallback
  if (url.origin === self.location.origin) {
    e.respondWith(
      caches.match(e.request).then(cached => {
        const fetchPromise = fetch(e.request).then(response => {
          if (response && response.status === 200) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
          }
          return response;
        }).catch(() => cached);
        return cached || fetchPromise;
      })
    );
  }
});

// Web Push: show notification when push event received
self.addEventListener('push', e => {
  let data = { title: 'SecureChat', body: '您有新消息' };
  if (e.data) {
    try {
      const payload = e.data.json();
      data.title = payload.title || data.title;
      data.body = payload.body || data.body;
      data.data = payload.data || {};
    } catch {
      data.body = e.data.text() || data.body;
    }
  }
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 192 192"><rect width="192" height="192" rx="40" fill="%234A90D9"/><path d="M96 40c-22.1 0-40 17.9-40 40v16H48c-4.4 0-8 3.6-8 8v48c0 4.4 3.6 8 8 8h96c4.4 0 8-3.6 8-8v-48c0-4.4-3.6-8-8-8h-8V80c0-22.1-17.9-40-40-40zm0 16c13.3 0 24 10.7 24 24v16H72V80c0-13.3 10.7-24 24-24zm0 64c6.6 0 12 5.4 12 12s-5.4 12-12 12-12-5.4-12-12 5.4-12 12-12z" fill="white"/></svg>',
      badge: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96"><rect width="96" height="96" rx="20" fill="%234A90D9"/></svg>',
      tag: 'securechat-msg',
      renotify: true,
      data: data.data
    })
  );
});

// Notification click: focus or open app
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(clients => {
      for (const client of clients) {
        if (client.url.includes('index.html') || client.url.endsWith('/')) {
          return client.focus();
        }
      }
      return self.clients.openWindow('./');
    })
  );
});
