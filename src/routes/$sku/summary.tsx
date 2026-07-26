import { useEffect } from "react";
import { Spinner } from "~components/Spinner";
import { useAddEventVisited } from "~utils/hooks/history";
import { useCurrentEvent } from "~utils/hooks/state";
import { LinkButton } from "~components/Button";
import { ArrowRightIcon } from "@heroicons/react/24/outline";
import { useEventIncidents } from "~utils/hooks/incident";
import { createFileRoute } from "@tanstack/react-router";
import { IncidentListSummary } from "~components/IncidentListSummary";

export const EventSummaryPage: React.FC = () => {
  const { data: event } = useCurrentEvent();
  const { mutateAsync: addEvent, isSuccess } = useAddEventVisited();
  const { data: incidents, isPending } = useEventIncidents(event?.sku);

  useEffect(() => {
    if (event && !isSuccess) {
      addEvent(event);
    }
  }, [event, isSuccess, addEvent]);

  if (!event) {
    return <Spinner show />;
  }

  return (
    <IncidentListSummary
      incidents={incidents}
      isPending={isPending}
      countLabel="Incident"
      exportFilenamePrefix="incidents"
      footer={
        <section className="mt-4">
          <LinkButton
            to="/$sku/deleted"
            params={{ sku: event.sku }}
            className="w-full flex items-center"
          >
            <span className="flex-1">Deleted Incidents</span>
            <ArrowRightIcon height={20} className="text-emerald-400" />
          </LinkButton>
        </section>
      }
    />
  );
};

export const Route = createFileRoute("/$sku/summary")({
  component: EventSummaryPage,
});
