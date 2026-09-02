import { createSyncApp } from "./core/app.js";
import { CloudflareD1Adapter } from "./adapters/cloudflare-d1.js";
import type { D1Database } from "@cloudflare/workers-types";

export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
  VEX_EVENTS_TOKEN?: string;
  VEX_API_KEY?: string;
  ASSETS?: { fetch: typeof fetch };
}

let cachedApp: ReturnType<typeof createSyncApp> | null = null;
let cachedStorage: CloudflareD1Adapter | null = null;

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    if (!cachedStorage || !cachedApp) {
      cachedStorage = new CloudflareD1Adapter(env.DB);
      cachedApp = createSyncApp(cachedStorage);
    }

    if (env.DB) {
      try {
        await cachedStorage.init();
      } catch (e) {
        console.error("Failed to initialize D1 storage schema:", e);
      }
    }

    const response = await cachedApp.fetch(request, env, ctx);
    if (response.status === 404 && env.ASSETS) {
      return env.ASSETS.fetch(request);
    }
    return response;
  },
};

