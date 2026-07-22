import { GlobeAmericasIcon } from "@heroicons/react/20/solid";
import { SunIcon, MoonIcon, ComputerDesktopIcon } from "@heroicons/react/24/outline";
import { createFileRoute } from "@tanstack/react-router";
import { useCallback, useEffect, useState } from "react";
import { Button, LinkButton } from "~components/Button";
import { ClickToCopy } from "~components/ClickToCopy";
import { ContactDevDialog } from "~components/dialogs/contact";
import { HiddenEventsDialog } from "~components/dialogs/hiddenEvents";
import { Input } from "~components/Input";
import { toast } from "~components/Toast";
import { Info } from "~components/Warning";
import { useShareConnection } from "~models/ShareConnection";
import { isWorldsBuild } from "~utils/data/state";
import { clearCache } from "~utils/sentry";
import { useTheme, Theme } from "~utils/hooks/theme";
import { useHiddenEvents } from "~utils/hooks/history";

export const SettingsPage: React.FC = () => {
  const { updateProfile, profile, userMetadata } = useShareConnection([
    "updateProfile",
    "profile",
    "userMetadata",
  ]);
  const [localName, setLocalName] = useState(profile?.name ?? "");
  const { theme, setTheme } = useTheme();
  const { data: hiddenEvents = [] } = useHiddenEvents();
  const [hiddenDialogOpen, setHiddenDialogOpen] = useState(false);

  const themes: { id: Theme; label: string; icon: React.ComponentType<any> }[] = [
    { id: "light", label: "Light", icon: SunIcon },
    { id: "dark", label: "Dark", icon: MoonIcon },
    { id: "system", label: "System", icon: ComputerDesktopIcon },
  ];

  useEffect(() => {
    if (profile?.name) {
      setLocalName(profile.name);
    }
  }, [profile?.name]);

  const [reportIssueDialogOpen, setReportIssueDialogOpen] = useState(false);

  const onClickRemoveVEXEvents = useCallback(async () => {
    await clearCache();
    toast({ type: "info", message: "Deleted cache." });

    window.location.reload();
  }, []);

  return (
    <main className="mt-4 overflow-y-auto">
      {isWorldsBuild() ? (
        <p className="bg-purple-500 text-zinc-300 p-2 rounded-md flex items-center gap-2 mt-4">
          <GlobeAmericasIcon height={20} />
          Worlds Build
          <span className="flex-1 text-right font-mono">
            {__ROBOREF_VERSION__}
          </span>
        </p>
      ) : null}
      <section className="mt-4">
        <h2 className="font-bold">Name</h2>
        <p className="text-zinc-400 text-sm">
          Your display name when sharing and logging incidents
        </p>
        <Input
          className="w-full mt-2"
          value={localName}
          onChange={(e) => setLocalName(e.currentTarget.value)}
          onBlur={() => updateProfile({ name: localName })}
        />
      </section>
      <section className="mt-4" aria-label="Theme selection">
        <h2 className="font-bold">Theme</h2>
        <p className="text-zinc-400 text-sm">
          Choose light, dark, or system default theme
        </p>
        <div className="flex bg-zinc-700 p-1 rounded-lg mt-2 gap-1 max-w-md">
          {themes.map(({ id, label, icon: Icon }) => {
            const active = theme === id;
            return (
              <button
                key={id}
                onClick={() => setTheme(id)}
                className={`flex flex-1 items-center justify-center gap-2 py-2 px-3 rounded-md transition-all duration-200 text-sm font-medium ${
                  active
                    ? "bg-zinc-800 text-emerald-600 dark:text-emerald-400 shadow-sm"
                    : "text-zinc-400 hover:text-zinc-100 hover:bg-zinc-600/50"
                }`}
              >
                <Icon className="w-5 h-5" />
                <span>{label}</span>
              </button>
            );
          })}
        </div>
      </section>
      <section className="mt-4">
        <h2 className="font-bold">Public Key</h2>
        <p className="text-zinc-400 text-sm">
          Your unique device identity used for live sharing and verification
        </p>
        <ClickToCopy message={profile?.key ?? ""} />
      </section>
      {userMetadata.isSystemKey ? (
        <Info message="System Key Enabled" className="mt-4" />
      ) : null}
      <section className="mt-4">
        <h2 className="font-bold">Hidden Events</h2>
        <p className="text-zinc-400 text-sm">
          Access hidden events which have stored local data. All events can still be selected from the Select Event dropdown on the main page
        </p>
        <Button
          className="mt-2"
          onClick={() => setHiddenDialogOpen(true)}
        >
          {hiddenEvents.length} Event{hiddenEvents.length === 1 ? "" : "s"} Hidden
        </Button>
      </section>
      <section className="mt-4">
        <h2 className="font-bold">Delete Cache</h2>
        <p className="text-zinc-400 text-sm">
          Delete all cached assets and VEX Events data. This will not remove any locally stored incidents.
        </p>
        <Button
          className="mt-2"
          mode="dangerous"
          onClick={onClickRemoveVEXEvents}
        >
          Delete Cache
        </Button>
      </section>
      <section className="mt-4">
        <h2 className="font-bold">Contact Developer</h2>
        <p className="text-zinc-400 text-sm">
          Get in touch about issues or features you would like to see
        </p>
        <ContactDevDialog
          open={reportIssueDialogOpen}
          setOpen={setReportIssueDialogOpen}
        />
        <Button className="mt-2" onClick={() => setReportIssueDialogOpen(true)}>
          Contact Developer
        </Button>
      </section>
      <section className="mt-4">
        <h2 className="font-bold">Privacy Policy</h2>
        <p className="text-zinc-400 text-sm">
          Read the RoboRef privacy policy
        </p>
        <LinkButton to="/privacy" className="w-full mt-2 text-center">
          Privacy Policy
        </LinkButton>
      </section>
      <HiddenEventsDialog
        open={hiddenDialogOpen}
        onClose={() => setHiddenDialogOpen(false)}
      />
    </main>
  );
};

export const Route = createFileRoute("/settings")({
  component: SettingsPage,
});
