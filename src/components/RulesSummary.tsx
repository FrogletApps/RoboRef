import { Incident, IncidentOutcome } from "@referee-fyi/share";
import React, { useMemo } from "react";
import { twMerge } from "tailwind-merge";

const highlights: Record<IncidentOutcome, string> = {
  Minor: "text-yellow-300",
  Disabled: "text-blue-300",
  Major: "text-red-300",
  General: "text-zinc-300",
  Inspection: "text-zinc-300",
};

const outcomeOrder: Record<IncidentOutcome, number> = {
  Major: 0,
  Minor: 1,
  Disabled: 2,
  General: 3,
  Inspection: 4,
};

export type RulesSummaryProps = {
  incidents: Incident[];
  filter?: (incident: Incident) => boolean;
  maxVisible?: number;
} & React.HTMLProps<HTMLUListElement>;

export const RulesSummary: React.FC<RulesSummaryProps> = ({
  incidents,
  filter,
  maxVisible = 3,
  ...props
}) => {
  const counts = useMemo(() => {
    const rules: Record<
      string,
      { key: string; rule: string; outcome: IncidentOutcome; incidents: Incident[] }
    > = {};

    for (const incident of incidents) {
      if (filter && !filter(incident)) {
        continue;
      }

      const ruleList = incident.rules.length < 1 ? ["NA"] : incident.rules;

      for (const rule of ruleList) {
        const key = `${rule}:${incident.outcome}`;
        if (rules[key]) {
          rules[key].incidents.push(incident);
        } else {
          rules[key] = {
            key,
            rule,
            outcome: incident.outcome,
            incidents: [incident],
          };
        }
      }
    }

    return Object.values(rules).sort((a, b) => {
      const outcomeDiff =
        (outcomeOrder[a.outcome] ?? 99) - (outcomeOrder[b.outcome] ?? 99);
      if (outcomeDiff !== 0) return outcomeDiff;

      const countDiff = b.incidents.length - a.incidents.length;
      if (countDiff !== 0) return countDiff;

      return a.rule.localeCompare(b.rule, undefined, {
        numeric: true,
        sensitivity: "base",
      });
    });
  }, [filter, incidents]);

  const visibleCounts = useMemo(
    () => (maxVisible ? counts.slice(0, maxVisible) : counts),
    [counts, maxVisible]
  );
  const extraCount = maxVisible ? counts.length - maxVisible : 0;

  return (
    <ul
      {...props}
      className={twMerge(
        "text-sm flex-1 flex-shrink break-normal overflow-x-hidden",
        props.className
      )}
    >
      {visibleCounts.map(({ key, rule, outcome, incidents }) => {
        return (
          <li
            key={key}
            className={twMerge(
              highlights[outcome],
              "text-sm font-mono inline mx-1"
            )}
          >
            {incidents.length}x{rule.replace(/[<>]/g, "")}
          </li>
        );
      })}
      {extraCount > 0 ? (
        <li className="text-sm font-mono inline mx-1 text-zinc-400 font-semibold">
          +{extraCount}
        </li>
      ) : null}
    </ul>
  );
};

const OutcomePillClasses: Record<IncidentOutcome, string> = {
  Major: "bg-red-500 text-white border-red-400",
  Minor: "bg-yellow-400 text-yellow-950 border-yellow-300",
  Disabled: "bg-blue-500 text-white border-blue-400",
  General: "bg-zinc-700 text-zinc-100 border-zinc-600",
  Inspection: "bg-zinc-700 text-zinc-100 border-zinc-600",
};

export type NoteSummaryPillsProps = {
  incidents?: Incident[];
  className?: string;
};

export const NoteSummaryPills: React.FC<NoteSummaryPillsProps> = ({
  incidents,
  className,
}) => {
  const pills = useMemo(() => {
    if (!incidents || incidents.length === 0) return [];

    const grouped: Record<
      string,
      { rule: string; outcome: IncidentOutcome; count: number }
    > = {};

    for (const incident of incidents) {
      const ruleList =
        incident.rules.length < 1 ? [incident.outcome] : incident.rules;
      for (const rule of ruleList) {
        const key = `${rule}:${incident.outcome}`;
        if (grouped[key]) {
          grouped[key].count += 1;
        } else {
          grouped[key] = {
            rule,
            outcome: incident.outcome,
            count: 1,
          };
        }
      }
    }

    return Object.values(grouped).sort((a, b) => {
      const outcomeDiff =
        (outcomeOrder[a.outcome] ?? 99) - (outcomeOrder[b.outcome] ?? 99);
      if (outcomeDiff !== 0) return outcomeDiff;

      const countDiff = b.count - a.count;
      if (countDiff !== 0) return countDiff;

      return a.rule.localeCompare(b.rule, undefined, {
        numeric: true,
        sensitivity: "base",
      });
    });
  }, [incidents]);

  if (pills.length === 0) return null;

  return (
    <div
      className={twMerge(
        "flex flex-wrap gap-1.5 pb-2 mb-2 border-b border-zinc-800/80",
        className
      )}
    >
      {pills.map(({ rule, outcome, count }) => (
        <span
          key={`${rule}-${outcome}`}
          className={twMerge(
            "px-2.5 py-0.5 rounded-full text-xs font-mono font-semibold shadow-sm",
            OutcomePillClasses[outcome]
          )}
        >
          {count}x{rule.replace(/[<>]/g, "")}
        </span>
      ))}
    </div>
  );
};
