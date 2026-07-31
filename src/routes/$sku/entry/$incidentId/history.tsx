import React from "react";
import { createFileRoute, useNavigate, useParams, useRouter } from "@tanstack/react-router";
import { EditHistoryView } from "~components/EditHistory";
import { useIncident } from "~utils/hooks/incident";
import { useEventTeam } from "~utils/hooks/robotevents";
import { useCurrentEvent } from "~utils/hooks/state";
import { Spinner } from "~components/Spinner";
import { Button } from "~components/Button";

export const NoteHistoryPage: React.FC = () => {
  const navigate = useNavigate();
  const router = useRouter();
  const { sku, incidentId } = useParams({ strict: false });
  const id = incidentId ?? "";

  const { data: incident, isLoading } = useIncident(id, { enabled: !!id });
  const { data: eventData } = useCurrentEvent();
  const { data: teamData } = useEventTeam(eventData, incident?.team);

  if (isLoading || !incident) {
    return (
      <div className="max-w-xl h-full w-full mx-auto flex-1 p-4">
        <Spinner show />
      </div>
    );
  }

  const onBack = () => {
    if (router.history.canGoBack()) {
      router.history.back();
    } else {
      navigate({
        to: "/$sku/entry/$incidentId",
        params: { sku: sku ?? "", incidentId: id },
      });
    }
  };

  return (
    <div className="max-w-xl h-full w-full mx-auto flex-1 overflow-y-auto p-4 pb-12">
      <header className="mb-4">
        <h1 className="text-xl font-bold">
          <span className="font-mono text-emerald-400">{incident.team}</span>
          {" • "}
          <span>{teamData?.team_name ?? "Note History"}</span>
        </h1>
      </header>

      <section className="mt-2">
        <EditHistoryView value={incident} />
      </section>

      <div className="mt-8">
        <Button mode="primary" className="w-full text-center" onClick={onBack}>
          Back to Edit Note
        </Button>
      </div>
    </div>
  );
};

export const Route = createFileRoute("/$sku/entry/$incidentId/history")({
  component: NoteHistoryPage,
});
