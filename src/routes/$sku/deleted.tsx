import React from "react";
import { useEventDeletedIncidents } from "~utils/hooks/incident";
import { useCurrentEvent } from "~utils/hooks/state";
import { createFileRoute } from "@tanstack/react-router";
import { IncidentListSummary } from "~components/IncidentListSummary";

export const EventDeletedIncidentsPage: React.FC = () => {
  const { data: event } = useCurrentEvent();
  const { data: deleted, isPending } = useEventDeletedIncidents(event?.sku);

  return (
    <IncidentListSummary
      incidents={deleted}
      isPending={isPending}
      countLabel="Deleted Note"
      exportFilenamePrefix="deleted-incidents"
      readonlyIncidents
      allowUndelete
    />
  );
};

export const Route = createFileRoute("/$sku/deleted")({
  component: EventDeletedIncidentsPage,
});
