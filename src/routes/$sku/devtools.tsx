import React, { Suspense } from "react";
import { createFileRoute, redirect } from "@tanstack/react-router";
import { Spinner } from "~components/Spinner";
import { getAppEnvironment } from "~utils/data/state";

const LazyEventDevTools = React.lazy(
  () => import("./-components/DevToolsContent")
);

const EventDevTools: React.FC = () => {
  return (
    <Suspense fallback={<Spinner show />}>
      <LazyEventDevTools />
    </Suspense>
  );
};

export const Route = createFileRoute("/$sku/devtools")({
  component: EventDevTools,
  beforeLoad: () => {
    if (getAppEnvironment() === "production") {
      throw redirect({
        to: "/",
      });
    }
  },
});

