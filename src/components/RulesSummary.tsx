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
      if (!filter?.(incident)) {
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

    return Object.values(rules).sort(
      (a, b) => a.incidents.length - b.incidents.length
    );
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
