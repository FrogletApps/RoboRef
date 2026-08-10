import React, { useCallback, useMemo } from "react";
import { Spinner } from "~components/Spinner";
import { useCurrentEvent } from "~utils/hooks/state";
import { Button, LinkButton } from "~components/Button";
import {
  AdjustmentsHorizontalIcon,
  ArrowDownTrayIcon,
  ArrowPathIcon,
} from "@heroicons/react/24/outline";
import { Incident } from "~components/Incident";
import { NoteSummaryPills } from "~components/RulesSummary";
import { twMerge } from "tailwind-merge";
import { useMutation } from "@tanstack/react-query";
import { ReadyState, useShareConnection } from "~models/ShareConnection";
import { Incident as IncidentData } from "@roboref/share";
import { VirtualizedList } from "~components/VirtualizedList";
import { useEventIncidents } from "~utils/hooks/incident";
import { isFilterApplied, useFilterStore } from "~utils/hooks/filters";

export const ForceSyncButton: React.FC = () => {
  const connection = useShareConnection(["readyState", "forceSync"]);
  const isConnected = connection.readyState === ReadyState.Open;

  const { mutateAsync: forceSync, isPending: isForceSyncPending } = useMutation(
    {
      mutationFn: connection.forceSync,
    }
  );

  if (!isConnected) {
    return null;
  }

  return (
    <Button
      onClick={() => forceSync()}
      disabled={isForceSyncPending}
      className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
    >
      <ArrowPathIcon
        className={twMerge(
          "w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0",
          isForceSyncPending ? "animate-spin" : "animate-none"
        )}
      />
      <span className="truncate">Force Sync</span>
    </Button>
  );
};

export const ExportButton: React.FC<{
  incidents?: any[];
  filenamePrefix?: string;
}> = ({ incidents: customIncidents, filenamePrefix = "incidents" }) => {
  const {
    profile: { name, key },
  } = useShareConnection(["profile"]);

  const { data: event } = useCurrentEvent();
  const { data: eventIncidents, isLoading } = useEventIncidents(event?.sku);

  const incidentsToExport = customIncidents ?? eventIncidents;

  const onClick = useCallback(() => {
    const sku = event?.sku ?? "";
    const timestamp = new Date().toISOString();

    const data = JSON.stringify(
      {
        meta: {
          version: __ROBOREF_VERSION__,
          sku,
          timestamp,
          user: { name, key },
        },
        incidents: incidentsToExport,
      },
      null,
      4
    );

    const blob = new Blob([data], { type: "text/json" });
    const url = URL.createObjectURL(blob);

    const a = document.createElement("a");
    a.href = url;
    a.setAttribute("download", `${filenamePrefix}-${sku}-${timestamp}.json`);
    a.click();
  }, [event?.sku, incidentsToExport, key, name, filenamePrefix]);

  if (!customIncidents && isLoading) {
    return null;
  }

  return (
    <Button
      onClick={onClick}
      className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
    >
      <ArrowDownTrayIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
      <span className="truncate">Export</span>
    </Button>
  );
};

export type IncidentListSummaryProps = {
  incidents?: IncidentData[];
  isPending?: boolean;
  countLabel: string;
  exportFilenamePrefix: string;
  readonlyIncidents?: boolean;
  allowUndelete?: boolean;
  footer?: React.ReactNode;
};

export const IncidentListSummary: React.FC<IncidentListSummaryProps> = ({
  incidents: allIncidents,
  isPending,
  countLabel,
  exportFilenamePrefix,
  readonlyIncidents,
  allowUndelete,
  footer,
}) => {
  const { data: event } = useCurrentEvent();
  const filters = useFilterStore((state) => state.filters);

  const filteredIncidents = useMemo(() => {
    const results = allIncidents?.filter((incident) => {
      if (!filters.outcomes[incident.outcome]) {
        return false;
      }

      const hasRule =
        filters.rules.length < 1 ||
        filters.rules.some((rule) => incident.rules.includes(rule.rule));
      if (!hasRule) {
        return false;
      }

      const people = new Set<string>();
      for (const register of Object.values(incident.consistency)) {
        people.add(register.peer);
        for (const item of register.history) {
          people.add(item.peer);
        }
      }

      if (filters.contact.size > 0) {
        let hasMatch = false;
        for (const person of people) {
          if (filters.contact.has(person)) {
            hasMatch = true;
            break;
          }
        }
        if (!hasMatch) {
          return false;
        }
      }

      // Division Filter
      if (typeof filters.division !== "number") {
        return true;
      }

      if (!incident.match) {
        return false;
      }

      if (incident.match.type !== "match") {
        return false;
      }
      return incident.match.division === filters.division;
    });

    return results ?? [];
  }, [allIncidents, filters]);

  const hasFiltersApplied = useMemo(() => isFilterApplied(filters), [filters]);

  return (
    <section className="mt-4 flex flex-col max-h-full">
      <p className="mb-2">
        {hasFiltersApplied ? (
          <>
            {filteredIncidents?.length ?? 0} {countLabel}
            {filteredIncidents?.length === 1 ? "" : "s"} visible /{" "}
            {allIncidents?.length ?? 0} {countLabel}
            {(allIncidents?.length ?? 0) === 1 ? "" : "s"} total
          </>
        ) : (
          <>
            {filteredIncidents?.length ?? 0} {countLabel}
            {filteredIncidents?.length === 1 ? "" : "s"}
          </>
        )}
      </p>
      <nav className="flex gap-2 w-full">
        <LinkButton
          to="/$sku/filters"
          params={{ sku: event?.sku ?? "" }}
          className="flex-1 flex items-center justify-center gap-1.5 px-3 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
        >
          <AdjustmentsHorizontalIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
          <span className="truncate">Filters</span>
        </LinkButton>
        <ExportButton
          incidents={filteredIncidents}
          filenamePrefix={exportFilenamePrefix}
        />
        <ForceSyncButton />
      </nav>
      {hasFiltersApplied && (
        <p className="text-zinc-400 text-sm mt-2">
          Filters have been applied, edit or remove these using the Filters button. Only visible notes will be exported.
        </p>
      )}
      <Spinner show={isPending} />
      <VirtualizedList
        data={filteredIncidents}
        header={
          filters.showPills !== false ? (
            <NoteSummaryPills
              incidents={filteredIncidents}
              className="mb-3 border-none pb-0"
            />
          ) : null
        }
        options={{ estimateSize: () => 64 }}
        className="flex-1 mt-3"
      >
        {(incident) => (
          <Incident
            incident={incident}
            key={incident.id}
            readonly={readonlyIncidents}
            allowUndelete={allowUndelete}
            className="h-14 overflow-hidden"
          />
        )}
      </VirtualizedList>
      {footer}
    </section>
  );
};
