import { useEffect, useMemo, useState } from "react";
import { createFileRoute, useParams } from "@tanstack/react-router";
import { useQuery, useMutation } from "@tanstack/react-query";
import { getRequestCodeUserKey, inviteUser } from "~utils/data/share";
import { useCurrentEvent } from "~utils/hooks/state";
import { getSkuTextColorClass } from "~utils/data/state";
import { Input, Checkbox } from "~components/Input";
import { Button } from "~components/Button";
import { ClickToCopy } from "~components/ClickToCopy";
import { QRCode } from "~components/QRCode";
import { Spinner } from "~components/Spinner";
import { Error, Success, Warning } from "~components/Warning";
import { twMerge } from "tailwind-merge";

export const EventInvitePage: React.FC = () => {
  const { sku: skuParam } = useParams({ strict: false });
  const { data: event } = useCurrentEvent();
  const sku = event?.sku ?? skuParam ?? "";

  const joinUrl = useMemo(() => {
    if (typeof window === "undefined") return `https://roboref.fyi/${sku}/join`;
    return `${window.location.origin}/${sku}/join`;
  }, [sku]);

  const [inviteCode, setInviteCode] = useState("");
  const [admin, setAdmin] = useState(false);

  const {
    data: response,
    isLoading: isLoadingRequestCode,
    isPending: isGetInvitePending,
  } = useQuery({
    queryKey: ["get_invite", sku, inviteCode],
    queryFn: () => getRequestCodeUserKey(sku, inviteCode),
    enabled: inviteCode.length > 0,
  });

  const user = useMemo(
    () => (response?.success ? response.data.user : null),
    [response]
  );
  const userVersion = useMemo(
    () => (response?.success ? response.data.version : null),
    [response]
  );

  const {
    mutateAsync: invite,
    isPending: isInvitePending,
    isError: isInviteError,
    isSuccess: isInviteSuccess,
    error: inviteError,
    reset: resetInvite,
  } = useMutation({
    mutationFn: (key: string) => inviteUser(sku, key, { admin }),
  });

  useEffect(() => {
    if (isInviteSuccess) {
      setTimeout(() => {
        if (isInviteSuccess) {
          setInviteCode("");
          setAdmin(false);
          resetInvite();
        }
      }, 2000);
    }
  }, [resetInvite, isInviteSuccess]);

  return (
    <section className="mt-4 flex flex-col px-2 max-w-lg mx-auto w-full pb-12">
      <p className="mb-4">
        To invite a user to this share instance, enter their invite code.
      </p>
      <div className="relative">
        <Input
          className={twMerge("w-full font-mono text-6xl text-center")}
          value={inviteCode}
          onChange={(e) =>
            setInviteCode(e.currentTarget.value.toUpperCase())
          }
        />
      </div>
      <p className="mt-2 text-sm text-zinc-400">
        You are adding a user to:{" "}
        <span className={twMerge("font-mono font-medium", getSkuTextColorClass(sku))}>
          {sku}
        </span>
        {event?.name ? <span className="text-zinc-200"> - {event.name}</span> : null}
      </p>
      <Spinner show={isLoadingRequestCode} />
      {user ? (
        <div className="mt-4">
          <p>{user.name}</p>
          <ClickToCopy message={user.key} />
          {userVersion !== __ROBOREF_VERSION__ ? (
            <Warning
              message="User is on a different version"
              className="mt-4"
            >
              <p>
                Your app version (<code>{__ROBOREF_VERSION__}</code>) does
                not match this user's app version (
                <code>{userVersion ?? "Unknown"}</code>
                ). This can lead to instability.
              </p>
            </Warning>
          ) : null}
          <Checkbox
            label="Invite as Admin"
            bind={{ value: admin, onChange: setAdmin }}
          />

          <Button
            mode="primary"
            className="mt-4"
            onClick={() => invite(user.key)}
          >
            Invite {user.name}
          </Button>
        </div>
      ) : null}
      {!user && !isGetInvitePending && inviteCode.length > 0 ? (
        <Error message="Invalid Code" className="mt-4" />
      ) : null}
      <Spinner show={isInvitePending} className="mt-4" />
      {isInviteError ? (
        <Error message={inviteError.message} className="mt-4" />
      ) : null}
      {isInviteSuccess ? (
        <Success message="Sent Invitation!" className="mt-4 bg-emerald-600" />
      ) : null}

      <div className="mt-8 flex flex-col items-start gap-2 w-full">
        <h2 className="font-bold text-lg">Invite to Event</h2>
        <p className="text-zinc-400 text-sm">
          Other users can use the QR code or link to access this event in RoboRef.
        </p>
        <div className="bg-zinc-900 border border-zinc-800 p-6 rounded-2xl shadow-xl flex flex-col items-center gap-5 w-full mt-2">
          <div className="w-56 h-56 bg-zinc-800/80 p-4 rounded-xl border border-zinc-700/50 flex items-center justify-center">
            <QRCode
              config={{
                text: joinUrl,
                radius: 0.4,
                ecLevel: "H",
                fill: "#10b981",
                background: null,
              }}
              className="w-full h-full p-0 bg-transparent"
            />
          </div>
          <div className="w-full flex flex-col gap-3">
            <ClickToCopy message={joinUrl} className="w-full justify-center text-center" />
          </div>
        </div>
      </div>
    </section>
  );
};

export const Route = createFileRoute("/$sku/invite")({
  component: EventInvitePage,
});
