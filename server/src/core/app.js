import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { renderPrivacyHtml } from "./privacy.js";
export function createSyncApp(storageProvider) {
    const app = new Hono();
    // In-memory cache for vexevents proxy
    const cacheMap = new Map();
    function cacheDurationSeconds(path) {
        if (/(^|\/)(matches|rankings|skills)(\/|$)/.test(path))
            return 60; // 1 min
        if (path.startsWith("events") || path.startsWith("seasons") || path.startsWith("programs"))
            return 3600 * 24; // 1 day
        if (path.startsWith("teams"))
            return 600; // 10 mins
        return 60;
    }
    // Global middleware
    app.use("*", logger());
    app.use("*", async (c, next) => {
        await next();
        c.res.headers.set("Access-Control-Allow-Private-Network", "true");
    });
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
    // Public Privacy Policy endpoint serving the single copy from app/assets/privacy.md
    const handlePrivacy = async (c) => {
        let markdown = null;
        // 1. In Cloudflare Workers with [assets], fetch from static assets
        const env = c.env;
        if (env?.ASSETS) {
            try {
                const assetUrl = new URL("/assets/assets/privacy.md", c.req.url);
                const res = await env.ASSETS.fetch(new Request(assetUrl));
                if (res.ok) {
                    markdown = await res.text();
                }
            }
            catch (err) {
                console.error("Failed to fetch privacy markdown from ASSETS:", err);
            }
        }
        // 2. In Node environment, read from disk if available
        if (!markdown && typeof process !== "undefined" && process.cwd) {
            try {
                const fs = await import("node:fs");
                const path = await import("node:path");
                const candidatePaths = [
                    path.resolve(process.cwd(), "../app/assets/privacy.md"),
                    path.resolve(process.cwd(), "app/assets/privacy.md"),
                    path.resolve(process.cwd(), "assets/privacy.md"),
                ];
                for (const p of candidatePaths) {
                    if (fs.existsSync(p)) {
                        markdown = fs.readFileSync(p, "utf-8");
                        break;
                    }
                }
            }
            catch {
                // Ignored in non-node or bundle environments
            }
        }
        if (!markdown) {
            return c.text("Privacy policy is temporarily unavailable.", 503);
        }
        if (c.req.header("Accept")?.includes("text/markdown") || c.req.header("Accept")?.includes("text/plain")) {
            return c.body(markdown, 200, {
                "Content-Type": c.req.header("Accept")?.includes("text/markdown")
                    ? "text/markdown; charset=utf-8"
                    : "text/plain; charset=utf-8",
            });
        }
        c.header("Cache-Control", "public, max-age=0, must-revalidate");
        return c.html(renderPrivacyHtml(markdown));
    };
    app.get("/privacy", handlePrivacy);
    app.get("/privacy/", handlePrivacy);
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
            return c.body(cached.body, cached.status);
        }
        const rawEnvKey = c.env?.VEX_EVENTS_TOKEN ||
            c.env?.VEX_EVENTS_API_KEY ||
            c.env?.VEX_API_KEY ||
            c.env?.VEX_TOKEN ||
            (typeof process !== "undefined"
                ? process.env?.VEX_EVENTS_TOKEN ||
                    process.env?.VEX_EVENTS_API_KEY ||
                    process.env?.VEX_API_KEY ||
                    process.env?.VEX_TOKEN
                : "");
        const envKey = typeof rawEnvKey === "string" ? rawEnvKey.trim() : "";
        let authHeader = c.req.header("Authorization");
        if (!authHeader && envKey) {
            authHeader = envKey.startsWith("Bearer ") ? envKey : `Bearer ${envKey}`;
        }
        const isDirectVex = Boolean(authHeader);
        const upstreamUrl = isDirectVex
            ? new URL(`https://events.vex.com/api/v2/${rawPath}`)
            : new URL(`https://roboref.app/api/vexevents/${rawPath}`);
        upstreamUrl.search = url.search;
        const headers = {
            Accept: "application/json",
            "User-Agent": "RoboRef/1.0",
        };
        if (authHeader) {
            headers["Authorization"] = authHeader;
        }
        try {
            let response = await fetch(upstreamUrl.toString(), {
                method: "GET",
                headers,
            });
            if (!response.ok && !isDirectVex) {
                const testFallbackUrl = new URL(`https://test.roboref.app/api/vexevents/${rawPath}`);
                testFallbackUrl.search = url.search;
                const testResp = await fetch(testFallbackUrl.toString(), { method: "GET", headers });
                if (testResp.ok) {
                    response = testResp;
                }
            }
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
            return c.body(bodyText, status);
        }
        catch (e) {
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
        const body = await c.req.json();
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
    function generateShareCode() {
        const chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";
        let code = "";
        for (let i = 0; i < 6; i++) {
            code += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return code;
    }
    // Check existing active shares for an event SKU
    app.get("/api/share/check", async (c) => {
        const sku = c.req.query("sku");
        if (!sku) {
            return c.json({ error: "Missing required 'sku' query parameter" }, 400);
        }
        const storage = c.get("storage");
        const activeShares = await storage.getActiveSharesForSku(sku);
        return c.json({
            sku,
            activeShares: activeShares.map((s) => ({
                id: s.id,
                sku: s.sku,
                adminRefereeName: s.adminRefereeName,
                participantCount: s.participants.length,
                createdAt: s.createdAt,
            })),
        });
    });
    // Create a new share session for an event
    app.post("/api/share/create", async (c) => {
        const body = await c.req.json();
        if (!body.sku || !body.adminDeviceId || !body.adminRefereeName) {
            return c.json({ error: "Missing required fields: sku, adminDeviceId, adminRefereeName" }, 400);
        }
        const storage = c.get("storage");
        const activeShares = await storage.getActiveSharesForSku(body.sku);
        // If active share exists and user did not specify force, warn user
        if (activeShares.length > 0 && !body.force) {
            const existing = activeShares[0];
            if (existing.adminDeviceId !== body.adminDeviceId) {
                return c.json({
                    error: "SHARE_ALREADY_EXISTS",
                    message: `A share session for ${body.sku} already exists and is hosted by ${existing.adminRefereeName}`,
                    existingShares: activeShares.map((s) => ({
                        id: s.id,
                        sku: s.sku,
                        adminRefereeName: s.adminRefereeName,
                        participantCount: s.participants.length,
                        createdAt: s.createdAt,
                    })),
                }, 409);
            }
            else {
                // Same admin already created a share, return existing session
                return c.json({
                    success: true,
                    session: existing,
                    isExisting: true,
                });
            }
        }
        const now = Date.now();
        const shareId = generateShareCode();
        const session = await storage.createShareSession({
            id: shareId,
            sku: body.sku,
            adminDeviceId: body.adminDeviceId,
            adminRefereeName: body.adminRefereeName,
            createdAt: now,
            updatedAt: now,
            participants: [
                {
                    deviceId: body.adminDeviceId,
                    refereeName: body.adminRefereeName,
                    role: "admin",
                    joinedAt: now,
                },
            ],
        });
        return c.json({
            success: true,
            session,
        });
    });
    // Get share session status and participants
    app.get("/api/share/status", async (c) => {
        const shareId = c.req.query("shareId");
        const deviceId = c.req.query("deviceId");
        if (!shareId) {
            return c.json({ error: "Missing required 'shareId' query parameter" }, 400);
        }
        const storage = c.get("storage");
        const session = await storage.getShareSession(shareId);
        if (!session) {
            return c.json({ error: "Share session not found or has ended", ended: true }, 404);
        }
        const participant = deviceId ? session.participants.find((p) => p.deviceId === deviceId) : undefined;
        return c.json({
            success: true,
            session,
            isParticipant: Boolean(participant),
            role: participant?.role,
        });
    });
    // Join an existing share session
    app.post("/api/share/join", async (c) => {
        const body = await c.req.json();
        if (!body.deviceId || !body.refereeName) {
            return c.json({ error: "Missing required fields: deviceId, refereeName" }, 400);
        }
        const storage = c.get("storage");
        let targetShareId = body.shareId?.trim().toUpperCase();
        if (!targetShareId && body.sku) {
            const active = await storage.getActiveSharesForSku(body.sku);
            if (active.length > 0) {
                targetShareId = active[0].id;
            }
        }
        if (!targetShareId) {
            return c.json({ error: "No active share session found to join" }, 404);
        }
        const session = await storage.getShareSession(targetShareId);
        if (!session) {
            return c.json({ error: "Share session not found or has ended" }, 404);
        }
        const updated = await storage.addParticipant(targetShareId, {
            deviceId: body.deviceId,
            refereeName: body.refereeName,
            role: session.adminDeviceId === body.deviceId ? "admin" : "member",
            joinedAt: Date.now(),
        });
        return c.json({
            success: true,
            session: updated,
        });
    });
    // Leave a share session
    app.post("/api/share/leave", async (c) => {
        const body = await c.req.json();
        if (!body.shareId || !body.deviceId) {
            return c.json({ error: "Missing required fields: shareId, deviceId" }, 400);
        }
        const storage = c.get("storage");
        try {
            const result = await storage.removeParticipant(body.shareId, body.deviceId);
            return c.json({
                success: true,
                deleted: result.deleted,
                remainingCount: result.session ? result.session.participants.length : 0,
            });
        }
        catch (e) {
            if (e?.message === "ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS") {
                return c.json({
                    error: "ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS",
                    message: "The admin cannot leave while other referees are still in the session. Remove all participants first.",
                }, 400);
            }
            return c.json({ error: e?.message || "Failed to leave share session" }, 500);
        }
    });
    // Admin removes/kicks a participant from the share session
    app.post("/api/share/remove-participant", async (c) => {
        const body = await c.req.json();
        if (!body.shareId || !body.adminDeviceId || !body.targetDeviceId) {
            return c.json({ error: "Missing required fields: shareId, adminDeviceId, targetDeviceId" }, 400);
        }
        const storage = c.get("storage");
        const session = await storage.getShareSession(body.shareId);
        if (!session) {
            return c.json({ error: "Share session not found" }, 404);
        }
        if (session.adminDeviceId !== body.adminDeviceId) {
            return c.json({ error: "Only the session admin can remove participants" }, 403);
        }
        if (body.targetDeviceId === session.adminDeviceId) {
            return c.json({ error: "Admin cannot remove themselves via this endpoint. Use leave endpoint." }, 400);
        }
        try {
            const result = await storage.removeParticipant(body.shareId, body.targetDeviceId);
            return c.json({
                success: true,
                session: result.session,
            });
        }
        catch (e) {
            return c.json({ error: e?.message || "Failed to remove participant" }, 500);
        }
    });
    return app;
}
