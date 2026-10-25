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

describe("CloudflareD1Adapter - init", () => {
  it("should initialize database tables successfully on first call and do nothing on subsequent calls", async () => {
    const mockDb = createMockD1Database();
    const adapter = new CloudflareD1Adapter(mockDb as any);

    await adapter.init();
    assert.strictEqual(mockDb.batchCalls.length, 1);
    assert.strictEqual(mockDb.batchCalls[0].length, 5);

    // Call init a second time - should return early due to initialized flag
    await adapter.init();
    assert.strictEqual(mockDb.batchCalls.length, 1);
  });

  it("should log error to console and rethrow when initialization fails", async () => {
    const mockDb = createMockD1Database();
    const mockError = new Error("D1 connection error");
    mockDb.batch = async () => {
      throw mockError;
    };

    const adapter = new CloudflareD1Adapter(mockDb as any);

    const originalConsoleError = console.error;
    const loggedErrors: any[] = [];
    console.error = (...args: any[]) => {
      loggedErrors.push(args);
    };

    try {
      await assert.rejects(
        async () => {
          await adapter.init();
        },
        (err: Error) => {
          assert.strictEqual(err, mockError);
          return true;
        }
      );

      assert.strictEqual(loggedErrors.length, 1);
      assert.strictEqual(loggedErrors[0][0], "CloudflareD1Adapter init error:");
      assert.strictEqual(loggedErrors[0][1], mockError);
    } finally {
      console.error = originalConsoleError;
    }
  });
});

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

describe("CloudflareD1Adapter - updateParticipantName escaping test", () => {
  it("should escape wildcard characters and include ESCAPE clause in query", async () => {
    const preparedQueries: { query: string; params: any[] }[] = [];
    const mockDb = {
      prepare(query: string) {
        const boundParams: any[] = [];
        const statement = {
          bind(...params: any[]) {
            boundParams.push(...params);
            return this;
          },
          async first<T = any>(): Promise<T | null> {
            return null;
          },
          async all<T = any>(): Promise<{ results: T[] }> {
            preparedQueries.push({ query, params: [...boundParams] });
            return {
              results: [
                {
                  id: "s-1",
                  sku: "RE-VRC-24-1000",
                  adminDeviceId: "dev%123",
                  adminRefereeName: "Old Name",
                  createdAt: 1000,
                  updatedAt: 1000,
                  participantsJson: JSON.stringify([{ deviceId: "dev%123", refereeName: "Old Name" }]),
                },
              ],
            };
          },
          async run(): Promise<any> {
            return { success: true };
          },
        };
        return statement;
      },
    };

    const adapter = new CloudflareD1Adapter(mockDb as any);
    const updated = await adapter.updateParticipantName("dev%123", "New Name");

    assert.strictEqual(updated.length, 1);
    assert.strictEqual(preparedQueries.length, 1);
    assert.ok(preparedQueries[0].query.includes("ESCAPE '\\'"));
    assert.strictEqual(preparedQueries[0].params[0], "dev%123");
    assert.strictEqual(preparedQueries[0].params[1], '%"deviceId":"dev\\%123"%');
  });
});
