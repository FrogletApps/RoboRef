import { createFileRoute, Outlet, useLocation } from "@tanstack/react-router";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Button, LinkButton } from "~components/Button";
import { Input } from "~components/Input";
import { Spinner } from "~components/Spinner";
import { getSkuTextColorClass } from "~utils/data/state";
import { useUnhideEvent } from "~utils/hooks/history";
import { useGeolocation } from "~utils/hooks/meta";
import { currentSeasons, useEvent, useEventSearch } from "~utils/hooks/robotevents";
import { formatEventDate } from "~utils/time";
import { AdjustmentsHorizontalIcon } from "@heroicons/react/24/outline";
import {
  useEventFilterStore,
  isEventFilterApplied,
  EVENT_TYPES,
} from "~utils/hooks/eventFilters";
import { operations } from "@referee-fyi/robotevents";

function isValidSKU(sku: string) {
  return !!sku.match(
    /RE-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC|ADC)-[0-9]{2}-[0-9]{4}/gi
  );
}

export const EventsPage: React.FC = () => {
  const { mutate: unhideEvent } = useUnhideEvent();
  const { data: geo } = useGeolocation();
  const filters = useEventFilterStore((state) => state.filters);
  const isFilterActive = useMemo(() => isEventFilterApplied(filters), [filters]);

  const [query, setQuery] = useState("");
  const { data: eventFromSKU, isLoading: isLoadingEventFromSKU } = useEvent(
    query.toUpperCase(),
    { enabled: isValidSKU(query) }
  );

  const start = useRef(
    new Date(Date.now() - 1000 * 60 * 60 * 24 * 3).toISOString()
  );
  const [end, setEnd] = useState(
    new Date(Date.now() + 1000 * 60 * 60 * 24 * 7)
  );

  const onClickMore = useCallback(() => {
    setEnd((end) => new Date(end.getTime() + 1000 * 60 * 60 * 24 * 31));
  }, []);

  const searchParams = useMemo(() => {
    const queryObj: operations["event_getEvents"]["parameters"]["query"] = {
      "season[]": currentSeasons,
      "eventTypes[]": ["tournament"],
      start: start.current,
      end: end.toISOString(),
    };

    if (filters.region) {
      queryObj.region = filters.region;
    }

    return queryObj;
  }, [filters.region, end]);

  const { data: events, isFetching, isPending } = useEventSearch(
    searchParams,
    {
      placeholderData: (prev) => prev,
    }
  );

  const isLoadingEvents = isFetching || isPending;

  const results = useMemo(() => {
    let list = events ?? [];

    if (filters.region) {
      const target = filters.region.toUpperCase();
      list = list.filter((e) => {
        const r = e.location?.region?.toUpperCase() ?? "";
        const c = e.location?.country?.toUpperCase() ?? "";
        return r === target || c === target || r.includes(target);
      });
    }

    if (filters.eventType) {
      const selected = EVENT_TYPES.find((t) => t.id === filters.eventType);
      if (selected) {
        list = list.filter((e) => {
          if (e.program?.id && selected.programId && e.program.id === selected.programId) {
            return true;
          }
          if (e.program?.code && e.program.code.toUpperCase() === selected.id.toUpperCase()) {
            return true;
          }
          const skuUpper = e.sku.toUpperCase();
          const selUpper = selected.id.toUpperCase();
          if (skuUpper.includes(selUpper)) return true;
          if (selected.id === "V5RC" && (skuUpper.includes("VRC") || skuUpper.includes("V5RC"))) return true;
          if (selected.id === "VURC" && (skuUpper.includes("VEXU") || skuUpper.includes("VURC"))) return true;
          if (selected.id === "VIQRC" && (skuUpper.includes("VIQC") || skuUpper.includes("VIQRC"))) return true;
          return false;
        });
      }
    }

    if (!query) {
      return list;
    }

    const q = query.toUpperCase();
    return list.filter((event) => {
      if (event.name.toUpperCase().includes(q)) return true;
      if (event.sku.toUpperCase().includes(q)) return true;
      if (event.location?.venue?.toUpperCase().includes(q)) return true;
      return false;
    });
  }, [query, events, filters.region, filters.eventType]);

  const regionResults = useMemo(() => {
    if (!geo?.region || !geo.country) {
      return [];
    }

    if (geo.country === "United States") {
      return results.filter((event) => event.location?.region === geo.region);
    }

    return results.filter((event) => event.location?.country === geo.country);
  }, [geo?.region, geo?.country, results]);

  const hasSearchOrFilter = useMemo(
    () => query.length > 3 || isFilterActive,
    [query, isFilterActive]
  );

  const maxTime = useMemo(
    () => new Date(Date.now() + 1000 * 60 * 60 * 24 * 30 * 3),
    []
  );

  useEffect(() => {
    const shouldLoadMore =
      hasSearchOrFilter &&
      !isLoadingEvents &&
      results.length < 3 &&
      end < maxTime;

    if (shouldLoadMore) {
      onClickMore();
    }
  }, [hasSearchOrFilter, results.length, isLoadingEvents, onClickMore, end, maxTime]);

  const isSearchComplete = useMemo(() => {
    if (isLoadingEvents) return false;
    if (hasSearchOrFilter) {
      return end >= maxTime;
    }
    return true;
  }, [isLoadingEvents, hasSearchOrFilter, end, maxTime]);

  return (
    <div className="overflow-y-auto flex flex-col gap-4">
      <section className="mt-4">
        <h2 className="text-lg font-bold text-zinc-100 mx-2">Search</h2>
        <div className="flex gap-2 items-center mt-2">
          <Input
            type="text"
            placeholder="Enter an Event Name or VEX Event ID"
            className="px-4 py-3 rounded-md invalid:bg-red-500 flex-1"
            value={query}
            onChange={(e) => setQuery(e.currentTarget.value)}
          />
          <LinkButton
            to="/events/filters"
            className="flex items-center gap-1.5 px-3 py-3 font-medium text-sm whitespace-nowrap min-w-0 bg-emerald-600 active:bg-emerald-700 text-white"
          >
            <AdjustmentsHorizontalIcon className="w-5 h-5 flex-shrink-0" />
            <span className="truncate">Filters</span>
          </LinkButton>
        </div>

        {isFilterActive && (
          <p className="text-zinc-400 text-sm mt-2 mx-1">
            Filters have been applied, edit or remove these using the Filters button.
          </p>
        )}

        <Spinner show={isLoadingEventFromSKU} />
        {eventFromSKU && (
          <div className="border-y border-zinc-700 mt-2 p-3 flex flex-col items-start justify-start">
            <p className="text-sm whitespace-nowrap text-ellipsis overflow-hidden w-full">
              <span className={`font-mono ${getSkuTextColorClass(eventFromSKU.sku)}`}>
                {eventFromSKU.sku}
              </span>
              {formatEventDate(eventFromSKU.start, eventFromSKU.end) ? (
                <>
                  {" • "}
                  <span>{formatEventDate(eventFromSKU.start, eventFromSKU.end)}</span>
                </>
              ) : null}
              {eventFromSKU.location.venue ? (
                <>
                  {" • "}
                  <span>{eventFromSKU.location.venue}</span>
                </>
              ) : null}
            </p>
            <p className="whitespace-nowrap text-ellipsis overflow-hidden w-full">
              {eventFromSKU.name}
            </p>
            <LinkButton
              to={"/$sku"}
              params={{ sku: eventFromSKU.sku }}
              replace
              onClick={() => {
                unhideEvent(eventFromSKU.sku);
              }}
              className="mt-4 bg-emerald-600 w-full text-center"
            >
              Go
            </LinkButton>
          </div>
        )}
      </section>

      {regionResults.length > 0 && geo?.region && !filters.region ? (
        <section className="mt-4">
          <h2 className="text-lg font-bold text-zinc-100 mx-2">
            {geo.region}
          </h2>
          <ul className="divide-y divide-zinc-700 border-y border-zinc-700 mt-2">
            {regionResults?.map((event) => (
              <li
                key={event.sku}
                aria-label={`${event.name} at ${event.location?.venue}. ${event.sku}`}
              >
                <LinkButton
                  to={"/$sku"}
                  params={{ sku: event.sku }}
                  replace
                  onClick={() => {
                    unhideEvent(event.sku);
                  }}
                  className="w-full bg-transparent rounded-none py-3 text-left flex flex-col items-start justify-start"
                >
                  <p className="text-sm whitespace-nowrap text-ellipsis overflow-hidden w-full">
                    <span className={`font-mono ${getSkuTextColorClass(event.sku)}`}>
                      {event.sku}
                    </span>
                    {formatEventDate(event.start, event.end) ? (
                      <>
                        {" • "}
                        <span>{formatEventDate(event.start, event.end)}</span>
                      </>
                    ) : null}
                    {event.location?.venue ? (
                      <>
                        {" • "}
                        <span>{event.location.venue}</span>
                      </>
                    ) : null}
                  </p>
                  <p className="whitespace-nowrap text-ellipsis overflow-hidden w-full">
                    {event.name}
                  </p>
                </LinkButton>
              </li>
            ))}
          </ul>
        </section>
      ) : null}

      <section className="mt-4 mb-4">
        <h2 className="text-lg font-bold text-zinc-100 mx-2">Events</h2>
        {isSearchComplete && results.length === 0 ? (
          <p className="text-zinc-400 p-4 text-center border-y border-zinc-700 mt-2">
            No events found
          </p>
        ) : (
          <ul className="divide-y divide-zinc-700 border-y border-zinc-700 mt-2">
            {results?.map((event) => (
              <li
                key={event.sku}
                aria-label={`${event.name} at ${event.location?.venue}. ${event.sku}`}
              >
                <LinkButton
                  to={"/$sku"}
                  params={{ sku: event.sku }}
                  replace
                  onClick={() => {
                    unhideEvent(event.sku);
                  }}
                  className="w-full bg-transparent rounded-none py-3 text-left flex flex-col items-start justify-start"
                >
                  <p className="text-sm whitespace-nowrap text-ellipsis overflow-hidden w-full">
                    <span className={`font-mono ${getSkuTextColorClass(event.sku)}`}>
                      {event.sku}
                    </span>
                    {formatEventDate(event.start, event.end) ? (
                      <>
                        {" • "}
                        <span>{formatEventDate(event.start, event.end)}</span>
                      </>
                    ) : null}
                    {event.location?.venue ? (
                      <>
                        {" • "}
                        <span>{event.location.venue}</span>
                      </>
                    ) : null}
                  </p>
                  <p className="whitespace-nowrap text-ellipsis overflow-hidden w-full">
                    {event.name}
                  </p>
                </LinkButton>
              </li>
            ))}
          </ul>
        )}
        <Spinner show={isLoadingEvents} />
        {!isLoadingEvents && isSearchComplete && (
          <Button onClick={onClickMore} mode="normal" className="mt-4">
            Load More
          </Button>
        )}
      </section>
    </div>
  );
};

export const EventsRouteComponent: React.FC = () => {
  const location = useLocation();
  if (location.pathname === "/events/filters") {
    return <Outlet />;
  }
  return <EventsPage />;
};

export const Route = createFileRoute("/events")({
  component: EventsRouteComponent,
});
