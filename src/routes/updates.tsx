import { createFileRoute } from "@tanstack/react-router";
import { ClickToCopy } from "~components/ClickToCopy";
import UpdateNotes from "../../documents/updateNotes.md";

import "./markdown.css";

export const UpdatesPage: React.FC = () => {
  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto markdown">
      <section className="mt-4">
        <h2 className="font-bold">Current Version</h2>
        <ClickToCopy message={__ROBOREF_VERSION__} />
      </section>
      <section className="mt-4">
        <UpdateNotes />
      </section>
    </main>
  );
};

export const Route = createFileRoute("/updates")({
  component: UpdatesPage,
});
