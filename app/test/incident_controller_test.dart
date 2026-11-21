import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'current_sku': 'RE-V5RC-24-1234',
      'referee_name': 'Ref Alice',
      'device_id': 'device-test-123',
      'server_url': 'http://127.0.0.1:8080',
    });
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer createContainer({
    AppDatabase? customDb,
    SharedPreferences? customPrefs,
    http.Client? syncHttpClient,
  }) {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(customPrefs ?? prefs),
        databaseProvider.overrideWithValue(customDb ?? db),
        if (syncHttpClient != null)
          syncClientHttpClientProvider.overrideWithValue(syncHttpClient),
      ],
    );
  }

  group('IncidentController - deleteNote', () {
    test('soft deletes existing incident note, updating isDeleted, isSynced, and updatedAt', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const noteId = 'note-to-delete-1';
      const sku = 'RE-V5RC-24-1234';
      final initialTime = DateTime.now().millisecondsSinceEpoch - 10000;

      // Seed a note in the database
      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const Value(noteId),
          sku: const Value(sku),
          teamNumber: const Value('1234A'),
          matchId: const Value('Q1'),
          ruleCodesJson: Value(jsonEncode(['G12'])),
          severity: const Value('warning'),
          notes: const Value('Initial warning'),
          refereeName: const Value('Ref Alice'),
          deviceId: const Value('device-test-123'),
          createdAt: Value(initialTime),
          updatedAt: Value(initialTime),
          isDeleted: const Value(false),
          version: const Value(1),
          isSynced: const Value(true), // Was synced before deletion
        ),
      );

      // Verify initial state
      final initialNotes = await (db.select(db.incidentNotes)..where((tbl) => tbl.id.equals(noteId))).get();
      expect(initialNotes.length, 1);
      expect(initialNotes.first.isDeleted, false);
      expect(initialNotes.first.isSynced, true);

      // Call deleteNote via IncidentController
      final controller = container.read(incidentControllerProvider.notifier);
      await controller.deleteNote(noteId);

      // Verify post-deletion state in database
      final updatedNotes = await (db.select(db.incidentNotes)..where((tbl) => tbl.id.equals(noteId))).get();
      expect(updatedNotes.length, 1);
      final deletedNote = updatedNotes.first;

      expect(deletedNote.isDeleted, isTrue, reason: 'isDeleted should be set to true (soft delete tombstone)');
      expect(deletedNote.isSynced, isFalse, reason: 'isSynced should be reset to false so it syncs deletion to server');
      expect(deletedNote.updatedAt, greaterThanOrEqualTo(initialTime), reason: 'updatedAt should be refreshed');
    });

    test('calling deleteNote on non-existent ID completes safely without errors', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(incidentControllerProvider.notifier);

      // Ensure no error is thrown when deleting a non-existent note
      await expectLater(
        controller.deleteNote('non-existent-id-999'),
        completes,
      );

      final allNotes = await db.select(db.incidentNotes).get();
      expect(allNotes, isEmpty);
    });

    test('deleted note is included in getUnsyncedNotes as a tombstone for sync', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const noteId = 'note-tombstone-1';
      const sku = 'RE-V5RC-24-1234';

      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const Value(noteId),
          sku: const Value(sku),
          teamNumber: const Value('2056A'),
          ruleCodesJson: Value(jsonEncode(['S1'])),
          severity: const Value('general'),
          notes: const Value('Safety violation'),
          refereeName: const Value('Ref Alice'),
          deviceId: const Value('device-test-123'),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          isDeleted: const Value(false),
          version: const Value(0),
          isSynced: const Value(true),
        ),
      );

      // Soft delete note
      final controller = container.read(incidentControllerProvider.notifier);
      await controller.deleteNote(noteId);

      // getUnsyncedNotes should return the soft-deleted note so pushChanges can send the tombstone
      final unsynced = await db.getUnsyncedNotes();
      expect(unsynced.length, 1);
      expect(unsynced.first.id, noteId);
      expect(unsynced.first.isDeleted, isTrue);
      expect(unsynced.first.isSynced, isFalse);
    });

    test('addNote creates an active note and triggerSync is executed', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(incidentControllerProvider.notifier);

      await controller.addNote(
        teamNumber: '1114A',
        matchId: 'Q5',
        ruleCodes: ['G12', 'SG3'],
        severity: 'warning',
        notes: 'Contact during autonomous',
      );

      final notes = await db.select(db.incidentNotes).get();
      expect(notes.length, 1);
      final note = notes.first;
      expect(note.teamNumber, '1114A');
      expect(note.matchId, 'Q5');
      expect(jsonDecode(note.ruleCodesJson), ['G12', 'SG3']);
      expect(note.severity, 'warning');
      expect(note.notes, 'Contact during autonomous');
      expect(note.isDeleted, false);
      expect(note.isSynced, false);

      // After soft deleting this newly added note
      await controller.deleteNote(note.id);

      final updatedNotes = await db.select(db.incidentNotes).get();
      expect(updatedNotes.length, 1);
      expect(updatedNotes.first.isDeleted, true);
    });

    test('triggerSync resets sync state gracefully when event is not shared online', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const noteId = 'unshared-event-note';
      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const Value(noteId),
          sku: const Value('RE-V5RC-24-1234'),
          teamNumber: const Value('1114A'),
          ruleCodesJson: Value(jsonEncode([])),
          severity: const Value('general'),
          notes: const Value('Note for unshared event'),
          refereeName: const Value('Ref Alice'),
          deviceId: const Value('device-test-123'),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          isDeleted: const Value(false),
          isSynced: const Value(false),
        ),
      );

      final controller = container.read(incidentControllerProvider.notifier);
      await controller.deleteNote(noteId);

      final syncSettings = container.read(syncSettingsProvider);
      expect(syncSettings.isSyncing, isFalse);

      final unsynced = await db.getUnsyncedNotes();
      expect(unsynced.length, 1);
      expect(unsynced.first.isDeleted, isTrue);
    });
  });

  group('IncidentController - updateNote & Multi-User Sync', () {
    test('updateNote overwrites existing note fields, increments updatedAt, and marks note unsynced', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const noteId = 'note-to-edit-1';
      const sku = 'RE-V5RC-24-1234';
      final initialTime = DateTime.now().millisecondsSinceEpoch;

      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const Value(noteId),
          sku: const Value(sku),
          teamNumber: const Value('1234A'),
          matchId: const Value('Q1'),
          ruleCodesJson: Value(jsonEncode(['<SG1>'])),
          severity: const Value('minor'),
          notes: const Value('Original note text'),
          refereeName: const Value('Ref Alice'),
          deviceId: const Value('device-test-123'),
          createdAt: Value(initialTime),
          updatedAt: Value(initialTime),
          isDeleted: const Value(false),
          version: const Value(1),
          isSynced: const Value(true),
        ),
      );

      final controller = container.read(incidentControllerProvider.notifier);
      await controller.updateNote(
        id: noteId,
        teamNumber: ' 2056b ',
        matchId: ' q12 ',
        ruleCodes: ['<SG1>', '<GG2>'],
        severity: 'major',
        notes: ' Updated note text after review ',
      );

      final allNotes = await db.select(db.incidentNotes).get();
      expect(allNotes.length, 1, reason: 'Editing a note must overwrite in place, not create a new note');

      final edited = allNotes.first;
      expect(edited.id, noteId);
      expect(edited.sku, sku);
      expect(edited.teamNumber, '2056B');
      expect(edited.matchId, 'Q12');
      expect(jsonDecode(edited.ruleCodesJson), ['<SG1>', '<GG2>']);
      expect(edited.severity, 'major');
      expect(edited.notes, 'Updated note text after review');
      expect(edited.createdAt, initialTime);
      expect(edited.updatedAt, greaterThan(initialTime), reason: 'updatedAt must be strictly greater than previous updatedAt');
      expect(edited.isDeleted, isFalse);
      expect(edited.isSynced, isFalse, reason: 'isSynced must be reset to false so changes push to server');
    });

    test('updateNote can clear optional matchId to null when match is emptied', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      const noteId = 'note-clear-match';
      const sku = 'RE-V5RC-24-1234';
      final initialTime = DateTime.now().millisecondsSinceEpoch - 5000;

      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const Value(noteId),
          sku: const Value(sku),
          teamNumber: const Value('1114A'),
          matchId: const Value('Q4'),
          ruleCodesJson: Value(jsonEncode([])),
          severity: const Value('general'),
          notes: const Value('Had a match initially'),
          refereeName: const Value('Ref Alice'),
          deviceId: const Value('device-test-123'),
          createdAt: Value(initialTime),
          updatedAt: Value(initialTime),
          isDeleted: const Value(false),
          version: const Value(1),
          isSynced: const Value(true),
        ),
      );

      final controller = container.read(incidentControllerProvider.notifier);
      await controller.updateNote(
        id: noteId,
        teamNumber: '1114A',
        matchId: null,
        ruleCodes: [],
        severity: 'inspection',
        notes: 'Converted to general inspection note',
      );

      final edited = await (db.select(db.incidentNotes)..where((t) => t.id.equals(noteId))).getSingle();
      expect(edited.matchId, isNull);
      expect(edited.severity, 'inspection');
      expect(edited.notes, 'Converted to general inspection note');
    });

    test('calling updateNote on non-existent ID completes safely without errors', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final controller = container.read(incidentControllerProvider.notifier);
      await expectLater(
        controller.updateNote(
          id: 'does-not-exist',
          teamNumber: '1234A',
          ruleCodes: [],
          severity: 'general',
          notes: 'Should not insert',
        ),
        completes,
      );

      final allNotes = await db.select(db.incidentNotes).get();
      expect(allNotes, isEmpty);
    });

    test('edited note syncs and overwrites the note for all connected users', () async {
      const sku = 'RE-V5RC-24-1234';

      // In-memory mock server state matching CloudflareD1Adapter / LocalSqliteAdapter behavior
      final Map<String, Map<String, dynamic>> serverNotesById = {};
      int serverVersionCounter = 0;

      final mockSyncClient = MockClient((request) async {
        if (request.url.path == '/api/sync/push' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final changes = (body['changes'] as List).cast<Map<String, dynamic>>();
          for (final change in changes) {
            final id = change['id'] as String;
            final incomingUpdatedAt = change['updatedAt'] as int;
            final existing = serverNotesById[id];
            serverVersionCounter += 1;
            if (existing == null || incomingUpdatedAt > (existing['updatedAt'] as int)) {
              serverNotesById[id] = {
                ...change,
                'version': serverVersionCounter,
              };
            }
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'sku': body['sku'],
              'latestVersion': serverVersionCounter,
              'appliedCount': changes.length,
            }),
            200,
          );
        } else if (request.url.path == '/api/sync/pull' && request.method == 'GET') {
          final reqSku = request.url.queryParameters['sku'] ?? '';
          final since = int.tryParse(request.url.queryParameters['since'] ?? '0') ?? 0;
          final matching = serverNotesById.values
              .where((n) => n['sku'] == reqSku && (n['version'] as int) > since)
              .toList()
            ..sort((a, b) => (a['version'] as int).compareTo(b['version'] as int));
          final latestVer = matching.fold<int>(
            since,
            (maxV, n) => (n['version'] as int) > maxV ? (n['version'] as int) : maxV,
          );
          return http.Response(
            jsonEncode({
              'sku': reqSku,
              'latestVersion': latestVer,
              'changes': matching,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      // Setup Device B (Connected Referee Bob)
      final dbB = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
      addTearDown(dbB.close);

      // Mark event as shared on both Device A (db) and Device B (dbB)
      await db.updateEventShareState(sku, isShared: true, shareId: 'ABC123', shareRole: 'admin');
      await dbB.updateEventShareState(sku, isShared: true, shareId: 'ABC123', shareRole: 'member');

      final containerA = createContainer(customDb: db, syncHttpClient: mockSyncClient);
      final containerB = createContainer(customDb: dbB, syncHttpClient: mockSyncClient);
      addTearDown(containerA.dispose);
      addTearDown(containerB.dispose);

      final controllerA = containerA.read(incidentControllerProvider.notifier);
      final controllerB = containerB.read(incidentControllerProvider.notifier);

      // 1. User A adds a note and syncs
      await controllerA.addNote(
        teamNumber: '1114A',
        matchId: 'Q1',
        ruleCodes: ['<SG1>'],
        severity: 'minor',
        notes: 'Initial note from User A',
      );
      await controllerA.triggerSync();

      // 2. User B syncs and receives the note
      await controllerB.triggerSync();
      final notesOnBInitial = await dbB.watchNotesForSku(sku).first;
      expect(notesOnBInitial.length, 1);
      final noteId = notesOnBInitial.first.id;
      expect(notesOnBInitial.first.teamNumber, '1114A');
      expect(notesOnBInitial.first.matchId, 'Q1');
      expect(notesOnBInitial.first.severity, 'minor');
      expect(notesOnBInitial.first.notes, 'Initial note from User A');

      // 3. User A edits the note and saves
      await controllerA.updateNote(
        id: noteId,
        teamNumber: '2056A',
        matchId: 'Q2',
        ruleCodes: ['<SG1>', '<GG2>'],
        severity: 'major',
        notes: 'Edited note synced to all users',
      );
      await controllerA.triggerSync();

      // 4. User B syncs and verifies the existing note was overwritten
      await controllerB.triggerSync();
      final notesOnBAfterEdit = await dbB.watchNotesForSku(sku).first;
      expect(notesOnBAfterEdit.length, 1, reason: 'Connected user should have the single overwritten note');
      expect(notesOnBAfterEdit.first.id, noteId);
      expect(notesOnBAfterEdit.first.teamNumber, '2056A');
      expect(notesOnBAfterEdit.first.matchId, 'Q2');
      expect(jsonDecode(notesOnBAfterEdit.first.ruleCodesJson), ['<SG1>', '<GG2>']);
      expect(notesOnBAfterEdit.first.severity, 'major');
      expect(notesOnBAfterEdit.first.notes, 'Edited note synced to all users');
    });
  });
}
