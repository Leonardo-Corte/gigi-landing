"use client";

import { useEffect } from "react";

export function ServiceWorkerRegister() {
  useEffect(() => {
    if (!("serviceWorker" in navigator)) {
      return;
    }

    let isMounted = true;

    navigator.serviceWorker
      .register("/sw.js")
      .then((registration) => {
        if (!isMounted) {
          return;
        }
        if (registration.active) {
          registration.active.postMessage({ type: "GIGI_PING" });
        }
      })
      .catch(() => {
        // Keep silent in production UI.
      });

    return () => {
      isMounted = false;
    };
  }, []);

  return null;
}
