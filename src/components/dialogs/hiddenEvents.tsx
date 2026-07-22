import React from "react";
import { Button } from "~components/Button";
import { Dialog, DialogHeader, DialogBody } from "~components/Dialog";
import { useEvent } from "~utils/hooks/robotevents";
import { useHiddenEvents, useUnhideEvent } from "~utils/hooks/history";
import { getSkuTextColorClass } from "~utils/data/state";
import { twMerge } from "tailwind-merge";

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

export const HiddenEventsDialog: React.FC<{
  open: boolean;
  onClose: () => void;
}> = ({ open, onClose }) => {
  const { data: hiddenEvents = [] } = useHiddenEvents();

  return (
    <Dialog
      open={open}
      mode="modal"
      onClose={onClose}
      aria-label="Hidden Events"
    >
      <DialogHeader title="Hidden Events" onClose={onClose} />
      <DialogBody className="p-4">
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
      </DialogBody>
    </Dialog>
  );
};
