import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../database/app_database.dart';
import '../../../core/network/sync_client.dart';
import '../../settings/state/sync_settings_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Stream of notes for the currently active tournament SKU
final activeTournamentNotesProvider = StreamProvider.autoDispose<List<IncidentNote>>((ref) {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(syncSettingsProvider);
  return db.watchNotesForSku(settings.currentSku);
});

// Incident Action Notifier
class IncidentController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  IncidentController(this.ref) : super(const AsyncValue.data(null));

  AppDatabase get _db => ref.read(databaseProvider);
  SyncSettingsState get _settings => ref.read(syncSettingsProvider);

  // Add a new incident note
  Future<void> addNote({
    required String teamNumber,
    String? matchId,
    required List<String> ruleCodes,
    required String severity,
    required String notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final noteId = const Uuid().v4();

    await _db.into(_db.incidentNotes).insert(
      IncidentNotesCompanion(
        id: Value(noteId),
        sku: Value(_settings.currentSku),
        teamNumber: Value(teamNumber.trim().toUpperCase()),
        matchId: Value(matchId?.trim().toUpperCase()),
        ruleCodesJson: Value(jsonEncode(ruleCodes)),
        severity: Value(severity),
        notes: Value(notes.trim()),
        refereeName: Value(_settings.refereeName),
        deviceId: Value(_settings.deviceId),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        version: const Value(0),
        isSynced: const Value(false),
      ),
    );

    // Trigger sync in background
    triggerSync();
  }

  // Delete an incident note (soft delete for sync tombstones)
  Future<void> deleteNote(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.incidentNotes)..where((tbl) => tbl.id.equals(id))).write(
      IncidentNotesCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ),
    );

    triggerSync();
  }

  // Sync with remote server (push local changes, pull remote changes)
  Future<void> triggerSync() async {
    final settings = ref.read(syncSettingsProvider);
    final notifier = ref.read(syncSettingsProvider.notifier);

    notifier.setSyncing(true);

    final client = SyncClient(
      baseUrl: settings.serverUrl,
      deviceId: settings.deviceId,
    );

    try {
      // 1. Push dirty local records
      final unsynced = await _db.getUnsyncedNotes();
      if (unsynced.isNotEmpty) {
        final pushResult = await client.pushChanges(
          sku: settings.currentSku,
          localNotes: unsynced,
        );

        if (pushResult.success) {
          await _db.markNotesAsSynced(unsynced.map((n) => n.id).toList());
        }
      }

      // 2. Pull remote records
      final remoteNotes = await client.pullChanges(
        sku: settings.currentSku,
        sinceVersion: 0,
      );

      if (remoteNotes.isNotEmpty) {
        final companions = remoteNotes.map((r) {
          return IncidentNotesCompanion(
            id: Value(r['id'] as String),
            sku: Value(r['sku'] as String),
            teamNumber: Value(r['teamNumber'] as String),
            matchId: Value(r['matchId'] as String?),
            ruleCodesJson: Value(jsonEncode(r['ruleCodes'] ?? [])),
            severity: Value(r['severity'] as String),
            notes: Value(r['notes'] as String),
            refereeName: Value(r['refereeName'] as String),
            deviceId: Value(r['deviceId'] as String),
            createdAt: Value(r['createdAt'] as int),
            updatedAt: Value(r['updatedAt'] as int),
            isDeleted: Value(r['isDeleted'] as bool? ?? false),
            version: Value(r['version'] as int? ?? 0),
            isSynced: const Value(true),
          );
        }).toList();

        await _db.upsertRemoteNotes(companions);
      }

      notifier.setSyncing(false);
    } catch (e) {
      notifier.setSyncing(false, error: e.toString());
    }
  }
}

final incidentControllerProvider =
    StateNotifierProvider<IncidentController, AsyncValue<void>>((ref) {
  return IncidentController(ref);
});
