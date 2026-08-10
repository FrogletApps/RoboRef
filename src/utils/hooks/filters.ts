import { create } from "zustand";
import { Rule } from "./rules";
import { IncidentOutcome } from "@roboref/share";

export type Filters = {
  outcomes: Record<IncidentOutcome, boolean>;
  rules: Rule[];
  division?: number;
  contact: Set<string>;
  showPills?: boolean;
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
  showPills: true,
};

export const isFilterApplied = (filters: Filters): boolean => {
  const hasCustomOutcomes = Object.values(filters.outcomes).some((v) => !v);
  const hasCustomRules = filters.rules.length > 0;
  const hasCustomDivision = typeof filters.division === "number";
  const hasCustomContact = filters.contact.size > 0;
  const hasCustomPills = filters.showPills === false;
  return (
    hasCustomOutcomes ||
    hasCustomRules ||
    hasCustomDivision ||
    hasCustomContact ||
    hasCustomPills
  );
};

interface FilterStore {
  filters: Filters;
  setFilters: (filters: Filters) => void;
  resetFilters: () => void;

  teamFilters: Filters;
  setTeamFilters: (filters: Filters) => void;
  resetTeamFilters: () => void;
}

export const useFilterStore = create<FilterStore>((set) => ({
  filters: DEFAULT_FILTERS,
  setFilters: (filters) => set({ filters }),
  resetFilters: () => set({ filters: DEFAULT_FILTERS }),

  teamFilters: DEFAULT_FILTERS,
  setTeamFilters: (teamFilters) => set({ teamFilters }),
  resetTeamFilters: () => set({ teamFilters: DEFAULT_FILTERS }),
}));
