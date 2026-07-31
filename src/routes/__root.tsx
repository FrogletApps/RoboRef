import { useEffect } from "react";
import { Button, IconButton } from "~components/Button";
import {
  ChevronLeftIcon,
  HomeIcon,
  PlusIcon,
} from "@heroicons/react/24/outline";
import { Spinner } from "~components/Spinner";
import { useCurrentDivision, useCurrentEvent } from "~utils/hooks/state";
import { Toaster } from "react-hot-toast";
import { useEventInvitation } from "~utils/hooks/share";
import { useShareConnection } from "~models/ShareConnection";
import { useMutation } from "@tanstack/react-query";
import { runMigrations } from "../migrations";
import { toast } from "~components/Toast";
import { getEventInvitation, getShareProfile } from "~utils/data/share";
import { getSkuTextColorClass } from "~utils/data/state";
import {
  createRootRoute,
  Outlet,
  useLocation,
  useNavigate,
  useParams,
  useRouter,
} from "@tanstack/react-router";
import AppIcon from "/icons/roboref.svg?url";

function isValidSKU(sku: string) {
  return !!sku.match(
    /RE-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC|ADC)-[0-9]{2}-[0-9]{4}/g
  );
}

export const EventPicker: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { sku: skuParam } = useParams({ strict: false });

  const { data: event, isPending: isPendingCurrentEvent } = useCurrentEvent();
  const division = useCurrentDivision();

  const sku = event?.sku ?? (skuParam && isValidSKU(skuParam) ? skuParam : "");

  const selectedDiv = event?.divisions?.find((d) => d.id === division);
  const showDiv =
    location.pathname !== `/${event?.sku}` &&
    (event?.divisions?.length ?? 0) > 1;

  const isIndex = location.pathname === "/";

  const onClick = () => {
    if (showDiv && event) {
      navigate({ to: "/$sku", params: { sku: event.sku } });
    } else {
      navigate({ to: "/events" });
    }
  };

  if (!isIndex) {
    return (
      <div className="flex-1 overflow-hidden whitespace-nowrap text-ellipsis min-w-0">
        <p
          className="overflow-hidden whitespace-nowrap text-ellipsis"
          style={{
            visibility: sku && isPendingCurrentEvent ? "hidden" : "visible",
          }}
        >
          {event?.name ??
            (sku && isPendingCurrentEvent
              ? "Loading Event..."
              : "Select Event")}
        </p>
        <p className={`text-sm ${showDiv ? "text-emerald-400" : getSkuTextColorClass(sku)}`}>
          {showDiv ? <span>{selectedDiv?.name}</span> : sku}
        </p>
      </div>
    );
  }

  return (
    <Button
      mode="primary"
      className="w-full h-16 flex items-center justify-center gap-2 text-lg font-semibold rounded-lg shadow-sm"
      onClick={onClick}
      aria-label="Add a new event"
    >
      <PlusIcon className="w-6 h-6 stroke-[2.5]" />
      <span>Add a new event</span>
    </Button>
  );
};



const ConnectionManager: React.FC = () => {
  const { data: event } = useCurrentEvent();
  const { data: invitation } = useEventInvitation(event?.sku);

  const { connect, disconnect, updateProfile } = useShareConnection([
    "connect",
    "disconnect",
    "updateProfile",
  ]);

  useEffect(() => {
    if (invitation) {
      connect(invitation);
    } else {
      disconnect();
    }

    return () => {
      disconnect();
    };
  }, [connect, disconnect, invitation]);

  useEffect(() => {
    async function update() {
      const profile = await getShareProfile();
      updateProfile(profile);
    }
    update();
  }, [updateProfile]);

  useEffect(() => {
    const controller = new AbortController();

    document.addEventListener("visibilitychange", async () => {
      if (!event?.sku) {
        return;
      }

      if (document.visibilityState !== "visible") {
        return;
      }

      const invitation = await getEventInvitation(event.sku);
      if (invitation) {
        toast({ message: "Reconnecting...", type: "info" });
        connect(invitation);
      }
    });

    return () => controller.abort();
  }, [connect, event?.sku]);

  return null;
};

const MigrationManager: React.FC = () => {
  const { mutateAsync } = useMutation({
    mutationKey: ["migrations"],
    mutationFn: runMigrations,
    onSuccess: (data) => {
      const applied = Object.values(data).filter(
        (result) => !result.preapplied
      );

      if (applied.length > 0) {
        toast({ type: "info", message: "Applied Migrations!" });
      }
    },
  });

  useEffect(() => {
    mutateAsync();
  }, [mutateAsync]);

  return null;
};

const RoboRefTitleBar: React.FC = () => {
  return (
    <header className="flex items-center gap-3 h-[56px] py-2 px-3 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm w-full min-w-0">
      <div className="p-1.5 px-2.5 bg-zinc-800 rounded-md border border-zinc-700/60 flex items-center justify-center aspect-auto">
        <img src={AppIcon} alt="RoboRef Logo" className="h-5 w-5 object-contain" />
      </div>
      <h1 className="text-xl font-bold font-mono tracking-tight flex-1 min-w-0 overflow-hidden whitespace-nowrap text-ellipsis">
        <span className="text-zinc-100">RoboRef</span>
        <span className="text-zinc-400">.fyi</span>
      </h1>
    </header>
  );
};

export const AppShell: React.FC = () => {
  const { isLoading } = useCurrentEvent();
  const navigate = useNavigate();
  const router = useRouter();
  const location = useLocation();
  const { team: teamParam } = useParams({ strict: false });

  const isIndex = location.pathname === "/";
  const isSettings = location.pathname === "/settings";
  const isUpdates = location.pathname === "/updates";
  const isEvents = location.pathname === "/events";
  const isEventFilters = location.pathname === "/events/filters";
  const isShare = location.pathname === "/share";
  const isPrivacy = location.pathname === "/privacy";
  const isContact = location.pathname === "/contact";
  const isJoin = location.pathname.endsWith("/join");
  const isInvite = location.pathname.endsWith("/invite");
  const isNewNote = location.pathname.endsWith("/new");
  const isNoteHistory = location.pathname.endsWith("/history");
  const isEditNote = location.pathname.includes("/entry/") && !isNoteHistory;
  const isTeamNotes = location.pathname.endsWith("/teamNotes");
  const isDeleted = location.pathname.endsWith("/deleted");
  const isSummary = location.pathname.endsWith("/summary");
  const isFilters = location.pathname.endsWith("/filters");
  const isTeamPage = Boolean(teamParam) && !isTeamNotes;

  const customHeaderTitle = isSettings
    ? "Settings"
    : isUpdates
    ? "Change Log"
    : isEventFilters
    ? "Filter Events"
    : isEvents
    ? "Pick An Event"
    : isShare
    ? "Share RoboRef"
    : isPrivacy
    ? "Privacy Policy"
    : isContact
    ? "Contact Developer"
    : isJoin
    ? "Join Request"
    : isInvite
    ? "Invite User"
    : isNewNote
    ? "New Note"
    : isNoteHistory
    ? "Note History"
    : isEditNote
    ? "Edit Note"
    : isTeamNotes
    ? "Team Notes"
    : isDeleted
    ? "Deleted Notes"
    : isSummary
    ? "Note Summary"
    : isFilters
    ? "Filter Notes"
    : isTeamPage
    ? `${teamParam} Team Info`
    : null;

  return (
    <main
      className="w-full max-w-full h-[100dvh] grid p-4 overflow-hidden"
      style={{
        gridTemplateRows: "auto minmax(0, 1fr)",
        gridTemplateColumns: "minmax(0, 1fr)",
      }}
    >
      <Toaster containerClassName="mb-16" />
      <ConnectionManager />
      <MigrationManager />
      <div className="flex flex-col max-w-full">
        {isIndex && <RoboRefTitleBar />}
        {!isIndex && (
          <header className="flex items-center gap-3 h-[56px] py-2 px-3 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm w-full min-w-0">
            <IconButton
              onClick={() =>
                customHeaderTitle && router.history.canGoBack()
                  ? router.history.back()
                  : navigate({ to: "/" })
              }
              icon={
                customHeaderTitle ? (
                  <ChevronLeftIcon height={20} />
                ) : (
                  <HomeIcon height={20} />
                )
              }
              className="p-1.5 px-2.5 bg-zinc-800 hover:bg-zinc-700/80 active:bg-zinc-700 rounded-md border border-zinc-700/60 transition-colors aspect-auto"
              aria-label={customHeaderTitle ? "Back" : "Home"}
            />
            {customHeaderTitle ? (
              <h1 className="text-xl font-bold font-mono tracking-tight text-zinc-100 overflow-hidden whitespace-nowrap text-ellipsis flex-1 min-w-0">
                {customHeaderTitle}
              </h1>
            ) : (
              <EventPicker />
            )}
          </header>
        )}
      </div>
      <Spinner show={isLoading} />
      {!isLoading && <Outlet />}
    </main>
  );
};

export const Route = createRootRoute({
  component: AppShell,
});
