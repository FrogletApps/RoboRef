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

  // Register user when they open
  const { profile, updateProfile } = useShareConnection([
    "updateProfile",
    "profile",
  ]);

  const hasName = Boolean(profile?.name);

  // 2-minute timeout timer
  useEffect(() => {
    if (!hasName) return;
    setIsTimedOut(false);
    const timer = setTimeout(() => {
      setIsTimedOut(true);
    }, TIMEOUT_DURATION_MS);

    return () => clearTimeout(timer);
  }, [timerKey, hasName]);

  // Request Code
  const { data: requestCode, isLoading: isLoadingRequestCode } = useQuery({
    queryKey: ["request_code", sku],
    queryFn: () => putRequestCode(sku),
    enabled: sku.length > 0 && !isTimedOut && hasName,
    gcTime: 600000,
    refetchInterval: isTimedOut ? false : 60000,
  });

  const code = useMemo(() => {
    return requestCode?.success ? requestCode.data.code : "";
  }, [requestCode]);

  const [localName, setLocalName] = useState("");

  useEffect(() => {
    if (profile?.name) {
      setLocalName(profile.name);
    } else {
      setLocalName("");
    }
  }, [profile?.name]);

  // Invitation
  const { data: invitation } = useQuery({
    queryKey: ["join_custom_get_invite"],
    queryFn: () => fetchInvitation(sku),
    refetchInterval: isTimedOut ? false : 2000,
    networkMode: "always",
    enabled: sku.length > 0 && !isTimedOut && hasName,
  });

  const { mutate: setNameContinue, isPending: isPendingSetNameContinue } =
    useMutation({
      mutationFn: async () => {
        const trimmed = localName.trim();
        if (!trimmed) return;
        await updateProfile({ name: trimmed });
        await queryClient.invalidateQueries({ queryKey: ["request_code", sku] });
      },
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

  const handleNameSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (localName.trim()) {
      setNameContinue();
    }
  };

  return (
    <section className="mt-4 flex flex-col px-2 max-w-lg mx-auto w-full">
      {!hasName ? (
        <form onSubmit={handleNameSubmit}>
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
            className={twMerge("mt-4 w-full", !localName.trim() ? "opacity-50" : "")}
            disabled={!localName.trim() || isPendingSetNameContinue}
            mode="primary"
            type="submit"
          >
            Continue
          </Button>
          <Spinner show={isPendingSetNameContinue} className="mt-4" />
        </form>
      ) : null}
      {hasName && isTimedOut ? (
        <section className="mt-4 flex flex-col">
          <Error
            message="Your invite code timed out, click the button below to retry. An admin will need to see the code to add you."
            className="mb-4"
          />
          <Button mode="primary" onClick={handleRetry}>
            Retry
          </Button>
        </section>
      ) : null}
      {hasName && !isTimedOut ? (
        <>
          <p className="mb-4">
            To join an existing instance, you will need an admin to invite you. Have
            them enter the code shown below on their device.
          </p>
          {isLoadingRequestCode ? (
            <Spinner show className="my-8" />
          ) : code ? (
            <ClickToCopy
              message={code}
              className="font-mono text-6xl text-center"
            />
          ) : (
            <div className="flex flex-col items-center gap-4 my-4">
              <Error message="Unable to generate join code. Please check your connection and try again." />
              <Button mode="primary" onClick={handleRetry}>
                Retry
              </Button>
            </div>
          )}
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
