const VERSION = "gigi-sw-v1";

self.addEventListener("install", (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

// Lightweight "self-preservation" heartbeat for SW lifecycle awareness.
let lastAudioSignalAt = 0;

self.addEventListener("message", (event) => {
  const data = event.data || {};
  if (data.type === "GIGI_AUDIO_SIGNAL") {
    lastAudioSignalAt = Date.now();
  }
  if (data.type === "GIGI_PING") {
    event.source?.postMessage({
      type: "GIGI_PONG",
      version: VERSION,
      lastAudioSignalAt,
    });
  }
});

// Handles Push Notifications (e.g., Supabase-triggered push relayed via your push provider).
self.addEventListener("push", (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch {
    payload = { title: "GIGI", body: event.data ? event.data.text() : "New update available." };
  }

  const title = payload.title || "GIGI";
  const options = {
    body: payload.body || "You have a new command update.",
    icon: payload.icon || "/gigi-logo.png",
    badge: payload.badge || "/gigi-logo.png",
    data: {
      url: payload.url || "/",
    },
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const targetUrl = event.notification?.data?.url || "/";

  event.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientsArr) => {
      for (const client of clientsArr) {
        if ("focus" in client) {
          client.navigate(targetUrl);
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl);
      }
      return null;
    })
  );
});
