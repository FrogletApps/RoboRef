import { sentryVitePlugin } from "@sentry/vite-plugin";
import react from "@vitejs/plugin-react-swc";
import { defineConfig } from "vite";
import { vitePluginVersionMark } from "vite-plugin-version-mark";
import { VitePWA } from "vite-plugin-pwa";
import tsconfigPaths from "vite-tsconfig-paths";
import { plugin as markdown, Mode } from "vite-plugin-markdown";
import { execSync } from "node:child_process";
import { TanStackRouterVite } from "@tanstack/router-plugin/vite";

import { type Plugin } from "vite";

// Single source of truth for the app version, formatted as
// `YYYY-MM-DD-<short commit hash>` (build date + git short SHA).
// Fed to BOTH the baked-in `__ROBOREF_VERSION__` (via vite-plugin-version-mark)
// and the `/version.json` the running app polls, so the two are always identical
// within a build and the "Update Available" prompt only fires on a genuinely
// newer deploy.
const APP_VERSION = (() => {
  const shortSHA = (() => {
    try {
      // git's default short SHA (shortest unambiguous prefix, ~7 chars)
      return execSync("git rev-parse --short HEAD").toString().trim();
    } catch {
      // Fallback for environments without a git checkout (e.g. CI)
      return (process.env.CF_PAGES_COMMIT_SHA || "unknown").slice(0, 7);
    }
  })();
  const date = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC build date)
  return `${date}-${shortSHA}`;
})();

const generateVersionJson: Plugin = {
  name: "generate-version-json",
  apply: "build",
  buildStart() {
    this.emitFile({
      type: "asset",
      fileName: "version.json",
      source: JSON.stringify({ version: APP_VERSION }),
    });
  },
};

// https://vitejs.dev/config/
export default defineConfig(() => ({
  plugins: [
    TanStackRouterVite({
      target: "react",
      autoCodeSplitting: true,
    }),
    react(),
    markdown({
      mode: [Mode.REACT],
    }),
    vitePluginVersionMark({
      name: "RoboRef",
      version: APP_VERSION,
    }),
    generateVersionJson,
    tsconfigPaths({}),
    VitePWA({
      registerType: "autoUpdate",
      injectRegister: "inline",
      includeAssets: ["./rules/**/*.json", "updateNotes.md"],
      manifest: {
        id: "app.frogletapps.roboref.v1",
        name: "RoboRef",
        short_name: "RoboRef",
        start_url: "/",
        display: "standalone",
        background_color: "#27272A",
        theme_color: "#27272A",
        description:
          "RoboRef is an anomaly log for Head Referees at robotics events. It allows you to quickly record violations, see summaries before a match, and share your log with others.",
        orientation: "portrait-primary",

        launch_handler: {
          client_mode: ["navigate-existing", "auto"],
        },
        icons: [
          {
            src: "/icons/roboref-48x48.png",
            sizes: "48x48",
            type: "image/png",
          },
          {
            src: "/icons/roboref-72x72.png",
            sizes: "72x72",
            type: "image/png",
          },
          {
            src: "/icons/roboref-96x96.png",
            sizes: "96x96",
            type: "image/png",
          },
          {
            src: "/icons/roboref-144x144.png",
            sizes: "144x144",
            type: "image/png",
          },
          {
            src: "/icons/roboref-168x168.png",
            sizes: "168x168",
            type: "image/png",
          },
          {
            src: "/icons/roboref-192x192.png",
            sizes: "192x192",
            type: "image/png",
          },
          {
            src: "/icons/roboref-256x256.png",
            sizes: "256x256",
            type: "image/png",
          },
          {
            src: "/icons/roboref-512x512.png",
            sizes: "512x512",
            type: "image/png",
          },
          {
            src: "/icons/roboref.svg",
            sizes: "512x512",
            type: "image/svg",
          },
        ],
        screenshots: [
          {
            src: "/screenshots/screenshot1.png",
            sizes: "1080x2400",
            label:
              "The match list view for the 2023 VEX Robotics World Championship High School Division.",
          },
          {
            src: "/screenshots/screenshot2.png",
            sizes: "1080x2400",
            label:
              "The match dialog, containing a general note and a major violation on a team.",
          },
          {
            src: "/screenshots/screenshot3.png",
            sizes: "1080x2400",
            label:
              "The manage tab, which allows you to share the anomaly log with others.",
          },
          {
            src: "/screenshots/screenshot4.png",
            sizes: "1080x2400",
            label: "The home screen, where you select relevant events.",
          },
        ],
      },
      workbox: {
        // All /api/* routes should always go to the server
        navigateFallbackDenylist: [/^\/api/],
      },
    }),
    sentryVitePlugin({
      org: "referee-fyi",
      project: "referee-fyi",
      bundleSizeOptimizations: {
        excludeDebugStatements: true,
        excludeReplayIframe: true,
        excludeReplayShadowDom: true,
        excludeReplayWorker: true,
      },
    }),
  ],

  base: "/",
  build: {
    sourcemap: true,
  },
}));
