import { Button, ButtonProps } from "~components/Button";
import {
  FlagIcon,
  ChevronDownIcon,
  ChevronRightIcon,
} from "@heroicons/react/20/solid";
import { useMemo, useState } from "react";
import { twMerge } from "tailwind-merge";
import { useTeamIncidentsByMatch } from "~utils/hooks/incident";
import { EventNewIncidentDialog } from "./new";
import { Incident as IncidentData } from "~utils/data/incident";
import { Match } from "@referee-fyi/robotevents";
import { Incident } from "~components/Incident";
import { TeamIsolationDialog } from "./team";
import { ArrowsPointingOutIcon } from "@heroicons/react/24/outline";
import { MatchScratchpad } from "~components/scratchpad/Scratchpad";
import { RulesSummary } from "~components/RulesSummary";

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
  const [isolationOpen, setIsolationOpen] = useState(false);

  const teamAlliance = match.alliances.find((alliance) =>
    alliance.teams.some((t) => t.team?.name === number)
  );

  const hasGeneral = useMemo(() => {
    return incidents.some((incident) => incident.outcome === "General");
  }, [incidents]);

  return (
    <details open={open} onToggle={(e) => setOpen(e.currentTarget.open)}>
      <summary className="flex gap-2 items-center active:bg-zinc-700 max-w-full mt-0 sticky top-0 bg-zinc-900 h-16 z-10">
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
          incidents={incidents}
          filter={(i) => i.outcome !== "General" && i.match?.type !== "skills"}
        />
        <TeamFlagButton match={match} team={number} />
      </summary>
      {/* For performance - don't render Incidents unless the dialog is open */}
      {open ? (
        <>
          {incidents.map((incident) => (
            <Incident
              className="max-h-20 overflow-hidden"
              incident={incident}
              key={incident.id}
            />
          ))}
          {incidents.length > 0 ? (
            <>
              <TeamIsolationDialog
                key={number}
                team={number}
                open={isolationOpen}
                setOpen={setIsolationOpen}
              />
              <Button
                mode="normal"
                className="flex gap-2 items-center mt-2 justify-center h-12"
                onClick={() => setIsolationOpen(true)}
              >
                <ArrowsPointingOutIcon height={20} />
                <p>Isolate Team</p>
              </Button>
            </>
          ) : null}
        </>
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
  const [open, setOpen] = useState(false);

  return (
    <>
      <EventNewIncidentDialog
        open={open}
        setOpen={setOpen}
        initial={{ match, team }}
        key={match?.id + team}
      />
      <Button
        mode="primary"
        {...props}
        className={twMerge(
          "flex items-center w-min flex-shrink-0 my-2",
          props.className
        )}
        onClick={() => setOpen(true)}
        aria-label={`New entry for ${team}`}
      >
        <FlagIcon height={20} className="mr-2" />
        <span>New</span>
      </Button>
    </>
  );
};

export type EventMatchViewProps = {
  match?: Match | null;
};
export const EventMatchView: React.FC<EventMatchViewProps> = ({ match }) => {
  const { data: incidentsByTeam } = useTeamIncidentsByMatch(match, {
    initialData: () => {
      if (!match) {
        return [];
      }

      const alliances = [match.alliance("red"), match.alliance("blue")];
      const teams =
        alliances.map((a) => a.teams.map((t) => t.team!.name)).flat() ?? [];

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


