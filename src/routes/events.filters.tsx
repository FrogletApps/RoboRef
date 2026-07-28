import React, { useCallback, useMemo, useState } from "react";
import { createFileRoute, useRouter } from "@tanstack/react-router";
import { Select } from "~components/Input";
import { Button } from "~components/Button";
import {
  useEventFilterStore,
  EventFilters,
  EVENT_TYPES,
} from "~utils/hooks/eventFilters";
import { useGeolocation } from "~utils/hooks/meta";
import { currentSeasons, useEventSearch } from "~utils/hooks/robotevents";

const COMMON_REGIONS = [
  "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut",
  "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana",
  "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts",
  "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska",
  "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina",
  "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
  "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
  "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming",
  "Alberta", "British Columbia", "Manitoba", "New Brunswick", "Ontario", "Quebec",
  "United Kingdom", "China", "Taiwan", "Japan", "Australia", "New Zealand", "Mexico"
];

export const EventFilterPage: React.FC = () => {
  const router = useRouter();
  const { data: geo } = useGeolocation();

  const globalFilters = useEventFilterStore((state) => state.filters);
  const setGlobalFilters = useEventFilterStore((state) => state.setFilters);
  const resetGlobalFilters = useEventFilterStore((state) => state.resetFilters);

  const [filters, setFilters] = useState<EventFilters>(globalFilters);

  const { data: events } = useEventSearch(
    {
      "season[]": currentSeasons,
      "eventTypes[]": ["tournament"],
    },
    { placeholderData: (prev) => prev }
  );

  const regionOptions = useMemo(() => {
    const set = new Set<string>(COMMON_REGIONS);
    if (geo?.region) set.add(geo.region);
    if (events) {
      for (const e of events) {
        if (e.location?.region) set.add(e.location.region);
        if (e.location?.country) set.add(e.location.country);
      }
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b));
  }, [geo?.region, events]);

  const onClickApply = useCallback(() => {
    setGlobalFilters(filters);
    if (router.history.canGoBack()) {
      router.history.back();
    } else {
      router.navigate({ to: "/events" });
    }
  }, [filters, setGlobalFilters, router]);

  const onClickRemoveAll = useCallback(() => {
    resetGlobalFilters();
    if (router.history.canGoBack()) {
      router.history.back();
    } else {
      router.navigate({ to: "/events" });
    }
  }, [resetGlobalFilters, router]);

  return (
    <div className="max-w-xl h-full w-full mx-auto flex-1 overflow-y-auto p-4 flex flex-col justify-between gap-4">
      <div className="flex flex-col gap-4">
        <label>
          <p className="font-medium mb-1">Region</p>
          <Select
            value={filters.region}
            onChange={(e) => {
              const val = e.target.value;
              setFilters((f) => ({ ...f, region: val }));
            }}
            className="w-full mt-1"
          >
            <option value="">All Regions</option>
            {regionOptions.map((reg) => (
              <option key={reg} value={reg}>
                {reg}
              </option>
            ))}
          </Select>
        </label>

        <label>
          <p className="font-medium mb-1">Event Type</p>
          <Select
            value={filters.eventType}
            onChange={(e) => {
              const val = e.target.value;
              setFilters((f) => ({ ...f, eventType: val }));
            }}
            className="w-full mt-1"
          >
            {EVENT_TYPES.map((type) => (
              <option key={type.id} value={type.id}>
                {type.name}
              </option>
            ))}
          </Select>
        </label>
      </div>

      <nav className="flex flex-col gap-2 mt-4 pb-4">
        <Button mode="primary" onClick={onClickApply}>
          Apply Filters
        </Button>
        <Button mode="dangerous" onClick={onClickRemoveAll}>
          Remove All Filters
        </Button>
      </nav>
    </div>
  );
};

export const Route = createFileRoute("/events/filters")({
  component: EventFilterPage,
});
