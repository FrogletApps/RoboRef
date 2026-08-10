import React, { useCallback, useMemo, useState } from "react";
import { createFileRoute, useRouter } from "@tanstack/react-router";
import { useCurrentEvent } from "~utils/hooks/state";
import { useRulesForEvent } from "~utils/hooks/rules";
import { useShareConnection } from "~models/ShareConnection";
import { Checkbox, RulesMultiSelect, Select } from "~components/Input";
import { Button } from "~components/Button";
import { OUTCOMES } from "@roboref/share";
import { Filters, useFilterStore } from "~utils/hooks/filters";
import { Spinner } from "~components/Spinner";

export type FilterSearch = {
  target?: "event" | "team";
};

const FilterPage: React.FC = () => {
  const router = useRouter();
  const { target } = Route.useSearch();
  const isTeam = target === "team";
  const { data: event } = useCurrentEvent();
  const divisions = useMemo(() => event?.divisions ?? [], [event]);
  const { data: game } = useRulesForEvent(event);

  const eventFilters = useFilterStore((state) => state.filters);
  const setEventFilters = useFilterStore((state) => state.setFilters);
  const resetEventFilters = useFilterStore((state) => state.resetFilters);

  const teamFilters = useFilterStore((state) => state.teamFilters);
  const setTeamFilters = useFilterStore((state) => state.setTeamFilters);
  const resetTeamFilters = useFilterStore((state) => state.resetTeamFilters);

  const globalFilters = isTeam ? teamFilters : eventFilters;
  const setGlobalFilters = isTeam ? setTeamFilters : setEventFilters;
  const resetGlobalFilters = isTeam ? resetTeamFilters : resetEventFilters;

  const [filters, setFilters] = useState<Filters>(globalFilters);

  const setFiltersField = useCallback(
    <T extends keyof Filters>(key: T, value: Filters[T]) => {
      setFilters((f) => ({ ...f, [key]: value }));
    },
    []
  );

  const { invitations } = useShareConnection(["invitations"]);

  const onClickApply = useCallback(() => {
    setGlobalFilters(filters);
    if (router.history.canGoBack()) {
      router.history.back();
    } else {
      router.navigate({ to: "/$sku/summary", params: { sku: event?.sku ?? "" } });
    }
  }, [filters, setGlobalFilters, router, event?.sku]);

  const onClickRemoveAll = useCallback(() => {
    resetGlobalFilters();
    if (router.history.canGoBack()) {
      router.history.back();
    } else {
      router.navigate({ to: "/$sku/summary", params: { sku: event?.sku ?? "" } });
    }
  }, [resetGlobalFilters, router, event?.sku]);

  if (!event || !game) {
    return <Spinner show />;
  }

  return (
    <div className="max-w-xl h-full w-full mx-auto flex-1 overflow-y-auto p-4 flex flex-col justify-between gap-4">
      <div className="flex flex-col gap-4">
        <label>
          <p className="font-medium">Include Rules</p>
          <RulesMultiSelect
            game={game}
            value={filters.rules}
            onChange={(rules) => setFiltersField("rules", rules)}
          />
        </label>
        <div>
          <p className="font-medium">Outcomes</p>
          {OUTCOMES.map((outcome) => (
            <Checkbox
              key={outcome}
              label={outcome}
              checked={filters.outcomes[outcome]}
              onChange={(e) =>
                setFiltersField("outcomes", {
                  ...filters.outcomes,
                  [outcome]: e.currentTarget.checked,
                })
              }
            />
          ))}
        </div>
        <div>
          <p className="font-medium">Display Options</p>
          <Checkbox
            label="Show Note Summary pills"
            checked={filters.showPills ?? true}
            onChange={(e) =>
              setFiltersField("showPills", e.currentTarget.checked)
            }
          />
        </div>
        {!isTeam && divisions.length > 0 ? (
          <label>
            <p className="font-medium">Division</p>
            <Select
              value={filters.division}
              onChange={(e) =>
                setFiltersField(
                  "division",
                  isNaN(Number.parseInt(e.currentTarget.value))
                    ? undefined
                    : Number.parseInt(e.currentTarget.value)
                )
              }
              className="w-full mt-1"
            >
              <option value={undefined}>Pick Division</option>
              {divisions
                .sort((a, b) => a.order! - b.order!)
                .map((div) => (
                  <option value={div.id} key={div.id}>
                    {div.name}
                  </option>
                ))}
            </Select>
          </label>
        ) : null}
        {invitations.length > 0 ? (
          <label>
            <p className="font-medium">User Created/Modified</p>
            <fieldset>
              {invitations.map((inv) => (
                <Checkbox
                  key={inv.user.key}
                  label={inv.user.name}
                  labelProps={{ className: "mt-2" }}
                  bind={{
                    value: filters.contact.has(inv.user.key),
                    onChange: (checked) => {
                      const newContact = new Set(filters.contact);
                      if (checked) {
                        newContact.add(inv.user.key);
                      } else {
                        newContact.delete(inv.user.key);
                      }
                      setFiltersField("contact", newContact);
                    },
                  }}
                />
              ))}
            </fieldset>
          </label>
        ) : null}
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

export const Route = createFileRoute("/$sku/filters")({
  component: FilterPage,
  validateSearch: (search: Record<string, unknown>): FilterSearch => ({
    target: search.target === "team" ? "team" : "event",
  }),
});
