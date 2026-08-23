import { createSyncApp } from "./core/app.js";
import { CloudflareD1Adapter } from "./adapters/cloudflare-d1.js";
import type { D1Database } from "@cloudflare/workers-types";

export interface Env {
  DB: D1Database;
  ENVIRONMENT: string;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const storage = new CloudflareD1Adapter(env.DB);
    // Initialize DB schema lazily
    await storage.init();

    const app = createSyncApp(storage);
    return app.fetch(request, env, ctx);
  },
};
