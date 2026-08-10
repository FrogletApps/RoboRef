import { useEffect, useId, useMemo, useState } from "react";
import { Match, MatchData } from "@roboref/vexevents";
import { MatchContext } from "./Context";
import { Button } from "./Button";
import { twMerge } from "tailwind-merge";

function formatTime(ms: number, showSign = false) {
  const seconds = Math.floor(Math.abs(ms / 1000));
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.round(seconds % 60);

  let formatted = "";
  if (h > 0) {
    formatted = `${h}h ${m}m ${s}s`;
  } else if (m > 0) {
    formatted = `${m}m ${s}s`;
  } else {
    formatted = `${s}s`;
  }

  if (showSign) {
    return ms < 0 ? `-${formatted}` : `+${formatted}`;
  }
  return formatted;
}

export type MatchTimeProps = {
  match?: MatchData;
  showSign?: boolean;
};

export function useMatchDelta(match?: MatchData) {
  const [now, setNow] = useState<number>(Date.now());

  const delta = useMemo(() => {
    if (!match?.scheduled) {
      return undefined;
    }

    const scheduled = new Date(match.scheduled).getTime();
    const currentOrStarted = match.started
      ? new Date(match.started).getTime()
      : now;

    return currentOrStarted - scheduled;
  }, [match, now]);

  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  return delta;
}

export const MatchTime: React.FC<MatchTimeProps> = ({
  match,
  showSign = false,
}) => {
  const delta = useMatchDelta(match);

  if (typeof delta === "undefined") {
    return null;
  }

  const colorClass =
    delta >= 0
      ? "text-red-400"
      : delta >= -60000
      ? "text-yellow-400"
      : "text-emerald-400";

  return (
    <span className={twMerge("font-mono", colorClass)}>
      {formatTime(delta, showSign)}
    </span>
  );
};

function getSafeLocale(): string {
  if (typeof navigator === "undefined" || !navigator.language) {
    return "en";
  }
  const locale = navigator.language.split("@")[0].split(".")[0].replace("_", "-");
  try {
    new Intl.DateTimeFormat(locale);
    return locale;
  } catch (e) {
    return "en";
  }
}

const dateFormatter = new Intl.DateTimeFormat(getSafeLocale(), {
  hour: "numeric",
  minute: "numeric",
});

function matchTime(match: MatchData) {
  if (match.started) {
    return <span>{dateFormatter.format(new Date(match.started))}</span>;
  }

  if (!match.scheduled) {
    return <span className="italic">Not Scheduled</span>;
  }

  return (
    <span className="italic">
      {dateFormatter.format(new Date(match.scheduled))}
    </span>
  );
}
export type ClickableMatchProps = {
  match: Match;
  selectedTeam?: string;
  onClick: React.EventHandler<React.MouseEvent<HTMLButtonElement>>;
};

export const ClickableMatch: React.FC<ClickableMatchProps> = ({
  match,
  selectedTeam,
  onClick,
}) => {
  const id = useId();

  const teamAllianceColor = useMemo(() => {
    if (!selectedTeam) return undefined;
    const alliance = match.alliances.find((a) =>
      a.teams.some((t) => t.team?.name === selectedTeam)
    );
    return alliance?.color;
  }, [match, selectedTeam]);

  const matchNumberColorClass =
    teamAllianceColor === "red"
      ? "text-red-400"
      : teamAllianceColor === "blue"
      ? "text-blue-400"
      : "text-emerald-400";

  return (
    <div
      key={match.id}
      className="w-full h-full flex items-center justify-between gap-4 border-b border-zinc-700 text-zinc-50 px-1"
    >
      <Button
        mode={"transparent"}
        data-matchid={match.id}
        onClick={onClick}
        className="flex-1 min-w-0 active:bg-zinc-600 pl-0 flex flex-col justify-center text-left"
        aria-label={`Jump to ${match.name}`}
        id={id}
      >
        <p className={twMerge("font-semibold", matchNumberColorClass)}>
          {match.shortName()}
        </p>
        <p className="text-sm text-zinc-400">{matchTime(match)}</p>
      </Button>
      <label htmlFor={id} className="flex items-center justify-center shrink-0">
        <MatchContext match={match} />
      </label>
    </div>
  );
};
