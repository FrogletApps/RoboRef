import { describe, it } from "node:test";
import assert from "node:assert";
import { createSyncApp } from "../src/core/app.js";
import type { StorageAdapter, IncidentNoteRecord, EventRecord } from "../src/core/types.js";

class MockStorageAdapter implements StorageAdapter {
  public notes: IncidentNoteRecord[] = [];
  public events: EventRecord[] = [];

  async init(): Promise<void> {}

  async getEvent(sku: string): Promise<EventRecord | null> {
    return this.events.find((e) => e.sku === sku) || null;
  }

  async saveEvent(event: EventRecord): Promise<void> {
    this.events.push(event);
  }

  async getNotesSince(sku: string, sinceVersion: number): Promise<IncidentNoteRecord[]> {
    return this.notes.filter((n) => n.sku === sku && n.version > sinceVersion);
  }

  async applyNoteChanges(sku: string, changes: IncidentNoteRecord[]): Promise<{ latestVersion: number }> {
    let maxVer = this.notes.reduce((max, n) => Math.max(max, n.version), 0);
    for (const change of changes) {
      maxVer += 1;
      this.notes.push({
        ...change,
        sku,
        version: maxVer,
      });
    }
    return { latestVersion: maxVer };
  }
}

describe("Sync Server Endpoints", () => {
  describe("GET /api/sync/pull", () => {
    it("should return 400 error if sku parameter is missing", async () => {
      const storage = new MockStorageAdapter();
      const app = createSyncApp(storage);

      const res = await app.request("/api/sync/pull");
      assert.strictEqual(res.status, 400);

      const json = await res.json();
      assert.deepStrictEqual(json, { error: "Missing required 'sku' query parameter" });
    });

    it("should return empty changes and since version when no notes exist", async () => {
      const storage = new MockStorageAdapter();
      const app = createSyncApp(storage);

      const res = await app.request("/api/sync/pull?sku=RE-VRC-23-1234");
      assert.strictEqual(res.status, 200);

      const json = await res.json();
      assert.deepStrictEqual(json, {
        sku: "RE-VRC-23-1234",
        latestVersion: 0,
        changes: [],
      });
    });

    it("should return notes filtered by since version and calculate latestVersion", async () => {
      const storage = new MockStorageAdapter();
      const sampleNote1: IncidentNoteRecord = {
        id: "note-1",
        sku: "RE-VRC-23-1234",
        teamNumber: "1234A",
        ruleCodes: ["G1"],
        severity: "minor",
        notes: "First note",
        refereeName: "Ref 1",
        deviceId: "dev-1",
        createdAt: 1000,
        updatedAt: 1000,
        isDeleted: false,
        version: 1,
      };
      const sampleNote2: IncidentNoteRecord = {
        id: "note-2",
        sku: "RE-VRC-23-1234",
        teamNumber: "1234B",
        ruleCodes: ["G2"],
        severity: "major",
        notes: "Second note",
        refereeName: "Ref 2",
        deviceId: "dev-2",
        createdAt: 2000,
        updatedAt: 2000,
        isDeleted: false,
        version: 2,
      };
      const otherSkuNote: IncidentNoteRecord = {
        id: "note-3",
        sku: "OTHER-SKU",
        teamNumber: "9999X",
        ruleCodes: ["G3"],
        severity: "warning",
        notes: "Other note",
        refereeName: "Ref 3",
        deviceId: "dev-3",
        createdAt: 3000,
        updatedAt: 3000,
        isDeleted: false,
        version: 1,
      };

      storage.notes.push(sampleNote1, sampleNote2, otherSkuNote);
      const app = createSyncApp(storage);

      // Pull since version 0
      const res1 = await app.request("/api/sync/pull?sku=RE-VRC-23-1234&since=0");
      assert.strictEqual(res1.status, 200);
      const json1 = await res1.json();
      assert.strictEqual(json1.sku, "RE-VRC-23-1234");
      assert.strictEqual(json1.latestVersion, 2);
      assert.strictEqual(json1.changes.length, 2);

      // Pull since version 1
      const res2 = await app.request("/api/sync/pull?sku=RE-VRC-23-1234&since=1");
      assert.strictEqual(res2.status, 200);
      const json2 = await res2.json();
      assert.strictEqual(json2.sku, "RE-VRC-23-1234");
      assert.strictEqual(json2.latestVersion, 2);
      assert.strictEqual(json2.changes.length, 1);
      assert.strictEqual(json2.changes[0].id, "note-2");

      // Pull since version 2 (up to date)
      const res3 = await app.request("/api/sync/pull?sku=RE-VRC-23-1234&since=2");
      assert.strictEqual(res3.status, 200);
      const json3 = await res3.json();
      assert.strictEqual(json3.sku, "RE-VRC-23-1234");
      assert.strictEqual(json3.latestVersion, 2);
      assert.strictEqual(json3.changes.length, 0);
    });
  });

  describe("POST /api/sync/push", () => {
    it("should return 400 error when payload is missing sku", async () => {
      const storage = new MockStorageAdapter();
      const app = createSyncApp(storage);

      const res = await app.request("/api/sync/push", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ deviceId: "dev-1", changes: [] }),
      });

      assert.strictEqual(res.status, 400);
      const json = await res.json();
      assert.deepStrictEqual(json, { error: "Invalid payload format" });
    });

    it("should return 400 error when payload changes is not an array", async () => {
      const storage = new MockStorageAdapter();
      const app = createSyncApp(storage);

      const res = await app.request("/api/sync/push", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sku: "RE-VRC-23-1234", deviceId: "dev-1", changes: "invalid" }),
      });

      assert.strictEqual(res.status, 400);
      const json = await res.json();
      assert.deepStrictEqual(json, { error: "Invalid payload format" });
    });

    it("should successfully push changes and return updated latestVersion and appliedCount", async () => {
      const storage = new MockStorageAdapter();
      const app = createSyncApp(storage);

      const change1: IncidentNoteRecord = {
        id: "note-100",
        sku: "RE-VRC-23-1234",
        teamNumber: "1234A",
        ruleCodes: ["G12"],
        severity: "minor",
        notes: "Push note 1",
        refereeName: "Ref A",
        deviceId: "dev-1",
        createdAt: 5000,
        updatedAt: 5000,
        isDeleted: false,
        version: 0,
      };

      const change2: IncidentNoteRecord = {
        id: "note-101",
        sku: "RE-VRC-23-1234",
        teamNumber: "1234B",
        ruleCodes: ["S1"],
        severity: "major",
        notes: "Push note 2",
        refereeName: "Ref B",
        deviceId: "dev-1",
        createdAt: 5010,
        updatedAt: 5010,
        isDeleted: false,
        version: 0,
      };

      const res = await app.request("/api/sync/push", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sku: "RE-VRC-23-1234",
          deviceId: "dev-1",
          changes: [change1, change2],
        }),
      });

      assert.strictEqual(res.status, 200);
      const json = await res.json();
      assert.deepStrictEqual(json, {
        success: true,
        sku: "RE-VRC-23-1234",
        latestVersion: 2,
        appliedCount: 2,
      });

      assert.strictEqual(storage.notes.length, 2);
      assert.strictEqual(storage.notes[0].id, "note-100");
      assert.strictEqual(storage.notes[1].id, "note-101");
    });
  });
});
