import { useEffect, useState } from "react";
import { Button } from "~components/Button";
import { Input } from "~components/Input";
import { Spinner } from "~components/Spinner";
import { useShareConnection } from "~models/ShareConnection";
import { tryPersistStorage } from "~utils/data/keyval";
import { useCurrentEvent } from "~utils/hooks/state";
import { useCreateInstance } from "~utils/hooks/share";
import { useMutation } from "@tanstack/react-query";
import { createFileRoute, useNavigate, useParams } from "@tanstack/react-router";
import { twMerge } from "tailwind-merge";
import { toast } from "~components/Toast";

const BeginSharingPage: React.FC = () => {
  const { sku: skuParam } = useParams({ strict: false });
  const { data: event } = useCurrentEvent();
  const sku = event?.sku ?? skuParam ?? "";
  const navigate = useNavigate();

  const { profile, updateProfile } = useShareConnection([
    "updateProfile",
    "profile",
  ]);

  const [localName, setLocalName] = useState(profile?.name ?? "");

  useEffect(() => {
    if (profile?.name) {
      setLocalName(profile.name);
    } else {
      setLocalName("");
    }
  }, [profile?.name]);

  const { mutateAsync: createInstance } = useCreateInstance(sku);

  const { mutate: setNameAndBegin, isPending } = useMutation({
    mutationFn: async () => {
      const trimmed = localName.trim();
      if (!trimmed) return;
      await updateProfile({ name: trimmed });
      await tryPersistStorage();
      const response = await createInstance();
      if (response.success) {
        toast({ type: "info", message: "Sharing!" });
      } else {
        toast({
          type: "error",
          message: response.details,
          context: JSON.stringify(response),
        });
      }
      navigate({ to: "/$sku", params: { sku } });
    },
  });

  const handleNameSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (localName.trim() && !isPending) {
      setNameAndBegin();
    }
  };

  return (
    <section className="mt-4 flex flex-col px-2 max-w-lg mx-auto w-full">
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
            autoFocus
          />
        </label>
        <Button
          className={twMerge(
            "mt-4 w-full",
            !localName.trim() ? "opacity-50" : ""
          )}
          disabled={!localName.trim() || isPending}
          mode="primary"
          type="submit"
        >
          Continue
        </Button>
        <Spinner show={isPending} className="mt-4" />
      </form>
    </section>
  );
};

export const Route = createFileRoute("/$sku/share")({
  component: BeginSharingPage,
});
