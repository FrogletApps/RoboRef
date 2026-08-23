import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';

class CsvImportResult {
  final bool success;
  final int teamsImported;
  final int matchesImported;
  final String? errorMessage;

  CsvImportResult({
    required this.success,
    this.teamsImported = 0,
    this.matchesImported = 0,
    this.errorMessage,
  });
}

class CsvImportService {
  /// Import Tournament Manager Teams CSV into local SQLite database
  static Future<CsvImportResult> importTeamsCsv({
    required String csvContent,
    required String sku,
    required AppDatabase db,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    if (cleanSku.isEmpty) {
      return CsvImportResult(success: false, errorMessage: 'SKU cannot be empty');
    }

    try {
      final lines = const LineSplitter().convert(csvContent.trim());
      if (lines.isEmpty) {
        return CsvImportResult(success: false, errorMessage: 'CSV is empty');
      }

      // Parse headers
      final headerLine = lines.first;
      final delimiter = headerLine.contains('\t') ? '\t' : ',';
      final headers = _parseCsvRow(headerLine, delimiter).map((h) => h.toLowerCase().trim()).toList();

      int numberIdx = headers.indexWhere((h) => h.contains('number') || h == 'team');
      int nameIdx = headers.indexWhere((h) => h.contains('name') || h == 'team name');
      int orgIdx = headers.indexWhere((h) => h.contains('org') || h.contains('affiliation') || h.contains('school'));
      int cityIdx = headers.indexWhere((h) => h.contains('city'));
      int regionIdx = headers.indexWhere((h) => h.contains('state') || h.contains('region') || h.contains('prov'));
      int countryIdx = headers.indexWhere((h) => h.contains('country'));

      if (numberIdx == -1) {
        // Fallback: assume column 0 is team number, column 1 is team name
        numberIdx = 0;
        nameIdx = headers.length > 1 ? 1 : -1;
      }

      final List<TeamsCompanion> teamCompanions = [];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cols = _parseCsvRow(line, delimiter);
        if (cols.length <= numberIdx) continue;

        final teamNumber = cols[numberIdx].trim().toUpperCase();
        if (teamNumber.isEmpty) continue;

        final teamName = (nameIdx != -1 && cols.length > nameIdx) ? cols[nameIdx].trim() : 'Team $teamNumber';
        final org = (orgIdx != -1 && cols.length > orgIdx) ? cols[orgIdx].trim() : null;
        final city = (cityIdx != -1 && cols.length > cityIdx) ? cols[cityIdx].trim() : null;
        final region = (regionIdx != -1 && cols.length > regionIdx) ? cols[regionIdx].trim() : null;
        final country = (countryIdx != -1 && cols.length > countryIdx) ? cols[countryIdx].trim() : null;

        teamCompanions.add(
          TeamsCompanion(
            teamNumber: Value(teamNumber),
            teamName: Value(teamName),
            sku: Value(cleanSku),
            organization: Value(org),
            city: Value(city),
            region: Value(region),
            country: Value(country),
          ),
        );
      }

      if (teamCompanions.isNotEmpty) {
        await db.upsertTeams(teamCompanions);
      }

      return CsvImportResult(
        success: true,
        teamsImported: teamCompanions.length,
      );
    } catch (e) {
      return CsvImportResult(
        success: false,
        errorMessage: 'Failed to parse Teams CSV: ${e.toString()}',
      );
    }
  }

  /// Import Tournament Manager Match Schedule CSV into local SQLite database
  static Future<CsvImportResult> importMatchesCsv({
    required String csvContent,
    required String sku,
    required AppDatabase db,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    if (cleanSku.isEmpty) {
      return CsvImportResult(success: false, errorMessage: 'SKU cannot be empty');
    }

    try {
      final lines = const LineSplitter().convert(csvContent.trim());
      if (lines.isEmpty) {
        return CsvImportResult(success: false, errorMessage: 'CSV is empty');
      }

      final headerLine = lines.first;
      final delimiter = headerLine.contains('\t') ? '\t' : ',';
      final headers = _parseCsvRow(headerLine, delimiter).map((h) => h.toLowerCase().trim()).toList();

      int matchIdx = headers.indexWhere((h) => h.contains('match'));
      int fieldIdx = headers.indexWhere((h) => h.contains('field'));
      int timeIdx = headers.indexWhere((h) => h.contains('time') || h.contains('sched'));
      int r1Idx = headers.indexWhere((h) => h.contains('red 1') || h.contains('red1'));
      int r2Idx = headers.indexWhere((h) => h.contains('red 2') || h.contains('red2'));
      int b1Idx = headers.indexWhere((h) => h.contains('blue 1') || h.contains('blue1'));
      int b2Idx = headers.indexWhere((h) => h.contains('blue 2') || h.contains('blue2'));

      if (matchIdx == -1) {
        matchIdx = 0;
      }

      final List<MatchesCompanion> matchCompanions = [];

      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cols = _parseCsvRow(line, delimiter);
        if (cols.length <= matchIdx) continue;

        final matchName = cols[matchIdx].trim().toUpperCase();
        if (matchName.isEmpty) continue;

        final field = (fieldIdx != -1 && cols.length > fieldIdx) ? cols[fieldIdx].trim() : null;
        final time = (timeIdx != -1 && cols.length > timeIdx) ? cols[timeIdx].trim() : null;

        final List<String> redTeams = [];
        if (r1Idx != -1 && cols.length > r1Idx && cols[r1Idx].trim().isNotEmpty) {
          redTeams.add(cols[r1Idx].trim().toUpperCase());
        }
        if (r2Idx != -1 && cols.length > r2Idx && cols[r2Idx].trim().isNotEmpty) {
          redTeams.add(cols[r2Idx].trim().toUpperCase());
        }

        final List<String> blueTeams = [];
        if (b1Idx != -1 && cols.length > b1Idx && cols[b1Idx].trim().isNotEmpty) {
          blueTeams.add(cols[b1Idx].trim().toUpperCase());
        }
        if (b2Idx != -1 && cols.length > b2Idx && cols[b2Idx].trim().isNotEmpty) {
          blueTeams.add(cols[b2Idx].trim().toUpperCase());
        }

        matchCompanions.add(
          MatchesCompanion(
            matchId: Value(matchName),
            sku: Value(cleanSku),
            divisionId: const Value(1),
            name: Value(matchName),
            field: Value(field),
            scheduledTime: Value(time),
            redTeamsJson: Value(jsonEncode(redTeams)),
            blueTeamsJson: Value(jsonEncode(blueTeams)),
          ),
        );
      }

      if (matchCompanions.isNotEmpty) {
        await db.upsertMatches(matchCompanions);
      }

      return CsvImportResult(
        success: true,
        matchesImported: matchCompanions.length,
      );
    } catch (e) {
      return CsvImportResult(
        success: false,
        errorMessage: 'Failed to parse Matches CSV: ${e.toString()}',
      );
    }
  }

  static List<String> _parseCsvRow(String line, String delimiter) {
    final List<String> result = [];
    bool inQuotes = false;
    final StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(current.toString().trim().replaceAll('"', ''));
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim().replaceAll('"', ''));
    return result;
  }
}
