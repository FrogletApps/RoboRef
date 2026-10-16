import { describe, it } from "node:test";
import assert from "node:assert";
import { createSyncApp, isAllowedOrigin } from "../src/core/app.js";
import type { StorageAdapter, ShareSessionRecord, IncidentNoteRecord, EventRecord } from "../src/core/types.js";

class DummyStorageAdapter implements StorageAdapter {
  async init(): Promise<void> {}
  async getEvent(): Promise<EventRecord | null> { return null; }
  async saveEvent(): Promise<void> {}
  async getNotesSince(): Promise<IncidentNoteRecord[]> { return []; }
  async applyNoteChanges(): Promise<{ latestVersion: number }> { return { latestVersion: 0 }; }
  async createShareSession(s: ShareSessionRecord): Promise<ShareSessionRecord> { return s; }
  async getShareSession(): Promise<ShareSessionRecord | null> { return null; }
  async getActiveShareSessionBySku(): Promise<ShareSessionRecord | null> { return null; }
  async addParticipant(): Promise<{ session: ShareSessionRecord }> { throw new Error("not implemented"); }
  async removeParticipant(): Promise<{ session: ShareSessionRecord | null }> { return { session: null }; }
  async updateShareSession(): Promise<void> {}
}

describe("CORS Security Middleware & Origin Validation", () => {
  describe("isAllowedOrigin unit tests", () => {
    it("allows official RoboRef domains", () => {
      assert.strictEqual(isAllowedOrigin("https://roboref.app"), true);
      assert.strictEqual(isAllowedOrigin("https://test.roboref.app"), true);
      assert.strictEqual(isAllowedOrigin("https://staging.roboref.app:8443"), true);
    });

    it("allows localhost and 127.0.0.1", () => {
      assert.strictEqual(isAllowedOrigin("http://localhost"), true);
      assert.strictEqual(isAllowedOrigin("http://localhost:3000"), true);
      assert.strictEqual(isAllowedOrigin("https://localhost:8443"), true);
      assert.strictEqual(isAllowedOrigin("http://127.0.0.1:8080"), true);
    });

    it("allows private IPv4 networks (RFC 1918)", () => {
      assert.strictEqual(isAllowedOrigin("http://10.0.0.1:3000"), true);
      assert.strictEqual(isAllowedOrigin("http://172.16.0.2:8080"), true);
      assert.strictEqual(isAllowedOrigin("http://172.31.255.255:3000"), true);
      assert.strictEqual(isAllowedOrigin("http://192.168.1.100:8000"), true);
      assert.strictEqual(isAllowedOrigin("http://192.168.0.1"), true);
    });

    it("allows mDNS local hostnames (*.local)", () => {
      assert.strictEqual(isAllowedOrigin("http://roboref.local:3000"), true);
      assert.strictEqual(isAllowedOrigin("http://raspberrypi.local"), true);
    });

    it("allows explicit env ALLOWED_ORIGINS", () => {
      assert.strictEqual(isAllowedOrigin("https://custom-referee.com", "https://custom-referee.com"), true);
      assert.strictEqual(
        isAllowedOrigin("https://custom-referee.com", "https://other.com, https://custom-referee.com"),
        true
      );
      assert.strictEqual(isAllowedOrigin("https://any-domain.com", "*"), true);
    });

    it("rejects unauthorized external domains", () => {
      assert.strictEqual(isAllowedOrigin("https://evil.com"), false);
      assert.strictEqual(isAllowedOrigin("https://roboref.app.evil.com"), false);
      assert.strictEqual(isAllowedOrigin("http://8.8.8.8:8080"), false);
      assert.strictEqual(isAllowedOrigin("http://172.32.0.1"), false);
      assert.strictEqual(isAllowedOrigin(""), false);
    });
  });

  describe("CORS HTTP Endpoint integration tests", () => {
    it("returns Access-Control-Allow-Origin for allowed official origin", async () => {
      const app = createSyncApp(new DummyStorageAdapter());
      const res = await app.request("/api/health", {
        headers: { Origin: "https://roboref.app" },
      });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.headers.get("Access-Control-Allow-Origin"), "https://roboref.app");
    });

    it("returns Access-Control-Allow-Origin for local IP origin", async () => {
      const app = createSyncApp(new DummyStorageAdapter());
      const res = await app.request("/api/health", {
        headers: { Origin: "http://192.168.1.50:8080" },
      });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.headers.get("Access-Control-Allow-Origin"), "http://192.168.1.50:8080");
    });

    it("returns Access-Control-Allow-Origin for mDNS .local origin", async () => {
      const app = createSyncApp(new DummyStorageAdapter());
      const res = await app.request("/api/health", {
        headers: { Origin: "http://roboref.local:3000" },
      });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.headers.get("Access-Control-Allow-Origin"), "http://roboref.local:3000");
    });

    it("does NOT set Access-Control-Allow-Origin for disallowed external origin", async () => {
      const app = createSyncApp(new DummyStorageAdapter());
      const res = await app.request("/api/health", {
        headers: { Origin: "https://evil.com" },
      });

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.headers.get("Access-Control-Allow-Origin"), null);
    });

    it("allows custom origins passed in env ALLOWED_ORIGINS", async () => {
      const app = createSyncApp(new DummyStorageAdapter());
      const res = await app.request(
        "/api/health",
        {
          headers: { Origin: "https://my-custom-domain.org" },
        },
        { ALLOWED_ORIGINS: "https://my-custom-domain.org" }
      );

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.headers.get("Access-Control-Allow-Origin"), "https://my-custom-domain.org");
    });

    it("handles requests without Origin header (native apps)", async () => {
      const app = createSyncApp(new DummyStorageAdapter());
      const res = await app.request("/api/health");

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.headers.get("Access-Control-Allow-Origin"), null);
    });
  });
});
