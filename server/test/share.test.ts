import { describe, it } from "node:test";
import assert from "node:assert";
import { createSyncApp } from "../src/core/app.js";
import type { StorageAdapter, ShareSessionRecord, ShareParticipant, IncidentNoteRecord, EventRecord } from "../src/core/types.js";

class MockShareStorageAdapter implements StorageAdapter {
  public notes: IncidentNoteRecord[] = [];
  public events: EventRecord[] = [];
  public shareSessions: ShareSessionRecord[] = [];

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
      this.notes.push({ ...change, sku, version: maxVer });
    }
    return { latestVersion: maxVer };
  }
  async createShareSession(session: ShareSessionRecord): Promise<ShareSessionRecord> {
    this.shareSessions.push(session);
    return session;
  }
  async getShareSession(id: string): Promise<ShareSessionRecord | null> {
    return this.shareSessions.find((s) => s.id === id) || null;
  }
  async getActiveSharesForSku(sku: string): Promise<ShareSessionRecord[]> {
    return this.shareSessions.filter((s) => s.sku === sku);
  }
  async addParticipant(shareId: string, participant: ShareParticipant): Promise<ShareSessionRecord | null> {
    const s = await this.getShareSession(shareId);
    if (!s) return null;
    const existingIdx = s.participants.findIndex((p) => p.deviceId === participant.deviceId);
    if (existingIdx >= 0) {
      s.participants[existingIdx] = participant;
    } else {
      s.participants.push(participant);
    }
    s.updatedAt = Date.now();
    return s;
  }
  async removeParticipant(
    shareId: string,
    deviceId: string
  ): Promise<{ session: ShareSessionRecord | null; deleted: boolean }> {
    const s = await this.getShareSession(shareId);
    if (!s) return { session: null, deleted: false };
    if (s.adminDeviceId === deviceId && s.participants.length > 1) {
      throw new Error("ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS");
    }
    s.participants = s.participants.filter((p) => p.deviceId !== deviceId);
    if (s.participants.length === 0) {
      this.shareSessions = this.shareSessions.filter((sess) => sess.id !== shareId);
      this.notes = this.notes.filter((n) => n.sku !== s.sku);
      return { session: null, deleted: true };
    }
    return { session: s, deleted: false };
  }
  async deleteShareSession(shareId: string): Promise<void> {
    this.shareSessions = this.shareSessions.filter((s) => s.id !== shareId);
  }
  async purgeSkuNotes(sku: string): Promise<void> {
    this.notes = this.notes.filter((n) => n.sku !== sku);
  }
}

describe("Secure Share Server Endpoints", () => {
  it("GET /api/share/check returns empty list when no active share exists", async () => {
    const storage = new MockShareStorageAdapter();
    const app = createSyncApp(storage);

    const res = await app.request("/api/share/check?sku=RE-VRC-24-1234");
    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.sku, "RE-VRC-24-1234");
    assert.deepStrictEqual(json.activeShares, []);
  });

  it("POST /api/share/create creates a new share session and sets creator as admin", async () => {
    const storage = new MockShareStorageAdapter();
    const app = createSyncApp(storage);

    const res = await app.request("/api/share/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: "RE-VRC-24-1234",
        adminDeviceId: "dev-admin-1",
        adminRefereeName: "Alice Head Ref",
      }),
    });

    assert.strictEqual(res.status, 200);
    const json = await res.json();
    assert.strictEqual(json.success, true);
    assert.strictEqual(json.session.sku, "RE-VRC-24-1234");
    assert.strictEqual(json.session.adminDeviceId, "dev-admin-1");
    assert.strictEqual(json.session.adminRefereeName, "Alice Head Ref");
    assert.strictEqual(json.session.participants.length, 1);
    assert.strictEqual(json.session.participants[0].role, "admin");
    assert.ok(json.session.id.length >= 6);
  });

  it("POST /api/share/create warns with 409 if a share already exists owned by someone else", async () => {
    const storage = new MockShareStorageAdapter();
    const app = createSyncApp(storage);

    // First person creates share
    await app.request("/api/share/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: "RE-VRC-24-1234",
        adminDeviceId: "dev-admin-1",
        adminRefereeName: "Alice Head Ref",
      }),
    });

    // Second person tries to create share for same SKU
    const res2 = await app.request("/api/share/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: "RE-VRC-24-1234",
        adminDeviceId: "dev-referee-2",
        adminRefereeName: "Bob Referee",
      }),
    });

    assert.strictEqual(res2.status, 409);
    const json2 = await res2.json();
    assert.strictEqual(json2.error, "SHARE_ALREADY_EXISTS");
    assert.ok(json2.message.includes("Alice Head Ref"));
    assert.strictEqual(json2.existingShares.length, 1);
    assert.strictEqual(json2.existingShares[0].adminRefereeName, "Alice Head Ref");
  });

  it("POST /api/share/join allows a peer referee to join active share", async () => {
    const storage = new MockShareStorageAdapter();
    const app = createSyncApp(storage);

    const createRes = await app.request("/api/share/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: "RE-VRC-24-1234",
        adminDeviceId: "dev-admin-1",
        adminRefereeName: "Alice Head Ref",
      }),
    });
    const { session } = await createRes.json();

    const joinRes = await app.request("/api/share/join", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        shareId: session.id,
        deviceId: "dev-referee-2",
        refereeName: "Bob Field Ref",
      }),
    });

    assert.strictEqual(joinRes.status, 200);
    const joinJson = await joinRes.json();
    assert.strictEqual(joinJson.success, true);
    assert.strictEqual(joinJson.session.participants.length, 2);
    assert.strictEqual(joinJson.session.participants[1].role, "member");
    assert.strictEqual(joinJson.session.participants[1].refereeName, "Bob Field Ref");
  });

  it("POST /api/share/remove-participant allows admin to remove a member", async () => {
    const storage = new MockShareStorageAdapter();
    const app = createSyncApp(storage);

    const createRes = await app.request("/api/share/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: "RE-VRC-24-1234",
        adminDeviceId: "dev-admin-1",
        adminRefereeName: "Alice Head Ref",
      }),
    });
    const { session } = await createRes.json();

    await app.request("/api/share/join", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        shareId: session.id,
        deviceId: "dev-referee-2",
        refereeName: "Bob Field Ref",
      }),
    });

    // Non-admin cannot remove
    const failKick = await app.request("/api/share/remove-participant", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        shareId: session.id,
        adminDeviceId: "dev-referee-2",
        targetDeviceId: "dev-admin-1",
      }),
    });
    assert.strictEqual(failKick.status, 403);

    // Admin removes Bob
    const kickRes = await app.request("/api/share/remove-participant", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        shareId: session.id,
        adminDeviceId: "dev-admin-1",
        targetDeviceId: "dev-referee-2",
      }),
    });
    assert.strictEqual(kickRes.status, 200);
    const kickJson = await kickRes.json();
    assert.strictEqual(kickJson.session.participants.length, 1);
    assert.strictEqual(kickJson.session.participants[0].deviceId, "dev-admin-1");
  });

  it("POST /api/share/leave blocks admin from leaving while other participants are still present", async () => {
    const storage = new MockShareStorageAdapter();
    const app = createSyncApp(storage);

    const createRes = await app.request("/api/share/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: "RE-VRC-24-1234",
        adminDeviceId: "dev-admin-1",
        adminRefereeName: "Alice Head Ref",
      }),
    });
    const { session } = await createRes.json();

    await app.request("/api/share/join", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        shareId: session.id,
        deviceId: "dev-referee-2",
        refereeName: "Bob Field Ref",
      }),
    });

    // Admin attempts to leave while Bob is connected
    const leaveRes = await app.request("/api/share/leave", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        shareId: session.id,
        deviceId: "dev-admin-1",
      }),
    });

    assert.strictEqual(leaveRes.status, 400);
    const leaveJson = await leaveRes.json();
    assert.strictEqual(leaveJson.error, "ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS");
  });

  it("POST /api/share/leave automatically purges cloud notes and deletes session when last person leaves", async () => {
    const storage = new MockShareStorageAdapter();
    const app = createSyncApp(storage);

    // Seed some notes
    storage.notes.push({
      id: "note-1",
      sku: "RE-VRC-24-1234",
      teamNumber: "1234A",
      ruleCodes: ["G12"],
      severity: "minor",
      notes: "Cloud note",
      refereeName: "Alice",
      deviceId: "dev-admin-1",
      createdAt: 1000,
      updatedAt: 1000,
      isDeleted: false,
      version: 1,
    });

    const createRes = await app.request("/api/share/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sku: "RE-VRC-24-1234",
        adminDeviceId: "dev-admin-1",
        adminRefereeName: "Alice Head Ref",
      }),
    });
    const { session } = await createRes.json();

    // Admin is alone, leaves
    const leaveRes = await app.request("/api/share/leave", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        shareId: session.id,
        deviceId: "dev-admin-1",
      }),
    });

    assert.strictEqual(leaveRes.status, 200);
    const leaveJson = await leaveRes.json();
    assert.strictEqual(leaveJson.deleted, true);
    assert.strictEqual(leaveJson.remainingCount, 0);

    // Verify session and notes were purged from storage
    assert.strictEqual(storage.shareSessions.length, 0);
    assert.strictEqual(storage.notes.length, 0);
  });
});
