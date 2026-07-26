import React from "react";
import { createFileRoute, useParams } from "@tanstack/react-router";
import { Incident } from "~components/Incident";
import { VirtualizedList } from "~components/VirtualizedList";
import { useTeamIncidentsByEvent } from "~utils/hooks/incident";
import { useCurrentEvent } from "~utils/hooks/state";

export const TeamNotesPage: React.FC = () => {
  const { team } = useParams({ strict: false });
  const { data: event } = useCurrentEvent();
  const { data: incidents } = useTeamIncidentsByEvent(team, event?.sku);

  if (!team) {
    return null;
  }

  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto p-4">
      <header className="mb-4">
        <h1 className="text-xl font-bold">
          Notes about Team <span className="font-mono text-emerald-400">{team}</span>
        </h1>
        <p className="text-zinc-400 text-sm mt-1">
          This is a summary of all rules violations logged for this team.
        </p>
      </header>
      <VirtualizedList data={incidents ?? []} options={{ estimateSize: () => 64 }}>
        {(incident) => (
          <Incident
            incident={incident}
            className="h-14 overflow-hidden"
            readonly
          />
        )}
      </VirtualizedList>
    </main>
  );
};

export const Route = createFileRoute("/$sku/team/$team/teamNotes")({
  component: TeamNotesPage,
});
