import { describe, it } from "node:test";
import assert from "node:assert";
import { CloudflareD1Adapter } from "../src/adapters/cloudflare-d1.js";
import type { IncidentNoteRecord } from "../src/core/types.js";

function createMockD1Database() {
  const batchCalls: any[][] = [];

  const mockDb = {
    batchCalls,
    prepare(query: string) {
      const boundParams: any[] = [];
      return {
        bind(...params: any[]) {
          boundParams.push(...params);
          return this;
        },
        async first<T = any>(): Promise<T | null> {
          if (query.includes("SELECT MAX(version)")) {
            return { maxVer: 10 } as T;
          }
          return null;
        },
        async all<T = any>(): Promise<{ results: T[] }> {
          return { results: [] };
        },
        async run(): Promise<any> {
          return { success: true };
        },
        _query: query,
        _params: boundParams,
      };
    },
    async batch(statements: any[]): Promise<any[]> {
      batchCalls.push(statements);
      return statements.map(() => ({ success: true }));
    },
  };

  return mockDb;
}

function generateNotes(count: number, sku = "RE-VRC-24-1000"): IncidentNoteRecord[] {
  const notes: IncidentNoteRecord[] = [];
  for (let i = 0; i < count; i++) {
    notes.push({
      id: `note-${i}`,
      sku,
      teamNumber: `${1000 + i}`,
      ruleCodes: ["G1"],
      severity: "minor",
      notes: `Test note ${i}`,
      refereeName: "Ref 1",
      deviceId: "dev-1",
      createdAt: Date.now(),
      updatedAt: Date.now(),
      isDeleted: false,
      version: 0,
    });
  }
  return notes;
}

describe("CloudflareD1Adapter - applyNoteChanges batching test & benchmark", () => {
  it("should handle 0 changes without errors", async () => {
    const mockDb = createMockD1Database();
    const adapter = new CloudflareD1Adapter(mockDb as any);

    const result = await adapter.applyNoteChanges("RE-VRC-24-1000", []);
    assert.strictEqual(result.latestVersion, 10);
  });

  it("should handle changes with batching limits", async () => {
    const mockDb = createMockD1Database();
    const adapter = new CloudflareD1Adapter(mockDb as any);

    const changes = generateNotes(250);
    const start = performance.now();
    const result = await adapter.applyNoteChanges("RE-VRC-24-1000", changes);
    const duration = performance.now() - start;

    console.log(`[Baseline/Test] Applied 250 changes in ${duration.toFixed(3)}ms across ${mockDb.batchCalls.length} batch call(s)`);
    mockDb.batchCalls.forEach((b, i) => {
      console.log(` Batch call ${i + 1} size: ${b.length}`);
    });

    assert.strictEqual(result.latestVersion, 260); // maxVer (10) + 250 changes
  });
});
