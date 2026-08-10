import { AutoRouter } from "itty-router";
import { Env, RequestHasInvitation } from "../types";
import { verifyInvitation, verifySignature, verifyUser } from "../utils/verify";
import { response } from "../utils/request";
import { getAssetMeta, getInvitation, setAssetMeta } from "../utils/data";
import {
  ApiGetAssetOriginalURLResponseBody,
  ApiGetAssetPreviewURLResponseBody,
  APIGetAssetUploadURLResponseBody,
  ImageAssetMeta,
} from "@roboref/share";

const assetRouter = AutoRouter<RequestHasInvitation, [Env]>({
  before: [verifySignature, verifyUser, verifyInvitation],
});

assetRouter.get(
  "/api/:sku/asset/upload_url",
  async (request: RequestHasInvitation) => {
    const sku = request.params.sku;
    const type = request.query.type;
    const id = request.query.id;

    if (typeof id !== "string") {
      return response({
        success: false,
        reason: "bad_request",
        details: "Missing asset ID",
      });
    }

    if (type !== "image") {
      return response({
        success: false,
        reason: "bad_request",
        details: "Unsupported asset type",
      });
    }

    return response<APIGetAssetUploadURLResponseBody>({
      success: true,
      data: {
        uploadURL: `/api/${sku}/asset/upload?id=${encodeURIComponent(id)}&type=${encodeURIComponent(type)}`,
      },
    });
  }
);

const MAX_ASSET_SIZE_BYTES = 20 * 1024 * 1024; // 20MB

assetRouter.post(
  "/api/:sku/asset/upload",
  async (request: RequestHasInvitation, env: Env) => {
    const sku = request.params.sku;
    const type = request.query.type;
    const id = request.query.id;

    if (typeof id !== "string") {
      console.error("[assetRouter.post] Missing asset ID", { id });
      return response({
        success: false,
        reason: "bad_request",
        details: "Missing asset ID",
      });
    }

    if (type !== "image") {
      console.error("[assetRouter.post] Unsupported asset type", { type });
      return response({
        success: false,
        reason: "bad_request",
        details: "Unsupported asset type",
      });
    }

    const contentLength = request.headers.get("content-length");
    if (contentLength && parseInt(contentLength, 10) > MAX_ASSET_SIZE_BYTES) {
      console.error("[assetRouter.post] File size exceeds 20MB limit (Content-Length)", { contentLength });
      return response({
        success: false,
        reason: "bad_request",
        details: "File size exceeds 20MB limit",
      });
    }

    // Allow owner to update/overwrite their asset, but prevent others from overwriting.
    const current = await getAssetMeta(env, id);
    if (current && current.owner !== request.user.key) {
      console.error("[assetRouter.post] Asset already exists with different owner", { owner: current.owner, user: request.user.key });
      return response({
        success: false,
        reason: "bad_request",
        details: "Asset already exists",
      });
    }

    let body: ArrayBuffer | ReadableStream;
    let contentType = request.headers.get("content-type") || "image/jpeg";

    if (contentType.includes("multipart/form-data")) {
      const formData = await request.formData();
      const file = formData.get("file") as File | null;
      if (!file) {
        console.error("[assetRouter.post] Missing file payload in multipart form");
        return response({
          success: false,
          reason: "bad_request",
          details: "Missing file payload",
        });
      }
      if (file.size > MAX_ASSET_SIZE_BYTES) {
        console.error("[assetRouter.post] File size exceeds 20MB limit (File object)", { size: file.size });
        return response({
          success: false,
          reason: "bad_request",
          details: "File size exceeds 20MB limit",
        });
      }
      body = await file.arrayBuffer();
      if (file.type) {
        contentType = file.type;
      }
    } else {
      body = await request.arrayBuffer();
    }

    if (body instanceof ArrayBuffer && body.byteLength > MAX_ASSET_SIZE_BYTES) {
      console.error("[assetRouter.post] File size exceeds 20MB limit (ArrayBuffer)", { byteLength: body.byteLength });
      return response({
        success: false,
        reason: "bad_request",
        details: "File size exceeds 20MB limit",
      });
    }

    if (!contentType.startsWith("image/")) {
      console.error("[assetRouter.post] Only image files allowed", { contentType });
      return response({
        success: false,
        reason: "bad_request",
        details: "Only image files are allowed",
      });
    }

    try {
      // Save object into R2 bucket
      await env.IMAGES_BUCKET.put(id, body, {
        httpMetadata: { contentType },
      });
    } catch (err) {
      console.error("[assetRouter.post] R2 IMAGES_BUCKET.put failed!", err);
      return response({
        success: false,
        reason: "server_error",
        details: "R2 bucket write failed",
      });
    }

    const meta: ImageAssetMeta = {
      id,
      type: "image",
      owner: request.user.key,
      sku,
      contentType,
    };

    // Store asset metadata in KV namespace (retained for 30 days)
    await setAssetMeta(env, meta);

    return response({
      success: true,
      data: { id },
    });
  }
);

type RequestHasAssetAuthorization = RequestHasInvitation & {
  asset: ImageAssetMeta;
};

async function ensureImageAuthorized(request: RequestHasInvitation, env: Env) {
  const id = request.params.id || request.query.id;
  if (typeof id !== "string") {
    return response({
      success: false,
      reason: "bad_request",
      details: "Missing asset ID",
    });
  }

  const meta = await getAssetMeta(env, id);

  if (!meta) {
    return response({
      success: false,
      reason: "bad_request",
      details: "Asset not found",
    });
  }

  // The owner of the asset must be on the same share instance as the requester.
  const ownerInvitation = await getInvitation(env, meta.owner, meta.sku);
  if (
    !ownerInvitation ||
    !ownerInvitation.accepted ||
    ownerInvitation.instance_secret !== request.invitation.instance_secret
  ) {
    return response({
      success: false,
      reason: "bad_request",
      details: "Unauthorized",
    });
  }

  (request as RequestHasAssetAuthorization).asset = meta;
}

assetRouter.get(
  "/api/:sku/asset/preview_url",
  ensureImageAuthorized,
  async (request: RequestHasAssetAuthorization) => {
    const id = request.query.id;
    return response<ApiGetAssetPreviewURLResponseBody>({
      success: true,
      data: {
        owner: request.asset.owner,
        previewURL: `/api/${request.params.sku}/asset/${id}/file`,
      },
    });
  }
);

assetRouter.get(
  "/api/:sku/asset/url",
  ensureImageAuthorized,
  async (request: RequestHasAssetAuthorization) => {
    const id = request.query.id;
    return response<ApiGetAssetOriginalURLResponseBody>({
      success: true,
      data: {
        owner: request.asset.owner,
        url: `/api/${request.params.sku}/asset/${id}/file`,
      },
    });
  }
);

assetRouter.get(
  "/api/:sku/asset/:id/file",
  ensureImageAuthorized,
  async (request: RequestHasAssetAuthorization, env: Env) => {
    const id = request.params.id;
    const object = await env.IMAGES_BUCKET.get(id);

    if (!object) {
      return new Response("Image not found", { status: 404 });
    }

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    if (object.httpEtag) {
      headers.set("etag", object.httpEtag);
    }
    headers.set("Cache-Control", "public, max-age=31536000, immutable");

    return new Response(object.body, { headers });
  }
);

export { assetRouter };
