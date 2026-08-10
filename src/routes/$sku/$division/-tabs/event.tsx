import { useCallback, useMemo } from "react";
import { EventData } from "@roboref/robotevents";
import { useEventMatches } from "~utils/hooks/robotevents";
import { useCurrentDivision } from "~utils/hooks/state";
import { Spinner } from "~components/Spinner";
import { ClickableMatch, MatchTime } from "~components/Match";
import { Button, ExternalLinkButton } from "~components/Button";
import { ArrowRightIcon, GlobeAltIcon } from "@heroicons/react/24/outline";
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
      className="text-left flex gap-2 items-center bg-zinc-700 absolute bottom-16 left-0 z-10 w-full h-12 rounded-b-none"
      data-matchid={match?.id}
      onClick={onClickMatch}
      aria-label={`Jump to Match ${match?.name}`}
    >
      <span className="flex-1">Current Match: {match?.name}</span>
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
  const { data: matches, isLoading } = useEventMatches(event, division);
  const navigate = useNavigate();

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
    <>
      <UpcomingMatch event={event} onClickMatch={onClickMatch} />
      <section className="contents">
        <Spinner show={isLoading} />
        <DisconnectedWarning />
        <VirtualizedList
          data={matches}
          header={
            <ExternalLinkButton
              href={`https://events.vex.com/${event.sku}.html`}
              className="w-full text-center mb-2 bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-medium flex items-center justify-center gap-2"
            >
              <GlobeAltIcon height={20} />
              <span>View VEX Events page</span>
            </ExternalLinkButton>
          }
          options={{ estimateSize: () => 64 }}
          className="flex-1"
          parts={{
            list: { className: "mb-24" },
            item: { className: "w-full h-full flex items-center" },
          }}
        >
          {(match) => <ClickableMatch match={match} onClick={onClickMatch} />}
        </VirtualizedList>
      </section>
    </>
  );
};
