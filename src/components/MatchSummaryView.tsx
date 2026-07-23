import React, { useCallback, useEffect, useMemo, useState } from "react";
import { EventData } from "@referee-fyi/robotevents";
import { useCurrentDivision, useCurrentEvent } from "~utils/hooks/state";
import { useEventMatches } from "~utils/hooks/robotevents";
import { Spinner } from "~components/Spinner";
import { IconButton } from "~components/Button";
import { ArrowLeftIcon, ArrowRightIcon } from "@heroicons/react/20/solid";
import { MatchContext } from "~components/Context";
import { MatchTime } from "~components/Match";
import { EventMatchView } from "~components/dialogs/match";
import { animate, PanInfo, useMotionValue } from "motion/react";
import * as m from "motion/react-m";
import useResizeObserver from "use-resize-observer";

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

  const [[matchIndex, animateMatchTransition], setMatchIndex] = useState<
    [index: number, animate: boolean]
  >([0, false]);

  useEffect(() => {
    if (!matches || matches.length === 0) return;
    if (initialMatchId !== undefined && !isNaN(initialMatchId)) {
      const index = matches.findIndex((m) => m.id === initialMatchId);
      if (index !== -1) {
        setMatchIndex([index, false]);
        return;
      }
    }
    const upcomingIndex = matches.findIndex(
      (m) => !m.started && m.alliances.every((a) => a.score === 0)
    );
    if (upcomingIndex !== -1) {
      setMatchIndex([upcomingIndex, false]);
    } else {
      setMatchIndex([0, false]);
    }
  }, [initialMatchId, matches]);

  const match = useMemo(() => matches?.[matchIndex], [matchIndex, matches]);

  const hasNextMatch = matchIndex + 1 < (matches?.length ?? Infinity);
  const hasPrevMatch = matchIndex - 1 >= 0;

  const onClickNextMatch = useCallback(() => {
    if (!matches || !hasNextMatch) return;
    setMatchIndex([matchIndex + 1, true]);
  }, [hasNextMatch, matchIndex, matches]);

  const onClickPrevMatch = useCallback(() => {
    if (!matches || !hasPrevMatch) return;
    setMatchIndex([matchIndex - 1, true]);
  }, [hasPrevMatch, matchIndex, matches]);

  // Swipey Swipe Animation
  const { ref: containerRef, width: containerWidth = 0 } =
    useResizeObserver<HTMLDivElement>();

  const viewsToRender = [-1, 0, 1];
  const x = useMotionValue(0);

  const calculateNewX = useCallback(
    () => -matchIndex * containerWidth,
    [matchIndex, containerWidth]
  );

  const onDragEnd = useCallback(
    (_: Event, dragProps: PanInfo) => {
      const { offset, velocity } = dragProps;

      if (Math.abs(velocity.y) > Math.abs(velocity.x)) {
        animate(x, calculateNewX(), transition);
        return;
      }

      if (offset.x > containerWidth / 6) {
        onClickPrevMatch();
      } else if (offset.x < -containerWidth / 6) {
        onClickNextMatch();
      } else {
        animate(x, calculateNewX(), transition);
      }
    },
    [calculateNewX, containerWidth, onClickNextMatch, onClickPrevMatch, x]
  );

  useEffect(() => {
    if (!animateMatchTransition) {
      x.set(calculateNewX());
      return;
    }
    const controls = animate(x, calculateNewX(), transition);
    return controls.stop;
  }, [matchIndex, calculateNewX, x, animateMatchTransition]);

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

  if (isLoading && !match) {
    return <Spinner show />;
  }

  return (
    <section className="flex-1 flex flex-col max-h-full overflow-hidden mt-4">
      <header className="grid grid-cols-[1fr_auto_1fr] items-center gap-2 p-2 bg-zinc-900 border border-zinc-800 rounded-lg mb-3 flex-shrink-0">
        <div className="flex items-center justify-start gap-2 min-w-0">
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
          {scheduledTime ? (
            <span className="text-zinc-100 font-mono whitespace-nowrap">
              {scheduledTime}
            </span>
          ) : null}
        </div>
        <h1 className="text-xl font-bold font-mono text-zinc-100 text-center truncate px-2">
          {match?.name ?? "Match Summary"}
        </h1>
        <div className="flex items-center justify-end gap-2 min-w-0">
          {match && <MatchTime match={match} />}
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
                  left: (matchIndex + i) * containerWidth,
                  right: (matchIndex + i) * containerWidth,
                  overflowY: "auto",
                }}
                draggable
                drag="x"
                dragElastic={1}
                onDragEnd={onDragEnd}
              >
                <EventMatchView key={matchIndex + i} match={mItem} />
              </m.div>
            );
          })}
        </m.div>
      </div>
    </section>
  );
};
