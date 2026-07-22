import { Button, LinkButton } from "~components/Button";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Dialog, DialogHeader, DialogBody } from "~components/Dialog";

import { Cog8ToothIcon, UserGroupIcon } from "@heroicons/react/20/solid";
import { useEvent, useEventSearch } from "~utils/hooks/robotevents";
import {
  useHiddenEvents,
  useRecentEvents,
  useUnhideEvent,
} from "~utils/hooks/history";
import {
  getSkuTextColorClass,
  isWorldsBuild,
  WORLDS_EVENTS,
} from "~utils/data/state";
import { useQuery } from "@tanstack/react-query";
import { getEventInvitation } from "~utils/data/share";
import { ClickToCopy } from "~components/ClickToCopy";
import { UpdatePrompt } from "~components/UpdatePrompt";
import { useDisplayMode, useInstallPrompt } from "~utils/hooks/pwa";
import { twMerge } from "tailwind-merge";

import AppIcon from "/icons/roboref.svg?url";
import UpdateNotes from "../../documents/updateNotes.md";

import "./markdown.css";

import { createFileRoute } from "@tanstack/react-router";

const UserWelcome: React.FC = () => {
  return (
    <section className="mt-4 bg-zinc-900 p-4 rounded-md">
      <h2 className="font-bold">Welcome to RoboRef!</h2>
      <p>
        This is an anomaly log for Head Referees at robotics events.
      </p>
      <p>
        To get started, pick your event from the dropdown above.
      </p>
    </section>
  );
};

const InstallPrompt: React.FC = () => {
  const mode = useDisplayMode();
  const prompt = useInstallPrompt();
  const [hidden, setHidden] = useState(true);

  useEffect(() => {
    const value = localStorage.getItem("meta#installPromptHidden");
    if (value === "true") {
      setHidden(true);
    } else {
      setHidden(false);
    }
  }, []);

  const shouldPrompt = useMemo(() => {
    if (hidden) {
      return false;
    }

    if (mode === "standalone") {
      return false;
    }

    return prompt !== null;
  }, [hidden, mode, prompt]);

  const onClickInstall = useCallback(() => {
    if (prompt) {
      prompt.prompt();
    }
  }, [prompt]);

  const onClickDismiss = useCallback(() => {
    setHidden(true);
    localStorage.setItem("meta#installPromptHidden", "true");
  }, []);

  if (!shouldPrompt) {
    return null;
  }

  return (
    <section className="mt-4 bg-zinc-900 p-4 rounded-md">
      <header className="flex gap-4 items-center">
        <img src={AppIcon} alt="RoboRef" className="w-12 h-12" />
        <p>
          For a better experience, consider adding RoboRef to your home
          screen.
        </p>
      </header>
      <nav className="flex items-end justify-center mt-4 gap-2">
        <Button mode="primary" onClick={onClickInstall}>
          Install
        </Button>
        <Button mode="normal" onClick={onClickDismiss}>
          Dismiss
        </Button>
      </nav>
    </section>
  );
};

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

const HiddenEventsDialog: React.FC<{
  open: boolean;
  onClose: () => void;
  hiddenEvents: string[];
}> = ({ open, onClose, hiddenEvents }) => {
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
          <div className="flex flex-col max-h-96 overflow-y-auto">
            {hiddenEvents.map((sku) => (
              <HiddenEventItem key={sku} sku={sku} />
            ))}
          </div>
        )}
      </DialogBody>
    </Dialog>
  );
};

function useHomeEvents() {
  const { data: worldsEvents } = useEventSearch(
    {
      "sku[]": WORLDS_EVENTS,
    },
    { enabled: isWorldsBuild() }
  );

  const { data: recentUser } = useRecentEvents(5);

  return isWorldsBuild() ? worldsEvents : recentUser;
}

export const HomePage: React.FC = () => {
  const events = useHomeEvents();
  const { data: hiddenEvents = [] } = useHiddenEvents();
  const visibleEvents = useMemo(() => {
    return events?.filter((event) => !hiddenEvents.includes(event.sku));
  }, [events, hiddenEvents]);

  const { data: eventsInvitations } = useQuery({
    queryKey: ["event_invitations", visibleEvents],
    queryFn: () =>
      Promise.all(
        visibleEvents?.map((event) => getEventInvitation(event.sku)) ?? []
      ),
  });

  const [updateDialogOpen, setUpdateDialogOpen] = useState(false);
  const [hiddenDialogOpen, setHiddenDialogOpen] = useState(false);

  useEffect(() => {
    const userVersion = localStorage.getItem("version");

    if (userVersion && userVersion !== __ROBOREF_VERSION__) {
      setUpdateDialogOpen(true);
    }

    localStorage.setItem("version", __ROBOREF_VERSION__);
  }, []);

  return (
    <>
      <div className="overflow-y-auto">
        <nav className="flex items-center gap-4 mt-4">
          <div className="flex-1">
            <Button
              mode="primary"
              className="text-right w-max"
              onClick={() => setUpdateDialogOpen(true)}
            >
              Update Notes
            </Button>
          </div>
          <LinkButton to="/settings" className="flex items-center gap-2">
            <Cog8ToothIcon height={20} />
            <p>Settings</p>
          </LinkButton>
        </nav>
        <UpdatePrompt />
        <section className="max-w-full mb-4">
          {visibleEvents?.map((event) => (
            <LinkButton
              to={"/$sku"}
              params={{ sku: event.sku }}
              className="w-full max-w-full mt-4 relative"
              key={event.sku}
            >
              <div className="text-sm flex">
                <p
                  className={twMerge(
                    getSkuTextColorClass(event.sku),
                    "font-mono flex-1"
                  )}
                >
                  {event.sku}
                </p>
                {eventsInvitations?.find((inv) => inv?.sku === event.sku) ? (
                  <UserGroupIcon height={20} />
                ) : null}
              </div>
              <p>{event.name}</p>
            </LinkButton>
          ))}
          {visibleEvents?.length === 0 && hiddenEvents.length === 0 ? (
            <UserWelcome />
          ) : null}
          {hiddenEvents.length > 0 && (
            <Button
              mode="normal"
              className="w-full max-w-full mt-4 relative text-left"
              onClick={() => setHiddenDialogOpen(true)}
            >
              <div className="text-sm flex">
                <p className="text-white font-mono flex-1">
                  Hidden Events
                </p>
              </div>
              <p>
                {hiddenEvents.length} event
                {hiddenEvents.length === 1 ? "" : "s"} hidden
              </p>
            </Button>
          )}
          <InstallPrompt />
        </section>
      </div>
      <Dialog
        open={updateDialogOpen}
        mode="modal"
        onClose={() => setUpdateDialogOpen(false)}
        aria-label="What's New with RoboRef"
      >
        <DialogHeader
          title="What's New"
          onClose={() => setUpdateDialogOpen(false)}
        />
        <DialogBody className="markdown">
          <section className="m-4 mt-0">
            <p>Build Version</p>
            <ClickToCopy message={__ROBOREF_VERSION__} />
            <UpdateNotes />
          </section>
        </DialogBody>
      </Dialog>
      <HiddenEventsDialog
        open={hiddenDialogOpen}
        onClose={() => setHiddenDialogOpen(false)}
        hiddenEvents={hiddenEvents}
      />
    </>
  );
};

export const Route = createFileRoute("/")({
  component: HomePage,
});
