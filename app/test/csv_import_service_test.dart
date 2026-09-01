import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull;
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

  group('CsvImportService - importTeamsCsv', () {
    test('returns error when SKU is empty or whitespace', () async {
      final resultEmpty = await CsvImportService.importTeamsCsv(
        csvContent: 'Number,Name\n1234A,Alpha',
        sku: '',
        db: db,
      );
      expect(resultEmpty.success, false);
      expect(resultEmpty.errorMessage, 'SKU cannot be empty');

      final resultWhitespace = await CsvImportService.importTeamsCsv(
        csvContent: 'Number,Name\n1234A,Alpha',
        sku: '   ',
        db: db,
      );
      expect(resultWhitespace.success, false);
      expect(resultWhitespace.errorMessage, 'SKU cannot be empty');
    });

    test('returns error when CSV content is empty or whitespace', () async {
      final result = await CsvImportService.importTeamsCsv(
        csvContent: '   \n  \n ',
        sku: 'RE-V5RC-24-1234',
        db: db,
      );
      expect(result.success, false);
      expect(result.errorMessage, 'CSV is empty');
    });

    test('imports teams from standard comma-separated CSV with all headers', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
Number,Name,Organization,City,State,Country
1111A,Alpha Bot,Robotics Club,Austin,TX,USA
2222B,Beta Bot,High School,London,ON,Canada
''';

      final result = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.teamsImported, 2);
      expect(result.errorMessage, isNull);

      final teams = await db.getTeamsForSku(sku);
      expect(teams.length, 2);
      expect(teams[0].teamNumber, '1111A');
      expect(teams[0].teamName, 'Alpha Bot');
      expect(teams[0].organization, 'Robotics Club');
      expect(teams[0].city, 'Austin');
      expect(teams[0].region, 'TX');
      expect(teams[0].country, 'USA');

      expect(teams[1].teamNumber, '2222B');
      expect(teams[1].teamName, 'Beta Bot');
      expect(teams[1].organization, 'High School');
      expect(teams[1].city, 'London');
      expect(teams[1].region, 'ON');
      expect(teams[1].country, 'Canada');
    });

    test('imports teams with alternative header names (Team, Team Name, Affiliation, Prov)', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
Team,Team Name,Affiliation,City,Prov,Country
9999Z,Zeta Bot,Tech Academy,Seattle,WA,USA
''';

      final result = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.teamsImported, 1);

      final teams = await db.getTeamsForSku(sku);
      expect(teams.first.teamNumber, '9999Z');
      expect(teams.first.teamName, 'Zeta Bot');
      expect(teams.first.organization, 'Tech Academy');
      expect(teams.first.region, 'WA');
    });

    test('imports tab-separated CSV content', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = "Number\tName\tCity\n5555E\tEcho Bot\tDallas";

      final result = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.teamsImported, 1);

      final teams = await db.getTeamsForSku(sku);
      expect(teams.first.teamNumber, '5555E');
      expect(teams.first.teamName, 'Echo Bot');
      expect(teams.first.city, 'Dallas');
    });

    test('handles quoted values with quotes and spaces', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
"Number","Name","Organization"
"7777G",""Special" Quoting","Academy, Inc."
''';

      final result = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.teamsImported, 1);

      final teams = await db.getTeamsForSku(sku);
      expect(teams.first.teamNumber, '7777G');
      expect(teams.first.teamName, 'Special Quoting');
      expect(teams.first.organization, 'Academy, Inc.');
    });

    test('fallback logic when team number header is missing (column 0 = number, column 1 = name)', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
CustomHeader1,CustomHeader2
8888H,Helix Bot
''';

      final result = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.teamsImported, 1);

      final teams = await db.getTeamsForSku(sku);
      expect(teams.first.teamNumber, '8888H');
      expect(teams.first.teamName, 'Helix Bot');
    });

    test('skips empty rows or rows with empty team numbers', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
Number,Name
1111A,Alpha Bot

,No Number Bot
3333C,Gamma Bot
''';

      final result = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.teamsImported, 2);

      final teams = await db.getTeamsForSku(sku);
      expect(teams.map((t) => t.teamNumber).toList(), ['1111A', '3333C']);
    });

    test('defaults team name to "Team <Number>" when name column is missing or absent', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
Number
4444D
''';

      final result = await CsvImportService.importTeamsCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.teamsImported, 1);

      final teams = await db.getTeamsForSku(sku);
      expect(teams.first.teamNumber, '4444D');
      expect(teams.first.teamName, 'Team 4444D');
    });
  });

  group('CsvImportService - importMatchesCsv', () {
    test('returns error when SKU is empty or whitespace', () async {
      final resultEmpty = await CsvImportService.importMatchesCsv(
        csvContent: 'Match,Red 1,Blue 1\nQ1,1111A,2222B',
        sku: '',
        db: db,
      );
      expect(resultEmpty.success, false);
      expect(resultEmpty.errorMessage, 'SKU cannot be empty');
    });

    test('returns error when CSV content is empty', () async {
      final result = await CsvImportService.importMatchesCsv(
        csvContent: '',
        sku: 'RE-V5RC-24-1234',
        db: db,
      );
      expect(result.success, false);
      expect(result.errorMessage, 'CSV is empty');
    });

    test('imports V5RC matches with Red 1, Red 2, Blue 1, Blue 2', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
Match,Field,Time,Red 1,Red 2,Blue 1,Blue 2
Q1,Field 1,09:00 AM,1111A,2222B,3333C,4444D
Q2,Field 2,09:10 AM,5555E,6666F,7777G,8888H
''';

      final result = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.matchesImported, 2);
      expect(result.errorMessage, isNull);

      final matches = await db.getMatchesForSku(sku);
      expect(matches.length, 2);
      expect(matches[0].name, 'Qualification 1');
      expect(matches[0].field, 'Field 1');
      expect(matches[0].scheduledTime, '09:00 AM');
      expect(jsonDecode(matches[0].redTeamsJson), ['1111A', '2222B']);
      expect(jsonDecode(matches[0].blueTeamsJson), ['3333C', '4444D']);

      expect(matches[1].name, 'Qualification 2');
      expect(matches[1].field, 'Field 2');
      expect(matches[1].scheduledTime, '09:10 AM');
      expect(jsonDecode(matches[1].redTeamsJson), ['5555E', '6666F']);
      expect(jsonDecode(matches[1].blueTeamsJson), ['7777G', '8888H']);
    });

    test('imports VEX IQ match schedule CSV (Team 1, Team 2 / Alliance format)', () async {
      const sku = 'RE-VIQRC-24-1234';
      const csv = '''
Match,Field,Time,Team 1,Team 2
Q1,Main Field,10:00 AM,1001A,1002B
''';

      final result = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.matchesImported, 1);

      final matches = await db.getMatchesForSku(sku);
      expect(matches.first.name, 'Qualification 1');
      expect(matches.first.field, 'Main Field');
      expect(matches.first.scheduledTime, '10:00 AM');
      expect(jsonDecode(matches.first.redTeamsJson), ['1001A', '1002B']);
      expect(jsonDecode(matches.first.blueTeamsJson), isEmpty);
    });

    test('imports tab-delimited matches CSV', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = "Match\tField\tSched Time\tRed1\tRed2\tBlue1\tBlue2\nQ1\tField A\t08:00 AM\t100A\t100B\t200A\t200B";

      final result = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.matchesImported, 1);

      final matches = await db.getMatchesForSku(sku);
      expect(matches.first.name, 'Qualification 1');
      expect(matches.first.field, 'Field A');
      expect(matches.first.scheduledTime, '08:00 AM');
      expect(jsonDecode(matches.first.redTeamsJson), ['100A', '100B']);
      expect(jsonDecode(matches.first.blueTeamsJson), ['200A', '200B']);
    });

    test('skips empty match names or empty lines in match CSV', () async {
      const sku = 'RE-V5RC-24-1234';
      const csv = '''
Match,Red 1,Blue 1
Q1,1111A,2222B

,3333C,4444D
Q2,5555E,6666F
''';

      final result = await CsvImportService.importMatchesCsv(
        csvContent: csv,
        sku: sku,
        db: db,
      );

      expect(result.success, true);
      expect(result.matchesImported, 2);

      final matches = await db.getMatchesForSku(sku);
      expect(matches.map((m) => m.name).toList(), ['Qualification 1', 'Qualification 2']);
    });
  });
}
