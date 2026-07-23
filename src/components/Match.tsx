import { useEffect, useId, useMemo, useState } from "react";
import { Match, MatchData } from "@referee-fyi/robotevents";
import { MatchContext } from "./Context";
import { Button } from "./Button";
import { twMerge } from "tailwind-merge";

function formatTime(ms: number) {
  const seconds = Math.floor(Math.abs(ms / 1000));
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.round(seconds % 60);
  const t = [h, m > 9 ? m : h ? "0" + m : m || "0", s > 9 ? s : "0" + s]
    .filter(Boolean)
    .join(":");
  return ms < 0 ? `-${t}` : `+${t}`;
}

export type MatchTimeProps = {
  match?: MatchData;
};

export const MatchTime: React.FC<MatchTimeProps> = ({ match }) => {
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
      {formatTime(delta)}
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
export type ClickableMatch = {
  match: Match;
  onClick: React.EventHandler<React.MouseEvent<HTMLButtonElement>>;
};

export const ClickableMatch: React.FC<ClickableMatch> = ({
  match,
  onClick,
}) => {
  const id = useId();

  return (
    <div
      key={match.id}
      className="w-full h-full flex items-center justify-between gap-4 border-b border-zinc-700 text-zinc-50 px-1"
    >
      <Button
        mode={"transparent"}
        data-matchid={match.id}
        onClick={onClick}
        className="flex-1 min-w-0 active:bg-zinc-600 pl-0 flex flex-col justify-center"
        aria-label={`Jump to ${match.name}`}
        id={id}
      >
        <p className="text-emerald-400">{match.shortName()} </p>
        <p className="text-sm">{matchTime(match)}</p>
      </Button>
      <label htmlFor={id} className="flex items-center justify-center shrink-0">
        <MatchContext match={match} />
      </label>
    </div>
  );
};
