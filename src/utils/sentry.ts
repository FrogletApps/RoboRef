import {
  init,
  browserTracingIntegration,
  setUser,
  setMeasurement,
} from "@sentry/react";
import { getShareProfile } from "./data/share";
export { clearCache } from "./data/cache";

// VITE_SENTRY_DSN lets a build override the target Sentry project; it falls back
// to the project's own DSN so reporting works even when the var is unset (a DSN
// is public, so embedding it in the client bundle is safe). Mirrors the
// VITE_REFEREE_FYI_SHARE_SERVER fallback pattern in utils/data/share.ts.
const dsn =
  import.meta.env.VITE_SENTRY_DSN ??
  "https://23c85f2c7692228bd3aabb4a17577a2c@o4511592950595584.ingest.de.sentry.io/4511592960622672";
const sentryEnvVar = import.meta.env.VITE_REFEREE_FYI_ENABLE_SENTRY as unknown;
const enableSentryOverride =
  sentryEnvVar === "true" || (sentryEnvVar as unknown) === true
    ? true
    : sentryEnvVar === "false" || (sentryEnvVar as unknown) === false
    ? false
    : undefined;

const enabled =
  enableSentryOverride !== undefined
    ? enableSentryOverride
    : import.meta.env.MODE === "production";

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

