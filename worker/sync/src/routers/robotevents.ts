import { AutoRouter, IRequest } from "itty-router";
import { Env } from "../types";

/**
 * Server-side proxy for the RobotEvents API (events.vex.com).
 *
 * The browser cannot call events.vex.com directly: it does not honor the
 * cross-origin Bearer token and 302-redirects to a login page that carries no
 * CORS headers, so the request is blocked. Instead the frontend calls this
 * route, and we forward to events.vex.com server-side (where CORS does not
 * apply) with the token injected from the worker secret. The shared `corsify`
 * finally-hook in index.ts adds the CORS headers the browser needs.
 *
 * The token therefore never ships in the public frontend bundle.
 */
const UPSTREAM = "https://events.vex.com/api/v2";
const PREFIX = "/api/robotevents/";

const MINUTE = 60;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const WEEK = 7 * DAY;

/**
 * How long the edge (and browser) may serve a cached copy of a given path.
 *
 * At a busy event dozens of referees' devices re-fetch the same season/event/
 * team lists; caching collapses those into a single upstream fetch, cutting
 * latency and free-tier subrequest usage. TTLs trade staleness for that win:
 * reference data (seasons, events, teams) changes rarely, but anything derived
 * from live scoring (matches, rankings, skills) must stay near-fresh.
 */
function cacheSeconds(path: string): number {
  // Live-scored sub-resources are entered during the event — keep these short.
  // `matches` appears under both /events and /teams, so test it before the
  // leading segment below.
  if (/(^|\/)(matches|rankings|skills)(\/|$)/.test(path)) return MINUTE;

  switch (path.split("/")[0]) {
    case "seasons":
      return WEEK;
    case "programs":
      return WEEK;
    case "events":
      return DAY;
    case "teams":
      return 10 * MINUTE;
    default:
      // Unknown resource: cache briefly rather than not at all.
      return MINUTE;
  }
}

const robotEventsRouter = AutoRouter<
  IRequest & Request,
  [Env, ExecutionContext]
>({
  before: [],
});

robotEventsRouter.all(
  "/api/robotevents/*",
  async (request: IRequest & Request, env: Env, ctx: ExecutionContext) => {
    const url = new URL(request.url);
    const path = url.pathname.slice(PREFIX.length);

    // Cache key is the incoming path+query only — the Bearer token lives in a
    // request header we never attach here, so a single shared entry safely
    // serves every device.
    const cache = caches.default;
    const cacheKey = new Request(url.toString(), { method: "GET" });

    const hit = await cache.match(cacheKey);
    if (hit) {
      // corsify (finally hook) re-wraps this and adds CORS headers.
      return hit;
    }

    const upstream = new URL(`${UPSTREAM}/${path}`);
    upstream.search = url.search;

    const response = await fetch(upstream.toString(), {
      method: "GET",
      headers: {
        Authorization: `Bearer ${env.VEX_EVENTS_TOKEN}`,
        Accept: "application/json",
      },
    });

    // Re-wrap so we control the headers; corsify (finally hook) adds CORS.
    const result = new Response(response.body, {
      status: response.status,
      headers: {
        "content-type":
          response.headers.get("content-type") ?? "application/json",
        "cache-control": `public, max-age=${cacheSeconds(path)}`,
      },
    });

    // Only cache successful responses; never persist an upstream error.
    // Store the pre-CORS copy so corsify can add the caller's origin per-hit.
    if (response.ok) {
      ctx.waitUntil(cache.put(cacheKey, result.clone()));
    }

    return result;
  },
);

export { robotEventsRouter };
