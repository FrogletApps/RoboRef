import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
        severity: const Value('general'),
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
    expect(notes.first.severity, 'general');
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
    expect(matches[0].name, 'Qualification 1');
    expect(matches[0].field, 'Field 1');
    expect(matches[0].scheduledTime, '09:00 AM');
    expect(jsonDecode(matches[0].redTeamsJson), ['1111A', '2222B']);
    expect(jsonDecode(matches[0].blueTeamsJson), ['3333C', '4444D']);
  });

  test('watchMatchesForSku and getMatchesForSku order matches chronologically (Practice, Q1-Q9, Q10-Q99, Finals)', () async {
    const sku = 'RE-V5RC-24-MATCH-SORT';
    const matchesCsv = '''
Match,Field,Time,Red 1,Red 2,Blue 1,Blue 2
Finals 1-1,Field 1,03:00 PM,1111A,2222B,3333C,4444D
Q10,Field 2,10:30 AM,1111A,2222B,3333C,4444D
Practice 1,Field 1,08:30 AM,1111A,2222B,3333C,4444D
QF 1-1,Field 1,01:30 PM,1111A,2222B,3333C,4444D
Q1,Field 1,09:00 AM,1111A,2222B,3333C,4444D
SF 1-1,Field 1,02:15 PM,1111A,2222B,3333C,4444D
Q2,Field 2,09:10 AM,1111A,2222B,3333C,4444D
Practice 2,Field 2,08:40 AM,1111A,2222B,3333C,4444D
R16 1-1,Field 1,01:00 PM,1111A,2222B,3333C,4444D
''';

    await CsvImportService.importMatchesCsv(
      csvContent: matchesCsv,
      sku: sku,
      db: db,
    );

    final streamMatches = await db.watchMatchesForSku(sku).first;
    expect(streamMatches.map((m) => m.name).toList(), [
      'Practice 1',
      'Practice 2',
      'Qualification 1',
      'Qualification 2',
      'Qualification 10',
      'R16 1-1',
      'QF 1-1',
      'SF 1-1',
      'Finals 1-1',
    ]);

    final getMatches = await db.getMatchesForSku(sku);
    expect(getMatches.map((m) => m.name).toList(), [
      'Practice 1',
      'Practice 2',
      'Qualification 1',
      'Qualification 2',
      'Qualification 10',
      'R16 1-1',
      'QF 1-1',
      'SF 1-1',
      'Finals 1-1',
    ]);
  });

  test('can import VEX IQ match schedule CSV with Team 1 & Team 2 and orders chronologically (Q1..Q10 then Finals 1-1 onwards)', () async {
    const sku = 'RE-VIQRC-24-IQ-SORT';
    const matchesCsv = '''
Match,Field,Time,Team 1,Team 2
Finals 1-5,Field 1,03:20 PM,1001A,1002B
Q10,Field 1,11:00 AM,1003C,1004D
Finals 1-1,Field 1,03:00 PM,1005E,1006F
Q1,Field 1,09:00 AM,1001A,1003C
Finals 1-2,Field 1,03:05 PM,1007G,1008H
Q2,Field 1,09:10 AM,1002B,1004D
''';

    final result = await CsvImportService.importMatchesCsv(
      csvContent: matchesCsv,
      sku: sku,
      db: db,
    );

    expect(result.success, true);
    expect(result.matchesImported, 6);

    final matches = await db.getMatchesForSku(sku);
    expect(matches.map((m) => m.name).toList(), [
      'Qualification 1',
      'Qualification 2',
      'Qualification 10',
      'Finals 1-1',
      'Finals 1-2',
      'Finals 1-5',
    ]);

    expect(jsonDecode(matches.first.redTeamsJson), ['1001A']);
    expect(jsonDecode(matches.first.blueTeamsJson), ['1003C']);
  });

  test('updateAdminRefereeName updates adminRefereeName and updatedAt timestamp', () async {
    const sku = 'RE-V5RC-24-TEST1';
    final initialTime = DateTime.now().millisecondsSinceEpoch - 10000;

    await db.upsertEvent(
      EventsCompanion(
        sku: const Value(sku),
        name: const Value('Test Tournament 1'),
        program: const Value('V5RC'),
        season: const Value('2024-2025'),
        startDate: const Value('2024-11-01'),
        endDate: const Value('2024-11-02'),
        updatedAt: Value(initialTime),
      ),
    );

    var event = await db.getEventBySku(sku);
    expect(event, isNotNull);
    expect(event!.adminRefereeName, isNull);
    expect(event.updatedAt, initialTime);

    // Call updateAdminRefereeName
    await db.updateAdminRefereeName(sku, 'Head Ref Alice');

    event = await db.getEventBySku(sku);
    expect(event, isNotNull);
    expect(event!.adminRefereeName, 'Head Ref Alice');
    expect(event.updatedAt, greaterThanOrEqualTo(initialTime + 10000));

    // Overwrite with a new name
    await db.updateAdminRefereeName(sku, 'Head Ref Bob');

    event = await db.getEventBySku(sku);
    expect(event, isNotNull);
    expect(event!.adminRefereeName, 'Head Ref Bob');
  });

  test('updateAdminRefereeName does nothing and does not throw for non-existent SKU', () async {
    const sku = 'RE-V5RC-24-EXISTING';
    const nonExistentSku = 'RE-V5RC-24-NONEXISTENT';

    await db.upsertEvent(
      EventsCompanion(
        sku: const Value(sku),
        name: const Value('Existing Tournament'),
        program: const Value('V5RC'),
        season: const Value('2024-2025'),
        startDate: const Value('2024-11-01'),
        endDate: const Value('2024-11-02'),
        adminRefereeName: const Value('Original Ref'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Update non-existent SKU
    await db.updateAdminRefereeName(nonExistentSku, 'New Ref');

    // Verify existing event was unchanged
    final existingEvent = await db.getEventBySku(sku);
    expect(existingEvent, isNotNull);
    expect(existingEvent!.adminRefereeName, 'Original Ref');

    // Verify non-existent event is still null
    final nonExistentEvent = await db.getEventBySku(nonExistentSku);
    expect(nonExistentEvent, isNull);
  });

  test('clearTournamentData deletes matches and teams for specified sku, preserving other skus and tables', () async {
    const targetSku = 'RE-V5RC-24-TARGET';
    const otherSku = 'RE-V5RC-24-OTHER';

    // Insert teams and matches for target SKU
    await db.upsertTeams([
      const TeamsCompanion(
        teamNumber: Value('1001A'),
        sku: Value(targetSku),
        teamName: Value('Target Team A'),
      ),
    ]);
    await db.upsertMatches([
      const MatchesCompanion(
        matchId: Value('M1'),
        sku: Value(targetSku),
        divisionId: Value(1),
        name: Value('Qual 1'),
        redTeamsJson: Value('["1001A"]'),
        blueTeamsJson: Value('["1001B"]'),
      ),
    ]);

    // Insert teams and matches for other SKU
    await db.upsertTeams([
      const TeamsCompanion(
        teamNumber: Value('2002B'),
        sku: Value(otherSku),
        teamName: Value('Other Team B'),
      ),
    ]);
    await db.upsertMatches([
      const MatchesCompanion(
        matchId: Value('M2'),
        sku: Value(otherSku),
        divisionId: Value(1),
        name: Value('Qual 2'),
        redTeamsJson: Value('["2002B"]'),
        blueTeamsJson: Value('["2002C"]'),
      ),
    ]);

    // Insert incident note and event for target SKU
    await db.into(db.incidentNotes).insert(
      IncidentNotesCompanion(
        id: const Value('note-target-1'),
        sku: const Value(targetSku),
        teamNumber: const Value('1001A'),
        matchId: const Value('M1'),
        ruleCodesJson: const Value('["G12"]'),
        severity: const Value('warning'),
        notes: const Value('Target note'),
        refereeName: const Value('Ref Bob'),
        deviceId: const Value('device-1'),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await db.upsertEvent(
      EventsCompanion(
        sku: const Value(targetSku),
        name: const Value('Target Event'),
        program: const Value('V5RC'),
        season: const Value('2024-2025'),
        startDate: const Value('2024-11-01'),
        endDate: const Value('2024-11-02'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    // Perform clearTournamentData for targetSku
    await db.clearTournamentData(targetSku);

    // Verify targetSku matches and teams are deleted
    final targetTeams = await db.getTeamsForSku(targetSku);
    final targetMatches = await db.getMatchesForSku(targetSku);
    expect(targetTeams.isEmpty, true);
    expect(targetMatches.isEmpty, true);

    // Verify otherSku matches and teams are intact
    final otherTeams = await db.getTeamsForSku(otherSku);
    final otherMatches = await db.getMatchesForSku(otherSku);
    expect(otherTeams.length, 1);
    expect(otherTeams.first.teamNumber, '2002B');
    expect(otherMatches.length, 1);
    expect(otherMatches.first.matchId, 'M2');

    // Verify incidentNotes and events for targetSku are untouched
    final notes = await db.watchNotesForSku(targetSku).first;
    expect(notes.length, 1);
    expect(notes.first.id, 'note-target-1');

    final event = await db.getEventBySku(targetSku);
    expect(event, isNotNull);
    expect(event!.name, 'Target Event');
  });

  test('clearTournamentData executes cleanly when called on a non-existent or empty sku', () async {
    const nonExistentSku = 'RE-V5RC-24-EMPTY';

    await db.clearTournamentData(nonExistentSku);

    final teams = await db.getTeamsForSku(nonExistentSku);
    final matches = await db.getMatchesForSku(nonExistentSku);
    expect(teams.isEmpty, true);
    expect(matches.isEmpty, true);
  });
}
