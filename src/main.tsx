import React from "react";
import ReactDOM from "react-dom/client";
import { QueryClientProvider } from "@tanstack/react-query";
import {
  captureException,
  tanstackRouterBrowserTracingIntegration,
} from "@sentry/react";
import { initIncidentStore } from "~utils/data/incident";
import { queryClient } from "~utils/data/query";
import { registerSW } from "virtual:pwa-register";
import { initHistoryStore } from "~utils/hooks/history";
import { createRouter, RouterProvider } from "@tanstack/react-router";
import { ThemeProvider } from "~utils/hooks/theme";
import { QRCodeProvider } from "~utils/hooks/qr";
import {
  ErrorBoundary,
  ErrorContactDevFallback,
} from "~components/ErrorBoundary";
import { Spinner } from "~components/Spinner";
import { client as sentry } from "~utils/sentry";

import "~utils/sentry";
import "./index.css";

import { routeTree } from "./routeTree.gen";

window.addEventListener("vite:preloadError", (event) => {
  const PRELOAD_KEY = "vite_preload_reloaded";
  try {
    if (window.sessionStorage && !sessionStorage.getItem(PRELOAD_KEY)) {
      sessionStorage.setItem(PRELOAD_KEY, "true");
      const url = new URL(window.location.href);
      url.searchParams.set("_cb", Date.now().toString());
      window.location.replace(url.toString());
    } else {
      event.preventDefault();
    }
  } catch {
    event.preventDefault();
  }
});

setTimeout(() => {
  sessionStorage.removeItem("vite_preload_reloaded");
}, 5000);

const router = createRouter({
  routeTree,
  defaultPreload: "intent",
  defaultPreloadStaleTime: 1000 * 60,
  defaultPendingMs: 150,
  defaultPendingComponent: () => <Spinner show />,
  defaultErrorComponent: ({ error, reset, info }) => {
    const eventId = captureException(error, { extra: { info } });
    return (
      <ErrorContactDevFallback
        error={error}
        resetError={reset}
        eventId={eventId}
        componentStack={info?.componentStack ?? ""}
      />
    );
  },
});
sentry?.addIntegration(tanstackRouterBrowserTracingIntegration(router));

declare module "@tanstack/react-router" {
  interface Register {
    router: typeof router;
  }
}

registerSW({ immediate: true });

initIncidentStore();
initHistoryStore();

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <QRCodeProvider>
          <ErrorBoundary>
            <RouterProvider router={router} />
          </ErrorBoundary>
        </QRCodeProvider>
      </ThemeProvider>
    </QueryClientProvider>
  </React.StrictMode>
);
