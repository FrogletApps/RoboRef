export interface EventRecord {
  sku: string;
  name: string;
  program: string;
  season: string;
  startDate: string;
  endDate: string;
  updatedAt: number;
}

export interface TeamRecord {
  teamNumber: string;
  teamName: string;
  organization?: string;
  city?: string;
  region?: string;
  country?: string;
}

export interface MatchRecord {
  matchId: string;
  sku: string;
  divisionId: number;
  name: string;
  field?: string;
  scheduledTime?: string;
  redTeams: string[];
  blueTeams: string[];
  redScore?: number;
  blueScore?: number;
}

export interface IncidentNoteRecord {
  id: string; // UUID v4
  sku: string;
  teamNumber: string;
  matchId?: string;
  ruleCodes: string[]; // e.g. ["G12", "S1", "SG6"]
  severity: "minor" | "major" | "warning" | "d_q";
  notes: string;
  refereeName: string;
  deviceId: string;
  createdAt: number; // UTC timestamp ms
  updatedAt: number; // UTC timestamp ms
  isDeleted: boolean;
  version: number;
}

export interface SyncPushPayload {
  sku: string;
  deviceId: string;
  changes: IncidentNoteRecord[];
}

export interface SyncPullResponse {
  sku: string;
  latestVersion: number;
  changes: IncidentNoteRecord[];
}

export interface StorageAdapter {
  init(): Promise<void>;
  getEvent(sku: string): Promise<EventRecord | null>;
  saveEvent(event: EventRecord): Promise<void>;
  getNotesSince(sku: string, sinceVersion: number): Promise<IncidentNoteRecord[]>;
  applyNoteChanges(sku: string, changes: IncidentNoteRecord[]): Promise<{ latestVersion: number }>;
}
