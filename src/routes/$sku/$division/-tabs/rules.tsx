import React, { useMemo, useState } from "react";
import { EventData, ProgramCode } from "@referee-fyi/robotevents";
import { useCurrentSeason, useSeason } from "~utils/hooks/robotevents";
import { Rule, useRulesForSeason } from "~utils/hooks/rules";
import { RulesSelect } from "~components/Input";
import { ExternalLinkButton } from "~components/Button";
import { Spinner } from "~components/Spinner";
import { BookOpenIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";

export type EventRulesTabProps = {
  event?: EventData | null;
};

export const EventRulesTab: React.FC<EventRulesTabProps> = ({ event }) => {
  const program = useMemo(() => event?.program?.id as ProgramCode, [event]);

  const { data: currentSeasonForProgram } = useCurrentSeason(program);
  const { data: season } = useSeason(event?.season?.id);
  const { data: rules, isLoading } = useRulesForSeason(
    season ?? currentSeasonForProgram
  );

  const [rule, setRule] = useState<Rule | null>(null);

  const rulesUrl = useMemo(() => {
    if (!rules?.ruleGroups) return undefined;
    for (const group of rules.ruleGroups) {
      for (const r of group.rules) {
        if (r.link) return r.link.split("#")[0];
      }
    }
    return undefined;
  }, [rules]);

  const qaBaseUrl = useMemo(() => {
    return rules?.qa;
  }, [rules]);

  const qaUrl = useMemo(() => {
    if (!rules?.qa || !rule) return undefined;
    return `${rules.qa}?query=${rule.rule.replace(/[<>]/g, "")}`;
  }, [rules, rule]);

  return (
    <div className="flex-1 flex flex-col p-4 mb-20 overflow-y-auto">
      <div className="grid grid-cols-2 gap-2 mb-4 w-full">
        <ExternalLinkButton
          href={rulesUrl}
          className="flex items-center justify-center gap-1.5 px-2 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
        >
          <BookOpenIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
          <span className="truncate">Rules</span>
        </ExternalLinkButton>
        <ExternalLinkButton
          href={qaBaseUrl}
          className="flex items-center justify-center gap-1.5 px-2 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
        >
          <MagnifyingGlassIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
          <span className="truncate">Q&A</span>
        </ExternalLinkButton>
      </div>
      <h2 className="text-lg font-bold text-zinc-100 mb-2">Search</h2>
      <div className="mb-4">
        <RulesSelect
          game={rules ?? null}
          rule={rule}
          setRule={setRule}
          className="w-full"
        />
      </div>
      <div className="flex-1 flex flex-col justify-start">
        {isLoading ? (
          <Spinner show={true} />
        ) : rule ? (
          <div className="flex flex-col gap-4 bg-zinc-800/50 border border-zinc-700/50 p-6 rounded-xl backdrop-blur-sm">
            <div className="flex items-center gap-3 border-b border-zinc-700/50 pb-4">
              {rule.icon && (
                <div className="bg-zinc-700/50 p-2 rounded-lg">
                  <img
                    src={rule.icon}
                    alt="Rule icon"
                    className="h-8 w-auto object-contain"
                  />
                </div>
              )}
              <h3 className="text-2xl font-mono font-bold text-emerald-400">
                {rule.rule}
              </h3>
            </div>
            <p className="text-zinc-200 text-base leading-relaxed font-sans">
              {rule.description}
            </p>
            {(rule.link || qaUrl) && (
              <div className="flex flex-col gap-2 mt-4">
                {rule.link && (
                  <ExternalLinkButton
                    href={rule.link}
                    className="w-full text-center bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-medium py-3 rounded-lg flex items-center justify-center gap-2 transition-all duration-200 shadow-lg shadow-emerald-900/20"
                  >
                    <BookOpenIcon height={20} />
                    <span>View {rule.rule.replace(/[<>{}]/g, "")} in Game Rules</span>
                  </ExternalLinkButton>
                )}
                {qaUrl && (
                  <ExternalLinkButton
                    href={qaUrl}
                    className="w-full text-center bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-medium py-3 rounded-lg flex items-center justify-center gap-2 transition-all duration-200 shadow-lg shadow-blue-900/20"
                  >
                    <MagnifyingGlassIcon height={20} />
                    <span>Search {rule.rule.replace(/[<>{}]/g, "")} in Q&A</span>
                  </ExternalLinkButton>
                )}
              </div>
            )}
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-12 text-zinc-400">
            <BookOpenIcon className="w-16 h-16 mb-4 text-zinc-500" />
            <p className="text-center text-sm">
              Select a rule from the dropdown above to view details.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
