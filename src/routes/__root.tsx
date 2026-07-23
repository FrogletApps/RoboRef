import { useCallback, useEffect, useMemo, useState } from "react";
import {
  useCurrentSeason,
  useSeason,
} from "~utils/hooks/robotevents";
import { Button, IconButton, ExternalLinkButton } from "~components/Button";
import {
  BookOpenIcon,
  ChevronDownIcon,
  XMarkIcon,
  ChevronLeftIcon,
  MagnifyingGlassIcon,
} from "@heroicons/react/24/outline";
import { Spinner } from "~components/Spinner";
import { useCurrentDivision, useCurrentEvent } from "~utils/hooks/state";
import {
  Dialog,
  DialogBody,
  DialogCustomHeader,
} from "~components/Dialog";
import { ProgramCode } from "@referee-fyi/robotevents";
import { RulesSelect } from "~components/Input";
import { Rule, useRulesForSeason } from "~utils/hooks/rules";
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

  const onClick = () => {
    if (showDiv && event) {
      navigate({ to: "/$sku", params: { sku: event.sku } });
    } else {
      navigate({ to: "/events" });
    }
  };

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

const Rules: React.FC = () => {
  const { data: event } = useCurrentEvent();

  const [open, setOpen] = useState(false);
  const program = useMemo(() => event?.program.id as ProgramCode, [event]);

  const { data: currentSeasonForProgram } = useCurrentSeason(program);
  const { data: season } = useSeason(event?.season.id);
  const { data: rules } = useRulesForSeason(season ?? currentSeasonForProgram);

  const [rule, setRule] = useState<Rule | null>(null);

  const qaUrl = useMemo(() => {
    if (!rules?.qa || !rule) return undefined;
    return `${rules.qa}?query=${rule.rule.replace(/[<>]/g, "")}`;
  }, [rules, rule]);

  const onClose = useCallback(() => {
    setRule(null);
    setOpen(false);
  }, []);

  if (!program || !event) {
    return null;
  }

  return (
    <>
      <Dialog
        open={open}
        mode="modal"
        onClose={onClose}
        aria-label="Rules Reference"
      >
        <DialogCustomHeader>
          <IconButton
            icon={<XMarkIcon height={24} />}
            onClick={onClose}
            className="bg-transparent"
            autoFocus
          />
          <RulesSelect
            game={rules}
            rule={rule}
            setRule={setRule}
            className="w-full"
          />
        </DialogCustomHeader>
        <DialogBody className="px-4 py-6 flex flex-col gap-6 relative min-h-40 justify-center">
          {!rules ? (
            <Spinner show={true} />
          ) : rule ? (
            <div className="flex flex-col gap-4 bg-zinc-800/50 border border-zinc-700/50 p-6 rounded-xl backdrop-blur-sm">
              <div className="flex items-center gap-3 border-b border-zinc-700/50 pb-4">
                {rule.icon && (
                  <div className="bg-zinc-700/50 p-2 rounded-lg">
                    <img src={rule.icon} alt="Rule icon" className="h-8 w-auto object-contain" />
                  </div>
                )}
                <h3 className="text-2xl font-mono font-bold text-emerald-400">{rule.rule}</h3>
              </div>
              <p className="text-zinc-200 text-base leading-relaxed font-sans">{rule.description}</p>
              {(rule.link || qaUrl) && (
                <div className="flex flex-col gap-2 mt-4">
                  {rule.link && (
                    <ExternalLinkButton
                      href={rule.link}
                      className="w-full text-center bg-emerald-600 hover:bg-emerald-500 active:bg-emerald-700 text-white font-medium py-3 rounded-lg flex items-center justify-center gap-2 transition-all duration-200 shadow-lg shadow-emerald-900/20"
                    >
                      <BookOpenIcon height={20} />
                      <span>Open in Rule Book</span>
                    </ExternalLinkButton>
                  )}
                  {qaUrl && (
                    <ExternalLinkButton
                      href={qaUrl}
                      className="w-full text-center bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white font-medium py-3 rounded-lg flex items-center justify-center gap-2 transition-all duration-200 shadow-lg shadow-blue-900/20"
                    >
                      <MagnifyingGlassIcon height={20} />
                      <span>Search the Q&A</span>
                    </ExternalLinkButton>
                  )}
                </div>
              )}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-12 text-zinc-400">
              <BookOpenIcon className="w-16 h-16 mb-4 text-zinc-500" />
              <p className="text-center text-sm">
                Select a rule from the dropdown above to view details.
              </p>
            </div>
          )}
        </DialogBody>
      </Dialog>
      <IconButton
        onClick={() => setOpen(true)}
        icon={<BookOpenIcon height={24} />}
        aria-label="Rules Reference"
      />
    </>
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
    mutationFn: runMigrations,
    onSuccess(data) {
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

export const AppShell: React.FC = () => {
  const { isLoading } = useCurrentEvent();
  const navigate = useNavigate();
  const router = useRouter();
  const location = useLocation();

  const isIndex = location.pathname === "/";
  const isSettings = location.pathname === "/settings";
  const isUpdates = location.pathname === "/updates";
  const isEvents = location.pathname === "/events";

  const customHeaderTitle = isSettings
    ? "Settings"
    : isUpdates
    ? "What's New"
    : isEvents
    ? "Pick An Event"
    : null;

  return (
    <main
      className="w-screen h-[100dvh] grid mb-4 p-4 overflow-hidden"
      style={{
        gridTemplateRows: "4rem minmax(0, 1fr)",
        gridTemplateColumns: "calc(100dvw - 32px)",
      }}
    >
      <Toaster containerClassName="mb-16" />
      <ConnectionManager />
      <MigrationManager />
      {customHeaderTitle ? (
        <DialogCustomHeader className="px-0">
          <IconButton
            icon={<ChevronLeftIcon height={24} />}
            onClick={() =>
              router.history.canGoBack()
                ? router.history.back()
                : navigate({ to: "/" })
            }
            className="bg-transparent"
            aria-label="Back"
            autoFocus
          />
          <h1 className="text-xl text-zinc-100 font-normal">
            {customHeaderTitle}
          </h1>
        </DialogCustomHeader>
      ) : (
        <nav className="h-16 flex gap-4 max-w-full">
          {!isIndex && (
            <IconButton
              onClick={() =>
                router.history.canGoBack()
                  ? router.history.back()
                  : navigate({ to: "/" })
              }
              icon={<ChevronLeftIcon height={24} />}
              className="aspect-auto bg-transparent"
              aria-label="Back"
            />
          )}
          <EventPicker />
          <Rules />
        </nav>
      )}
      <Spinner show={isLoading} />
      {!isLoading && <Outlet />}
    </main>
  );
};

export const Route = createRootRoute({
  component: AppShell,
});
