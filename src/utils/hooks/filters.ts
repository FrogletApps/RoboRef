import { create } from "zustand";
import { Rule } from "./rules";
import { IncidentOutcome } from "@referee-fyi/share";

export type Filters = {
  outcomes: Record<IncidentOutcome, boolean>;
  rules: Rule[];
  division?: number;
  contact: Set<string>;
};

export const DEFAULT_FILTERS: Filters = {
  outcomes: {
    Disabled: true,
    General: true,
    Major: true,
    Minor: true,
    Inspection: true,
  },
  rules: [],
  contact: new Set(),
};

export const isFilterApplied = (filters: Filters): boolean => {
  const hasCustomOutcomes = Object.values(filters.outcomes).some((v) => !v);
  const hasCustomRules = filters.rules.length > 0;
  const hasCustomDivision = typeof filters.division === "number";
  const hasCustomContact = filters.contact.size > 0;
  return (
    hasCustomOutcomes ||
    hasCustomRules ||
    hasCustomDivision ||
    hasCustomContact
  );
};

interface FilterStore {
  filters: Filters;
  setFilters: (filters: Filters) => void;
  resetFilters: () => void;
}

export const useFilterStore = create<FilterStore>((set) => ({
  filters: DEFAULT_FILTERS,
  setFilters: (filters) => set({ filters }),
  resetFilters: () => set({ filters: DEFAULT_FILTERS }),
}));
