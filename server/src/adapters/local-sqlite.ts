import Database from "better-sqlite3";
import type { StorageAdapter, EventRecord, IncidentNoteRecord } from "../core/types.js";

export class LocalSqliteAdapter implements StorageAdapter {
  private db: Database.Database;

  constructor(dbPath: string = "roboref.sqlite") {
    this.db = new Database(dbPath);
    this.db.pragma("journal_mode = WAL");
  }

  async init(): Promise<void> {
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
    `);
  }

  async getEvent(sku: string): Promise<EventRecord | null> {
    const row = this.db.prepare("SELECT * FROM events WHERE sku = ?").get(sku) as EventRecord | undefined;
    return row || null;
  }

  async saveEvent(event: EventRecord): Promise<void> {
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

  async getNotesSince(sku: string, sinceVersion: number): Promise<IncidentNoteRecord[]> {
    const rows = this.db.prepare(
      "SELECT * FROM notes WHERE sku = ? AND version > ? ORDER BY version ASC"
    ).all(sku, sinceVersion) as any[];

    return rows.map((r) => ({
      ...r,
      isDeleted: Boolean(r.isDeleted),
      ruleCodes: JSON.parse(r.ruleCodes),
    }));
  }

  async applyNoteChanges(sku: string, changes: IncidentNoteRecord[]): Promise<{ latestVersion: number }> {
    const maxVerRow = this.db.prepare("SELECT MAX(version) as maxVer FROM notes WHERE sku = ?").get(sku) as { maxVer: number | null };
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

    const transaction = this.db.transaction((records: IncidentNoteRecord[]) => {
      for (const record of records) {
        currentMax += 1;
        upsertStmt.run(
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
        );
      }
    });

    transaction(changes);
    return { latestVersion: currentMax };
  }
}
