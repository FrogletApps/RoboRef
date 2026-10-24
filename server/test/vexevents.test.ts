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

  it("uses 10-minute TTL for events/:id/teams and short 1-minute TTL for events with empty divisions", async () => {
    globalThis.fetch = async (input: RequestInfo | URL) => {
      const urlStr = input.toString();
      if (urlStr.includes("/teams")) {
        return new Response(JSON.stringify({ data: [] }), {
          status: 200,
          headers: { "content-type": "application/json" },
        });
      }
      if (urlStr.includes("EMPTY-DIVS")) {
        return new Response(JSON.stringify({ data: [{ id: 100, sku: "EMPTY-DIVS", divisions: [] }] }), {
          status: 200,
          headers: { "content-type": "application/json" },
        });
      }
      return new Response(JSON.stringify({ data: [{ id: 101, sku: "WITH-DIVS", divisions: [{ id: 1, name: "Default" }] }] }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    };

    const app = createSyncApp(new DummyStorageAdapter());

    const teamsRes = await app.request("/api/vexevents/events/100/teams");
    assert.strictEqual(teamsRes.headers.get("Cache-Control"), "public, max-age=600");

    const emptyDivsRes = await app.request("/api/vexevents/events?sku[]=EMPTY-DIVS");
    assert.strictEqual(emptyDivsRes.headers.get("Cache-Control"), "public, max-age=60");

    const withDivsRes = await app.request("/api/vexevents/events?sku[]=WITH-DIVS");
    assert.strictEqual(withDivsRes.headers.get("Cache-Control"), "public, max-age=300");
  });

  it("bypasses cache and updates canonical cache entry when refresh query param is provided", async () => {
    let fetchCalls = 0;
    const fetchedUrls: string[] = [];
    globalThis.fetch = async (input: RequestInfo | URL) => {
      fetchCalls++;
      fetchedUrls.push(input.toString());
      const divisions = fetchCalls === 1 ? [] : [{ id: 1, name: "Default Division" }];
      return new Response(JSON.stringify({ data: [{ id: 42, sku: "RE-V5RC-26-0042", divisions }] }), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    };

    const app = createSyncApp(new DummyStorageAdapter());
    const env = { VEX_EVENTS_TOKEN: "test-token" };

    // 1. Initial load before schedule/divisions exist -> MISS
    const res1 = await app.request("/api/vexevents/events?sku[]=RE-V5RC-26-0042", {}, env as any);
    assert.strictEqual(res1.headers.get("X-RoboRef-Cache"), "MISS");
    const body1 = (await res1.json()) as any;
    assert.strictEqual(body1.data[0].divisions.length, 0);
    assert.strictEqual(fetchCalls, 1);

    // 2. Normal repeat request -> HIT (still empty divisions)
    const res2 = await app.request("/api/vexevents/events?sku[]=RE-V5RC-26-0042", {}, env as any);
    assert.strictEqual(res2.headers.get("X-RoboRef-Cache"), "HIT");
    assert.strictEqual(fetchCalls, 1);

    // 3. Explicit refresh -> bypasses cache, strips 'refresh' for upstream VEX API, returns fresh divisions
    const res3 = await app.request("/api/vexevents/events?sku[]=RE-V5RC-26-0042&refresh=1700000000", {}, env as any);
    assert.strictEqual(res3.headers.get("X-RoboRef-Cache"), "MISS");
    assert.strictEqual(res3.headers.get("Cache-Control"), "no-cache, no-store, must-revalidate");
    const body3 = (await res3.json()) as any;
    assert.strictEqual(body3.data[0].divisions.length, 1);
    assert.strictEqual(fetchCalls, 2);
    assert.ok(!fetchedUrls[1].includes("refresh="), "Upstream direct VEX URL should strip refresh parameter");

    // 4. Subsequent normal request -> HIT with the newly updated divisions!
    const res4 = await app.request("/api/vexevents/events?sku[]=RE-V5RC-26-0042", {}, env as any);
    assert.strictEqual(res4.headers.get("X-RoboRef-Cache"), "HIT");
    const body4 = (await res4.json()) as any;
    assert.strictEqual(body4.data[0].divisions.length, 1);
    assert.strictEqual(fetchCalls, 2);
  });

  it("rejects path traversal attempts with 400 Bad Request", async () => {
    let fetchCalls = 0;
    globalThis.fetch = async () => {
      fetchCalls++;
      return new Response("OK", { status: 200 });
    };

    const app = createSyncApp(new DummyStorageAdapter());

    const res1 = await app.request("/api/vexevents/%252e%252e/admin");
    assert.strictEqual(res1.status, 400);
    const body1 = await res1.json();
    assert.deepStrictEqual(body1, { error: "Invalid path specified" });

    const res2 = await app.request("/api/vexevents/events/%252e%252e/admin");
    assert.strictEqual(res2.status, 400);

    assert.strictEqual(fetchCalls, 0, "No upstream fetch calls should be attempted on path traversal");
  });
});
