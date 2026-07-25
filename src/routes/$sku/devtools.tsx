import React, { Suspense } from "react";
import { createFileRoute, redirect } from "@tanstack/react-router";
import { Spinner } from "~components/Spinner";

const LazyEventDevTools = React.lazy(
  () => import("./-components/DevToolsContent")
);

export const EventDevTools: React.FC = () => {
  return (
    <Suspense fallback={<Spinner show />}>
      <LazyEventDevTools />
    </Suspense>
  );
};

export const Route = createFileRoute("/$sku/devtools")({
  component: EventDevTools,
  beforeLoad: () => {
    if (!import.meta.env.DEV) {
      throw redirect({
        to: "/",
      });
    }
  },
});
