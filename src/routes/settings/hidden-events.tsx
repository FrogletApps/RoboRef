import React from "react";
import { Button } from "~components/Button";
import { useEvent } from "~utils/hooks/robotevents";
import { useHiddenEvents, useUnhideEvent } from "~utils/hooks/history";
import { getSkuTextColorClass } from "~utils/data/state";
import { twMerge } from "tailwind-merge";
import { createFileRoute } from "@tanstack/react-router";

const HiddenEventItem: React.FC<{ sku: string }> = ({ sku }) => {
  const { data: event } = useEvent(sku);
  const { mutate: unhide } = useUnhideEvent();

  return (
    <Button
      mode="normal"
      className="w-full max-w-full mt-4 relative text-left"
      onClick={() => unhide(sku)}
    >
      <div className="text-sm flex">
        <p className={twMerge(getSkuTextColorClass(sku), "font-mono flex-1")}>
          {sku}
        </p>
      </div>
      <p>{event?.name ?? sku}</p>
    </Button>
  );
};

export const HiddenEventsPage: React.FC = () => {
  const { data: hiddenEvents = [] } = useHiddenEvents();

  return (
    <main className="max-w-xl h-full w-full mx-auto flex-1 pb-6 overflow-y-auto p-4">
      <p className="text-zinc-400 text-sm">Tap an event to unhide it</p>
      {hiddenEvents.length === 0 ? (
        <p className="text-zinc-400 text-sm mt-4">No hidden events.</p>
      ) : (
        <div className="flex flex-col">
          {hiddenEvents.map((sku) => (
            <HiddenEventItem key={sku} sku={sku} />
          ))}
        </div>
      )}
    </main>
  );
};

export const Route = createFileRoute("/settings/hidden-events")({
  component: HiddenEventsPage,
});
