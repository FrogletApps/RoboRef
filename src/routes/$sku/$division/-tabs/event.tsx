import { useCallback, useLayoutEffect, useMemo, useRef, useState } from "react";
import { EventData, TeamData } from "@roboref/vexevents";
import { useEventMatches, useEventTeams } from "~utils/hooks/vexevents";
import { useCurrentDivision } from "~utils/hooks/state";
import { Spinner } from "~components/Spinner";
import { ClickableMatch, MatchTime } from "~components/Match";
import { Button, ExternalLinkButton } from "~components/Button";
import {
  ArrowRightIcon,
  ExclamationCircleIcon,
  GlobeAltIcon,
  MagnifyingGlassIcon,
  NumberedListIcon,
} from "@heroicons/react/24/outline";
import { IconLabel, Input } from "~components/Input";
import { VirtualizedList } from "~components/VirtualizedList";
import { DisconnectedWarning } from "~components/DisconnectedWarning";
import { useNavigate } from "@tanstack/react-router";

export type UpcomingMatchProps = {
  event: EventData;
  onClickMatch: (e: React.MouseEvent<HTMLButtonElement>) => void;
};

export const UpcomingMatch: React.FC<UpcomingMatchProps> = ({
  event,
  onClickMatch,
}) => {
  const division = useCurrentDivision();
  const { data: matches } = useEventMatches(event, division);

  const match = useMemo(
    () =>
      matches?.find(
        (m) => !m.started && m.alliances.every((a) => a.score === 0)
      ),
    [matches]
  );

  if (!match) {
    return null;
  }

  return (
    <Button
      mode="normal"
      className="text-left flex gap-2 items-center bg-zinc-700 w-full h-11 rounded-md px-3"
      data-matchid={match?.id}
      onClick={onClickMatch}
      aria-label={`Jump to Match ${match?.name}`}
    >
      <span className="flex-1 text-sm font-medium">Current Match: {match?.name}</span>
      <MatchTime match={match} />
      <ArrowRightIcon height={20} />
    </Button>
  );
};

export type EventTabProps = {
  event: EventData;
  onSelectMatch?: (matchId: number) => void;
};

export const EventTab: React.FC<EventTabProps> = ({
  event,
  onSelectMatch,
}) => {
  const division = useCurrentDivision();
  const { data: matches, isLoading, isError } = useEventMatches(event, division);
  const { data: eventTeams } = useEventTeams(event);
  const navigate = useNavigate();
  const [filter, setFilter] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);
  const [bottomPadding, setBottomPadding] = useState(120);

  useLayoutEffect(() => {
    const el = bottomRef.current;
    if (!el) return;
    setBottomPadding(48 + el.offsetHeight);
    const observer = new ResizeObserver(() => {
      setBottomPadding(48 + el.offsetHeight);
    });
    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  const teamInfoMap = useMemo(() => {
    const map = new Map<
      string,
      { team_name?: string; organization?: string }
    >();
    if (eventTeams) {
      for (const team of eventTeams) {
        if (team.number) {
          map.set(team.number.toLowerCase(), {
            team_name: team.team_name,
            organization: team.organization,
          });
        }
      }
    }
    return map;
  }, [eventTeams]);

  const filteredMatches = useMemo(() => {
    if (!matches) return [];
    if (!filter.trim()) return matches;

    const qRaw = filter.trim().toLowerCase();
    const qNorm = qRaw.replace(/[^a-z0-9]/g, "");

    return matches.filter((match) => {
      const matchNameRaw = (match.name ?? "").toLowerCase();
      const shortNameRaw = (match.shortName ? match.shortName() : "").toLowerCase();
      const matchIdStr = match.id?.toString() ?? "";

      // Raw match name/ID check
      if (
        matchNameRaw.includes(qRaw) ||
        shortNameRaw.includes(qRaw) ||
        matchIdStr === qRaw
      ) {
        return true;
      }

      // Normalized match name/ID check (e.g. "F 1" matches "F1")
      if (qNorm.length > 0) {
        const matchNameNorm = matchNameRaw.replace(/[^a-z0-9]/g, "");
        const shortNameNorm = shortNameRaw.replace(/[^a-z0-9]/g, "");
        if (
          matchNameNorm.includes(qNorm) ||
          shortNameNorm.includes(qNorm) ||
          matchIdStr === qNorm
        ) {
          return true;
        }
      }

      // Check team number, team name, and school/organization
      return match.alliances?.some((alliance) =>
        alliance.teams?.some((t) => {
          const teamNumRaw = (t.team?.name || "").toLowerCase();
          if (!teamNumRaw) return false;

          const teamNumNorm = teamNumRaw.replace(/[^a-z0-9]/g, "");
          if (
            teamNumRaw.includes(qRaw) ||
            (qNorm.length > 0 && teamNumNorm.includes(qNorm))
          ) {
            return true;
          }

          const info = teamInfoMap.get(teamNumRaw);
          const teamName = (
            (t.team as { team_name?: string })?.team_name ||
            info?.team_name ||
            ""
          ).toLowerCase();
          const orgName = (
            (t.team as { organization?: string })?.organization ||
            info?.organization ||
            ""
          ).toLowerCase();

          if (
            teamName.includes(qRaw) ||
            orgName.includes(qRaw) ||
            (qNorm.length > 0 &&
              (teamName.replace(/[^a-z0-9]/g, "").includes(qNorm) ||
                orgName.replace(/[^a-z0-9]/g, "").includes(qNorm)))
          ) {
            return true;
          }

          return false;
        })
      );
    });
  }, [matches, filter, teamInfoMap]);

  const onClickMatch = useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      const matchIdStr = e.currentTarget.dataset.matchid;
      if (!matchIdStr || isNaN(parseInt(matchIdStr, 10))) return;
      const matchId = parseInt(matchIdStr, 10);
      if (onSelectMatch) {
        onSelectMatch(matchId);
      } else {
        navigate({
          to: "/$sku/match/$matchId",
          params: { sku: event.sku, matchId: matchIdStr },
        });
      }
    },
    [event.sku, navigate, onSelectMatch]
  );

  return (
    <div className="flex flex-col h-full min-h-0 relative overflow-hidden">
      <div className="flex flex-col flex-shrink-0 z-10 w-full px-1 pt-1 border-b border-zinc-700">
        <IconLabel icon={<MagnifyingGlassIcon height={24} />}>
          <Input
            placeholder="Search team, school, or match..."
            className="flex-1"
            value={filter}
            onChange={(e) => setFilter(e.currentTarget.value)}
          />
        </IconLabel>
        <div className="flex items-center justify-center py-2.5 px-3 text-center w-full">
          <p className="text-sm text-zinc-400 text-center w-full">
            Tap on a match to show more info
          </p>
        </div>
      </div>

      <div className="flex-1 min-h-0 relative">
        <Spinner show={isLoading} />
        <DisconnectedWarning />
        {!isLoading && isError ? (
          <div className="flex-1 h-full flex flex-col items-center justify-center p-6 text-center text-zinc-400 gap-2">
            <ExclamationCircleIcon className="w-10 h-10 text-zinc-500" />
            <p className="text-base font-semibold text-zinc-200">
              Data could not be loaded from VEX Events.
            </p>
            <p className="text-xs text-zinc-400 max-w-xs">
              Please check your internet connection or try again later.
            </p>
          </div>
        ) : !isLoading && (!matches || matches.length === 0) ? (
          <div className="flex-1 h-full flex flex-col items-center justify-center p-6 text-center text-zinc-400 gap-2">
            <NumberedListIcon className="w-10 h-10 text-zinc-500" />
            <p className="text-base font-semibold text-zinc-200">
              No matches scheduled yet
            </p>
            <p className="text-xs text-zinc-400 max-w-xs">
              Matches will appear here once the schedule is published.
            </p>
          </div>
        ) : !isLoading && filteredMatches.length === 0 ? (
          <div className="flex-1 h-full flex flex-col items-center justify-center p-6 text-center text-zinc-400 gap-2">
            <MagnifyingGlassIcon className="w-10 h-10 text-zinc-500" />
            <p className="text-base font-medium text-zinc-300">
              No matches found matching &ldquo;{filter}&rdquo;
            </p>
          </div>
        ) : (
          <VirtualizedList
            data={filteredMatches}
            options={{ estimateSize: () => 64 }}
            paddingBottom={bottomPadding}
            className="h-full"
            parts={{
              item: { className: "w-full h-full flex items-center" },
            }}
          >
            {(match) => <ClickableMatch match={match} onClick={onClickMatch} />}
          </VirtualizedList>
        )}
      </div>

      <div
        ref={bottomRef}
        className="fixed bottom-16 left-0 right-0 z-20 px-5 py-2 bg-zinc-900/80 backdrop-blur-sm flex flex-col gap-2"
      >
        <UpcomingMatch event={event} onClickMatch={onClickMatch} />
        <ExternalLinkButton
          href={`https://events.vex.com/${event.sku}.html`}
          className="w-full bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white flex items-center justify-center gap-1.5 px-2 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0 rounded-md shadow-md"
        >
          <GlobeAltIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
          <span>View VEX Events page</span>
        </ExternalLinkButton>
      </div>
    </div>
  );
};
