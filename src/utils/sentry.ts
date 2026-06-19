import {
  init,
  browserTracingIntegration,
  setUser,
  setMeasurement,
} from "@sentry/react";
import { queryClient } from "./data/query";
import { getShareProfile } from "./data/share";

export async function clearCache() {
  // Invalidate All Queries
  await queryClient.invalidateQueries({ type: "all" });

  // Unregister Service Workers
  if ("serviceWorker" in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    for (const registration of registrations) {
      await registration.unregister();
    }
  }

  // Reload
  window.location.reload();
}

// VITE_SENTRY_DSN lets a build override the target Sentry project; it falls back
// to the project's own DSN so reporting works even when the var is unset (a DSN
// is public, so embedding it in the client bundle is safe). Mirrors the
// VITE_REFEREE_FYI_SHARE_SERVER fallback pattern in utils/data/share.ts.
const dsn =
  import.meta.env.VITE_SENTRY_DSN ??
  "https://23c85f2c7692228bd3aabb4a17577a2c@o4511592950595584.ingest.de.sentry.io/4511592960622672";
const enabled =
  import.meta.env.MODE === "production" ||
  import.meta.env.VITE_REFEREE_FYI_ENABLE_SENTRY;

export const client = init({
  dsn,
  integrations: [browserTracingIntegration()],
  attachStacktrace: true,
  enableLogs: true,
  environment: import.meta.env.MODE,
  enabled,
  // Performance Monitoring
  tracesSampleRate: 1.0, //  Capture 100% of the transactions
});

window.addEventListener("load", async () => {
  // Initialize user
  const profile = await getShareProfile();
  if (profile) {
    setUser({
      id: profile.key,
      username: profile.name,
    });
  }
});

export function reportMeasurement(
  name: string,
  value: number,
  unit: Parameters<typeof setMeasurement>[2]
) {
  return setMeasurement(name, value, unit);
}

export function measure(name: string, executor: () => void) {
  const start = performance.now();
  executor();
  const end = performance.now();

  const duration = end - start;
  reportMeasurement(name, duration, "millisecond");
  return duration;
}
