import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import type { StorageAdapter, SyncPushPayload } from "./types.js";

export interface AppEnv {
  Bindings?: {
    DB?: any;
    ENVIRONMENT?: string;
    VEX_EVENTS_TOKEN?: string;
    VEX_API_KEY?: string;
  };
  Variables: {
    storage: StorageAdapter;
  };
}

export function createSyncApp(storageProvider: StorageAdapter) {
  const app = new Hono<AppEnv>();

  // In-memory cache for vexevents proxy
  const cacheMap = new Map<string, { body: string; status: number; contentType: string; expires: number }>();

  function cacheDurationSeconds(path: string): number {
    if (/(^|\/)(matches|rankings|skills)(\/|$)/.test(path)) return 60; // 1 min
    if (path.startsWith("events") || path.startsWith("seasons") || path.startsWith("programs")) return 3600 * 24; // 1 day
    if (path.startsWith("teams")) return 600; // 10 mins
    return 60;
  }

  // Global middleware
  app.use("*", logger());
  app.use("*", cors({
    origin: "*",
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization", "X-Device-ID"],
  }));

  // Attach storage adapter to request context
  app.use("*", async (c, next) => {
    c.set("storage", storageProvider);
    await next();
  });

  // Health check & discovery endpoint (for mDNS / local LAN detection)
  app.get("/api/health", (c) => {
    return c.json({
      status: "ok",
      server: "RoboRef Universal Sync Server",
      timestamp: Date.now(),
    });
  });

  // Proxy endpoint for VEX Events API v2
  app.get("/api/vexevents/*", async (c) => {
    const rawPath = c.req.path.replace(/^\/api\/vexevents\/?/, "");
    const url = new URL(c.req.url);
    const cacheKey = `${rawPath}${url.search}`;

    const now = Date.now();
    const cached = cacheMap.get(cacheKey);
    if (cached && cached.expires > now) {
      c.header("Content-Type", cached.contentType);
      c.header("Cache-Control", `public, max-age=${Math.floor((cached.expires - now) / 1000)}`);
      c.header("X-RoboRef-Cache", "HIT");
      return c.body(cached.body, cached.status as any);
    }

    const envKey =
      (c.env as any)?.VEX_EVENTS_TOKEN ||
      (c.env as any)?.VEX_API_KEY ||
      (typeof process !== "undefined"
        ? process.env.VEX_EVENTS_TOKEN || process.env.VEX_API_KEY
        : "");

    const authHeader = c.req.header("Authorization") || (envKey ? `Bearer ${envKey}` : undefined);

    const upstreamUrl = new URL(`https://events.vex.com/api/v2/${rawPath}`);
    upstreamUrl.search = url.search;

    const headers: Record<string, string> = {
      Accept: "application/json",
      "User-Agent": "RoboRef/1.0",
    };
    if (authHeader) {
      headers["Authorization"] = authHeader;
    }

    try {
      const response = await fetch(upstreamUrl.toString(), {
        method: "GET",
        headers,
      });

      const bodyText = await response.text();
      const status = response.status;
      const contentType = response.headers.get("content-type") || "application/json";

      if (response.ok) {
        const ttlSecs = cacheDurationSeconds(rawPath);
        cacheMap.set(cacheKey, {
          body: bodyText,
          status,
          contentType,
          expires: now + ttlSecs * 1000,
        });
        c.header("Cache-Control", `public, max-age=${ttlSecs}`);
      }

      c.header("Content-Type", contentType);
      c.header("X-RoboRef-Cache", "MISS");
      return c.body(bodyText, status as any);
    } catch (e: any) {
      return c.json({ error: "Failed to proxy request to VEX Events API", details: e?.message }, 502);
    }
  });

  // Fetch changes since a specific version
  app.get("/api/sync/pull", async (c) => {
    const sku = c.req.query("sku");
    const since = parseInt(c.req.query("since") || "0", 10);

    if (!sku) {
      return c.json({ error: "Missing required 'sku' query parameter" }, 400);
    }

    const storage = c.get("storage");
    const changes = await storage.getNotesSince(sku, since);
    const latestVersion = changes.reduce((max, n) => Math.max(max, n.version), since);

    return c.json({
      sku,
      latestVersion,
      changes,
    });
  });

  // Push batches of locally recorded notes / updates
  app.post("/api/sync/push", async (c) => {
    const body = await c.req.json<SyncPushPayload>();

    if (!body.sku || !Array.isArray(body.changes)) {
      return c.json({ error: "Invalid payload format" }, 400);
    }

    const storage = c.get("storage");
    const result = await storage.applyNoteChanges(body.sku, body.changes);

    return c.json({
      success: true,
      sku: body.sku,
      latestVersion: result.latestVersion,
      appliedCount: body.changes.length,
    });
  });

  return app;
}
