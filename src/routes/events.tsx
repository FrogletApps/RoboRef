import { createFileRoute } from "@tanstack/react-router";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Button, LinkButton } from "~components/Button";
import { Input } from "~components/Input";
import { Spinner } from "~components/Spinner";
import { getSkuTextColorClass } from "~utils/data/state";
import { useUnhideEvent } from "~utils/hooks/history";
import { useGeolocation } from "~utils/hooks/meta";
import { currentSeasons, useEvent, useEventSearch } from "~utils/hooks/robotevents";

function isValidSKU(sku: string) {
  return !!sku.match(
    /RE-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC|ADC)-[0-9]{2}-[0-9]{4}/g
  );
}

export const EventsPage: React.FC = () => {
  const { mutate: unhideEvent } = useUnhideEvent();
  const { data: geo } = useGeolocation();

  const [query, setQuery] = useState("");
  const { data: eventFromSKU, isLoading: isLoadingEventFromSKU } = useEvent(
    query,
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
        if (event.name.toUpperCase().includes(query)) {
          return true;
        }

        if (event.sku.toUpperCase().includes(query)) {
          return true;
        }

        if (event.location.venue?.toUpperCase().includes(query)) {
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
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto">
      <Spinner show={isLoadingEvents} />
      <section className="mt-4">
        <h2 className="text-lg font-bold text-zinc-100 mx-2">Search</h2>
        <Input
          type="text"
          placeholder="SKU or Event Name"
          className="px-4 py-4 rounded-md invalid:bg-red-500 w-full mt-2"
          value={query}
          onChange={(e) => setQuery(e.currentTarget.value.toUpperCase())}
        />
        <Spinner show={isLoadingEventFromSKU} />
        {eventFromSKU && (
          <>
            <div className="p-2 pt-4">
              <p className="text-sm whitespace-nowrap text-ellipsis overflow-hidden">
                <span className={`font-mono ${getSkuTextColorClass(eventFromSKU.sku)}`}>
                  {eventFromSKU.sku}
                </span>
                {" • "}
                <span>{eventFromSKU.location.venue}</span>
              </p>
              <p className="whitespace-nowrap text-ellipsis overflow-hidden">
                {eventFromSKU.name}
              </p>
            </div>
            <LinkButton
              to={"/$sku"}
              params={{ sku: eventFromSKU.sku }}
              onClick={() => {
                unhideEvent(eventFromSKU.sku);
              }}
              className="mt-4 bg-emerald-600 w-full text-center"
            >
              Go
            </LinkButton>
          </>
        )}
      </section>
      {regionResults.length > 0 && geo?.region ? (
        <section className="mt-4">
          <h2 className="text-lg font-bold text-zinc-100 mx-2">
            {geo.region}
          </h2>
          <ul>
            {regionResults?.map((event) => (
              <li
                key={event.sku}
                aria-label={`${event.name} at ${event.location.venue}. ${event.sku}`}
              >
                <LinkButton
                  to={"/$sku"}
                  params={{ sku: event.sku }}
                  onClick={() => {
                    unhideEvent(event.sku);
                  }}
                  className="w-full mt-2 bg-transparent"
                >
                  <p className="text-sm whitespace-nowrap text-ellipsis overflow-hidden">
                    <span className={`font-mono ${getSkuTextColorClass(event.sku)}`}>
                      {event.sku}
                    </span>
                    {" • "}
                    <span>{event.location.venue}</span>
                  </p>
                  <p className="whitespace-nowrap text-ellipsis overflow-hidden">
                    {event.name}
                  </p>
                </LinkButton>
              </li>
            ))}
          </ul>
        </section>
      ) : null}
      <section className="mt-4">
        <h2 className="text-lg font-bold text-zinc-100 mx-2">Events</h2>
        <ul>
          {results?.map((event) => (
            <li
              key={event.sku}
              aria-label={`${event.name} at ${event.location.venue}. ${event.sku}`}
            >
              <LinkButton
                to={"/$sku"}
                params={{ sku: event.sku }}
                onClick={() => {
                  unhideEvent(event.sku);
                }}
                className="w-full mt-2 bg-transparent"
              >
                <p className="text-sm whitespace-nowrap text-ellipsis overflow-hidden">
                  <span className={`font-mono ${getSkuTextColorClass(event.sku)}`}>
                    {event.sku}
                  </span>
                  {" • "}
                  <span>{event.location.venue}</span>
                </p>
                <p className="whitespace-nowrap text-ellipsis overflow-hidden">
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
    </main>
  );
};

export const Route = createFileRoute("/events")({
  component: EventsPage,
});
