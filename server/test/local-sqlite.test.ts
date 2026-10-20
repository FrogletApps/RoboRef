import { describe, it } from "node:test";
import assert from "node:assert";
import { LocalSqliteAdapter } from "../src/adapters/local-sqlite.js";
import type { IncidentNoteRecord } from "../src/core/types.js";

describe("LocalSqliteAdapter", () => {
  it("should successfully apply note changes in a transaction", async () => {
    const adapter = new LocalSqliteAdapter(":memory:");
    await adapter.init();

    const sampleNote: IncidentNoteRecord = {
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
      version: 0,
    };

    const result = await adapter.applyNoteChanges("RE-VRC-23-1234", [sampleNote]);
    assert.strictEqual(result.latestVersion, 1);

    const notes = await adapter.getNotesSince("RE-VRC-23-1234", 0);
    assert.strictEqual(notes.length, 1);
    assert.strictEqual(notes[0].id, "note-1");
    assert.strictEqual(notes[0].version, 1);
  });

  it("should rollback transaction and rethrow when an error occurs during applyNoteChanges", async () => {
    const adapter = new LocalSqliteAdapter(":memory:");
    await adapter.init();

    const sampleNote: IncidentNoteRecord = {
      id: "note-err-1",
      sku: "RE-VRC-23-1234",
      teamNumber: "1234B",
      ruleCodes: ["G2"],
      severity: "major",
      notes: "Note that should rollback",
      refereeName: "Ref 2",
      deviceId: "dev-2",
      createdAt: 2000,
      updatedAt: 2000,
      isDeleted: false,
      version: 0,
    };

    const db = (adapter as any).db;
    const originalExec = db.exec.bind(db);
    const execCalls: string[] = [];

    db.exec = (sql: string) => {
      execCalls.push(sql);
      if (sql.includes("COMMIT")) {
        throw new Error("Simulated DB error on COMMIT");
      }
      return originalExec(sql);
    };

    await assert.rejects(
      async () => {
        await adapter.applyNoteChanges("RE-VRC-23-1234", [sampleNote]);
      },
      {
        name: "Error",
        message: "Simulated DB error on COMMIT",
      }
    );

    // Verify SQL exec sequence included BEGIN, COMMIT, and ROLLBACK
    assert.ok(execCalls.includes("BEGIN;"));
    assert.ok(execCalls.includes("COMMIT;"));
    assert.ok(execCalls.includes("ROLLBACK;"));

    // Restore original exec method to query DB
    db.exec = originalExec;

    // Verify notes were rolled back and not saved
    const notes = await adapter.getNotesSince("RE-VRC-23-1234", 0);
    assert.strictEqual(notes.length, 0);
  });
});
