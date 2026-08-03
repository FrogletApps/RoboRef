import { useCallback, useMemo } from "react";
import { useNavigate } from "@tanstack/react-router";
import {
  compressImage,
  ImageLocalAsset,
  LocalAsset,
  MAX_ASSET_SIZE_BYTES,
  MAX_ASSET_SIZE_MB,
  saveLocalAsset,
} from "~utils/data/assets";
import { twMerge } from "tailwind-merge";
import {
  useAssetPreviewURL,
  useAssetUploadStatus,
} from "~utils/hooks/assets";
import { useCurrentEvent } from "~utils/hooks/state";
import { PhotoIcon } from "@heroicons/react/20/solid";
import { toast } from "./Toast";
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

      await saveLocalAsset(asset);
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
  assetId?: string;
  previewUrl: string;
  owner?: string | null;
  uploadedAt?: string | Date | null;
} & React.HTMLProps<HTMLImageElement>;

export const ImagePreview: React.FC<ImagePreviewProps> = ({
  assetId,
  previewUrl,
  owner,
  uploadedAt,
  className,
  alt,
  ...props
}) => {
  const navigate = useNavigate();
  const { data: event } = useCurrentEvent();

  const onClick = useCallback(
    (e: React.MouseEvent) => {
      e.stopPropagation();
      e.preventDefault();
      if (assetId && event?.sku) {
        navigate({
          to: "/$sku/asset/$assetId",
          params: { sku: event.sku, assetId },
          search: {
            owner: owner ?? undefined,
            uploadedAt: uploadedAt ? new Date(uploadedAt).toISOString() : undefined,
          },
        });
      }
    },
    [assetId, event?.sku, navigate, owner, uploadedAt]
  );

  return (
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
      assetId={asset.id}
      previewUrl={url}
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
  const { data: uploadStatus } = useAssetUploadStatus(asset);

  const uploadedAt = propUploadedAt ?? uploadStatus?.date;

  if (!previewUrl) {
    return <PhotoFallback />;
  }

  return (
    <ImagePreview
      assetId={asset}
      previewUrl={previewUrl ?? ""}
      owner={propOwner}
      uploadedAt={uploadedAt}
    />
  );
};
