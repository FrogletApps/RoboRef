import React, { Suspense } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { ClickToCopy } from "~components/ClickToCopy";
import { Spinner } from "~components/Spinner";

import "./markdown.css";

const UpdateNotes = React.lazy(() => import("../../documents/updateNotes.md"));

export const UpdatesPage: React.FC = () => {
  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto markdown">
      <section className="mt-4">
        <h2 className="font-bold">Current Version</h2>
        <ClickToCopy message={__ROBOREF_VERSION__} />
      </section>
      <section className="mt-4">
        <Suspense fallback={<Spinner show />}>
          <UpdateNotes />
        </Suspense>
      </section>
    </main>
  );
};

export const Route = createFileRoute("/updates")({
  component: UpdatesPage,
});
