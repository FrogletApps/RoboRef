import { ArrowRightIcon, GlobeAmericasIcon } from "@heroicons/react/20/solid";
import { SunIcon, MoonIcon, ComputerDesktopIcon } from "@heroicons/react/24/outline";
import { createFileRoute } from "@tanstack/react-router";
import { useCallback, useEffect, useState } from "react";
import { Button, LinkButton } from "~components/Button";
import { ClickToCopy } from "~components/ClickToCopy";
import { ContactDevDialog } from "~components/dialogs/contact";
import { Input } from "~components/Input";
import { toast } from "~components/Toast";
import { Info } from "~components/Warning";
import { useShareConnection } from "~models/ShareConnection";
import { isWorldsBuild } from "~utils/data/state";
import { clearCache } from "~utils/sentry";
import { useTheme, Theme } from "~utils/hooks/theme";

export const SettingsPage: React.FC = () => {
  const { updateProfile, profile, userMetadata } = useShareConnection([
    "updateProfile",
    "profile",
    "userMetadata",
  ]);
  const [localName, setLocalName] = useState(profile?.name ?? "");
  const { theme, setTheme } = useTheme();

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
        <Input
          className="w-full mt-2"
          value={localName}
          onChange={(e) => setLocalName(e.currentTarget.value)}
          onBlur={() => updateProfile({ name: localName })}
        />
      </section>
      <section className="mt-4" aria-label="Theme selection">
        <h2 className="font-bold">Theme</h2>
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
        <ClickToCopy message={profile?.key ?? ""} />
      </section>
      {userMetadata.isSystemKey ? (
        <Info message="System Key Enabled" className="mt-4" />
      ) : null}
      <section className="mt-4">
        <h2 className="font-bold">Contact Developer</h2>
        <p>
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
        <h2 className="font-bold">Delete Cache</h2>
        <p>
          Delete all cached assets and VEX Events data. This will not remove
          any locally stored incidents.
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
        <LinkButton to="/privacy" className="w-full flex items-center">
          <span className="flex-1">Privacy Policy</span>
          <ArrowRightIcon height={20} className="text-emerald-400" />
        </LinkButton>
      </section>
    </main>
  );
};

export const Route = createFileRoute("/settings")({
  component: SettingsPage,
});
