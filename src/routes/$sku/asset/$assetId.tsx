import React, { useState, useMemo, useRef } from "react";
import { createFileRoute, useNavigate, useParams, useRouter } from "@tanstack/react-router";
import { twMerge } from "tailwind-merge";
import { IconButton } from "~components/Button";
import { PhotoFallback } from "~components/Assets";
import { ChevronLeftIcon, ClockIcon, UserCircleIcon } from "@heroicons/react/24/outline";
import { useCurrentEvent } from "~utils/hooks/state";
import { useAssetOriginalURL, useAssetPreviewURL, useAssetUploadStatus } from "~utils/hooks/assets";
import { usePeerUserName } from "~utils/data/share";
import { Spinner } from "~components/Spinner";

export type ImagePreviewSearch = {
  owner?: string;
  uploadedAt?: string;
};

export const ImagePreviewPage: React.FC = () => {
  const navigate = useNavigate();
  const router = useRouter();
  const { sku, assetId } = useParams({ strict: false });
  const search = Route.useSearch();
  const { data: event } = useCurrentEvent();
  const currentSku = sku || event?.sku || "";
  const id = assetId || "";

  const { data: previewUrl } = useAssetPreviewURL(currentSku, id);
  const { data: originalUrl } = useAssetOriginalURL(currentSku, id);
  const { data: uploadStatus } = useAssetUploadStatus(id);

  const [loaded, setLoaded] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);

  const onBack = () => {
    if (router.history.canGoBack()) {
      router.history.back();
    } else {
      navigate({
        to: "/$sku/summary",
        params: { sku: currentSku },
      });
    }
  };

  const imgSrc = originalUrl || previewUrl;
  const owner = search.owner;
  const peerName = usePeerUserName(owner ?? undefined);
  const takenBy =
    peerName ||
    (owner && !owner.startsWith("0x")
      ? owner
      : owner
      ? `Peer ${owner.slice(0, 6)}`
      : undefined);

  const uploadedAt = search.uploadedAt || uploadStatus?.date;
  const formattedDate = useMemo(() => {
    if (!uploadedAt) return undefined;
    const d = new Date(uploadedAt);
    if (isNaN(d.getTime())) return undefined;
    return d.toLocaleString(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    });
  }, [uploadedAt]);

  return (
    <div className="overflow-y-auto max-w-full my-2 bg-zinc-900 border border-zinc-800 rounded-lg p-4 shadow-sm space-y-4 flex flex-col min-h-[calc(100vh-6rem)]">
      <header className="flex items-center gap-3 h-[56px] py-2 px-3 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm w-full min-w-0">
        <IconButton
          onClick={onBack}
          icon={<ChevronLeftIcon height={20} />}
          className="p-1.5 px-2.5 bg-zinc-800 hover:bg-zinc-700/80 active:bg-zinc-700 rounded-md border border-zinc-700/60 transition-colors aspect-auto"
          aria-label="Back"
        />
        <h1 className="text-xl font-bold font-mono tracking-tight text-zinc-100 overflow-hidden whitespace-nowrap text-ellipsis flex-1 min-w-0">
          View Image
        </h1>
      </header>
      <div className="flex-1 flex items-center justify-center min-h-[300px] min-w-0 p-4 overflow-hidden bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm">
        {!imgSrc ? (
          <Spinner show />
        ) : (
          <div className="relative w-full h-full flex items-center justify-center min-h-0">
            {!loaded && <PhotoFallback className="absolute w-full h-full" />}
            <img
              ref={imgRef}
              className={twMerge(
                "max-w-full max-h-full object-contain rounded-md z-10 transition-opacity duration-200",
                loaded ? "opacity-100" : "opacity-0"
              )}
              src={imgSrc}
              alt="View Image"
              onLoad={() => setLoaded(true)}
            />
          </div>
        )}
      </div>
      {(takenBy || formattedDate) && (
        <footer className="bg-zinc-900 border border-zinc-800 rounded-lg p-3.5 shadow-sm flex flex-wrap items-center justify-between gap-3 text-sm">
          {takenBy && (
            <div className="flex items-center gap-2 text-zinc-200">
              <UserCircleIcon className="h-5 w-5 text-emerald-400 flex-shrink-0" />
              <span>
                <span className="text-zinc-400 font-medium mr-1">
                  Uploaded by:
                </span>
                <span className="font-semibold text-zinc-100">
                  {takenBy}
                </span>
              </span>
            </div>
          )}
          {formattedDate && (
            <div className="flex items-center gap-2 text-zinc-200">
              <ClockIcon className="h-5 w-5 text-emerald-400 flex-shrink-0" />
              <span>
                <span className="text-zinc-400 font-medium mr-1">
                  Date/Time uploaded:
                </span>
                <span className="font-semibold text-zinc-100">
                  {formattedDate}
                </span>
              </span>
            </div>
          )}
        </footer>
      )}
    </div>
  );
};

export const Route = createFileRoute("/$sku/asset/$assetId")({
  validateSearch: (search: Record<string, unknown>): ImagePreviewSearch => {
    return {
      owner: (search.owner as string) || undefined,
      uploadedAt: (search.uploadedAt as string) || undefined,
    };
  },
  component: ImagePreviewPage,
});
