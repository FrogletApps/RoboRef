import { describe, it } from "node:test";
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
  async getActiveShareSessionBySku(): Promise<ShareSessionRecord | null> { return null; }
  async addParticipant(): Promise<{ session: ShareSessionRecord }> { throw new Error("not implemented"); }
  async removeParticipant(): Promise<{ session: ShareSessionRecord | null }> { return { session: null }; }
  async updateShareSession(): Promise<void> {}
}

describe("Privacy Policy Endpoint (/privacy)", () => {
  it("serves responsive HTML by default using local asset fallback", async () => {
    const app = createSyncApp(new DummyStorageAdapter());
    const res = await app.request("/privacy");

    assert.strictEqual(res.status, 200);
    assert.match(res.headers.get("Content-Type") || "", /text\/html/);

    const html = await res.text();
    assert.match(html, /RoboRef Privacy Policy/);
    assert.match(html, /Global Robotics &amp; Science Foundation/);
    assert.match(html, /RoboRef cloud servers/);
    assert.match(html, /dev@roboref.app/);
    assert.match(html, /Go to RoboRef/);
  });

  it("serves raw markdown when requested via Accept header", async () => {
    const app = createSyncApp(new DummyStorageAdapter());
    const res = await app.request("/privacy", {
      headers: { Accept: "text/markdown" },
    });

    assert.strictEqual(res.status, 200);
    assert.match(res.headers.get("Content-Type") || "", /text\/markdown/);

    const text = await res.text();
    assert.match(text, /# RoboRef Privacy Policy/);
    assert.match(text, /Global Robotics & Science Foundation/);
  });

  it("serves HTML from Cloudflare ASSETS binding if provided in env", async () => {
    const app = createSyncApp(new DummyStorageAdapter());
    const mockMarkdown = "# Mock Policy\n\n- No tracking\n";

    const mockEnv = {
      ASSETS: {
        fetch: async (req: Request) => {
          assert.match(req.url, /\/assets\/assets\/privacy\.md/);
          return new Response(mockMarkdown, { status: 200 });
        },
      },
    };

    const res = await app.request("/privacy", {}, mockEnv);
    assert.strictEqual(res.status, 200);
    const html = await res.text();
    assert.match(html, /Mock Policy/);
    assert.match(html, /No tracking/);
  });
});
