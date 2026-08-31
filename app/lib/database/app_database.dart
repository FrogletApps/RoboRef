import 'package:drift/drift.dart';
import 'tables/events_table.dart';
import 'tables/teams_table.dart';
import 'tables/matches_table.dart';
import 'tables/incident_notes_table.dart';
import 'connection/connection.dart' as impl;
import '../core/utils/team_utils.dart';
import '../core/utils/match_utils.dart';

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

  // --- Events DAO Methods ---

  // Stream of recent visible events
  Stream<List<Event>> watchRecentEvents({int limit = 10}) {
    return (select(events)
          ..where((tbl) => tbl.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .watch();
  }

  // Get a single event by SKU
  Future<Event?> getEventBySku(String sku) {
    return (select(events)..where((tbl) => tbl.sku.equals(sku))).getSingleOrNull();
  }

  // Stream a single event by SKU for reactive UI updates
  Stream<Event?> watchEventBySku(String sku) {
    return (select(events)..where((tbl) => tbl.sku.equals(sku))).watchSingleOrNull();
  }

  // Upsert an event record
  Future<void> upsertEvent(EventsCompanion entry) {
    return into(events).insertOnConflictUpdate(entry);
  }

  // Hide an event from recent history
  Future<void> hideEvent(String sku) {
    return (update(events)..where((tbl) => tbl.sku.equals(sku))).write(
      const EventsCompanion(isHidden: Value(true)),
    );
  }

  // Unhide an event in history
  Future<void> unhideEvent(String sku) {
    return (update(events)..where((tbl) => tbl.sku.equals(sku))).write(
      const EventsCompanion(isHidden: Value(false)),
    );
  }

  // Delete an event record
  Future<void> deleteEvent(String sku) {
    return (delete(events)..where((tbl) => tbl.sku.equals(sku))).go();
  }

  // --- Teams DAO Methods ---
  Stream<List<Team>> watchTeamsForSku(String sku) {
    return (select(teams)
          ..where((tbl) => tbl.sku.equals(sku)))
        .watch()
        .map((list) => List<Team>.from(list)..sort(compareTeams));
  }

  Future<List<Team>> getTeamsForSku(String sku) async {
    final list = await (select(teams)
          ..where((tbl) => tbl.sku.equals(sku)))
        .get();
    return List<Team>.from(list)..sort(compareTeams);
  }

  Future<void> upsertTeams(List<TeamsCompanion> entries) async {
    await batch((batch) {
      for (final entry in entries) {
        batch.insert(
          teams,
          entry,
          onConflict: DoUpdate(
            (old) => entry,
            target: [teams.teamNumber, teams.sku],
          ),
        );
      }
    });
  }

  // --- Matches DAO Methods ---
  Stream<List<Matche>> watchMatchesForSku(String sku) {
    return (select(matches)
          ..where((tbl) => tbl.sku.equals(sku)))
        .watch()
        .map((list) => List<Matche>.from(list)..sort(compareMatches));
  }

  Future<List<Matche>> getMatchesForSku(String sku) async {
    final list = await (select(matches)
          ..where((tbl) => tbl.sku.equals(sku)))
        .get();
    return List<Matche>.from(list)..sort(compareMatches);
  }

  Future<void> upsertMatches(List<MatchesCompanion> entries) async {
    await batch((batch) {
      for (final entry in entries) {
        batch.insert(
          matches,
          entry,
          onConflict: DoUpdate(
            (old) => entry,
            target: [matches.matchId, matches.sku],
          ),
        );
      }
    });
  }

  // Clear all tournament data for a SKU
  Future<void> clearTournamentData(String sku) async {
    await (delete(matches)..where((tbl) => tbl.sku.equals(sku))).go();
    await (delete(teams)..where((tbl) => tbl.sku.equals(sku))).go();
  }
}
