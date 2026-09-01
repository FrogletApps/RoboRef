import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/teams/screens/team_list_screen.dart';
import 'package:roboref/features/teams/state/team_controller.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';

void main() {
  testWidgets('TeamListScreen displays smaller team numbers first (e.g. 96F before 1016X)', (tester) async {
    const teams = [
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '1016X', teamName: 'Ten Sixteen'),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '96F', teamName: 'Ninety Six'),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '224A', teamName: 'Two Twenty Four'),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '1A', teamName: 'One A'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentTeamsProvider.overrideWith((ref) => Stream.value(teams)),
          activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: TeamListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 4 teams appear on screen
    expect(find.text('1A'), findsWidgets);
    expect(find.text('96F'), findsWidgets);
    expect(find.text('224A'), findsWidgets);
    expect(find.text('1016X'), findsWidgets);

    // Verify ordering in list
    final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(listTiles.length, 4);

    final titleTexts = listTiles.map((tile) {
      final row = tile.title as Row;
      final textWidget = row.children.first as Text;
      return textWidget.data;
    }).toList();

    expect(titleTexts, equals(['1A', '96F', '224A', '1016X']));
  });

  testWidgets('TeamListScreen includes teams from incident notes sorted naturally', (tester) async {
    final note = IncidentNote(
      id: 'note-1',
      sku: 'RE-V5RC-26-4487',
      teamNumber: '12B',
      ruleCodesJson: '[]',
      severity: 'warning',
      notes: 'Test note',
      refereeName: 'Ref',
      deviceId: 'dev',
      createdAt: 1000,
      updatedAt: 1000,
      isDeleted: false,
      version: 0,
      isSynced: true,
    );

    const registeredTeams = [
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '1016X', teamName: 'Ten Sixteen'),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '96F', teamName: 'Ninety Six'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentTeamsProvider.overrideWith((ref) => Stream.value(registeredTeams)),
          activeTournamentNotesProvider.overrideWith((ref) => Stream.value([note])),
        ],
        child: const MaterialApp(
          home: TeamListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(listTiles.length, 3);

    final titleTexts = listTiles.map((tile) {
      final row = tile.title as Row;
      final textWidget = row.children.first as Text;
      return textWidget.data;
    }).toList();

    // 12B < 96F < 1016X
    expect(titleTexts, equals(['12B', '96F', '1016X']));
  });

  testWidgets('TeamListScreen displays team event ranking in the leading icon avatar', (tester) async {
    const teamsWithRanks = [
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '1A', teamName: 'One A', rank: 1),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '96F', teamName: 'Ninety Six', rank: 14),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '224A', teamName: 'Two Twenty Four', rank: 105),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '1016X', teamName: 'Ten Sixteen', rank: null),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentTeamsProvider.overrideWith((ref) => Stream.value(teamsWithRanks)),
          activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: TeamListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final avatars = tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();
    expect(avatars.length, 4);

    final avatarTexts = avatars.map((avatar) {
      final text = avatar.child as Text;
      return text.data;
    }).toList();

    // 1A (Rank 1), 96F (Rank 14), 224A (Rank 105), 1016X (Unranked '-')
    expect(avatarTexts, equals(['1', '14', '105', '-']));
  });
}
