import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import type { StorageAdapter, SyncPushPayload } from "./types.js";

export interface AppEnv {
  Variables: {
    storage: StorageAdapter;
  };
}

export function createSyncApp(storageProvider: StorageAdapter) {
  const app = new Hono<AppEnv>();

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
