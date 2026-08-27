import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_data/services/csv_import_service.dart';

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

  test('can import Tournament Manager teams CSV and query teams', () async {
    const sku = 'RE-V5RC-24-9999';
    const teamsCsv = '''
Number,Name,City,State,Country
1111A,Alpha Bot,Austin,TX,USA
2222B,Beta Bot,London,,UK
3333C,Gamma Bot,Toronto,ON,Canada
''';

    final result = await CsvImportService.importTeamsCsv(
      csvContent: teamsCsv,
      sku: sku,
      db: db,
    );

    expect(result.success, true);
    expect(result.teamsImported, 3);

    final teams = await db.watchTeamsForSku(sku).first;
    expect(teams.length, 3);
    expect(teams[0].teamNumber, '1111A');
    expect(teams[0].teamName, 'Alpha Bot');
    expect(teams[1].teamNumber, '2222B');
    expect(teams[2].teamNumber, '3333C');
  });

  test('watchTeamsForSku and getTeamsForSku order smaller team numbers first (e.g. 96F before 1016X)', () async {
    const sku = 'RE-V5RC-24-SORT';
    const teamsCsv = '''
Number,Name,City,State,Country
1016X,Ten Sixteen,Toronto,ON,Canada
96F,Ninety Six,Austin,TX,USA
224A,Two Twenty Four,London,,UK
1B,One B,San Jose,CA,USA
''';

    await CsvImportService.importTeamsCsv(
      csvContent: teamsCsv,
      sku: sku,
      db: db,
    );

    final streamTeams = await db.watchTeamsForSku(sku).first;
    expect(streamTeams.map((t) => t.teamNumber).toList(), ['1B', '96F', '224A', '1016X']);

    final getTeams = await db.getTeamsForSku(sku);
    expect(getTeams.map((t) => t.teamNumber).toList(), ['1B', '96F', '224A', '1016X']);
  });

  test('can import Tournament Manager match schedule CSV and query matches', () async {
    const sku = 'RE-V5RC-24-9999';
    const matchesCsv = '''
Match,Field,Time,Red 1,Red 2,Blue 1,Blue 2
Q1,Field 1,09:00 AM,1111A,2222B,3333C,4444D
Q2,Field 2,09:10 AM,5555E,6666F,7777G,8888H
''';

    final result = await CsvImportService.importMatchesCsv(
      csvContent: matchesCsv,
      sku: sku,
      db: db,
    );

    expect(result.success, true);
    expect(result.matchesImported, 2);

    final matches = await db.watchMatchesForSku(sku).first;
    expect(matches.length, 2);
    expect(matches[0].name, 'Q1');
    expect(matches[0].field, 'Field 1');
    expect(matches[0].scheduledTime, '09:00 AM');
    expect(jsonDecode(matches[0].redTeamsJson), ['1111A', '2222B']);
    expect(jsonDecode(matches[0].blueTeamsJson), ['3333C', '4444D']);
  });
}
