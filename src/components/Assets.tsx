import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import {
  compressImage,
  ImageLocalAsset,
  LocalAsset,
  MAX_ASSET_SIZE_BYTES,
  MAX_ASSET_SIZE_MB,
} from "~utils/data/assets";
import { twMerge } from "tailwind-merge";
import { IconButton } from "./Button";
import {
  useAssetOriginalURL,
  useAssetPreviewURL,
  useAssetUploadStatus,
} from "~utils/hooks/assets";
import { useCurrentEvent } from "~utils/hooks/state";
import { PhotoIcon } from "@heroicons/react/20/solid";
import {
  ChevronLeftIcon,
  ClockIcon,
  UserCircleIcon,
} from "@heroicons/react/24/outline";
import { toast } from "./Toast";
import { usePeerUserName } from "~utils/data/share";
import { useShareConnection } from "~models/ShareConnection";

export const PhotoFallback: React.FC<React.HTMLProps<HTMLDivElement>> = (
  props
) => {
  return (
    <div
      {...props}
      className={twMerge(
        "bg-zinc-700 animate-pulse rounded-md flex justify-center items-center aspect-square",
        props.className
      )}
    >
      <PhotoIcon className="h-8 w-8 text-zinc-200" />
    </div>
  );
};

export type AssetPickerProps = Omit<
  React.HTMLProps<HTMLInputElement>,
  "onChange" | "multiple" | "value"
> & {
  onPick?: (buffer: LocalAsset) => void;
  readonly fields: Omit<LocalAsset, "data" | "id">;
};

export const AssetPicker: React.FC<AssetPickerProps> = ({
  onPick,
  fields,
  ...props
}) => {
  const onChange = useCallback(
    async (e: React.ChangeEvent<HTMLInputElement>) => {
      const blob = e.target.files?.[0];
      if (!blob) return;

      if (blob.size > MAX_ASSET_SIZE_BYTES) {
        toast({
          type: "warn",
          message: `Photo must be under ${MAX_ASSET_SIZE_MB}MB.`,
        });
        e.target.value = "";
        return;
      }

      const compressed = await compressImage(blob);

      if (compressed.size > MAX_ASSET_SIZE_BYTES) {
        toast({
          type: "warn",
          message: `Photo must be under ${MAX_ASSET_SIZE_MB}MB.`,
        });
        e.target.value = "";
        return;
      }

      const asset: LocalAsset = {
        id: crypto.randomUUID(),
        data: compressed,
        ...fields,
      };

      onPick?.(asset);
      e.target.value = "";
    },
    [fields, onPick]
  );
  return (
    <input
      type="file"
      {...props}
      className={twMerge("sr-only", props.className)}
      onChange={onChange}
    />
  );
};

export type ImagePreviewProps = {
  previewUrl: string;
  originalUrl?: string | null;
  owner?: string | null;
  uploadedAt?: string | Date | null;
} & React.HTMLProps<HTMLImageElement>;

export const ImagePreview: React.FC<ImagePreviewProps> = ({
  originalUrl,
  previewUrl,
  owner,
  uploadedAt,
  className,
  alt,
  ...props
}) => {
  const [open, setOpen] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);

  const onClick = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      e.preventDefault();
      setOpen(true);
    },
    [setOpen]
  );

  const onClose = useCallback(() => {
    setOpen(false);
  }, []);

  useEffect(() => {
    if (!open) {
      setLoaded(false);
      return;
    }

    if (imgRef.current?.complete) {
      setLoaded(true);
    }

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setOpen(false);
      }
    };

    window.addEventListener("keydown", onKeyDown);
    return () => {
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [open, originalUrl, previewUrl]);

  const peerName = usePeerUserName(owner ?? undefined);
  const takenBy =
    peerName ||
    (owner && !owner.startsWith("0x")
      ? owner
      : owner
      ? `Peer ${owner.slice(0, 6)}`
      : undefined);

  const formattedDate = useMemo(() => {
    if (!uploadedAt) return undefined;
    const d = new Date(uploadedAt);
    if (isNaN(d.getTime())) return undefined;
    return d.toLocaleString(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    });
  }, [uploadedAt]);

  const imgSrc = originalUrl || previewUrl;

  return (
    <>
      {open &&
        createPortal(
          <div
            className="fixed inset-0 z-50 bg-zinc-800 text-zinc-100 w-full max-w-full h-[100dvh] grid p-4 gap-4 overflow-hidden"
            style={{
              gridTemplateRows:
                takenBy || formattedDate
                  ? "auto minmax(0, 1fr) auto"
                  : "auto minmax(0, 1fr)",
              gridTemplateColumns: "minmax(0, 1fr)",
            }}
          >
            <header className="flex items-center gap-3 h-[56px] py-2 px-3 bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm w-full min-w-0">
              <IconButton
                onClick={onClose}
                icon={<ChevronLeftIcon height={20} />}
                className="p-1.5 px-2.5 bg-zinc-800 hover:bg-zinc-700/80 active:bg-zinc-700 rounded-md border border-zinc-700/60 transition-colors aspect-auto"
                aria-label="Back"
              />
              <h1 className="text-xl font-bold font-mono tracking-tight text-zinc-100 overflow-hidden whitespace-nowrap text-ellipsis flex-1 min-w-0">
                View Image
              </h1>
            </header>
            <div className="flex-1 flex items-center justify-center min-h-0 min-w-0 p-4 overflow-hidden bg-zinc-900 border border-zinc-800 rounded-lg shadow-sm">
              <div className="relative w-full h-full flex items-center justify-center min-h-0">
                {!loaded && <PhotoFallback className="absolute w-full h-full" />}
                <img
                  ref={imgRef}
                  className={twMerge(
                    "max-w-full max-h-full object-contain rounded-md z-10 transition-opacity duration-200",
                    loaded ? "opacity-100" : "opacity-0"
                  )}
                  src={imgSrc}
                  alt={alt ?? "View Image"}
                  onLoad={() => setLoaded(true)}
                />
              </div>
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
          </div>,
          document.body
        )}
      <img
        className={twMerge(
          "w-full h-full object-cover aspect-square z-10 rounded-md bg-zinc-700 cursor-pointer",
          className
        )}
        onClick={onClick}
        src={previewUrl}
        alt={alt}
        {...props}
      />
    </>
  );
};

export type LocalImageAssetPreviewProps = {
  asset: ImageLocalAsset;
  owner?: string | null;
  uploadedAt?: string | Date | null;
} & React.HTMLProps<HTMLDivElement>;

export const ImageAssetPreview: React.FC<LocalImageAssetPreviewProps> = ({
  asset,
  owner,
  uploadedAt,
}) => {
  const url = useMemo(() => URL.createObjectURL(asset.data), [asset.data]);
  const { profile } = useShareConnection(["profile"]);
  const now = useMemo(() => new Date(), []);

  return (
    <ImagePreview
      previewUrl={url}
      originalUrl={url}
      owner={owner ?? profile?.name ?? "You"}
      uploadedAt={uploadedAt ?? now}
    />
  );
};

export type LocalAssetPreviewProps = {
  asset: LocalAsset;
  owner?: string | null;
  uploadedAt?: string | Date | null;
} & React.HTMLProps<HTMLDivElement>;

export const LocalAssetPreview: React.FC<LocalAssetPreviewProps> = ({
  asset,
  owner,
  uploadedAt,
  ...props
}) => {
  if (asset.type === "image") {
    return (
      <ImageAssetPreview
        asset={asset}
        owner={owner}
        uploadedAt={uploadedAt}
        {...props}
      />
    );
  }

  return (
    <div className="w-full h-full bg-gray-200 flex items-center justify-center">
      <span>Unsupported asset type</span>
    </div>
  );
};

export type AssetPreviewProps = {
  asset: string;
  owner?: string | null;
  uploadedAt?: string | Date | null;
};

export const AssetPreview: React.FC<AssetPreviewProps> = ({
  asset,
  owner: propOwner,
  uploadedAt: propUploadedAt,
}) => {
  const { data: event } = useCurrentEvent();

  const { data: previewUrl } = useAssetPreviewURL(event?.sku, asset);
  const { data: originalUrl } = useAssetOriginalURL(event?.sku, asset);
  const { data: uploadStatus } = useAssetUploadStatus(asset);

  const uploadedAt = propUploadedAt ?? uploadStatus?.date;

  if (!previewUrl) {
    return <PhotoFallback />;
  }

  return (
    <ImagePreview
      previewUrl={previewUrl ?? ""}
      originalUrl={originalUrl}
      owner={propOwner}
      uploadedAt={uploadedAt}
    />
  );
};
