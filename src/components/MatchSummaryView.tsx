import React, { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { EventData } from "@referee-fyi/robotevents";
import { useCurrentDivision, useCurrentEvent } from "~utils/hooks/state";
import { useEventMatches } from "~utils/hooks/robotevents";
import { Spinner } from "~components/Spinner";
import { IconButton } from "~components/Button";
import { ArrowLeftIcon, ArrowRightIcon, ClockIcon } from "@heroicons/react/20/solid";
import { MatchContext } from "~components/Context";
import { MatchTime, useMatchDelta } from "~components/Match";
import { twMerge } from "tailwind-merge";
import { EventMatchView } from "~components/MatchView";
import { animate, PanInfo, useMotionValue } from "motion/react";
import * as m from "motion/react-m";
import { useResizeObserver } from "use-resize-observer";
import { UpcomingMatch } from "../routes/$sku/$division/-tabs/event";

const transition = {
  type: "spring",
  bounce: 0,
} as const;

export type MatchSummaryViewProps = {
  initialMatchId?: number;
  event?: EventData | null;
  division?: number;
};

export const MatchSummaryView: React.FC<MatchSummaryViewProps> = ({
  initialMatchId,
  event: eventProp,
  division: divisionProp,
}) => {
  const { data: currentEvent } = useCurrentEvent();
  const event = eventProp ?? currentEvent;
  const currentDivision = useCurrentDivision();
  const division = divisionProp ?? currentDivision;

  const { data: matches, isLoading } = useEventMatches(event, division);

  const [matchIndex, setMatchIndex] = useState<number>(0);

  const isInitializedRef = useRef(false);
  const prevInitialMatchIdRef = useRef<number | undefined>(initialMatchId);

  useEffect(() => {
    if (!matches || matches.length === 0) return;

    if (
      initialMatchId !== undefined &&
      !isNaN(initialMatchId) &&
      initialMatchId !== prevInitialMatchIdRef.current
    ) {
      prevInitialMatchIdRef.current = initialMatchId;
      const index = matches.findIndex((m) => m.id === initialMatchId);
      if (index !== -1) {
        setMatchIndex(index);
        return;
      }
    }

    if (isInitializedRef.current) return;
    isInitializedRef.current = true;

    if (initialMatchId !== undefined && !isNaN(initialMatchId)) {
      const index = matches.findIndex((m) => m.id === initialMatchId);
      if (index !== -1) {
        setMatchIndex(index);
        return;
      }
    }

    const upcomingIndex = matches.findIndex(
      (m) => !m.started && m.alliances.every((a) => a.score === 0)
    );
    if (upcomingIndex !== -1) {
      setMatchIndex(upcomingIndex);
    } else {
      setMatchIndex(0);
    }
  }, [initialMatchId, matches]);

  const match = useMemo(() => matches?.[matchIndex], [matchIndex, matches]);
  const delta = useMatchDelta(match);

  const hasNextMatch = matchIndex + 1 < (matches?.length ?? Infinity);
  const hasPrevMatch = matchIndex - 1 >= 0;

  const onClickNextMatch = useCallback(() => {
    if (!matches || !hasNextMatch) return;
    setMatchIndex(matchIndex + 1);
  }, [hasNextMatch, matchIndex, matches]);

  const onClickPrevMatch = useCallback(() => {
    if (!matches || !hasPrevMatch) return;
    setMatchIndex(matchIndex - 1);
  }, [hasPrevMatch, matchIndex, matches]);

  const containerRef = useRef<HTMLDivElement>(null);
  const { width: containerWidth = 0 } = useResizeObserver({ ref: containerRef });

  const viewsToRender = [-1, 0, 1];
  const x = useMotionValue(0);

  const onDragEnd = useCallback(
    (_: Event, dragProps: PanInfo) => {
      const { offset, velocity } = dragProps;
      const threshold = containerWidth > 0 ? containerWidth / 6 : 60;

      if (Math.abs(velocity.y) > Math.abs(velocity.x)) {
        animate(x, 0, transition);
        return;
      }

      if (offset.x > threshold) {
        if (hasPrevMatch) {
          onClickPrevMatch();
          x.set(0);
        } else {
          animate(x, 0, transition);
        }
      } else if (offset.x < -threshold) {
        if (hasNextMatch) {
          onClickNextMatch();
          x.set(0);
        } else {
          animate(x, 0, transition);
        }
      } else {
        animate(x, 0, transition);
      }
    },
    [containerWidth, hasNextMatch, hasPrevMatch, onClickNextMatch, onClickPrevMatch, x]
  );

  useEffect(() => {
    x.set(0);
  }, [matchIndex, x]);

  const scheduledTime = useMemo(() => {
    if (!match?.scheduled) return undefined;
    try {
      return new Intl.DateTimeFormat(undefined, {
        hour: "numeric",
        minute: "numeric",
      }).format(new Date(match.scheduled));
    } catch {
      return undefined;
    }
  }, [match?.scheduled]);

  const onClickUpcomingMatch = useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      const matchIdStr = e.currentTarget.dataset.matchid;
      if (!matchIdStr || isNaN(parseInt(matchIdStr, 10))) return;
      const matchId = parseInt(matchIdStr, 10);
      const index = matches?.findIndex((m) => m.id === matchId);
      if (index !== undefined && index !== -1) {
        setMatchIndex(index);
      }
    },
    [matches]
  );

  if (isLoading && !match) {
    return <Spinner show />;
  }

  return (
    <section className="flex-1 flex flex-col max-h-full overflow-hidden mt-4">
      {event && (
        <UpcomingMatch event={event} onClickMatch={onClickUpcomingMatch} />
      )}
      <header className="flex flex-col gap-1.5 p-2 bg-zinc-900 border border-zinc-800 rounded-lg mb-3 flex-shrink-0">
        <div className="grid grid-cols-[auto_1fr_auto] items-center gap-2">
          <IconButton
            icon={
              <ArrowLeftIcon
                height={20}
                className={hasPrevMatch ? "text-zinc-100" : "text-zinc-600 opacity-40"}
              />
            }
            onClick={onClickPrevMatch}
            disabled={!hasPrevMatch}
            aria-label={`Previous Match: ${matches?.[matchIndex - 1]?.name ?? "None"}`}
            className="p-1.5 bg-zinc-800 rounded-md border border-zinc-700/60 aspect-auto shrink-0 disabled:bg-zinc-800 disabled:cursor-not-allowed enabled:hover:bg-zinc-700/80 enabled:active:bg-zinc-700"
          />
          <h1 className="text-xl font-bold font-mono text-zinc-100 text-center truncate px-2">
            {match?.name ?? "Match Summary"}
          </h1>
          <IconButton
            icon={
              <ArrowRightIcon
                height={20}
                className={hasNextMatch ? "text-zinc-100" : "text-zinc-600 opacity-40"}
              />
            }
            onClick={onClickNextMatch}
            disabled={!hasNextMatch}
            aria-label={`Next Match: ${matches?.[matchIndex + 1]?.name ?? "None"}`}
            className="p-1.5 bg-zinc-800 rounded-md border border-zinc-700/60 aspect-auto shrink-0 disabled:bg-zinc-800 disabled:cursor-not-allowed enabled:hover:bg-zinc-700/80 enabled:active:bg-zinc-700"
          />
        </div>
        <div className="flex items-center justify-between gap-2 text-xs sm:text-sm pt-1.5 border-t border-zinc-800/80 px-1">
          <div className="flex items-center gap-1.5 min-w-0">
            <ClockIcon className="h-4 w-4 text-zinc-400 shrink-0" />
            <span className="text-zinc-400 font-medium shrink-0">Scheduled for:</span>
            <span className="text-zinc-100 font-mono whitespace-nowrap">
              {scheduledTime ?? "Not Scheduled"}
            </span>
          </div>
          {delta !== undefined ? (
            <div
              className={twMerge(
                "flex items-center gap-1.5 px-2 py-0.5 rounded-md border text-xs sm:text-sm font-medium shrink-0",
                delta >= 0
                  ? "bg-red-950/40 border-red-800/60 text-red-400"
                  : delta >= -60000
                  ? "bg-yellow-950/40 border-yellow-800/60 text-yellow-400"
                  : "bg-emerald-950/40 border-emerald-800/60 text-emerald-400"
              )}
            >
              <span>{delta < 0 ? "Early by:" : "Late by:"}</span>
              <MatchTime match={match} />
            </div>
          ) : null}
        </div>
      </header>

      <div className="relative flex-1 flex flex-col overflow-hidden">
        <Spinner show={!match} />
        {match ? (
          <MatchContext
            match={match}
            className="mb-4 flex-shrink-0"
            parts={{ alliance: { className: "w-full" } }}
          />
        ) : null}
        <m.div
          ref={containerRef}
          style={{
            position: "relative",
            flexGrow: 1,
            overflow: "hidden",
          }}
        >
          {viewsToRender.map((i) => {
            const mItem = matches?.[matchIndex + i];
            const hiddenProps =
              i !== 0
                ? {
                    "aria-hidden": true,
                    tabIndex: -1,
                    inert: true,
                  }
                : {};
            return (
              <m.div
                {...hiddenProps}
                key={matchIndex + i}
                style={{
                  position: "absolute",
                  width: "100%",
                  height: "100%",
                  x,
                  left: `${i * 100}%`,
                  overflowY: "auto",
                }}
                draggable
                drag="x"
                dragElastic={1}
                onDragEnd={onDragEnd}
              >
                <div className="pb-24">
                  <EventMatchView key={matchIndex + i} match={mItem} />
                </div>
              </m.div>
            );
          })}
        </m.div>
      </div>
    </section>
  );
};
