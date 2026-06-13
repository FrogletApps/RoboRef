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

const robotEventsRouter = AutoRouter<IRequest & Request, [Env]>({
  before: [],
});

robotEventsRouter.all(
  "/api/robotevents/*",
  async (request: IRequest & Request, env: Env) => {
    const url = new URL(request.url);
    const path = url.pathname.slice(PREFIX.length);

    const upstream = new URL(`${UPSTREAM}/${path}`);
    upstream.search = url.search;

    const response = await fetch(upstream.toString(), {
      method: "GET",
      headers: {
        Authorization: `Bearer ${env.ROBOTEVENTS_TOKEN}`,
        Accept: "application/json",
      },
    });

    // Re-wrap so we control the headers; corsify (finally hook) adds CORS.
    return new Response(response.body, {
      status: response.status,
      headers: {
        "content-type":
          response.headers.get("content-type") ?? "application/json",
      },
    });
  }
);

export { robotEventsRouter };
