import { useState, useCallback } from "react";
import { twMerge } from "tailwind-merge";
import { useNavigate } from "@tanstack/react-router";
import {
  IncidentOutcome,
  Incident as IncidentData,
  matchToString,
} from "~utils/data/incident";
import { useCurrentEvent } from "~utils/hooks/state";
import { useRulesForEvent } from "~utils/hooks/rules";
import { useEventTeam } from "~utils/hooks/vexevents";
import { ButtonProps, Button, LinkButton, IconButton } from "./Button";
import { usePeerUserName } from "~utils/data/share";
import { UserCircleIcon } from "@heroicons/react/24/outline";
import { Warning } from "./Warning";
import { AssetPreview } from "./Assets";
import { CameraIcon, EllipsisVerticalIcon, FlagIcon, ChevronLeftIcon } from "@heroicons/react/20/solid";
import { RulesDisplay } from "./Input";
import { useDeleteIncident, useUndeleteIncident } from "~utils/hooks/incident";
import { toast } from "./Toast";

const IncidentOutcomeBackgroundClasses: { [O in IncidentOutcome]: string } = {
  Minor: "bg-yellow-400 text-yellow-900",
  Major: "bg-red-400 text-red-900",
  Disabled: "bg-blue-400 text-blue-900",
  General: "bg-zinc-300 text-zinc-900",
  Inspection: "bg-zinc-300 text-zinc-900",
};

export type IncidentProps = {
  incident: IncidentData;
  readonly?: boolean;
  allowUndelete?: boolean;
} & ButtonProps;

export type IncidentHighlightProps = {
  incident: IncidentData;
};

export const IncidentHighlights: React.FC<IncidentHighlightProps> = ({
  incident,
}) => {
  const { data: eventData } = useCurrentEvent();
  const { data: game } = useRulesForEvent(eventData);

  const firstRule = incident.rules[0];
  const firstRuleIcon = game?.rulesLookup?.[firstRule]?.icon;

  return (
    <>
      <span key={`${incident.id}-name`}>{incident.team}</span>
      {"•"}
      <span key={`${incident.id}-match`}>
        {incident.match ? matchToString(incident.match) : "Non-Match"}
      </span>
      {"•"}
      <span className="flex gap-x-1">
        {firstRuleIcon && (
          <img
            alt="Icon"
            className="max-h-5 max-w-5 object-contain"
            src={firstRuleIcon}
          ></img>
        )}
        <span>{firstRule}</span>
      </span>
      {incident.rules.length >= 2 ? (
        <span>+ {incident.rules.length - 1}</span>
      ) : null}
      {incident.rules.length > 0 ? "•" : null}
      <span key={`${incident.id}-outcome`}>{incident.outcome}</span>
      {incident.assets && incident.assets.length > 0 ? (
        <>
          {"•"}
          <span
            className="inline-flex items-center gap-0.5"
            title={`${incident.assets.length} photo${incident.assets.length > 1 ? "s" : ""} attached`}
          >
            <CameraIcon className="h-4 w-4 inline-block opacity-80" />
            {incident.assets.length > 1 ? (
              <span className="text-xs font-semibold">{incident.assets.length}</span>
            ) : null}
          </span>
        </>
      ) : null}
      {incident.flags?.includes("judge") ? (
        <>
          {"•"}
          <span
            className="inline-flex items-center"
            title="Flagged for Judging"
          >
            <FlagIcon className="h-4 w-4 inline-block opacity-80" />
          </span>
        </>
      ) : null}
    </>
  );
};

export const Incident: React.FC<IncidentProps> = ({
  incident,
  readonly,
  allowUndelete,
  ...props
}) => {
  const navigate = useNavigate();
  const { data: event } = useCurrentEvent();

  const onClick = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      navigate({
        to: "/$sku/entry/$incidentId/view",
        params: {
          sku: event?.sku ?? incident.event ?? "",
          incidentId: incident.id,
        },
      });
    },
    [navigate, event, incident]
  );

  return (
    <button
      type="button"
      onClick={onClick}
      {...props}
      className={twMerge(
        IncidentOutcomeBackgroundClasses[incident.outcome],
        "px-4 py-2 rounded-md mt-2 flex relative w-full text-left cursor-pointer active:opacity-80 transition-opacity",
        props.className
      )}
    >
      <div className="flex-auto overflow-hidden">
        <div className="text-sm whitespace-nowrap">
          <div className="flex items-center gap-x-1">
            <IncidentHighlights incident={incident} />
          </div>
        </div>
        <p>
          {incident.notes}
          {import.meta.env.DEV ? (
            <span className="font-mono text-sm">{incident.id}</span>
          ) : null}
        </p>
      </div>
      <div className="w-5 absolute right-2 h-full top-0 flex items-center">
        <EllipsisVerticalIcon height={20} className="text-zinc-950/80 h-5" />
      </div>
    </button>
  );
};

export type IncidentMenuProps = {
  incident: IncidentData;
  readonly?: boolean;
  allowUndelete?: boolean;
  onClose?: () => void;
};

export const IncidentMenu: React.FC<IncidentMenuProps> = ({
  incident,
  readonly,
  allowUndelete,
  onClose,
}) => {
  const { data: event } = useCurrentEvent();
  const { data: team } = useEventTeam(event, incident.team);

  const { data: rules } = useRulesForEvent(event);

  const contactName = usePeerUserName(incident.consistency.outcome.peer);
  const date = new Date(incident.consistency.outcome.instant);

  const { mutateAsync: undeleteIncident, isPending: isUndeletePending } =
    useUndeleteIncident();

  const { mutateAsync: deleteIncident, isPending: isDeletePending } =
    useDeleteIncident();
  const [confirmDelete, setConfirmDelete] = useState(false);

  const onUndelete = useCallback(
    async (e: React.MouseEvent) => {
      e.stopPropagation();

      try {
        await undeleteIncident(incident);
        toast({ type: "info", message: "Undeleted Note" });
        onClose?.();
      } catch (err) {
        toast({
          type: "error",
          message: "Could not undelete note!",
          context: JSON.stringify(err),
        });
      }
    },
    [incident, undeleteIncident, onClose]
  );

  const onDelete = useCallback(
    async (e: React.MouseEvent) => {
      e.stopPropagation();
      if (!confirmDelete) {
        setConfirmDelete(true);
        return;
      }

      try {
        await deleteIncident(incident.id);
        toast({ type: "info", message: "Deleted Note" });
        onClose?.();
      } catch (err) {
        toast({
          type: "error",
          message: "Could not delete note!",
          context: JSON.stringify(err),
        });
      }
    },
    [confirmDelete, incident.id, deleteIncident, onClose]
  );

  return (
    <>
      <header className="flex items-center gap-3 h-[56px] py-2 px-3 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm w-full min-w-0">
        <IconButton
          onClick={onClose}
          icon={<ChevronLeftIcon height={20} />}
          className="p-1.5 px-2.5 bg-zinc-800 hover:bg-zinc-700/80 active:bg-zinc-700 rounded-md border border-zinc-700/60 transition-colors aspect-auto"
          aria-label="Back"
        />
        <h1 className="text-xl font-bold font-mono tracking-tight text-zinc-100 overflow-hidden whitespace-nowrap text-ellipsis flex-1 min-w-0">
          Note Preview
        </h1>
      </header>

      <div className="flex-1 overflow-y-auto min-h-0 min-w-0 p-4 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm space-y-4">
        <div className="flex items-center gap-x-1 justify-between text-sm">
          {contactName ? (
            <span className="flex items-center gap-1.5 text-zinc-300">
              <UserCircleIcon height={20} className="text-emerald-400" />
              <span className="inline font-medium">{contactName}</span>
            </span>
          ) : (
            <span></span>
          )}
          <span className="text-zinc-400 font-mono text-xs">
            {date.toLocaleDateString(undefined, {
              month: "2-digit",
              day: "2-digit",
              year: "2-digit",
            })}
            {" • "}
            {date.toLocaleTimeString(undefined, {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </span>
        </div>

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
      </div>

      <footer className="bg-zinc-900 border border-zinc-800 rounded-lg p-3.5 shadow-sm flex-shrink-0">
        {allowUndelete ? (
          <Button
            mode="primary"
            className="w-full text-center"
            disabled={isUndeletePending}
            onClick={onUndelete}
          >
            Undelete Note
          </Button>
        ) : readonly ? null : confirmDelete ? (
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
              onClick={(e) => {
                e.stopPropagation();
                setConfirmDelete(false);
              }}
            >
              Cancel
            </Button>
          </div>
        ) : (
          <div className="flex gap-2">
            <Button
              mode="dangerous"
              className="flex-1 text-center"
              onClick={onDelete}
            >
              Delete Note
            </Button>
            <LinkButton
              to="/$sku/entry/$incidentId"
              params={{ sku: event?.sku ?? "", incidentId: incident.id }}
              className="flex-1 text-center bg-emerald-600 active:bg-emerald-700 text-white"
            >
              Edit Note
            </LinkButton>
          </div>
        )}
      </footer>
    </>
  );
};

