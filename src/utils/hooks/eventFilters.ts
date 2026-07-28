import { create } from "zustand";
import { persist } from "zustand/middleware";

export type EventTypeOption = {
  id: string;
  name: string;
  programId?: number;
};

export const EVENT_TYPES: EventTypeOption[] = [
  { id: "", name: "All Event Types" },
  { id: "V5RC", name: "VEX V5 (V5RC)", programId: 1 },
  { id: "VIQRC", name: "VEX IQ (VIQRC)", programId: 41 },
  { id: "VURC", name: "VEX U (VURC)", programId: 4 },
  { id: "VAIRC", name: "VEX AI (VAIRC)", programId: 57 },
  { id: "ADC", name: "Aerial Drone (ADC)", programId: 44 },
];

export type EventFilters = {
  region: string;
  eventType: string;
};

export const DEFAULT_EVENT_FILTERS: EventFilters = {
  region: "",
  eventType: "",
};

export const isEventFilterApplied = (filters: EventFilters): boolean => {
  return (
    (filters?.region ?? "") !== "" ||
    (filters?.eventType ?? "") !== ""
  );
};

interface EventFilterStore {
  filters: EventFilters;
  setFilters: (filters: EventFilters) => void;
  resetFilters: () => void;
}

export const useEventFilterStore = create<EventFilterStore>()(
  persist(
    (set) => ({
      filters: DEFAULT_EVENT_FILTERS,
      setFilters: (filters) => set({ filters }),
      resetFilters: () => set({ filters: DEFAULT_EVENT_FILTERS }),
    }),
    {
      name: "roboref:event_filters",
    }
  )
);
