import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/core/theme/app_theme.dart';
import 'package:roboref/core/utils/team_utils.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/teams/screens/team_list_screen.dart';
import 'package:roboref/features/teams/state/team_controller.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

List<String?> _extractVisibleTeamNumbers(WidgetTester tester) {
  final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
  return listTiles.map((tile) {
    final row = tile.title as Row;
    final textWidget = row.children.first as Text;
    return textWidget.data;
  }).toList();
}

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
      severity: 'general',
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

    // 1A (Rank 1st), 96F (Rank 14th), 224A (Rank 105th), 1016X (Unranked '-')
    expect(find.text('1'), findsOneWidget);
    expect(find.text('st'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('105'), findsOneWidget);
    expect(find.text('th'), findsNWidgets(2)); // 14th and 105th
    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('TeamListScreen search field shows clear button when typed and clears search query on tap', (tester) async {
    const teams = [
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '1A', teamName: 'One A'),
      Team(sku: 'RE-V5RC-26-4487', teamNumber: '96F', teamName: 'Ninety Six'),
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

    // Initially clear button should not be present
    expect(find.byTooltip('Clear search'), findsNothing);

    // Enter search query
    await tester.enterText(find.byType(TextField), '96');
    await tester.pumpAndSettle();

    // Verify clear button appears and search filters list
    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(find.text('96F'), findsWidgets);
    expect(find.text('1A'), findsNothing);

    // Tap clear button
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    // Verify search is cleared and all items return
    expect(find.byTooltip('Clear search'), findsNothing);
    expect(find.text('1A'), findsWidgets);
    expect(find.text('96F'), findsWidgets);
  });

  testWidgets('TeamListScreen displays school on team cards and in Team History sheet', (tester) async {
    const teams = [
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '1A',
        teamName: 'Alpha Robotics',
        organization: 'Northside High School',
        rank: 2,
      ),
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '96F',
        teamName: 'Ninety Six',
        organization: null,
        rank: 1,
      ),
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

    expect(find.text('Northside High School'), findsOneWidget);
    expect(find.byIcon(Icons.group_outlined), findsOneWidget);

    // Open team history bottom sheet and verify school is displayed there too
    await tester.tap(find.text('1A'));
    await tester.pumpAndSettle();

    expect(find.text('Team 1A History'), findsOneWidget);
    expect(find.text('Alpha Robotics • Northside High School'), findsOneWidget);
  });

  testWidgets('TeamListScreen supports searching by school and team name', (tester) async {
    const teams = [
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '1A',
        teamName: 'Cyber Wolves',
        organization: 'Central Academy',
      ),
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '96F',
        teamName: 'Iron Eagles',
        organization: 'Oak Ridge High',
      ),
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '224A',
        teamName: 'Solar Sparks',
        organization: 'Central Academy',
      ),
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

    // Search by school (case-insensitive)
    await tester.enterText(find.byType(TextField), 'central');
    await tester.pumpAndSettle();

    expect(_extractVisibleTeamNumbers(tester), equals(['1A', '224A']));
    expect(find.text('96F'), findsNothing);

    // Search by team name
    await tester.enterText(find.byType(TextField), 'eagles');
    await tester.pumpAndSettle();

    expect(_extractVisibleTeamNumbers(tester), equals(['96F']));
    expect(find.text('1A'), findsNothing);
    expect(find.text('224A'), findsNothing);
  });

  testWidgets('TeamListScreen sorts by team number, rank, team name, and school with direction toggle', (tester) async {
    const teams = [
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '1016X',
        teamName: 'Ten Sixteen',
        organization: 'West High',
        rank: 2,
      ),
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '96F',
        teamName: 'Alpha Bots',
        organization: 'Central High',
        rank: 1,
      ),
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '224A',
        teamName: 'Zeta Bots',
        organization: 'Central High',
        rank: null,
      ),
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '1A',
        teamName: 'Team 1A',
        organization: null,
        rank: 5,
      ),
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

    // Default: Team # ascending
    expect(_extractVisibleTeamNumbers(tester), equals(['1A', '96F', '224A', '1016X']));

    // Tap Team # again -> Team # descending
    await tester.tap(find.byKey(const ValueKey('team_sort_chip_number')));
    await tester.pumpAndSettle();
    expect(_extractVisibleTeamNumbers(tester), equals(['1016X', '224A', '96F', '1A']));

    // Sort by Rank ascending (unranked 224A at bottom)
    await tester.tap(find.byKey(const ValueKey('team_sort_chip_rank')));
    await tester.pumpAndSettle();
    expect(_extractVisibleTeamNumbers(tester), equals(['96F', '1016X', '1A', '224A']));

    // Tap Rank again -> Rank descending (unranked 224A stays at bottom)
    await tester.tap(find.byKey(const ValueKey('team_sort_chip_rank')));
    await tester.pumpAndSettle();
    expect(_extractVisibleTeamNumbers(tester), equals(['1A', '1016X', '96F', '224A']));

    // Sort by Name ascending (fallback Team 1A at bottom)
    await tester.tap(find.byKey(const ValueKey('team_sort_chip_name')));
    await tester.pumpAndSettle();
    expect(_extractVisibleTeamNumbers(tester), equals(['96F', '1016X', '224A', '1A']));

    // Tap Name again -> Name descending (fallback Team 1A stays at bottom)
    await tester.tap(find.byKey(const ValueKey('team_sort_chip_name')));
    await tester.pumpAndSettle();
    expect(_extractVisibleTeamNumbers(tester), equals(['224A', '1016X', '96F', '1A']));

    // Sort by School ascending (Central High tie-broken by team number: 96F < 224A; null school 1A last)
    await tester.tap(find.byKey(const ValueKey('team_sort_chip_school')));
    await tester.pumpAndSettle();
    expect(_extractVisibleTeamNumbers(tester), equals(['96F', '224A', '1016X', '1A']));

    // Tap School again -> School descending (null school 1A stays last)
    await tester.tap(find.byKey(const ValueKey('team_sort_chip_school')));
    await tester.pumpAndSettle();
    expect(_extractVisibleTeamNumbers(tester), equals(['1016X', '96F', '224A', '1A']));
  });

  test('TeamSortController persists and restores sort preference in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container1 = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container1.dispose);

    expect(container1.read(teamSortProvider), const TeamSortState(field: TeamSortField.number, ascending: true));

    container1.read(teamSortProvider.notifier).selectSortField(TeamSortField.school);
    expect(container1.read(teamSortProvider), const TeamSortState(field: TeamSortField.school, ascending: true));

    container1.read(teamSortProvider.notifier).selectSortField(TeamSortField.school);
    expect(container1.read(teamSortProvider), const TeamSortState(field: TeamSortField.school, ascending: false));

    // Re-read in a fresh container with the same SharedPreferences
    final container2 = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container2.dispose);

    expect(container2.read(teamSortProvider), const TeamSortState(field: TeamSortField.school, ascending: false));
  });

  testWidgets('TeamListScreen meets accessibility guidelines and 200% text scaling in light & dark themes', (tester) async {
    const teams = [
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '1114A',
        teamName: 'Simbotics',
        organization: 'Governor Simcoe Secondary School',
        rank: 1,
      ),
      Team(
        sku: 'RE-V5RC-26-4487',
        teamNumber: '2056A',
        teamName: 'OP Robotics',
        organization: 'Orchard Park Secondary School',
        rank: 14,
      ),
    ];

    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeTournamentTeamsProvider.overrideWith((ref) => Stream.value(teams)),
              activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              theme: theme,
              home: const TeamListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        handle.dispose();
      }
    }

    // Check 200% text scaling on mobile viewport (390x844) without overflow
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentTeamsProvider.overrideWith((ref) => Stream.value(teams)),
          activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: const TeamListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
