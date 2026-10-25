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

  it("should rollback transaction and rethrow when an error occurs during removeParticipant session deletion", async () => {
    const adapter = new LocalSqliteAdapter(":memory:");
    await adapter.init();

    const sku = "RE-VRC-23-1234";
    const shareId = "share-session-1";
    const deviceId = "dev-1";

    // Create share session
    await adapter.createShareSession({
      id: shareId,
      sku,
      adminDeviceId: deviceId,
      adminRefereeName: "Ref 1",
      createdAt: 1000,
      updatedAt: 1000,
      participants: [
        {
          deviceId,
          refereeName: "Ref 1",
          joinedAt: 1000,
        },
      ],
    });

    // Add a note
    await adapter.applyNoteChanges(sku, [
      {
        id: "note-1",
        sku,
        teamNumber: "1234A",
        ruleCodes: ["G1"],
        severity: "minor",
        notes: "Test note",
        refereeName: "Ref 1",
        deviceId,
        createdAt: 1000,
        updatedAt: 1000,
        isDeleted: false,
        version: 0,
      },
    ]);

    const db = (adapter as any).db;
    const originalExec = db.exec.bind(db);
    const execCalls: string[] = [];

    db.exec = (sql: string) => {
      execCalls.push(sql);
      if (sql.includes("COMMIT")) {
        throw new Error("Simulated DB error on COMMIT during removeParticipant");
      }
      return originalExec(sql);
    };

    await assert.rejects(
      async () => {
        await adapter.removeParticipant(shareId, deviceId);
      },
      {
        name: "Error",
        message: "Simulated DB error on COMMIT during removeParticipant",
      }
    );

    // Verify SQL exec sequence included BEGIN, COMMIT, and ROLLBACK
    assert.ok(execCalls.includes("BEGIN;"));
    assert.ok(execCalls.includes("COMMIT;"));
    assert.ok(execCalls.includes("ROLLBACK;"));

    // Restore original exec method to query DB
    db.exec = originalExec;

    // Verify share session and notes were rolled back and still exist
    const session = await adapter.getShareSession(shareId);
    assert.notStrictEqual(session, null);
    assert.strictEqual(session?.id, shareId);

    const notes = await adapter.getNotesSince(sku, 0);
    assert.strictEqual(notes.length, 1);
    assert.strictEqual(notes[0].id, "note-1");
  });

  it("should handle deviceId with LIKE wildcard characters safely in updateParticipantName", async () => {
    const adapter = new LocalSqliteAdapter(":memory:");
    await adapter.init();

    const targetDeviceId = "dev%123_test\\1";
    const otherDeviceId = "devX123YtestZ1";

    await adapter.createShareSession({
      id: "share-wildcard-1",
      sku: "RE-VRC-23-1000",
      adminDeviceId: targetDeviceId,
      adminRefereeName: "Ref Wildcard",
      createdAt: 1000,
      updatedAt: 1000,
      participants: [
        {
          deviceId: targetDeviceId,
          refereeName: "Ref Wildcard",
          joinedAt: 1000,
        },
      ],
    });

    await adapter.createShareSession({
      id: "share-wildcard-2",
      sku: "RE-VRC-23-1000",
      adminDeviceId: otherDeviceId,
      adminRefereeName: "Ref Other",
      createdAt: 1000,
      updatedAt: 1000,
      participants: [
        {
          deviceId: otherDeviceId,
          refereeName: "Ref Other",
          joinedAt: 1000,
        },
      ],
    });

    const updatedSessions = await adapter.updateParticipantName(targetDeviceId, "Ref Wildcard Updated");
    assert.strictEqual(updatedSessions.length, 1);
    assert.strictEqual(updatedSessions[0].id, "share-wildcard-1");
    assert.strictEqual(updatedSessions[0].adminRefereeName, "Ref Wildcard Updated");

    // Ensure session 2 was unaffected
    const session2 = await adapter.getShareSession("share-wildcard-2");
    assert.strictEqual(session2?.adminRefereeName, "Ref Other");
  });
});
