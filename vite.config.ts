import { sentryVitePlugin } from "@sentry/vite-plugin";
import react from "@vitejs/plugin-react-swc";
import { defineConfig } from "vite";
import { vitePluginVersionMark } from "vite-plugin-version-mark";
import { VitePWA } from "vite-plugin-pwa";
import mdx from "@mdx-js/rollup";
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

const isTestEnv =
  Boolean(process.env.VITE_REFEREE_FYI_SHARE_SERVER?.includes("test")) ||
  process.env.VITE_REFEREE_FYI_ENV === "test" ||
  process.env.CF_PAGES_PROJECT_NAME === "roboref-test";

const appName = isTestEnv ? "RoboRef TEST" : "RoboRef";
const appId = isTestEnv
  ? "app.frogletapps.roboref.test.v1"
  : "app.frogletapps.roboref.v1";

// https://vitejs.dev/config/
export default defineConfig(() => ({
  plugins: [
    TanStackRouterVite({
      target: "react",
      autoCodeSplitting: true,
    }),
    mdx(),
    react(),
    vitePluginVersionMark({
      name: "RoboRef",
      version: APP_VERSION,
      ifLog: false,
    }),
    generateVersionJson,
    VitePWA({
      registerType: "autoUpdate",
      injectRegister: "inline",
      includeAssets: ["./rules/**/*.json", "changeLog.md"],
      manifest: {
        id: appId,
        name: appName,
        short_name: appName,
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
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref-72x72.png",
            sizes: "72x72",
            type: "image/png",
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref-96x96.png",
            sizes: "96x96",
            type: "image/png",
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref-144x144.png",
            sizes: "144x144",
            type: "image/png",
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref-168x168.png",
            sizes: "168x168",
            type: "image/png",
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref-192x192.png",
            sizes: "192x192",
            type: "image/png",
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref-256x256.png",
            sizes: "256x256",
            type: "image/png",
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref-512x512.png",
            sizes: "512x512",
            type: "image/png",
            purpose: "any maskable",
          },
          {
            src: "/icons/roboref.svg",
            sizes: "512x512",
            type: "image/svg",
            purpose: "any maskable",
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
        cleanupOutdatedCaches: true,
        clientsClaim: true,
        skipWaiting: true,
      },
    }),
    sentryVitePlugin({
      org: "roboref",
      project: "roboref",
      bundleSizeOptimizations: {
        excludeDebugStatements: true,
        excludeReplayIframe: true,
        excludeReplayShadowDom: true,
        excludeReplayWorker: true,
      },
    }),
  ],

  base: "/",
  define: {
    __ROBOREF_VERSION__: JSON.stringify(APP_VERSION),
  },
  resolve: {
    tsconfigPaths: true,
  },
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes("node_modules")) {
            if (id.includes("@sentry")) {
              return "vendor-sentry";
            }
            if (id.includes("@tanstack")) {
              return "vendor-tanstack";
            }
            if (id.includes("motion")) {
              return "vendor-motion";
            }
            if (id.includes("@heroicons")) {
              return "vendor-icons";
            }
            if (id.includes("react") || id.includes("react-dom")) {
              return "vendor-react";
            }
          }
        },
      },
    },
  },
}));
