import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/core/utils/match_utils.dart';
import 'package:roboref/database/app_database.dart';

void main() {
  group('getMatchRoundOrder', () {
    test('identifies Practice matches', () {
      expect(getMatchRoundOrder('Practice 1'), 1);
      expect(getMatchRoundOrder('Practice #10'), 1);
      expect(getMatchRoundOrder('Prac 1'), 1);
      expect(getMatchRoundOrder('P 1'), 1);
      expect(getMatchRoundOrder('P1'), 1);
      expect(getMatchRoundOrder('P-1'), 1);
      expect(getMatchRoundOrder('P_1'), 1);
      expect(getMatchRoundOrder('P#1'), 1);
    });

    test('identifies Qualification matches', () {
      expect(getMatchRoundOrder('Qualification 1'), 2);
      expect(getMatchRoundOrder('Qualifier 10'), 2);
      expect(getMatchRoundOrder('Quals 1'), 2);
      expect(getMatchRoundOrder('Qual 1'), 2);
      expect(getMatchRoundOrder('Q 1'), 2);
      expect(getMatchRoundOrder('Q1'), 2);
      expect(getMatchRoundOrder('Q-1'), 2);
      expect(getMatchRoundOrder('Q#1'), 2);
      expect(getMatchRoundOrder('Q 10'), 2);
    });

    test('identifies Round of 16 matches', () {
      expect(getMatchRoundOrder('Round of 16 1-1'), 3);
      expect(getMatchRoundOrder('Round of Sixteen 1-1'), 3);
      expect(getMatchRoundOrder('RO16 1-1'), 3);
      expect(getMatchRoundOrder('R16 1-1'), 3);
      expect(getMatchRoundOrder('R16-1'), 3);
      expect(getMatchRoundOrder('R16 #1'), 3);
    });

    test('identifies Quarterfinals matches', () {
      expect(getMatchRoundOrder('Quarterfinal 1-1'), 4);
      expect(getMatchRoundOrder('Quarterfinals 1-1'), 4);
      expect(getMatchRoundOrder('Quarter-final 1-1'), 4);
      expect(getMatchRoundOrder('QF 1-1'), 4);
      expect(getMatchRoundOrder('QF1-1'), 4);
      expect(getMatchRoundOrder('QF #1'), 4);
      expect(getMatchRoundOrder('QTR 1'), 4);
    });

    test('identifies Semifinals matches', () {
      expect(getMatchRoundOrder('Semifinal 1-1'), 5);
      expect(getMatchRoundOrder('Semifinals 1-1'), 5);
      expect(getMatchRoundOrder('Semi-final 1-1'), 5);
      expect(getMatchRoundOrder('SF 1-1'), 5);
      expect(getMatchRoundOrder('SF1-1'), 5);
      expect(getMatchRoundOrder('SF #1'), 5);
    });

    test('identifies Finals matches', () {
      expect(getMatchRoundOrder('Final 1-1'), 6);
      expect(getMatchRoundOrder('Finals 1-1'), 6);
      expect(getMatchRoundOrder('Finals 1'), 6);
      expect(getMatchRoundOrder('F 1-1'), 6);
      expect(getMatchRoundOrder('F1-1'), 6);
      expect(getMatchRoundOrder('F1'), 6);
      expect(getMatchRoundOrder('F 1'), 6);
      expect(getMatchRoundOrder('F#1'), 6);
    });

    test('identifies Round Robin and Top N matches', () {
      expect(getMatchRoundOrder('Round Robin 1-1'), 7);
      expect(getMatchRoundOrder('RR 1-1'), 7);
      expect(getMatchRoundOrder('Top 8 1-1'), 7);
    });

    test('handles unknown or empty match names', () {
      expect(getMatchRoundOrder(''), 99);
      expect(getMatchRoundOrder(null), 99);
      expect(getMatchRoundOrder('Custom Exhibition 1'), 99);
    });
  });

  group('compareMatchNames', () {
    test('sorts qualification matches in natural numeric order (1-9 before 10-99, 1 NOT followed by 10)', () {
      final quals = [
        'Q10',
        'Q1',
        'Q100',
        'Q2',
        'Q20',
        'Q9',
        'Q3',
        'Q11',
      ];
      quals.sort(compareMatchNames);
      expect(quals, [
        'Q1',
        'Q2',
        'Q3',
        'Q9',
        'Q10',
        'Q11',
        'Q20',
        'Q100',
      ]);
    });

    test('sorts practice matches before qualification matches and in numeric order', () {
      final matches = [
        'Q1',
        'Practice 10',
        'Practice 1',
        'Q2',
        'Practice 2',
      ];
      matches.sort(compareMatchNames);
      expect(matches, [
        'Practice 1',
        'Practice 2',
        'Practice 10',
        'Q1',
        'Q2',
      ]);
    });

    test('sorts elimination rounds in chronological order: R16 -> QF -> SF -> Finals', () {
      final elims = [
        'Finals 1-1',
        'SF 1-1',
        'QF 1-1',
        'R16 1-1',
        'QF 2-1',
        'Finals 1-2',
        'SF 2-1',
        'R16 2-1',
      ];
      elims.sort(compareMatchNames);
      expect(elims, [
        'R16 1-1',
        'R16 2-1',
        'QF 1-1',
        'QF 2-1',
        'SF 1-1',
        'SF 2-1',
        'Finals 1-1',
        'Finals 1-2',
      ]);
    });

    test('sorts multi-part elimination match numbers correctly (instance and matchnum)', () {
      final qfs = [
        'QF 10-1',
        'QF 1-2',
        'QF 2-1',
        'QF 1-1',
        'QF 4-1',
      ];
      qfs.sort(compareMatchNames);
      expect(qfs, [
        'QF 1-1',
        'QF 1-2',
        'QF 2-1',
        'QF 4-1',
        'QF 10-1',
      ]);
    });

    test('sorts complete mixed tournament match schedule in chronological order', () {
      final tournament = [
        'Finals 1-1',
        'Q10',
        'Practice 2',
        'QF 2-1',
        'Q1',
        'SF 1-1',
        'Practice 1',
        'R16 1-1',
        'Q2',
        'QF 1-1',
        'Q9',
        'Practice 10',
        'Finals 1-2',
      ];
      tournament.sort(compareMatchNames);
      expect(tournament, [
        'Practice 1',
        'Practice 2',
        'Practice 10',
        'Q1',
        'Q2',
        'Q9',
        'Q10',
        'R16 1-1',
        'QF 1-1',
        'QF 2-1',
        'SF 1-1',
        'Finals 1-1',
        'Finals 1-2',
      ]);
    });
  });

  group('compareMatches', () {
    test('sorts Drift Matche records by division, round, and match number', () {
      const sku = 'RE-V5RC-24-1234';
      final matches = [
        const Matche(
          matchId: 'm-f1',
          sku: sku,
          divisionId: 1,
          name: 'Finals 1-1',
          redTeamsJson: '[]',
          blueTeamsJson: '[]',
        ),
        const Matche(
          matchId: 'm-q10',
          sku: sku,
          divisionId: 1,
          name: 'Q10',
          redTeamsJson: '[]',
          blueTeamsJson: '[]',
        ),
        const Matche(
          matchId: 'm-q1',
          sku: sku,
          divisionId: 1,
          name: 'Q1',
          redTeamsJson: '[]',
          blueTeamsJson: '[]',
        ),
        const Matche(
          matchId: 'm-p1',
          sku: sku,
          divisionId: 1,
          name: 'Practice 1',
          redTeamsJson: '[]',
          blueTeamsJson: '[]',
        ),
        const Matche(
          matchId: 'm-d2-q1',
          sku: sku,
          divisionId: 2,
          name: 'Q1',
          redTeamsJson: '[]',
          blueTeamsJson: '[]',
        ),
      ];

      matches.sort(compareMatches);

      expect(matches.map((m) => '${m.divisionId}:${m.name}').toList(), [
        '1:Practice 1',
        '1:Q1',
        '1:Q10',
        '1:Finals 1-1',
        '2:Q1',
      ]);
    });
  });
}
