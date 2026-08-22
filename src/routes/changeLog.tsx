import React, { Suspense, useEffect } from "react";
import { createFileRoute } from "@tanstack/react-router";
import { ClickToCopy } from "~components/ClickToCopy";
import { Spinner } from "~components/Spinner";
import changeLogRaw from "../../documents/changeLog.md?raw";

import "./markdown.css";

const ChangeLog = React.lazy(() => import("../../documents/changeLog.md"));

export function getChangeLogHash(content: string): string {
  let hash = 0;
  for (let i = 0; i < content.length; i++) {
    const char = content.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return hash.toString(36);
}

const ChangeLogPage: React.FC = () => {
  useEffect(() => {
    localStorage.setItem("last_seen_changelog_hash", getChangeLogHash(changeLogRaw));
    localStorage.setItem("version", __ROBOREF_VERSION__);
  }, []);

  return (
    <main className="w-full max-w-full md:max-w-3xl lg:max-w-4xl mx-auto px-2 sm:px-4 pb-6 overflow-y-auto overflow-x-hidden min-w-0 flex-1 markdown">
      <section className="mt-4">
        <h2 className="font-bold">Current Version</h2>
        <p className="text-zinc-400 text-sm mt-2">
          Use this to let a developer know what version you're using if you're having an issue
        </p>
        <ClickToCopy message={__ROBOREF_VERSION__} />
      </section>
      <br></br>
      <section className="mt-4">
        <Suspense fallback={<Spinner show />}>
          <ChangeLog />
        </Suspense>
      </section>
    </main>
  );
};

export const Route = createFileRoute("/changeLog")({
  component: ChangeLogPage,
});
