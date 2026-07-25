import { useCallback, useEffect, useMemo, useState } from "react";
import { Button } from "~components/Button";
import { ClickToCopy } from "~components/ClickToCopy";
import { Input } from "~components/Input";
import { Spinner } from "~components/Spinner";
import { Error, Info } from "~components/Warning";
import { useShareConnection } from "~models/ShareConnection";
import {
  acceptEventInvitation,
  fetchInvitation,
  putRequestCode,
  removeInvitation,
} from "~utils/data/share";
import { tryPersistStorage } from "~utils/data/keyval";
import { queryClient } from "~utils/data/query";
import { useCurrentEvent } from "~utils/hooks/state";
import { useMutation, useQuery } from "@tanstack/react-query";
import { createFileRoute, useNavigate, useParams } from "@tanstack/react-router";
import { twMerge } from "tailwind-merge";

const TIMEOUT_DURATION_MS = 120000; // 2 minutes

export const EventJoinPage: React.FC = () => {
  const { sku: skuParam } = useParams({ strict: false });
  const { data: event } = useCurrentEvent();
  const sku = event?.sku ?? skuParam ?? "";
  const navigate = useNavigate();

  const [isTimedOut, setIsTimedOut] = useState(false);
  const [timerKey, setTimerKey] = useState(0);

  // 2-minute timeout timer
  useEffect(() => {
    setIsTimedOut(false);
    const timer = setTimeout(() => {
      setIsTimedOut(true);
    }, TIMEOUT_DURATION_MS);

    return () => clearTimeout(timer);
  }, [timerKey]);

  // Request Code
  const { data: requestCode, isLoading: isLoadingRequestCode } = useQuery({
    queryKey: ["request_code", sku],
    queryFn: () => putRequestCode(sku),
    enabled: sku.length > 0 && !isTimedOut,
    gcTime: 600000,
    refetchInterval: isTimedOut ? false : 60000,
  });

  const code = useMemo(() => {
    return requestCode?.success ? requestCode.data.code : "";
  }, [requestCode]);

  // Register user when they open
  const { profile, updateProfile } = useShareConnection([
    "updateProfile",
    "profile",
  ]);

  const [localName, setLocalName] = useState("");
  const name = profile?.name;

  useEffect(() => {
    if (!profile) {
      return;
    }
    if (profile.name) {
      setLocalName(profile.name);
    } else {
      setLocalName("");
    }
  }, [profile]);

  useEffect(() => {
    if (!name) {
      return;
    }
    updateProfile({ name });
  }, [profile, name, updateProfile]);

  // Invitation
  const { data: invitation } = useQuery({
    queryKey: ["join_custom_get_invite"],
    queryFn: () => fetchInvitation(sku),
    refetchInterval: isTimedOut ? false : 2000,
    networkMode: "always",
    enabled: sku.length > 0 && !isTimedOut,
  });

  const { mutate: setNameContinue, isPending: isPendingSetNameContinue } =
    useMutation({
      mutationFn: () => updateProfile({ name: localName }),
    });

  const onAcceptInvitation = useCallback(async () => {
    if (!invitation || !invitation.success) {
      return;
    }
    await tryPersistStorage();
    await acceptEventInvitation(sku, invitation.data.id);
    navigate({ to: "/$sku", params: { sku } });
  }, [invitation, sku, navigate]);

  const onClearInvitation = useCallback(async () => {
    await removeInvitation(sku);
  }, [sku]);

  const handleRetry = useCallback(() => {
    setIsTimedOut(false);
    setTimerKey((k) => k + 1);
    queryClient.invalidateQueries({ queryKey: ["request_code", sku] });
    queryClient.invalidateQueries({ queryKey: ["join_custom_get_invite"] });
  }, [sku]);

  return (
    <section className="mt-4 flex flex-col px-2 max-w-lg mx-auto w-full">
      {!profile ? (
        <>
          <label>
            <h1 className="font-bold mt-4">Display Name</h1>
            <p className="text-zinc-400 text-sm mb-2">
              Your display name when sharing and logging incidents
            </p>
            <Input
              className="w-full"
              value={localName}
              onChange={(e) => setLocalName(e.currentTarget.value)}
            />
          </label>
          <Button
            className={twMerge("mt-4", !localName ? "opacity-50" : "")}
            mode="primary"
            onClick={() => setNameContinue()}
          >
            Continue
          </Button>
          <Spinner show={isPendingSetNameContinue} />
        </>
      ) : null}
      {profile && isTimedOut ? (
        <section className="mt-4 flex flex-col">
          <Error
            message="Your code was not added, click the button below to retry"
            className="mb-4"
          />
          <Button mode="primary" onClick={handleRetry}>
            Retry
          </Button>
        </section>
      ) : null}
      {profile && !isTimedOut ? (
        <>
          <p className="mb-4">
            To join an existing instance, you will need an admin to invite you. Have
            them enter the code shown below on their device.
          </p>
          <Spinner show={isLoadingRequestCode} />
          <ClickToCopy
            message={code}
            className="font-mono text-6xl text-center"
          />
          {invitation?.data ? (
            <section className="mt-4">
              <nav className="flex justify-between items-center">
                <Info
                  message={`Invitation From ${invitation?.data.from.name}`}
                />
                {invitation?.data.admin ? (
                  <p className="text-sm text-emerald-400">Admin</p>
                ) : null}
              </nav>
              <Button
                mode="primary"
                className="mt-2"
                onClick={onAcceptInvitation}
              >
                Accept & Join
              </Button>
              <Button
                mode="dangerous"
                className="mt-2"
                onClick={onClearInvitation}
              >
                Clear Invitation
              </Button>
            </section>
          ) : (
            <Spinner className="mt-4" show />
          )}
        </>
      ) : null}
    </section>
  );
};

export const Route = createFileRoute("/$sku/join")({
  component: EventJoinPage,
});
