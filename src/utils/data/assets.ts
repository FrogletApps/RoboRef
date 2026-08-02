import { AssetType } from "@referee-fyi/share";
import { get, getMany, set } from "./keyval";

export type LocalAssetType = AssetType;

export type LocalAsset = {
  id: string;
  type: LocalAssetType;
  data: Blob;
};

export type ImageLocalAsset = LocalAsset & {
  type: "image";
};

export function getLocalAsset(id: string) {
  return get<LocalAsset>(`asset_${id}`);
}

export function getManyLocalAssets(ids: string[]) {
  return getMany<LocalAsset>(ids.map((id) => `asset_${id}`));
}

export async function saveLocalAsset(asset: LocalAsset) {
  return set(`asset_${asset.id}`, asset);
}

export function generateLocalAsset(type: LocalAssetType, data: Blob) {
  return {
    id: crypto.randomUUID(),
    type,
    data,
  } satisfies LocalAsset;
}

export async function compressImage(
  file: Blob,
  maxDimension = 1920,
  quality = 0.85
): Promise<Blob> {
  if (!file.type.startsWith("image/") || file.size < 100 * 1024) {
    return file;
  }

  return new Promise((resolve) => {
    const img = new Image();
    const url = URL.createObjectURL(file);

    img.onload = () => {
      URL.revokeObjectURL(url);
      let { width, height } = img;

      if (width <= maxDimension && height <= maxDimension && file.size < 500 * 1024) {
        return resolve(file);
      }

      if (width > maxDimension || height > maxDimension) {
        if (width > height) {
          height = Math.round((height * maxDimension) / width);
          width = maxDimension;
        } else {
          width = Math.round((width * maxDimension) / height);
          height = maxDimension;
        }
      }

      const canvas = document.createElement("canvas");
      canvas.width = width;
      canvas.height = height;

      const ctx = canvas.getContext("2d");
      if (!ctx) {
        return resolve(file);
      }

      ctx.drawImage(img, 0, 0, width, height);

      canvas.toBlob(
        (blob) => {
          if (blob && blob.size < file.size) {
            resolve(blob);
          } else {
            resolve(file);
          }
        },
        "image/jpeg",
        quality
      );
    };

    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve(file);
    };

    img.src = url;
  });
}

export type AssetUploadStatus = {
  success: boolean;
  date: string; // ISO
  step: "get_upload_url" | "upload" | "complete";
};

export function getAssetUploadStatus(id: string) {
  return get<AssetUploadStatus>(`asset_upload_${id}`);
}

export function getManyAssetUploadStatus(ids: string[]) {
  return getMany<AssetUploadStatus>(ids.map((id) => `asset_upload_${id}`));
}

export function setAssetUploadStatus(id: string, status: AssetUploadStatus) {
  return set(`asset_upload_${id}`, status);
}
