import React, { Suspense } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { Spinner } from "~components/Spinner";

import "./markdown.css";

const DataExport = React.lazy(() => import("../../documents/dataExport.md"));

const DataExportPage: React.FC = () => {
  return (
    <main className="w-full max-w-full md:max-w-3xl lg:max-w-4xl mx-auto px-2 sm:px-4 py-6 overflow-y-auto overflow-x-hidden min-w-0 flex-1 markdown">
      <Suspense fallback={<Spinner show />}>
        <DataExport />
      </Suspense>
    </main>
  );
};

export const Route = createFileRoute("/dataExport")({
  component: DataExportPage,
});
