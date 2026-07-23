import { useEffect } from "react";
import { Button, IconButton } from "~components/Button";
import {
  ChevronDownIcon,
  ChevronLeftIcon,
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
  Link,
  Outlet,
  useLocation,
  useNavigate,
  useParams,
  useRouter,
} from "@tanstack/react-router";
import { QRCode } from "~components/QRCode";
import AppIcon from "/icons/roboref.svg?url";

function isValidSKU(sku: string) {
  return !!sku.match(
    /RE-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC|ADC)-[0-9]{2}-[0-9]{4}/g
  );
}

const EventPicker: React.FC = () => {
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
      mode="none"
      className="flex-1 active:bg-zinc-600"
      onClick={onClick}
      aria-description={
        "Click to " + (showDiv ? "Select Division" : "Select Event")
      }
    >
      <div
        className="grid items-center gap-2"
        style={{ gridTemplateColumns: "1fr 1.25rem" }}
      >
        <div className="flex-1 overflow-hidden whitespace-nowrap text-ellipsis">
          <p
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
        <ChevronDownIcon className="w-5 h-5" />
      </div>
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
    <header className="flex items-center justify-between gap-3 h-[56px] py-2 px-3 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm mb-3 w-full min-w-0">
      <div className="flex items-center gap-3 flex-1 min-w-0 overflow-hidden">
        <div className="h-8 flex items-center justify-center px-1 flex-shrink-0">
          <img src={AppIcon} alt="RoboRef Logo" className="h-8 w-8 object-contain" />
        </div>
        <h1 className="text-xl font-bold font-mono tracking-tight flex-1 min-w-0 overflow-hidden whitespace-nowrap text-ellipsis">
          <span className="text-zinc-100">RoboRef</span>
          <span className="text-zinc-400">.fyi</span>
        </h1>
      </div>
      <Link
        to="/share"
        title="Share RoboRef"
        aria-label="Share RoboRef"
        className="flex items-center justify-center gap-2.5 h-10 px-3.5 bg-zinc-800 hover:bg-zinc-700/80 active:bg-zinc-700 rounded-md border border-zinc-700/60 transition-colors group cursor-pointer flex-shrink-0"
      >
        <span className="text-base font-semibold text-zinc-300 group-hover:text-zinc-100 transition-colors">
          Share
        </span>
        <QRCode
          config={{
            text: "https://roboref.fyi",
            radius: 0.4,
            ecLevel: "H",
            fill: "#10b981",
            background: null,
          }}
          className="w-7.5 h-7.5 p-0 bg-transparent"
        />
      </Link>
    </header>
  );
};

export const AppShell: React.FC = () => {
  const { isLoading } = useCurrentEvent();
  const navigate = useNavigate();
  const router = useRouter();
  const location = useLocation();

  const isIndex = location.pathname === "/";
  const isSettings = location.pathname === "/settings";
  const isUpdates = location.pathname === "/updates";
  const isEvents = location.pathname === "/events";
  const isShare = location.pathname === "/share";
  const isPrivacy = location.pathname === "/privacy";

  const customHeaderTitle = isSettings
    ? "Settings"
    : isUpdates
    ? "Update Notes"
    : isEvents
    ? "Pick An Event"
    : isShare
    ? "Share RoboRef"
    : isPrivacy
    ? "Privacy Policy"
    : null;

  return (
    <main
      className="w-screen h-[100dvh] grid mb-4 p-4 overflow-hidden"
      style={{
        gridTemplateRows: "auto minmax(0, 1fr)",
        gridTemplateColumns: "calc(100dvw - 32px)",
      }}
    >
      <Toaster containerClassName="mb-16" />
      <ConnectionManager />
      <MigrationManager />
      <div className="flex flex-col max-w-full">
        {isIndex && <RoboRefTitleBar />}
        {isIndex ? (
          <nav className="h-16 flex gap-4 max-w-full">
            <EventPicker />
          </nav>
        ) : (
          <header className="flex items-center gap-3 p-3 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm w-full min-w-0 mb-4">
            <IconButton
              onClick={() =>
                router.history.canGoBack()
                  ? router.history.back()
                  : navigate({ to: "/" })
              }
              icon={<ChevronLeftIcon height={20} />}
              className="p-1.5 px-2.5 bg-zinc-800 hover:bg-zinc-700/80 active:bg-zinc-700 rounded-md border border-zinc-700/60 transition-colors aspect-auto"
              aria-label="Back"
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
