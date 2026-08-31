import type { D1Database } from "@cloudflare/workers-types";
import type { StorageAdapter, EventRecord, IncidentNoteRecord, ShareSessionRecord, ShareParticipant } from "../core/types.js";

export class CloudflareD1Adapter implements StorageAdapter {
  private db: D1Database;
  private initialized = false;

  constructor(d1: D1Database) {
    this.db = d1;
  }

  async init(): Promise<void> {
    if (this.initialized) return;
    try {
      await this.db.batch([
        this.db.prepare(`
          CREATE TABLE IF NOT EXISTS events (
            sku TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            program TEXT NOT NULL,
            season TEXT NOT NULL,
            startDate TEXT NOT NULL,
            endDate TEXT NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        `),
        this.db.prepare(`
          CREATE TABLE IF NOT EXISTS notes (
            id TEXT PRIMARY KEY,
            sku TEXT NOT NULL,
            teamNumber TEXT NOT NULL,
            matchId TEXT,
            ruleCodes TEXT NOT NULL,
            severity TEXT NOT NULL,
            notes TEXT NOT NULL,
            refereeName TEXT NOT NULL,
            deviceId TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isDeleted INTEGER NOT NULL DEFAULT 0,
            version INTEGER NOT NULL
          )
        `),
        this.db.prepare(`
          CREATE INDEX IF NOT EXISTS idx_notes_sku_ver ON notes (sku, version)
        `),
        this.db.prepare(`
          CREATE TABLE IF NOT EXISTS share_sessions (
            id TEXT PRIMARY KEY,
            sku TEXT NOT NULL,
            adminDeviceId TEXT NOT NULL,
            adminRefereeName TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            participantsJson TEXT NOT NULL
          )
        `),
        this.db.prepare(`
          CREATE INDEX IF NOT EXISTS idx_share_sessions_sku ON share_sessions (sku)
        `),
      ]);
      this.initialized = true;
    } catch (e) {
      console.error("CloudflareD1Adapter init error:", e);
      throw e;
    }
  }

  async getEvent(sku: string): Promise<EventRecord | null> {
    const result = await this.db.prepare("SELECT * FROM events WHERE sku = ?").bind(sku).first<EventRecord>();
    return result || null;
  }

  async saveEvent(event: EventRecord): Promise<void> {
    await this.db.prepare(`
      INSERT INTO events (sku, name, program, season, startDate, endDate, updatedAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(sku) DO UPDATE SET
        name=excluded.name,
        program=excluded.program,
        season=excluded.season,
        startDate=excluded.startDate,
        endDate=excluded.endDate,
        updatedAt=excluded.updatedAt
    `).bind(
      event.sku, event.name, event.program, event.season, event.startDate, event.endDate, event.updatedAt
    ).run();
  }

  async getNotesSince(sku: string, sinceVersion: number): Promise<IncidentNoteRecord[]> {
    const { results } = await this.db.prepare(
      "SELECT * FROM notes WHERE sku = ? AND version > ? ORDER BY version ASC"
    ).bind(sku, sinceVersion).all<any>();

    return (results || []).map((r) => ({
      ...r,
      isDeleted: Boolean(r.isDeleted),
      ruleCodes: JSON.parse(r.ruleCodes),
    }));
  }

  async applyNoteChanges(sku: string, changes: IncidentNoteRecord[]): Promise<{ latestVersion: number }> {
    const maxVerRow = await this.db.prepare("SELECT MAX(version) as maxVer FROM notes WHERE sku = ?").bind(sku).first<{ maxVer: number | null }>();
    let currentMax = maxVerRow?.maxVer ?? 0;

    const statements = [];
    for (const record of changes) {
      currentMax += 1;
      statements.push(
        this.db.prepare(`
          INSERT INTO notes (id, sku, teamNumber, matchId, ruleCodes, severity, notes, refereeName, deviceId, createdAt, updatedAt, isDeleted, version)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            sku=excluded.sku,
            teamNumber=excluded.teamNumber,
            matchId=excluded.matchId,
            ruleCodes=excluded.ruleCodes,
            severity=excluded.severity,
            notes=excluded.notes,
            refereeName=excluded.refereeName,
            deviceId=excluded.deviceId,
            createdAt=excluded.createdAt,
            updatedAt=excluded.updatedAt,
            isDeleted=excluded.isDeleted,
            version=excluded.version
          WHERE excluded.updatedAt > notes.updatedAt
        `).bind(
          record.id,
          record.sku,
          record.teamNumber,
          record.matchId ?? null,
          JSON.stringify(record.ruleCodes || []),
          record.severity,
          record.notes,
          record.refereeName,
          record.deviceId,
          record.createdAt,
          record.updatedAt,
          record.isDeleted ? 1 : 0,
          currentMax
        )
      );
    }

    if (statements.length > 0) {
      await this.db.batch(statements);
    }

    return { latestVersion: currentMax };
  }

  private mapShareRow(row: any): ShareSessionRecord {
    return {
      id: row.id,
      sku: row.sku,
      adminDeviceId: row.adminDeviceId,
      adminRefereeName: row.adminRefereeName,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      participants: JSON.parse(row.participantsJson || "[]"),
    };
  }

  async createShareSession(session: ShareSessionRecord): Promise<ShareSessionRecord> {
    await this.db.prepare(`
      INSERT INTO share_sessions (id, sku, adminDeviceId, adminRefereeName, createdAt, updatedAt, participantsJson)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        sku=excluded.sku,
        adminDeviceId=excluded.adminDeviceId,
        adminRefereeName=excluded.adminRefereeName,
        updatedAt=excluded.updatedAt,
        participantsJson=excluded.participantsJson
    `).bind(
      session.id,
      session.sku,
      session.adminDeviceId,
      session.adminRefereeName,
      session.createdAt,
      session.updatedAt,
      JSON.stringify(session.participants)
    ).run();

    return session;
  }

  async getShareSession(id: string): Promise<ShareSessionRecord | null> {
    const row = await this.db.prepare("SELECT * FROM share_sessions WHERE id = ?").bind(id).first<any>();
    if (!row) return null;
    return this.mapShareRow(row);
  }

  async getActiveSharesForSku(sku: string): Promise<ShareSessionRecord[]> {
    const { results } = await this.db.prepare("SELECT * FROM share_sessions WHERE sku = ? ORDER BY createdAt DESC").bind(sku).all<any>();
    return (results || []).map((r) => this.mapShareRow(r));
  }

  async addParticipant(shareId: string, participant: ShareParticipant): Promise<ShareSessionRecord | null> {
    const session = await this.getShareSession(shareId);
    if (!session) return null;

    const existingIdx = session.participants.findIndex((p: ShareParticipant) => p.deviceId === participant.deviceId);
    if (existingIdx >= 0) {
      session.participants[existingIdx] = {
        ...session.participants[existingIdx],
        refereeName: participant.refereeName,
        joinedAt: participant.joinedAt,
      };
    } else {
      session.participants.push(participant);
    }
    session.updatedAt = Date.now();

    await this.db.prepare("UPDATE share_sessions SET participantsJson = ?, updatedAt = ? WHERE id = ?").bind(
      JSON.stringify(session.participants),
      session.updatedAt,
      shareId
    ).run();

    return session;
  }

  async removeParticipant(
    shareId: string,
    deviceId: string
  ): Promise<{ session: ShareSessionRecord | null; deleted: boolean }> {
    const session = await this.getShareSession(shareId);
    if (!session) {
      return { session: null, deleted: false };
    }

    const isAdmin = session.adminDeviceId === deviceId;
    if (isAdmin && session.participants.length > 1) {
      throw new Error("ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS");
    }

    const updatedParticipants = session.participants.filter((p: ShareParticipant) => p.deviceId !== deviceId);

    if (updatedParticipants.length === 0) {
      await this.db.batch([
        this.db.prepare("DELETE FROM share_sessions WHERE id = ?").bind(shareId),
        this.db.prepare("DELETE FROM notes WHERE sku = ?").bind(session.sku),
      ]);
      return { session: null, deleted: true };
    }

    session.participants = updatedParticipants;
    session.updatedAt = Date.now();

    await this.db.prepare("UPDATE share_sessions SET participantsJson = ?, updatedAt = ? WHERE id = ?").bind(
      JSON.stringify(session.participants),
      session.updatedAt,
      shareId
    ).run();

    return { session, deleted: false };
  }

  async deleteShareSession(shareId: string): Promise<void> {
    await this.db.prepare("DELETE FROM share_sessions WHERE id = ?").bind(shareId).run();
  }

  async purgeSkuNotes(sku: string): Promise<void> {
    await this.db.prepare("DELETE FROM notes WHERE sku = ?").bind(sku).run();
  }
}

