import { describe, it, beforeEach, afterEach } from "node:test";
import assert from "node:assert";
import { createSyncApp } from "../src/core/app.js";
import type { StorageAdapter, ShareSessionRecord, IncidentNoteRecord, EventRecord } from "../src/core/types.js";

class DummyStorageAdapter implements StorageAdapter {
  async init(): Promise<void> {}
  async getEvent(): Promise<EventRecord | null> { return null; }
  async saveEvent(): Promise<void> {}
  async getNotesSince(): Promise<IncidentNoteRecord[]> { return []; }
  async applyNoteChanges(): Promise<{ latestVersion: number }> { return { latestVersion: 0 }; }
  async createShareSession(s: ShareSessionRecord): Promise<ShareSessionRecord> { return s; }
  async getShareSession(): Promise<ShareSessionRecord | null> { return null; }
  async getActiveSharesForSku(): Promise<ShareSessionRecord[]> { return []; }
  async addParticipant(): Promise<ShareSessionRecord | null> { return null; }
  async updateParticipantName(): Promise<ShareSessionRecord[]> { return []; }
  async removeParticipant(): Promise<{ session: ShareSessionRecord | null; deleted: boolean }> { return { session: null, deleted: false }; }
  async deleteShareSession(): Promise<void> {}
  async purgeSkuNotes(): Promise<void> {}
}

describe("Proxy VEX Events API Endpoints (/api/vexevents/*)", () => {
  const originalFetch = globalThis.fetch;

  afterEach(() => {
    globalThis.fetch = originalFetch;
  });

  it("returns 502 Bad Gateway with error details when fetch throws an error", async () => {
    globalThis.fetch = async () => {
      throw new Error("Connection timed out to upstream VEX API");
    };

    const app = createSyncApp(new DummyStorageAdapter());
    const res = await app.request("/api/vexevents/events/RE-VRC-23-1234");

    assert.strictEqual(res.status, 502);
    const body = await res.json();
    assert.deepStrictEqual(body, {
      error: "Failed to proxy request to VEX Events API",
      details: "Connection timed out to upstream VEX API",
    });
  });

  it("returns proxied response on success and sets cache headers (MISS then HIT)", async () => {
    let fetchCalls = 0;
    globalThis.fetch = async (input: RequestInfo | URL) => {
      fetchCalls++;
      return new Response(JSON.stringify({ data: "event_data" }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    };

    const app = createSyncApp(new DummyStorageAdapter());

    // First request - Cache MISS
    const res1 = await app.request("/api/vexevents/events/RE-VRC-23-9999");
    assert.strictEqual(res1.status, 200);
    assert.strictEqual(res1.headers.get("X-RoboRef-Cache"), "MISS");
    const data1 = await res1.json();
    assert.deepStrictEqual(data1, { data: "event_data" });
    assert.strictEqual(fetchCalls, 1);

    // Second request - Cache HIT
    const res2 = await app.request("/api/vexevents/events/RE-VRC-23-9999");
    assert.strictEqual(res2.status, 200);
    assert.strictEqual(res2.headers.get("X-RoboRef-Cache"), "HIT");
    const data2 = await res2.json();
    assert.deepStrictEqual(data2, { data: "event_data" });
    assert.strictEqual(fetchCalls, 1); // fetch should not be called again
  });

  it("falls back to test.roboref.app if primary upstream returns non-ok status and non-direct auth", async () => {
    const fetchedUrls: string[] = [];
    globalThis.fetch = async (input: RequestInfo | URL) => {
      const urlStr = input.toString();
      fetchedUrls.push(urlStr);
      if (urlStr.startsWith("https://roboref.app/")) {
        return new Response("Not Found", { status: 404 });
      }
      if (urlStr.startsWith("https://test.roboref.app/")) {
        return new Response(JSON.stringify({ data: "fallback_data" }), {
          status: 200,
          headers: { "content-type": "application/json" },
        });
      }
      return new Response("Bad Request", { status: 400 });
    };

    const app = createSyncApp(new DummyStorageAdapter());
    const res = await app.request("/api/vexevents/teams/1234A");

    assert.strictEqual(res.status, 200);
    const data = await res.json();
    assert.deepStrictEqual(data, { data: "fallback_data" });
    assert.strictEqual(fetchedUrls.length, 2);
    assert.ok(fetchedUrls[0].startsWith("https://roboref.app/"));
    assert.ok(fetchedUrls[1].startsWith("https://test.roboref.app/"));
  });
});
