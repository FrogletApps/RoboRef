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
}
