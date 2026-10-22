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

  it("handles ASSETS.fetch throwing an error gracefully and falls back to local disk", async () => {
    const app = createSyncApp(new DummyStorageAdapter());
    const fetchError = new Error("Failed ASSETS storage connection");
    let consoleErrorCalled = false;
    let loggedMsg = "";
    let loggedErr: unknown = null;

    const originalConsoleError = console.error;
    console.error = (msg: string, err: unknown) => {
      consoleErrorCalled = true;
      loggedMsg = msg;
      loggedErr = err;
    };

    try {
      const mockEnv = {
        ASSETS: {
          fetch: async () => {
            throw fetchError;
          },
        },
      };

      const res = await app.request("/privacy", {}, mockEnv);

      assert.strictEqual(consoleErrorCalled, true);
      assert.strictEqual(loggedMsg, "Failed to fetch privacy markdown from ASSETS:");
      assert.strictEqual(loggedErr, fetchError);

      assert.strictEqual(res.status, 200);
      const html = await res.text();
      assert.match(html, /RoboRef Privacy Policy/);
    } finally {
      console.error = originalConsoleError;
    }
  });

  it("returns 503 when ASSETS.fetch throws an error and disk fallback is unavailable", async () => {
    const app = createSyncApp(new DummyStorageAdapter());
    const originalCwd = process.cwd;
    const originalConsoleError = console.error;

    try {
      process.cwd = () => "/tmp/nonexistent_folder_roboref_test";
      console.error = () => {};

      const mockEnv = {
        ASSETS: {
          fetch: async () => {
            throw new Error("ASSETS error");
          },
        },
      };

      const res = await app.request("/privacy", {}, mockEnv);

      assert.strictEqual(res.status, 503);
      const text = await res.text();
      assert.strictEqual(text, "Privacy policy is temporarily unavailable.");
    } finally {
      process.cwd = originalCwd;
      console.error = originalConsoleError;
    }
  });
});
