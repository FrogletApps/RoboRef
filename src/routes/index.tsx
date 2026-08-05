import { Button, LinkButton } from "~components/Button";
import { useCallback, useEffect, useMemo, useState } from "react";

import { ArrowPathIcon, Cog8ToothIcon, QrCodeIcon, UserGroupIcon } from "@heroicons/react/20/solid";
import { useEventSearch } from "~utils/hooks/robotevents";
import {
  useHiddenEvents,
  useRecentEvents,
} from "~utils/hooks/history";
import {
  getSkuTextColorClass,
  isWorldsBuild,
  WORLDS_EVENTS,
} from "~utils/data/state";
import { useQuery } from "@tanstack/react-query";
import { getEventInvitation } from "~utils/data/share";
import { UpdatePrompt } from "~components/UpdatePrompt";
import { useDisplayMode, useInstallPrompt } from "~utils/hooks/pwa";
import { twMerge } from "tailwind-merge";
import AppIcon from "/icons/roboref.svg?url";
import { formatEventDate } from "~utils/time";

import "./markdown.css";
import changeLogRaw from "../../documents/changeLog.md?raw";
import { getChangeLogHash } from "./updates";

import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { EventPicker } from "./__root";

const UserWelcome: React.FC = () => {
  return (
    <section className="bg-zinc-900 p-4 rounded-md">
      <h2 className="font-bold">Welcome to RoboRef!</h2>
      <p>
        This is an anomaly log for Head Referees at VEX robotics competitions.
      </p>
      <p>
        To get started, add a new event using the button above.
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
    <section className="bg-zinc-900 p-4 rounded-md">
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

const HomePage: React.FC = () => {
  const navigate = useNavigate();
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

  useEffect(() => {
    const userVersion = localStorage.getItem("version");
    const lastSeenHash = localStorage.getItem("last_seen_changelog_hash");
    const currentHash = getChangeLogHash(changeLogRaw);

    if (userVersion && userVersion !== __ROBOREF_VERSION__ && lastSeenHash !== currentHash) {
      navigate({ to: "/updates" });
    }

    localStorage.setItem("version", __ROBOREF_VERSION__);
    localStorage.setItem("last_seen_changelog_hash", currentHash);
  }, [navigate]);

  return (
    <div className="overflow-y-auto flex flex-col gap-4">
      <nav className="grid grid-cols-3 gap-2 mt-4 mb-4 w-full">
        <LinkButton
          to="/updates"
          className="flex items-center justify-center gap-1.5 px-2 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
        >
          <ArrowPathIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
          <span className="truncate">Change Log</span>
        </LinkButton>
        <LinkButton
          to="/share"
          className="flex items-center justify-center gap-1.5 px-2 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
        >
          <QrCodeIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
          <span className="truncate">Share RoboRef</span>
        </LinkButton>
        <LinkButton
          to="/settings"
          className="flex items-center justify-center gap-1.5 px-2 py-2 text-xs sm:text-sm font-medium whitespace-nowrap min-w-0"
        >
          <Cog8ToothIcon className="w-4 h-4 sm:w-5 sm:h-5 flex-shrink-0" />
          <span className="truncate">Settings</span>
        </LinkButton>
      </nav>
      <EventPicker />
      <UpdatePrompt />
      <section className="max-w-full flex flex-col gap-4 mb-4">
        {visibleEvents?.map((event) => (
          <LinkButton
            to={"/$sku"}
            params={{ sku: event.sku }}
            className="w-full max-w-full relative"
            key={event.sku}
          >
            <div className="text-sm flex">
              <p className="break-words flex-1 min-w-0">
                <span
                  className={twMerge(
                    getSkuTextColorClass(event.sku),
                    "font-mono"
                  )}
                >
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
              {eventsInvitations?.find((inv) => inv?.sku === event.sku) ? (
                <UserGroupIcon height={20} className="flex-shrink-0 ml-2" />
              ) : null}
            </div>
            <p className="break-words w-full">{event.name}</p>
          </LinkButton>
        ))}
        {visibleEvents?.length === 0 ? (
          <UserWelcome />
        ) : null}
        <InstallPrompt />
      </section>
    </div>
  );
};

export const Route = createFileRoute("/")({
  component: HomePage,
});
