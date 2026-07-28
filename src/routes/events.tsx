import { createFileRoute } from "@tanstack/react-router";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Button, LinkButton } from "~components/Button";
import { Input } from "~components/Input";
import { Spinner } from "~components/Spinner";
import { getSkuTextColorClass } from "~utils/data/state";
import { useUnhideEvent } from "~utils/hooks/history";
import { useGeolocation } from "~utils/hooks/meta";
import { currentSeasons, useEvent, useEventSearch } from "~utils/hooks/robotevents";
import { formatEventDate } from "~utils/time";

function isValidSKU(sku: string) {
  return !!sku.match(
    /RE-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC|ADC)-[0-9]{2}-[0-9]{4}/gi
  );
}

export const EventsPage: React.FC = () => {
  const { mutate: unhideEvent } = useUnhideEvent();
  const { data: geo } = useGeolocation();

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
  }, [setEnd]);

  const { data: events, isPending: isLoadingEvents } = useEventSearch(
    {
      "season[]": currentSeasons,
      "eventTypes[]": ["tournament"],
      start: start.current,
      end: end.toISOString(),
    },
    {
      placeholderData: (prev) => prev,
    }
  );

  const results = useMemo(() => {
    if (!query) {
      return events ?? [];
    }

    return (
      events?.filter((event) => {
        if (event.name.toUpperCase().includes(query.toUpperCase())) {
          return true;
        }

        if (event.sku.toUpperCase().includes(query.toUpperCase())) {
          return true;
        }

        if (event.location.venue?.toUpperCase().includes(query.toUpperCase())) {
          return true;
        }
      }) ?? []
    );
  }, [query, events]);

  const regionResults = useMemo(() => {
    if (!geo?.region || !geo.country) {
      return [];
    }

    if (geo.country === "United States") {
      return results.filter((event) => event.location.region === geo.region);
    }

    return results.filter((event) => event.location.country === geo.country);
  }, [geo?.region, geo?.country, results]);

  useEffect(() => {
    const maxTime = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30 * 3);

    const shouldLoadMore =
      query.length > 3 &&
      !isLoadingEvents &&
      results.length < 1 &&
      end < maxTime;

    if (shouldLoadMore) {
      onClickMore();
    }
  }, [query, results, isLoadingEvents, onClickMore, end]);

  return (
    <div className="overflow-y-auto flex flex-col gap-4">
      <Spinner show={isLoadingEvents} />
      <section className="mt-4">
        <h2 className="text-lg font-bold text-zinc-100 mx-2">Search</h2>
        <Input
          type="text"
          placeholder="Enter an Event Name or VEX Event ID"
          className="px-4 py-4 rounded-md invalid:bg-red-500 w-full mt-2"
          value={query}
          onChange={(e) => setQuery(e.currentTarget.value)}
        />
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
      {regionResults.length > 0 && geo?.region ? (
        <section className="mt-4">
          <h2 className="text-lg font-bold text-zinc-100 mx-2">
            {geo.region}
          </h2>
          <ul className="divide-y divide-zinc-700 border-y border-zinc-700 mt-2">
            {regionResults?.map((event) => (
              <li
                key={event.sku}
                aria-label={`${event.name} at ${event.location.venue}. ${event.sku}`}
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
                    {event.location.venue ? (
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
        <ul className="divide-y divide-zinc-700 border-y border-zinc-700 mt-2">
          {results?.map((event) => (
            <li
              key={event.sku}
              aria-label={`${event.name} at ${event.location.venue}. ${event.sku}`}
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
                  {event.location.venue ? (
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
        <Spinner show={isLoadingEvents} />
        <Button onClick={onClickMore} mode="normal" className="mt-4">
          Load More
        </Button>
      </section>
    </div>
  );
};

export const Route = createFileRoute("/events")({
  component: EventsPage,
});
