import { Button, ButtonProps } from "~components/Button";
import {
  ChevronDownIcon,
  ChevronRightIcon,
  DocumentTextIcon,
} from "@heroicons/react/20/solid";
import { useMemo, useState } from "react";
import { twMerge } from "tailwind-merge";
import { useTeamIncidentsByMatch } from "~utils/hooks/incident";
import { Incident as IncidentData } from "~utils/data/incident";
import { Match } from "@roboref/robotevents";
import { Incident } from "~components/Incident";
import { MatchScratchpad } from "~components/scratchpad/Scratchpad";
import { NoteSummaryPills, RulesSummary } from "~components/RulesSummary";
import { useNavigate } from "@tanstack/react-router";
import { useCurrentEvent } from "~utils/hooks/state";

type TeamSummaryProps = {
  number: string;
  match: Match;
  incidents: IncidentData[];
};

const TeamSummary: React.FC<TeamSummaryProps> = ({
  number,
  match,
  incidents,
}) => {
  const [open, setOpen] = useState(false);

  const teamAlliance = match.alliances.find((alliance) =>
    alliance.teams.some((t) => t.team?.name === number)
  );

  const hasGeneral = useMemo(() => {
    return incidents.some((incident) => incident.outcome === "General");
  }, [incidents]);

  return (
    <details open={open} onToggle={(e) => setOpen(e.currentTarget.open)}>
      <summary className="flex gap-2 items-center active:bg-zinc-700 max-w-full mt-0 sticky top-0 bg-zinc-900 h-16 z-10 px-2 min-w-0 overflow-hidden">
        {open ? (
          <ChevronDownIcon height={16} width={16} className="flex-shrink-0" />
        ) : (
          <ChevronRightIcon height={16} width={16} className="flex-shrink-0" />
        )}
        <div
          className={twMerge(
            "py-1 px-2 rounded-md font-mono flex-shrink-0",
            teamAlliance?.color === "red" ? "text-red-400" : "text-blue-400"
          )}
        >
          <p>
            {number}
            <span className="text-zinc-300">{hasGeneral ? "*" : ""}</span>
          </p>
        </div>
        <RulesSummary
          className="min-w-0 flex-1 flex-shrink overflow-hidden"
          incidents={incidents}
          filter={(i) => i.outcome !== "General" && i.match?.type !== "skills"}
        />
        <TeamFlagButton match={match} team={number} />
      </summary>
      {/* For performance - don't render Incidents unless the dialog is open */}
      {open ? (
        <div className="p-2 bg-zinc-900/50">
          {incidents.length > 0 ? (
            <>
              <NoteSummaryPills incidents={incidents} />
              {incidents.map((incident) => (
                <Incident
                  className="max-h-20 overflow-hidden"
                  incident={incident}
                  key={incident.id}
                />
              ))}
              <div className="mt-2 flex justify-end">
                <TeamFlagButton match={match} team={number} />
              </div>
            </>
          ) : (
            <p className="p-2 text-sm text-zinc-400 italic">No notes recorded!</p>
          )}
        </div>
      ) : null}
    </details>
  );
};

export type TeamFlagButtonProps = {
  match?: Match;
  team: string;
} & ButtonProps;

export const TeamFlagButton: React.FC<TeamFlagButtonProps> = ({
  match,
  team,
  ...props
}) => {
  const { data: event } = useCurrentEvent();
  const navigate = useNavigate();

  return (
    <Button
      mode="primary"
      {...props}
      className={twMerge(
        "flex items-center w-max whitespace-nowrap flex-shrink-0 my-2 mr-2",
        props.className
      )}
      onClick={() =>
        navigate({
          to: "/$sku/new",
          params: { sku: event?.sku ?? "" },
          search: { team, match: match?.id },
          state: (s) => s,
        })
      }
      aria-label={`Add note for ${team}`}
    >
      <DocumentTextIcon height={20} className="mr-2" />
      <span>Add Note</span>
    </Button>
  );
};

export type EventMatchViewProps = {
  match?: Match | null;
};

export const EventMatchView: React.FC<EventMatchViewProps> = ({ match }) => {
  const { data: incidentsByTeam } = useTeamIncidentsByMatch(match, {
    placeholderData: (previousData) => {
      if (previousData) {
        return previousData;
      }
      if (!match) {
        return [];
      }

      const matchObj = new Match(match);
      const teams = matchObj.alliances
        .flatMap((a) => a.teams.map((t) => t.team?.name))
        .filter((t): t is string => !!t);

      return teams.map((team) => ({ team, incidents: [] }));
    },
  });

  if (!match) {
    return null;
  }

  return (
    <div className="mt-4 mx-2 contents">
      {incidentsByTeam?.map(({ team: number, incidents }) => (
        <TeamSummary
          key={number}
          incidents={incidents}
          match={match}
          number={number}
        />
      ))}
      <MatchScratchpad match={match} />
    </div>
  );
};
