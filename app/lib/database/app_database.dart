import 'package:drift/drift.dart';
import 'tables/events_table.dart';
import 'tables/teams_table.dart';
import 'tables/matches_table.dart';
import 'tables/incident_notes_table.dart';
import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

@DriftDatabase(tables: [Events, Teams, Matches, IncidentNotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  // Stream of all active (non-deleted) incident notes for a specific tournament SKU
  Stream<List<IncidentNote>> watchNotesForSku(String sku) {
    return (select(incidentNotes)
          ..where((tbl) => tbl.sku.equals(sku) & tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  // Stream of notes for a specific team at a tournament SKU
  Stream<List<IncidentNote>> watchNotesForTeam(String sku, String teamNumber) {
    return (select(incidentNotes)
          ..where((tbl) =>
              tbl.sku.equals(sku) &
              tbl.teamNumber.equals(teamNumber) &
              tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  // Get unsynced local changes to push to sync server
  Future<List<IncidentNote>> getUnsyncedNotes() {
    return (select(incidentNotes)..where((tbl) => tbl.isSynced.equals(false)))
        .get();
  }

  // Mark a batch of notes as synced
  Future<void> markNotesAsSynced(List<String> ids) async {
    await (update(incidentNotes)..where((tbl) => tbl.id.isIn(ids))).write(
      const IncidentNotesCompanion(isSynced: Value(true)),
    );
  }

  // Upsert incoming notes from remote sync server
  Future<void> upsertRemoteNotes(List<IncidentNotesCompanion> entries) async {
    await batch((batch) {
      for (final entry in entries) {
        batch.insert(
          incidentNotes,
          entry,
          onConflict: DoUpdate(
            (old) => entry,
            target: [incidentNotes.id],
          ),
        );
      }
    });
  }
}
