import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/core/utils/team_utils.dart';
import 'package:roboref/database/app_database.dart';

void main() {
  group('Team Number Natural Sorting Tests', () {
    test('smaller team numbers are ordered before larger team numbers (e.g. 96F before 1016X)', () {
      expect(compareTeamNumbers('96F', '1016X'), lessThan(0));
      expect(compareTeamNumbers('1016X', '96F'), greaterThan(0));
      expect(compareTeamNumbers('96F', '96F'), equals(0));
    });

    test('orders lists of team numbers numerically then alphabetically', () {
      final input = ['1016X', '96F', '224A', '96A', '10A', '100', '1B', '96', '96B'];
      final expected = ['1B', '10A', '96', '96A', '96B', '96F', '100', '224A', '1016X'];

      final sorted = List<String>.from(input)..sort(compareTeamNumbers);
      expect(sorted, equals(expected));
    });

    test('handles single-digit, multi-digit, and large numbers', () {
      final input = ['1000A', '2A', '10A', '1A', '20A', '100A'];
      final expected = ['1A', '2A', '10A', '20A', '100A', '1000A'];

      final sorted = List<String>.from(input)..sort(compareTeamNumbers);
      expect(sorted, equals(expected));
    });

    test('orders numeric teams before non-numeric teams', () {
      final input = ['BLRS', '1016X', 'AURA', '96F'];
      final expected = ['96F', '1016X', 'AURA', 'BLRS'];

      final sorted = List<String>.from(input)..sort(compareTeamNumbers);
      expect(sorted, equals(expected));
    });

    test('handles case differences and identical prefixes', () {
      expect(compareTeamNumbers('96a', '96B'), lessThan(0));
      expect(compareTeamNumbers('96', '96A'), lessThan(0));
      expect(compareTeamNumbers('96A', '96'), greaterThan(0));
    });

    test('handles null and empty strings gracefully', () {
      expect(compareTeamNumbers('', '96F'), greaterThan(0));
      expect(compareTeamNumbers('96F', ''), lessThan(0));
      expect(compareTeamNumbers(null, '96F'), greaterThan(0));
      expect(compareTeamNumbers('96F', null), lessThan(0));
      expect(compareTeamNumbers(null, null), equals(0));
    });

    test('compareTeams compares Team database records correctly', () {
      const team96 = Team(
        sku: 'RE-V5RC-24-1234',
        teamNumber: '96F',
        teamName: 'Ninety Six',
      );
      const team1016 = Team(
        sku: 'RE-V5RC-24-1234',
        teamNumber: '1016X',
        teamName: 'Ten Sixteen',
      );

      expect(compareTeams(team96, team1016), lessThan(0));
      expect(compareTeams(team1016, team96), greaterThan(0));
    });
  });

  group('Ordinal Suffix Tests', () {
    test('returns correct suffixes for single digits', () {
      expect(getOrdinalSuffix(1), equals('st'));
      expect(getOrdinalSuffix(2), equals('nd'));
      expect(getOrdinalSuffix(3), equals('rd'));
      expect(getOrdinalSuffix(4), equals('th'));
      expect(getOrdinalSuffix(9), equals('th'));
      expect(getOrdinalSuffix(10), equals('th'));
    });

    test('returns th for 11, 12, 13', () {
      expect(getOrdinalSuffix(11), equals('th'));
      expect(getOrdinalSuffix(12), equals('th'));
      expect(getOrdinalSuffix(13), equals('th'));
      expect(getOrdinalSuffix(111), equals('th'));
      expect(getOrdinalSuffix(112), equals('th'));
      expect(getOrdinalSuffix(113), equals('th'));
    });

    test('returns correct suffixes for higher numbers', () {
      expect(getOrdinalSuffix(21), equals('st'));
      expect(getOrdinalSuffix(22), equals('nd'));
      expect(getOrdinalSuffix(23), equals('rd'));
      expect(getOrdinalSuffix(24), equals('th'));
      expect(getOrdinalSuffix(101), equals('st'));
      expect(getOrdinalSuffix(102), equals('nd'));
      expect(getOrdinalSuffix(103), equals('rd'));
      expect(getOrdinalSuffix(104), equals('th'));
    });
  });

  group('Team Search & Normalization Tests', () {
    test('normalizeTeamDisplayName trims custom names and filters fallback or blank names', () {
      expect(normalizeTeamDisplayName('  RoboKnights  ', '1234A'), equals('RoboKnights'));
      expect(normalizeTeamDisplayName('Team 1234A', '1234A'), isNull);
      expect(normalizeTeamDisplayName('', '1234A'), isNull);
      expect(normalizeTeamDisplayName('   ', '1234A'), isNull);
      expect(normalizeTeamDisplayName(null, '1234A'), isNull);
    });

    test('normalizeTeamSchool trims school names and returns null for blank values', () {
      expect(normalizeTeamSchool('  Central High School  '), equals('Central High School'));
      expect(normalizeTeamSchool(''), isNull);
      expect(normalizeTeamSchool('   '), isNull);
      expect(normalizeTeamSchool(null), isNull);
    });

    test('matchesTeamSearch matches team number, team name, and school case-insensitively', () {
      expect(
        matchesTeamSearch(
          query: '',
          teamNumber: '96F',
          teamName: 'Ninety Six',
          school: 'Oak Ridge High',
        ),
        isTrue,
      );
      expect(
        matchesTeamSearch(
          query: '96f',
          teamNumber: '96F',
          teamName: 'Ninety Six',
          school: 'Oak Ridge High',
        ),
        isTrue,
      );
      expect(
        matchesTeamSearch(
          query: 'ninety',
          teamNumber: '96F',
          teamName: 'Ninety Six',
          school: 'Oak Ridge High',
        ),
        isTrue,
      );
      expect(
        matchesTeamSearch(
          query: 'oak ridge',
          teamNumber: '96F',
          teamName: 'Ninety Six',
          school: 'Oak Ridge High',
        ),
        isTrue,
      );
      expect(
        matchesTeamSearch(
          query: 'WESTSIDE',
          teamNumber: '96F',
          teamName: 'Ninety Six',
          school: 'Oak Ridge High',
        ),
        isFalse,
      );
      // Fallback "Team <number>" should not falsely match "team"
      expect(
        matchesTeamSearch(
          query: 'team',
          teamNumber: '96F',
          teamName: 'Team 96F',
          school: null,
        ),
        isFalse,
      );
    });
  });

  group('Team Entry Sorting Tests', () {
    const entries = [
      TeamListEntry(
        teamNumber: '1016X',
        teamName: 'Ten Sixteen',
        school: 'West High',
        rank: 2,
      ),
      TeamListEntry(
        teamNumber: '96F',
        teamName: 'Alpha Bots',
        school: 'Central High',
        rank: 1,
      ),
      TeamListEntry(
        teamNumber: '224A',
        teamName: 'Zeta Bots',
        school: 'Central High',
        rank: null,
      ),
      TeamListEntry(
        teamNumber: '1A',
        teamName: 'Team 1A',
        school: null,
        rank: 5,
      ),
    ];

    test('sorts by team number ascending and descending', () {
      final asc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.number, ascending: true));
      expect(asc.map((e) => e.teamNumber), equals(['1A', '96F', '224A', '1016X']));

      final desc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.number, ascending: false));
      expect(desc.map((e) => e.teamNumber), equals(['1016X', '224A', '96F', '1A']));
    });

    test('sorts by rank ascending and descending with unranked teams always last', () {
      final asc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.rank, ascending: true));
      expect(asc.map((e) => e.teamNumber), equals(['96F', '1016X', '1A', '224A']));

      final desc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.rank, ascending: false));
      expect(desc.map((e) => e.teamNumber), equals(['1A', '1016X', '96F', '224A']));
    });

    test('sorts by team name ascending and descending with fallback/unnamed teams last', () {
      final asc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.name, ascending: true));
      expect(asc.map((e) => e.teamNumber), equals(['96F', '1016X', '224A', '1A']));

      final desc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.name, ascending: false));
      expect(desc.map((e) => e.teamNumber), equals(['224A', '1016X', '96F', '1A']));
    });

    test('sorts by school ascending and descending with tie-break by team number and missing school last', () {
      final asc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.school, ascending: true));
      expect(asc.map((e) => e.teamNumber), equals(['96F', '224A', '1016X', '1A']));

      final desc = List<TeamListEntry>.from(entries)
        ..sort((a, b) => compareTeamEntries(a, b, sortBy: TeamSortField.school, ascending: false));
      expect(desc.map((e) => e.teamNumber), equals(['1016X', '96F', '224A', '1A']));
    });
  });
}
