import { queryClient } from "./query";

export async function clearCache() {
  try {
    // Invalidate All Queries
    await queryClient.invalidateQueries({ type: "all" });

    // Unregister Service Workers
    if ("serviceWorker" in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      for (const registration of registrations) {
        await registration.unregister();
      }
    }

    // Purge CacheStorage
    if ("caches" in window) {
      const keys = await caches.keys();
      for (const key of keys) {
        await caches.delete(key);
      }
    }
  } catch {}

  // Hard reload with cache-buster
  try {
    const url = new URL(window.location.href);
    url.searchParams.set("_cb", Date.now().toString());
    window.location.replace(url.toString());
  } catch {
    window.location.reload();
  }
}
