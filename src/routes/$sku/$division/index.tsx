import { useCurrentEvent } from "~hooks/state";
import { useCallback, useEffect, useState } from "react";
import { useAddEventVisited } from "~utils/hooks/history";
import { EventTab } from "./-tabs/event";
import { EventTeamsTab } from "./-tabs/teams";
import { EventMatchesTab } from "./-tabs/matches";
import { EventManageTab } from "./-tabs/manage";
import { EventRulesTab } from "./-tabs/rules";


import { NumberedListIcon as ScheduleIconOutline } from "@heroicons/react/24/outline";
import { NumberedListIcon as ScheduleIconSolid } from "@heroicons/react/24/solid";

import { PlayIcon as MatchesIconOutline } from "@heroicons/react/24/outline";
import { PlayIcon as MatchesIconSolid } from "@heroicons/react/24/solid";

import { UserGroupIcon as TeamsIconOutline } from "@heroicons/react/24/outline";
import { UserGroupIcon as TeamsIconSolid } from "@heroicons/react/24/solid";

import { CloudIcon as ManageIconOutline } from "@heroicons/react/24/outline";
import { CloudIcon as ManageIconSolid } from "@heroicons/react/24/solid";

import { BookOpenIcon as RulesIconOutline } from "@heroicons/react/24/outline";
import { BookOpenIcon as RulesIconSolid } from "@heroicons/react/24/solid";
import { Tabs } from "~components/Tabs";
import { createFileRoute, useRouter } from "@tanstack/react-router";

export type EventHomeSearch = {
  match?: number;
};

const EventHome: React.FC = () => {
  const { data: event } = useCurrentEvent();
  const { mutateAsync: addEvent, isSuccess } = useAddEventVisited();
  const search = Route.useSearch();
  const [selectedMatchId, setSelectedMatchId] = useState<number | undefined>(
    search.match
  );
  const router = useRouter();

  useEffect(() => {
    if (search.match !== undefined) {
      setSelectedMatchId(search.match);
    }
  }, [search.match]);

  useEffect(() => {
    if (event && !isSuccess) {
      addEvent(event);
    }
  }, [event, isSuccess, addEvent]);

  const onSelectMatch = useCallback(
    (matchId: number) => {
      setSelectedMatchId(matchId);
      const tabId = "/$sku/$division/-EventHome";
      router.navigate({
        state: (state) => ({
          ...state,
          tabActive: tabId,
          tabState: { ...state.tabState, [tabId]: { tab: 1 } },
        }),
        replace: false,
      });
    },
    [router]
  );

  return event ? (
    <section className="mt-2 flex flex-col flex-1 h-full min-h-0 relative">
      <Tabs
        id={["/$sku/$division/", "EventHome"]}
        className="flex-1"
        parts={{
          tablist: {
            className: "absolute bottom-0 right-0 left-0 z-30 p-0 bg-zinc-900",
          },
        }}
      >
        {[
          {
            type: "content",
            id: "event",
            label: "Schedule",
            icon: (active) =>
              active ? (
                <ScheduleIconSolid height={24} className="inline" />
              ) : (
                <ScheduleIconOutline height={24} className="inline" />
              ),
            content: (
              <EventTab event={event} onSelectMatch={onSelectMatch} />
            ),
          },
          {
            type: "content",
            id: "matches",
            label: "Matches",
            icon: (active) =>
              active ? (
                <MatchesIconSolid height={24} className="inline" />
              ) : (
                <MatchesIconOutline height={24} className="inline" />
              ),
            content: (
              <EventMatchesTab
                event={event}
                initialMatchId={selectedMatchId}
                key={selectedMatchId}
              />
            ),
          },
          {
            type: "content",
            id: "team",
            label: "Teams",
            icon: (active) =>
              active ? (
                <TeamsIconSolid height={24} className="inline" />
              ) : (
                <TeamsIconOutline height={24} className="inline" />
              ),
            content: <EventTeamsTab event={event} />,
          },
          {
            type: "content",
            id: "rules",
            label: "Rules",
            icon: (active) =>
              active ? (
                <RulesIconSolid height={24} className="inline" />
              ) : (
                <RulesIconOutline height={24} className="inline" />
              ),
            content: <EventRulesTab event={event} />,
          },
          {
            type: "content",
            id: "manage",
            label: "Manage",
            icon: (active) =>
              active ? (
                <ManageIconSolid height={24} className="inline" />
              ) : (
                <ManageIconOutline height={24} className="inline" />
              ),
            content: <EventManageTab event={event} />,
          },
        ]}
      </Tabs>
    </section>
  ) : null;
};

export const Route = createFileRoute("/$sku/$division/")({
  component: EventHome,
  validateSearch: (search: Record<string, unknown>): EventHomeSearch => ({
    match:
      typeof search.match === "number"
        ? search.match
        : typeof search.match === "string" && !isNaN(parseInt(search.match, 10))
        ? parseInt(search.match, 10)
        : undefined,
  }),
});
