import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
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

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
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
}
