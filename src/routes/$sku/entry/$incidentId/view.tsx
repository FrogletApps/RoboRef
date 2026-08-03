import React, { useState, useCallback, useMemo } from "react";
import { createFileRoute, useNavigate, useParams, useRouter } from "@tanstack/react-router";
import { twMerge } from "tailwind-merge";
import {
  IncidentOutcome,
  matchToString,
} from "~utils/data/incident";
import { useCurrentEvent } from "~utils/hooks/state";
import { useRulesForEvent } from "~utils/hooks/rules";
import { useEventTeam } from "~utils/hooks/robotevents";
import { Button, LinkButton } from "~components/Button";
import { usePeerUserName } from "~utils/data/share";
import { ClockIcon, UserCircleIcon } from "@heroicons/react/24/outline";
import { Warning } from "~components/Warning";
import { AssetPreview } from "~components/Assets";
import { RulesDisplay } from "~components/Input";
import { useDeleteIncident, useIncident, useUndeleteIncident } from "~utils/hooks/incident";
import { toast } from "~components/Toast";
import { Spinner } from "~components/Spinner";

const IncidentOutcomeBackgroundClasses: { [O in IncidentOutcome]: string } = {
  Minor: "bg-yellow-400 text-yellow-900",
  Major: "bg-red-400 text-red-900",
  Disabled: "bg-blue-400 text-blue-900",
  General: "bg-zinc-300 text-zinc-900",
  Inspection: "bg-zinc-300 text-zinc-900",
};

export const NotePreviewPage: React.FC = () => {
  const navigate = useNavigate();
  const router = useRouter();
  const { sku, incidentId } = useParams({ strict: false });
  const id = incidentId ?? "";

  const { data: incident, isLoading } = useIncident(id, { enabled: !!id });
  const { data: event } = useCurrentEvent();
  const { data: team } = useEventTeam(event, incident?.team);
  const { data: rules } = useRulesForEvent(event);

  const contactName = usePeerUserName(incident?.consistency.outcome.peer);
  const date = incident ? new Date(incident.consistency.outcome.instant) : null;

  const formattedDate = useMemo(() => {
    if (!date) return undefined;
    if (isNaN(date.getTime())) return undefined;
    return date.toLocaleString(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    });
  }, [date]);

  const { mutateAsync: undeleteIncident, isPending: isUndeletePending } =
    useUndeleteIncident();
  const [confirmUndelete, setConfirmUndelete] = useState(false);

  const { mutateAsync: deleteIncident, isPending: isDeletePending } =
    useDeleteIncident();
  const [confirmDelete, setConfirmDelete] = useState(false);

  const onBack = useCallback(() => {
    if (router.history.canGoBack()) {
      router.history.back();
    } else {
      navigate({
        to: "/$sku/summary",
        params: { sku: sku ?? "" },
      });
    }
  }, [router, navigate, sku]);

  const onUndelete = useCallback(async () => {
    if (!incident) return;
    if (!confirmUndelete) {
      setConfirmUndelete(true);
      return;
    }

    try {
      await undeleteIncident(incident);
      toast({ type: "info", message: "Undeleted Note" });
      onBack();
    } catch (err) {
      toast({
        type: "error",
        message: "Could not undelete note!",
        context: JSON.stringify(err),
      });
    }
  }, [confirmUndelete, incident, undeleteIncident, onBack]);

  const onDelete = useCallback(async () => {
    if (!incident) return;
    if (!confirmDelete) {
      setConfirmDelete(true);
      return;
    }

    try {
      await deleteIncident(incident.id);
      toast({ type: "info", message: "Deleted Note" });
      onBack();
    } catch (err) {
      toast({
        type: "error",
        message: "Could not delete note!",
        context: JSON.stringify(err),
      });
    }
  }, [confirmDelete, incident, deleteIncident, onBack]);

  if (isLoading || !incident) {
    return (
      <div className="max-w-xl h-full w-full mx-auto flex-1 p-4">
        <Spinner show />
      </div>
    );
  }

  return (
    <div className="overflow-y-auto max-w-full my-2 bg-zinc-900 border border-zinc-800 rounded-lg p-4 shadow-sm space-y-4">
      <h2 className="text-lg font-semibold">
        <span className="text-emerald-400 font-mono">{incident.team}</span>
        {" • "}
        <span className="text-zinc-200">{team?.team_name}</span>
      </h2>

      <div className="flex gap-x-2">
        <span
          className={twMerge(
            IncidentOutcomeBackgroundClasses[incident.outcome],
            "p-1 rounded-md px-2.5 text-sm font-semibold"
          )}
        >
          {incident.outcome}
        </span>
        <span className="p-1 rounded-md px-2.5 text-sm font-semibold bg-zinc-700 text-zinc-100">
          {incident.match ? matchToString(incident.match) : "Non-Match"}
        </span>
      </div>

      <div className="bg-zinc-800/60 p-3 rounded-md border border-zinc-800 text-zinc-100 whitespace-pre-wrap">
        {incident.notes}
        {import.meta.env.DEV ? (
          <span className="block font-mono text-xs text-zinc-500 mt-1">{incident.id}</span>
        ) : null}
      </div>

      {incident.assets && incident.assets.length > 0 && (
        <div>
          <h3 className="text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-2">Attached Images</h3>
          <div className="grid grid-cols-4 gap-3">
            {incident.assets.map((asset) => (
              <AssetPreview
                key={asset}
                asset={asset}
                owner={incident.consistency?.outcome?.peer}
                uploadedAt={incident.time}
              />
            ))}
          </div>
        </div>
      )}

      {incident.rules && incident.rules.length > 0 && (
        <div>
          <h3 className="text-xs font-semibold uppercase tracking-wider text-zinc-400 mb-2">Associated Rules</h3>
          {incident.rules
            .map((rule) => rules?.rulesLookup?.[rule])
            .map((rule) =>
              rule ? (
                <RulesDisplay key={rule.rule} rule={rule} className="mt-2" />
              ) : null
            )}
        </div>
      )}

      {incident.flags?.includes("judge") && (
        <div className="mt-4">
          <Warning message="Flagged for Judging" />
        </div>
      )}

      {(contactName || formattedDate) && (
        <div className="bg-zinc-800/60 border border-zinc-800 rounded-lg p-3.5 shadow-sm flex flex-wrap items-center justify-between gap-3 text-sm">
          {contactName && (
            <div className="flex items-center gap-2 text-zinc-200">
              <UserCircleIcon className="h-5 w-5 text-emerald-400 flex-shrink-0" />
              <span>
                <span className="text-zinc-400 font-medium mr-1">
                  Created by:
                </span>
                <span className="font-semibold text-zinc-100">
                  {contactName}
                </span>
              </span>
            </div>
          )}
          {formattedDate && (
            <div className="flex items-center gap-2 text-zinc-200">
              <ClockIcon className="h-5 w-5 text-emerald-400 flex-shrink-0" />
              <span>
                <span className="text-zinc-400 font-medium mr-1">
                  Date/Time created:
                </span>
                <span className="font-semibold text-zinc-100">
                  {formattedDate}
                </span>
              </span>
            </div>
          )}
        </div>
      )}

      <div className="pt-4 border-t border-zinc-800 space-y-3">
        {confirmUndelete ? (
          <div className="flex gap-2">
            <Button
              mode="dangerous"
              className="flex-1 text-center"
              disabled={isUndeletePending}
              onClick={onUndelete}
            >
              Are you sure?
            </Button>
            <Button
              mode="normal"
              className="flex-1 text-center"
              onClick={() => setConfirmUndelete(false)}
            >
              Cancel
            </Button>
          </div>
        ) : (
          <div className="space-y-3">
            <LinkButton
              to="/$sku/entry/$incidentId"
              params={{ sku: sku ?? "", incidentId: id }}
              className="w-full text-center block bg-emerald-600 active:bg-emerald-700 text-white font-semibold"
            >
              Edit Note
            </LinkButton>

            {confirmDelete ? (
              <div className="flex gap-2">
                <Button
                  mode="dangerous"
                  className="flex-1 text-center"
                  disabled={isDeletePending}
                  onClick={onDelete}
                >
                  Are you sure?
                </Button>
                <Button
                  mode="normal"
                  className="flex-1 text-center"
                  onClick={() => setConfirmDelete(false)}
                >
                  Cancel
                </Button>
              </div>
            ) : (
              <Button
                mode="dangerous"
                className="w-full text-center"
                onClick={onDelete}
              >
                Delete Note
              </Button>
            )}
          </div>
        )}

        <LinkButton
          to="/$sku/entry/$incidentId/history"
          params={{ sku: sku ?? "", incidentId: id }}
          className="w-full text-center block"
        >
          View Note History
        </LinkButton>
      </div>
    </div>
  );
};

export const Route = createFileRoute("/$sku/entry/$incidentId/view")({
  component: NotePreviewPage,
});
