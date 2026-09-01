import { DatabaseSync } from "node:sqlite";
export class LocalSqliteAdapter {
    db;
    constructor(dbPath = "roboref.sqlite") {
        this.db = new DatabaseSync(dbPath);
        this.db.exec("PRAGMA journal_mode = WAL;");
    }
    async init() {
        this.db.exec(`
      CREATE TABLE IF NOT EXISTS events (
        sku TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        program TEXT NOT NULL,
        season TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        updatedAt INTEGER NOT NULL
      );

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
      );

      CREATE INDEX IF NOT EXISTS idx_notes_sku_ver ON notes (sku, version);

      CREATE TABLE IF NOT EXISTS share_sessions (
        id TEXT PRIMARY KEY,
        sku TEXT NOT NULL,
        adminDeviceId TEXT NOT NULL,
        adminRefereeName TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        participantsJson TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_share_sessions_sku ON share_sessions (sku);
    `);
    }
    async getEvent(sku) {
        const row = this.db.prepare("SELECT * FROM events WHERE sku = ?").get(sku);
        return row || null;
    }
    async saveEvent(event) {
        const stmt = this.db.prepare(`
      INSERT INTO events (sku, name, program, season, startDate, endDate, updatedAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(sku) DO UPDATE SET
        name=excluded.name,
        program=excluded.program,
        season=excluded.season,
        startDate=excluded.startDate,
        endDate=excluded.endDate,
        updatedAt=excluded.updatedAt
    `);
        stmt.run(event.sku, event.name, event.program, event.season, event.startDate, event.endDate, event.updatedAt);
    }
    async getNotesSince(sku, sinceVersion) {
        const rows = this.db.prepare("SELECT * FROM notes WHERE sku = ? AND version > ? ORDER BY version ASC").all(sku, sinceVersion);
        return rows.map((r) => ({
            ...r,
            isDeleted: Boolean(r.isDeleted),
            ruleCodes: JSON.parse(r.ruleCodes),
        }));
    }
    async applyNoteChanges(sku, changes) {
        const maxVerRow = this.db.prepare("SELECT MAX(version) as maxVer FROM notes WHERE sku = ?").get(sku);
        let currentMax = maxVerRow?.maxVer ?? 0;
        const upsertStmt = this.db.prepare(`
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
    `);
        this.db.exec("BEGIN;");
        try {
            for (const record of changes) {
                currentMax += 1;
                upsertStmt.run(record.id, record.sku, record.teamNumber, record.matchId ?? null, JSON.stringify(record.ruleCodes || []), record.severity, record.notes, record.refereeName, record.deviceId, record.createdAt, record.updatedAt, record.isDeleted ? 1 : 0, currentMax);
            }
            this.db.exec("COMMIT;");
        }
        catch (err) {
            this.db.exec("ROLLBACK;");
            throw err;
        }
        return { latestVersion: currentMax };
    }
    mapShareRow(row) {
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
    async createShareSession(session) {
        const stmt = this.db.prepare(`
      INSERT INTO share_sessions (id, sku, adminDeviceId, adminRefereeName, createdAt, updatedAt, participantsJson)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        sku=excluded.sku,
        adminDeviceId=excluded.adminDeviceId,
        adminRefereeName=excluded.adminRefereeName,
        updatedAt=excluded.updatedAt,
        participantsJson=excluded.participantsJson
    `);
        stmt.run(session.id, session.sku, session.adminDeviceId, session.adminRefereeName, session.createdAt, session.updatedAt, JSON.stringify(session.participants));
        return session;
    }
    async getShareSession(id) {
        const row = this.db.prepare("SELECT * FROM share_sessions WHERE id = ?").get(id);
        if (!row)
            return null;
        return this.mapShareRow(row);
    }
    async getActiveSharesForSku(sku) {
        const rows = this.db.prepare("SELECT * FROM share_sessions WHERE sku = ? ORDER BY createdAt DESC").all(sku);
        return rows.map((r) => this.mapShareRow(r));
    }
    async addParticipant(shareId, participant) {
        const session = await this.getShareSession(shareId);
        if (!session)
            return null;
        const existingIdx = session.participants.findIndex((p) => p.deviceId === participant.deviceId);
        if (existingIdx >= 0) {
            session.participants[existingIdx] = {
                ...session.participants[existingIdx],
                refereeName: participant.refereeName,
                joinedAt: participant.joinedAt,
            };
        }
        else {
            session.participants.push(participant);
        }
        session.updatedAt = Date.now();
        const stmt = this.db.prepare("UPDATE share_sessions SET participantsJson = ?, updatedAt = ? WHERE id = ?");
        stmt.run(JSON.stringify(session.participants), session.updatedAt, shareId);
        return session;
    }
    async removeParticipant(shareId, deviceId) {
        const session = await this.getShareSession(shareId);
        if (!session) {
            return { session: null, deleted: false };
        }
        const isAdmin = session.adminDeviceId === deviceId;
        if (isAdmin && session.participants.length > 1) {
            throw new Error("ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS");
        }
        const updatedParticipants = session.participants.filter((p) => p.deviceId !== deviceId);
        if (updatedParticipants.length === 0) {
            // Last participant (or admin when alone) left -> delete share session and purge notes
            this.db.exec("BEGIN;");
            try {
                this.db.prepare("DELETE FROM share_sessions WHERE id = ?").run(shareId);
                this.db.prepare("DELETE FROM notes WHERE sku = ?").run(session.sku);
                this.db.exec("COMMIT;");
            }
            catch (err) {
                this.db.exec("ROLLBACK;");
                throw err;
            }
            return { session: null, deleted: true };
        }
        session.participants = updatedParticipants;
        session.updatedAt = Date.now();
        const stmt = this.db.prepare("UPDATE share_sessions SET participantsJson = ?, updatedAt = ? WHERE id = ?");
        stmt.run(JSON.stringify(session.participants), session.updatedAt, shareId);
        return { session, deleted: false };
    }
    async deleteShareSession(shareId) {
        this.db.prepare("DELETE FROM share_sessions WHERE id = ?").run(shareId);
    }
    async purgeSkuNotes(sku) {
        this.db.prepare("DELETE FROM notes WHERE sku = ?").run(sku);
    }
}
