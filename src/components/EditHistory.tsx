import {
  BaseWithLWWConsistency,
  KeyRegister,
  LWWKeys,
} from "@referee-fyi/consistency";
import { incidentMatchNameToString, IncidentMatch } from "@referee-fyi/share";
import { useMemo, useState } from "react";
import { twMerge } from "tailwind-merge";
import { timeAgo } from "~utils/time";
import { Button } from "./Button";
import { UserCircleIcon, ClockIcon } from "@heroicons/react/20/solid";
import { usePeerUserName } from "~utils/data/share";

export type HistoryRecord = {
  key: string;
  prev: unknown;
  to: unknown;
  peer: string;
  instant: string;
};

export type EditHistoryRecordItemProps = {
  record: HistoryRecord;
  render?: (value: unknown) => React.ReactNode;
};

function renderOutcomeBadge(outcome: unknown) {
  const label = String(outcome ?? "General");
  let colorClass = "bg-zinc-600/50 text-zinc-300 border-zinc-500/30";
  if (label === "Major") colorClass = "bg-red-500/20 text-red-400 border-red-500/30";
  else if (label === "Minor") colorClass = "bg-amber-500/20 text-amber-400 border-amber-500/30";
  else if (label === "Disabled") colorClass = "bg-rose-500/20 text-rose-400 border-rose-500/30";

  return (
    <span className={twMerge("px-2 py-0.5 rounded text-xs font-semibold border inline-block", colorClass)}>
      {label}
    </span>
  );
}

function renderRulesList(rulesVal: unknown) {
  const rules = Array.isArray(rulesVal) ? rulesVal : [];
  if (rules.length === 0) {
    return <span className="text-zinc-400 italic text-xs">None</span>;
  }
  return (
    <div className="flex flex-wrap gap-1 inline-flex">
      {rules.map((rule, idx) => (
        <span
          key={`${rule}-${idx}`}
          className="px-1.5 py-0.5 rounded text-xs font-mono bg-sky-500/20 text-sky-300 border border-sky-500/30"
        >
          &lt;{String(rule)}&gt;
        </span>
      ))}
    </div>
  );
}

function renderFlagsList(flagsVal: unknown) {
  const flags = Array.isArray(flagsVal) ? flagsVal : [];
  if (flags.length === 0) {
    return <span className="text-zinc-400 italic text-xs">None</span>;
  }
  return (
    <div className="flex flex-wrap gap-1 inline-flex">
      {flags.map((flag, idx) => (
        <span
          key={`${flag}-${idx}`}
          className="px-1.5 py-0.5 rounded text-xs font-semibold bg-yellow-500/20 text-yellow-300 border border-yellow-500/30"
        >
          {String(flag) === "judge" ? "Flagged for Judges" : String(flag)}
        </span>
      ))}
    </div>
  );
}

function renderAssetCount(assetsVal: unknown) {
  const count = Array.isArray(assetsVal) ? assetsVal.length : 0;
  return (
    <span className="text-xs text-zinc-300">
      {count} photo{count === 1 ? "" : "s"}
    </span>
  );
}

export const EditHistoryRecordItem: React.FC<EditHistoryRecordItemProps> = ({
  record,
  render = (value) => JSON.stringify(value),
}) => {
  const user = usePeerUserName(record.peer);
  const date = new Date(record.instant);

  // 1. Initial Creation Event
  if (record.key === "created") {
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        <div className="flex justify-between text-xs text-zinc-400 mb-1">
          <span>
            <UserCircleIcon height={16} className="inline mr-1 text-emerald-400" aria-hidden="true" />
            <span className="sr-only">User: </span>
            {user || "Referee"}
          </span>
          <span>
            <ClockIcon height={16} className="inline mr-1 text-zinc-400" aria-hidden="true" />
            <span className="sr-only">Time: </span>
            {date.toLocaleTimeString()}
          </span>
        </div>
        <p className="font-semibold text-emerald-400 text-sm">Created Note</p>
      </section>
    );
  }

  // 2. Deletion / Restoration Event
  if (record.key === "deleted") {
    const isDeletedAction = record.to === true;
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        <div className="flex justify-between text-xs text-zinc-400 mb-1">
          <span>
            <UserCircleIcon height={16} className="inline mr-1 text-emerald-400" aria-hidden="true" />
            <span className="sr-only">User: </span>
            {user || "Referee"}
          </span>
          <span>
            <ClockIcon height={16} className="inline mr-1 text-zinc-400" aria-hidden="true" />
            <span className="sr-only">Time: </span>
            {date.toLocaleTimeString()}
          </span>
        </div>
        <p className={twMerge("font-semibold text-sm", isDeletedAction ? "text-red-400" : "text-emerald-400")}>
          {isDeletedAction ? "Deleted Note" : "Undeleted Note"}
        </p>
      </section>
    );
  }

  // Header info for property edit events
  const header = (
    <div className="flex justify-between text-xs text-zinc-400 mb-1">
      <span>
        <UserCircleIcon height={16} className="inline mr-1 text-emerald-400" aria-hidden="true" />
        <span className="sr-only">User: </span>
        {user || "Referee"}
      </span>
      <span>
        <ClockIcon height={16} className="inline mr-1 text-zinc-400" aria-hidden="true" />
        <span className="sr-only">Time: </span>
        {date.toLocaleTimeString()}
      </span>
    </div>
  );

  // 3. Outcome / Severity change
  if (record.key === "outcome") {
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        {header}
        <p className="font-semibold text-amber-400 text-sm mb-2">Changed Severity / Outcome</p>
        <div className="text-xs grid grid-cols-2 gap-2 bg-zinc-800/60 p-2 rounded">
          <div>
            <span className="text-zinc-400 block mb-1">From</span>
            {renderOutcomeBadge(record.prev)}
          </div>
          <div>
            <span className="text-zinc-400 block mb-1">To</span>
            {renderOutcomeBadge(record.to)}
          </div>
        </div>
      </section>
    );
  }

  // 4. Game Rules cited change
  if (record.key === "rules") {
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        {header}
        <p className="font-semibold text-sky-400 text-sm mb-2">Updated Cited Rules</p>
        <div className="text-xs grid grid-cols-2 gap-2 bg-zinc-800/60 p-2 rounded">
          <div>
            <span className="text-zinc-400 block mb-1">From</span>
            {renderRulesList(record.prev)}
          </div>
          <div>
            <span className="text-zinc-400 block mb-1">To</span>
            {renderRulesList(record.to)}
          </div>
        </div>
      </section>
    );
  }

  // 5. Match context change
  if (record.key === "match") {
    const prevMatchStr = incidentMatchNameToString(record.prev as IncidentMatch | undefined);
    const toMatchStr = incidentMatchNameToString(record.to as IncidentMatch | undefined);
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        {header}
        <p className="font-semibold text-indigo-400 text-sm mb-2">Changed Match Context</p>
        <div className="text-xs grid grid-cols-2 gap-2 bg-zinc-800/60 p-2 rounded">
          <div>
            <span className="text-zinc-400 block mb-1">From</span>
            <span className="font-medium text-zinc-200">{prevMatchStr}</span>
          </div>
          <div>
            <span className="text-zinc-400 block mb-1">To</span>
            <span className="font-medium text-zinc-200">{toMatchStr}</span>
          </div>
        </div>
      </section>
    );
  }

  // 6. Flags change
  if (record.key === "flags") {
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        {header}
        <p className="font-semibold text-yellow-400 text-sm mb-2">Updated Flags</p>
        <div className="text-xs grid grid-cols-2 gap-2 bg-zinc-800/60 p-2 rounded">
          <div>
            <span className="text-zinc-400 block mb-1">From</span>
            {renderFlagsList(record.prev)}
          </div>
          <div>
            <span className="text-zinc-400 block mb-1">To</span>
            {renderFlagsList(record.to)}
          </div>
        </div>
      </section>
    );
  }

  // 7. Assets / Attachments change
  if (record.key === "assets") {
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        {header}
        <p className="font-semibold text-fuchsia-400 text-sm mb-2">Updated Attachments</p>
        <div className="text-xs grid grid-cols-2 gap-2 bg-zinc-800/60 p-2 rounded">
          <div>
            <span className="text-zinc-400 block mb-1">From</span>
            {renderAssetCount(record.prev)}
          </div>
          <div>
            <span className="text-zinc-400 block mb-1">To</span>
            {renderAssetCount(record.to)}
          </div>
        </div>
      </section>
    );
  }

  // 8. Notes text change
  if (record.key === "notes") {
    const prevText = String(record.prev ?? "");
    const toText = String(record.to ?? "");
    return (
      <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
        {header}
        <p className="font-semibold text-emerald-400 text-sm mb-2">Updated Referee Notes</p>
        <div className="text-xs space-y-2 bg-zinc-800/60 p-2 rounded">
          <div>
            <span className="text-zinc-400 block mb-0.5">From</span>
            <p className="text-zinc-300 italic bg-zinc-900/40 p-1.5 rounded break-words whitespace-pre-wrap">
              {prevText || "(empty)"}
            </p>
          </div>
          <div>
            <span className="text-zinc-400 block mb-0.5">To</span>
            <p className="text-emerald-300 bg-zinc-900/40 p-1.5 rounded break-words whitespace-pre-wrap">
              {toText || "(empty)"}
            </p>
          </div>
        </div>
      </section>
    );
  }

  // 9. Generic Property Fallback
  return (
    <section className="bg-zinc-700/80 p-3 rounded-md mb-3 border border-zinc-600/50">
      {header}
      <p className="font-semibold text-zinc-300 text-sm mb-2">
        Updated {record.key.charAt(0).toUpperCase() + record.key.slice(1)}
      </p>
      <div className="text-xs grid grid-cols-2 gap-2 bg-zinc-800/60 p-2 rounded">
        <div>
          <span className="text-zinc-400 block mb-1">From</span>
          <div className="text-zinc-300 break-words">{render(record.prev)}</div>
        </div>
        <div>
          <span className="text-zinc-400 block mb-1">To</span>
          <div className="text-zinc-300 break-words">{render(record.to)}</div>
        </div>
      </div>
    </section>
  );
};

export type EditHistoryViewProps<
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
> = {
  value: T | null | undefined;
  valueKey?: K;
  render?: (value: T[K]) => React.ReactNode;
  className?: string;
};

export const EditHistoryView = <
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
>({
  value,
  render,
  className,
}: EditHistoryViewProps<T, K>) => {
  const allRecords = useMemo(() => {
    if (!value || !value.consistency) return [];
    const records: HistoryRecord[] = [];

    let earliestInstant = "";
    let initialPeer = "";

    if ("time" in value && value.time) {
      earliestInstant = new Date(value.time as string | number | Date).toISOString();
    }

    for (const [key, register] of Object.entries(value.consistency)) {
      const reg = register as KeyRegister<Record<string, unknown>, string>;
      if (!reg) continue;

      const firstHist = reg.history?.[0];
      const regInitialInstant = firstHist ? firstHist.instant : reg.instant;
      const regInitialPeer = firstHist ? firstHist.peer : reg.peer;

      if (
        !earliestInstant ||
        (regInitialInstant && new Date(regInitialInstant).getTime() < new Date(earliestInstant).getTime())
      ) {
        earliestInstant = regInitialInstant;
        initialPeer = regInitialPeer;
      }
      if (!initialPeer && regInitialPeer) {
        initialPeer = regInitialPeer;
      }

      if (!reg.history) continue;

      reg.history.forEach((h, i) => {
        const nextHist = reg.history[i + 1];
        const to = nextHist?.prev ?? value[key];
        const editInstant = nextHist?.instant ?? reg.instant;

        records.push({
          key,
          prev: h.prev,
          to,
          peer: h.peer,
          instant: editInstant,
        });
      });
    }

    if (earliestInstant) {
      records.push({
        key: "created",
        prev: null,
        to: null,
        peer: initialPeer,
        instant: earliestInstant,
      });
    }

    return records.sort(
      (a, b) => new Date(b.instant).getTime() - new Date(a.instant).getTime()
    );
  }, [value]);

  if (!value) {
    return null;
  }

  return (
    <div className={twMerge("flex flex-col gap-2", className)}>
      {allRecords.length > 0 ? (
        allRecords.map((record) => (
          <EditHistoryRecordItem
            record={record}
            render={render as (value: unknown) => React.ReactNode}
            key={`${record.key}-${record.instant}`}
          />
        ))
      ) : (
        <p className="text-zinc-400 text-center py-8">No edit history yet</p>
      )}
    </div>
  );
};

export type EditHistoryProps<
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
> = {
  value: T | null | undefined;
  valueKey: K;
  dirty?: boolean;
  className?: string;
  render?: (value: T[K]) => React.ReactNode;
};

export const EditHistory = <
  T extends BaseWithLWWConsistency,
  K extends LWWKeys<T>,
>({
  value,
  valueKey,
  dirty = false,
  className,
  render,
}: EditHistoryProps<T, K>) => {
  const mostRecentRegister = useMemo(() => {
    if (!value || !value.consistency) return null;
    let newest: { peer: string; instant: string } | null = null;
    for (const reg of Object.values(value.consistency)) {
      const r = reg as KeyRegister<Record<string, unknown>, string>;
      if (!r || !r.instant) continue;
      if (!newest || new Date(r.instant).getTime() > new Date(newest.instant).getTime()) {
        newest = r;
      }
    }
    return newest;
  }, [value]);

  const user = usePeerUserName(mostRecentRegister?.peer);
  const [historyOpen, setHistoryOpen] = useState(false);

  if (!mostRecentRegister || !value) {
    return (
      <div
        className={twMerge(
          "flex items-center justify-between mt-2 h-8",
          className
        )}
      ></div>
    );
  }

  return (
    <div className={twMerge("flex flex-col gap-2 mt-2", className)}>
      <div className="flex items-center justify-between">
        <p
          className={twMerge(
            "px-2 text-sm ",
            dirty
              ? "text-black italic bg-emerald-400 rounded-md"
              : "text-emerald-400"
          )}
        >
          {user ? `${user}, ` : ""}
          {timeAgo(new Date(mostRecentRegister.instant))}
        </p>
        <Button
          className="flex items-center w-max gap-2 py-1"
          onClick={() => setHistoryOpen((open) => !open)}
        >
          <ClockIcon height={20} />
          {historyOpen ? "Hide History" : "History"}
        </Button>
      </div>
      {historyOpen && (
        <div className="mt-2 border-t border-zinc-700 pt-3">
          <EditHistoryView value={value} valueKey={valueKey} render={render} />
        </div>
      )}
    </div>
  );
};

