import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('can insert, query, and mark notes as synced', () async {
    const noteId = 'test-uuid-1';
    const sku = 'RE-V5RC-24-1234';

    await db.into(db.incidentNotes).insert(
      IncidentNotesCompanion(
        id: const Value(noteId),
        sku: const Value(sku),
        teamNumber: const Value('1234A'),
        matchId: const Value('Q1'),
        ruleCodesJson: Value(jsonEncode(['G12', 'S1'])),
        severity: const Value('warning'),
        notes: const Value('Entanglement near mobile goal'),
        refereeName: const Value('Ref Alice'),
        deviceId: const Value('device-1'),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        isDeleted: const Value(false),
        version: const Value(0),
        isSynced: const Value(false),
      ),
    );

    // Verify unsynced notes query
    final unsynced = await db.getUnsyncedNotes();
    expect(unsynced.length, 1);
    expect(unsynced.first.id, noteId);
    expect(unsynced.first.teamNumber, '1234A');
    expect(unsynced.first.isSynced, false);

    // Mark as synced
    await db.markNotesAsSynced([noteId]);
    final updatedUnsynced = await db.getUnsyncedNotes();
    expect(updatedUnsynced.isEmpty, true);

    // Test stream query
    final notes = await db.watchNotesForSku(sku).first;
    expect(notes.length, 1);
    expect(notes.first.severity, 'warning');
  });
}
