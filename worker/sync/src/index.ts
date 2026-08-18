import { AutoRouter, IRequest, withParams } from "itty-router";
import { corsify, preflight } from "./utils/request";
import { Env } from "./types";

import { integrationRouter } from "./routers/integration";
import { registrationRouter } from "./routers/registration";
import { keyExchangeRouter } from "./routers/keyexchange";
import { invitationRouter } from "./routers/invitation";
import { instanceRouter } from "./routers/instance";
import { assetRouter } from "./routers/assets";
import { metaRouter } from "./routers/meta";
import { vexEventsRouter } from "./routers/vexevents";

const router = AutoRouter<IRequest, [Env, ExecutionContext]>({
  before: [preflight, withParams],
  finally: [corsify],
});

router

  // External Integration API (just requires bearer token)
  .all("/api/integration/v1/:sku/*", integrationRouter.fetch)

  // VEX Events API proxy (browser -> worker -> events.vex.com).
  // Must precede the "/api/:sku/:path+" catch-all below.
  .all("/api/vexevents/*", vexEventsRouter.fetch)

  // Meta Routes
  .get("/api/meta/location", metaRouter.fetch)

  // User Registration
  .post("/api/user", registrationRouter.fetch)

  // Key Exchange
  .put("/api/:sku/request", keyExchangeRouter.fetch)
  .get("/api/:sku/request", keyExchangeRouter.fetch)

  // Manage Invitations
  .post("/api/:sku/create", invitationRouter.fetch)
  .get("/api/:sku/invitation", invitationRouter.fetch)
  .put("/api/:sku/accept", invitationRouter.fetch)
  .get("/api/:sku/list", invitationRouter.fetch)

  // Asset Actions
  .all("/api/:sku/asset/*", assetRouter.fetch)

  // Instance Actions
  .put("/api/:sku/invite", instanceRouter.fetch)
  .delete("/api/:sku/invite", instanceRouter.fetch)
  .all("/api/:sku/:path+", instanceRouter.fetch);

export default {
  async fetch(
    request: Request,
    env: Env,
    ctx: ExecutionContext
  ): Promise<Response> {
    const url = new URL(request.url);

    // API & WebSocket routes:
    if (url.pathname.startsWith("/api/")) {
      return router.fetch(request, env, ctx);
    }

    // Static Assets & Single-Page-Application client routes:
    if (env.STATIC_ASSETS) {
      const assetResponse = await env.STATIC_ASSETS.fetch(request);

      const isStaticCodeOrAsset =
        url.pathname.startsWith("/assets/") ||
        url.pathname.startsWith("/icons/") ||
        url.pathname.startsWith("/rules/") ||
        url.pathname.startsWith("/screenshots/") ||
        url.pathname.endsWith(".js") ||
        url.pathname.endsWith(".css") ||
        url.pathname.endsWith(".json") ||
        url.pathname.endsWith(".map") ||
        url.pathname.endsWith(".png") ||
        url.pathname.endsWith(".svg") ||
        url.pathname.endsWith(".ico") ||
        url.pathname.endsWith(".webmanifest");

      // Guard against serving HTML for missing JS/CSS/asset chunks
      if (isStaticCodeOrAsset) {
        const contentType = assetResponse.headers.get("content-type") || "";
        if (contentType.includes("text/html") && !url.pathname.endsWith(".html")) {
          return new Response("Asset Not Found", {
            status: 404,
            headers: {
              "Content-Type": "text/plain",
              "Cache-Control": "no-cache, no-store, must-revalidate",
            },
          });
        }
      }

      return assetResponse;
    }

    return new Response("Not Found", { status: 404 });
  },
};

export { ShareInstance } from "./objects/instance";
