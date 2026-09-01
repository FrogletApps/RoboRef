import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_data/services/csv_import_service.dart';

class ThrowingDatabase extends AppDatabase {
  ThrowingDatabase() : super.forTesting(DatabaseConnection(NativeDatabase.memory()));

  @override
  Future<void> upsertTeams(List<TeamsCompanion> entries) {
    throw Exception('Database write failed for teams');
  }

  @override
  Future<void> upsertMatches(List<MatchesCompanion> entries) {
    throw Exception('Database write failed for matches');
  }
}

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

  group('CsvImportService - importTeamsCsv', () {
    test('returns failure if SKU is empty or whitespace', () async {
      final res1 = await CsvImportService.importTeamsCsv(
        csvContent: 'Number,Name\n1234A,Alpha',
        sku: '',
        db: db,
      );
      expect(res1.success, false);
      expect(res1.errorMessage, 'SKU cannot be empty');

      final res2 = await CsvImportService.importTeamsCsv(
        csvContent: 'Number,Name\n1234A,Alpha',
        sku: '   ',
        db: db,
      );
      expect(res2.success, false);
      expect(res2.errorMessage, 'SKU cannot be empty');
    });

    test('returns failure if CSV content is empty or whitespace', () async {
      final res1 = await CsvImportService.importTeamsCsv(
        csvContent: '',
        sku: 'SKU123',
        db: db,
      );
      expect(res1.success, false);
      expect(res1.errorMessage, 'CSV is empty');

      final res2 = await CsvImportService.importTeamsCsv(
        csvContent: '   \n  \n',
        sku: 'SKU123',
        db: db,
      );
      expect(res2.success, false);
      expect(res2.errorMessage, 'CSV is empty');
    });

    test('parses standard comma-separated teams CSV with all columns', () async {
      const csv = '''
Number,Name,Organization,City,State,Country
1234A,Robo Team,Robo Org,Austin,TX,USA
5678B,Tech Titans,Tech High,Dallas,TX,USA
''';
      final res = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: 'sku123',
        db: db,
      );

      expect(res.success, true);
      expect(res.teamsImported, 2);

      final teams = await db.watchTeamsForSku('SKU123').first;
      expect(teams.length, 2);

      final t1 = teams.firstWhere((t) => t.teamNumber == '1234A');
      expect(t1.teamName, 'Robo Team');
      expect(t1.organization, 'Robo Org');
      expect(t1.city, 'Austin');
      expect(t1.region, 'TX');
      expect(t1.country, 'USA');
      expect(t1.sku, 'SKU123');
    });

    test('parses tab-separated values (TSV) and header alias variations', () async {
      const tsv = 'Team\tTeam Name\tAffiliation\tCity\tProv\tCountry\n'
          '9999X\tX-Ray\tSchool A\tToronto\tON\tCanada';

      final res = await CsvImportService.importTeamsCsv(
        csvContent: tsv,
        sku: 'SKU_TSV',
        db: db,
      );

      expect(res.success, true);
      expect(res.teamsImported, 1);

      final teams = await db.watchTeamsForSku('SKU_TSV').first;
      expect(teams.length, 1);
      expect(teams[0].teamNumber, '9999X');
      expect(teams[0].teamName, 'X-Ray');
      expect(teams[0].organization, 'School A');
      expect(teams[0].city, 'Toronto');
      expect(teams[0].region, 'ON');
      expect(teams[0].country, 'Canada');
    });

    test('handles fallback when no header contains number or team keyword', () async {
      // Header without 'number' or 'team'
      const csv = '''
Col0,Col1,Col2
1111A,Alpha Bot,Some Org
2222B,Beta Bot,Other Org
''';

      final res = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: 'FALLBACK_SKU',
        db: db,
      );

      expect(res.success, true);
      expect(res.teamsImported, 2);

      final teams = await db.watchTeamsForSku('FALLBACK_SKU').first;
      expect(teams.length, 2);
      expect(teams[0].teamNumber, '1111A');
      expect(teams[0].teamName, 'Alpha Bot');
    });

    test('handles fallback team name when column is missing or default name', () async {
      const csv = 'Number\n1234A\n5678B';

      final res = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: 'NO_NAME_SKU',
        db: db,
      );

      expect(res.success, true);
      expect(res.teamsImported, 2);

      final teams = await db.watchTeamsForSku('NO_NAME_SKU').first;
      expect(teams[0].teamName, 'Team 1234A');
      expect(teams[1].teamName, 'Team 5678B');
    });

    test('handles quoted strings and escaped double quotes in CSV row', () async {
      const csv = 'Number,Name,Org\n'
          '1000A,"Robo ""Super"" Squad","School, High"';

      final res = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: 'QUOTED_SKU',
        db: db,
      );

      expect(res.success, true);
      expect(res.teamsImported, 1);

      final teams = await db.watchTeamsForSku('QUOTED_SKU').first;
      expect(teams[0].teamNumber, '1000A');
      expect(teams[0].teamName, 'Robo Super Squad');
      expect(teams[0].organization, 'School, High');
    });

    test('skips empty rows, rows missing team numbers, or rows with insufficient columns', () async {
      const csv = '''
Number,Name
1001A,Valid Team

,Empty Number
2002B
''';

      final res = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: 'SKIP_TEST',
        db: db,
      );

      expect(res.success, true);
      expect(res.teamsImported, 2);

      final teams = await db.watchTeamsForSku('SKIP_TEST').first;
      expect(teams.length, 2);
      expect(teams.map((t) => t.teamNumber), containsAll(['1001A', '2002B']));
    });

    test('returns 0 teams imported when header exists but no valid team rows', () async {
      const csv = 'Number,Name\n\n   \n';

      final res = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: 'EMPTY_ROWS',
        db: db,
      );

      expect(res.success, true);
      expect(res.teamsImported, 0);
    });
  });

  group('CsvImportService - importMatchesCsv', () {
    test('returns failure if SKU is empty or whitespace', () async {
      final res = await CsvImportService.importMatchesCsv(
        csvContent: 'Match,Red 1,Blue 1\nQ1,1111A,2222B',
        sku: '   ',
        db: db,
      );
      expect(res.success, false);
      expect(res.errorMessage, 'SKU cannot be empty');
    });

    test('returns failure if CSV content is empty or whitespace', () async {
      final res = await CsvImportService.importMatchesCsv(
        csvContent: '   ',
        sku: 'SKU123',
        db: db,
      );
      expect(res.success, false);
      expect(res.errorMessage, 'CSV is empty');
    });

    test('parses standard comma-separated matches CSV with all fields', () async {
      const csv = '''
Match,Field,Scheduled Time,Red 1,Red 2,Blue 1,Blue 2
Q1,Field 1,09:00 AM,1111A,2222B,3333C,4444D
Q2,Field 2,09:15 AM,5555E,,6666F,
''';

      final res = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: 'MATCH_SKU',
        db: db,
      );

      expect(res.success, true);
      expect(res.matchesImported, 2);

      final matches = await db.watchMatchesForSku('MATCH_SKU').first;
      expect(matches.length, 2);

      final q1 = matches.firstWhere((m) => m.matchId == 'Q1');
      expect(q1.field, 'Field 1');
      expect(q1.scheduledTime, '09:00 AM');
      expect(jsonDecode(q1.redTeamsJson), ['1111A', '2222B']);
      expect(jsonDecode(q1.blueTeamsJson), ['3333C', '4444D']);

      final q2 = matches.firstWhere((m) => m.matchId == 'Q2');
      expect(q2.field, 'Field 2');
      expect(q2.scheduledTime, '09:15 AM');
      expect(jsonDecode(q2.redTeamsJson), ['5555E']);
      expect(jsonDecode(q2.blueTeamsJson), ['6666F']);
    });

    test('parses tab-separated matches CSV with alternative header names (red1, sched, etc)', () async {
      const tsv = 'Match\tField\tSched\tRed1\tRed2\tBlue1\tBlue2\n'
          'P1\tMain\t10:00 AM\t1010A\t2020B\t3030C\t4040D';

      final res = await CsvImportService.importMatchesCsv(
        csvContent: tsv,
        sku: 'MATCH_TSV',
        db: db,
      );

      expect(res.success, true);
      expect(res.matchesImported, 1);

      final matches = await db.watchMatchesForSku('MATCH_TSV').first;
      expect(matches[0].name, 'P1');
      expect(matches[0].scheduledTime, '10:00 AM');
      expect(jsonDecode(matches[0].redTeamsJson), ['1010A', '2020B']);
      expect(jsonDecode(matches[0].blueTeamsJson), ['3030C', '4040D']);
    });

    test('handles fallback when header does not contain "match"', () async {
      const csv = '''
Col0,Col1,Col2
Q1,Field 1,09:00 AM
Q2,Field 2,09:10 AM
''';

      final res = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: 'FALLBACK_MATCH_SKU',
        db: db,
      );

      expect(res.success, true);
      expect(res.matchesImported, 2);

      final matches = await db.watchMatchesForSku('FALLBACK_MATCH_SKU').first;
      expect(matches[0].matchId, 'Q1');
      expect(matches[1].matchId, 'Q2');
    });

    test('skips empty rows, blank match names, or rows with insufficient columns', () async {
      const csv = '''
Match,Red 1,Blue 1
Q1,1111A,2222B

,3333C,4444D
Q2,5555E,6666F
''';

      final res = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: 'SKIP_MATCHES',
        db: db,
      );

      expect(res.success, true);
      expect(res.matchesImported, 2);

      final matches = await db.watchMatchesForSku('SKIP_MATCHES').first;
      expect(matches.map((m) => m.matchId), containsAll(['Q1', 'Q2']));
    });

    test('returns 0 matches imported when header exists but no valid match rows', () async {
      const csv = 'Match,Red 1,Blue 1\n\n   \n';

      final res = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: 'EMPTY_MATCH_ROWS',
        db: db,
      );

      expect(res.success, true);
      expect(res.matchesImported, 0);
    });
  });

  group('CsvImportService - Error Handling & Edge Cases', () {
    test('handles exceptions during import gracefully', () async {
      final throwingDb = ThrowingDatabase();

      const teamsCsv = 'Number,Name\n1234A,Alpha';
      final teamRes = await CsvImportService.importTeamsCsv(
        csvContent: teamsCsv,
        sku: 'SKU_ERR',
        db: throwingDb,
      );

      expect(teamRes.success, false);
      expect(teamRes.errorMessage, contains('Failed to parse Teams CSV'));

      const matchesCsv = 'Match,Red 1\nQ1,1234A';
      final matchRes = await CsvImportService.importMatchesCsv(
        csvContent: matchesCsv,
        sku: 'SKU_ERR',
        db: throwingDb,
      );

      expect(matchRes.success, false);
      expect(matchRes.errorMessage, contains('Failed to parse Matches CSV'));

      await throwingDb.close();
    });
  });
}
