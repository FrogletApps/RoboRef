import { useMemo, useState } from "react";
import { EventData } from "@roboref/vexevents";
import { Spinner } from "~components/Spinner";
import { useEventIncidents } from "~utils/hooks/incident";
import { useDivisionTeams } from "~utils/hooks/vexevents";
import { useCurrentDivision } from "~utils/hooks/state";
import { ExclamationTriangleIcon, FlagIcon, InformationCircleIcon } from "@heroicons/react/20/solid";
import { VirtualizedList } from "~components/VirtualizedList";
import { IconLabel, Input } from "~components/Input";
import { filterTeams } from "~utils/filterteams";
import { MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { LinkButton } from "~components/Button";
import { DisconnectedWarning } from "~components/DisconnectedWarning";

export type EventTagProps = {
  event: EventData;
};

export const EventTeamsTab: React.FC<EventTagProps> = ({ event }) => {
  const division = useCurrentDivision();
  const {
    data: divisionTeams,
    isLoading,
    isPaused,
  } = useDivisionTeams(event, division);
  const { data: incidents } = useEventIncidents(event.sku);
  const [filter, setFilter] = useState("");

  const teams = useMemo(() => divisionTeams?.teams ?? [], [divisionTeams]);

  const majorIncidents = useMemo(() => {
    if (!incidents) return new Map<string, number>();

    const grouped = new Map<string, number>();

    for (const incident of incidents) {
      if (incident.outcome !== "Major") continue;
      const key = incident.team ?? "<none>";
      const count = grouped.get(key) ?? 0;
      grouped.set(key, count + 1);
    }

    return grouped;
  }, [incidents]);

  const minorIncidents = useMemo(() => {
    if (!incidents) return new Map<string, number>();

    const grouped = new Map<string, number>();

    for (const incident of incidents) {
      if (incident.outcome === "Major") continue;
      const key = incident.team ?? "<none>";
      const count = grouped.get(key) ?? 0;
      grouped.set(key, count + 1);
    }

    return grouped;
  }, [incidents]);

  const filteredTeams = useMemo(
    () => (teams ? filterTeams(teams, filter) : []),
    [filter, teams]
  );

  return (
    <section className="contents">
      <DisconnectedWarning />
      <IconLabel icon={<MagnifyingGlassIcon height={24} />}>
        <Input
          placeholder="Search teams..."
          className="flex-1"
          value={filter}
          onChange={(e) => setFilter(e.currentTarget.value)}
        />
      </IconLabel>
      <Spinner show={isLoading || isPaused} />
      <VirtualizedList
        data={filteredTeams}
        options={{ estimateSize: () => 64 }}
        className="flex-1"
        parts={{
          list: { className: "divide-y divide-zinc-700 border-y border-zinc-700 mt-2 mb-12" },
          item: { className: "border-b border-zinc-700 w-full h-full flex items-center" },
        }}
      >
        {(team) => (
          <LinkButton
            to={"/$sku/team/$team"}
            params={{ sku: event.sku, team: team.number }}
            className="w-full h-full bg-transparent rounded-none py-3 text-left flex items-center justify-between gap-4 p-0 text-zinc-50 active:bg-zinc-800/50"
            aria-label={`Team ${team.number} ${team.team_name}. ${
              majorIncidents.get(team.number) ?? 0
            } major violations. ${
              minorIncidents.get(team.number) ?? 0
            } minor violations`}
          >
            <div className="flex-1 min-w-0 flex flex-col justify-center">
              <p className="text-sm font-mono text-emerald-400 whitespace-nowrap text-ellipsis overflow-hidden w-full">
                {team.number}
              </p>
              <p className="whitespace-nowrap text-ellipsis overflow-hidden w-full">
                {team.team_name}
              </p>
            </div>
            <div className="flex items-center gap-3 shrink-0 px-2">
              <span className="text-red-400 flex items-center" aria-label={``}>
                <FlagIcon height={20} className="inline" />
                <span className="font-mono ml-1.5">
                  {majorIncidents.get(team.number) ?? 0}
                </span>
              </span>
              <span className="text-yellow-400 flex items-center">
                <ExclamationTriangleIcon height={20} className="inline" />
                <span className="font-mono ml-1.5">
                  {minorIncidents.get(team.number) ?? 0}
                </span>
              </span>
              <span className="bg-blue-600 active:bg-blue-700 text-white text-xs font-semibold px-2.5 py-1.5 rounded-md flex items-center gap-1 shadow-sm ml-1">
                <InformationCircleIcon height={16} width={16} className="inline" />
                <span>Info</span>
              </span>
            </div>
          </LinkButton>
        )}
      </VirtualizedList>
    </section>
  );
};
