import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roboref/features/incidents/screens/incident_logger_screen.dart';
import 'package:roboref/features/matches/screens/match_schedule_screen.dart';
import 'package:roboref/features/matches/state/match_controller.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';

void main() {
  testWidgets('IncidentLoggerScreen delete IconButton has tooltip "Delete Note"', (WidgetTester tester) async {
    final note = IncidentNote(
      id: 'note-1',
      sku: 'RE-VRC-24-0001',
      teamNumber: '1234A',
      matchId: 'Q1',
      ruleCodesJson: '["G1"]',
      severity: 'minor',
      notes: 'Minor rule warning',
      refereeName: 'Ref 1',
      deviceId: 'dev1',
      isDeleted: false,
      isSynced: true,
      version: 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentNotesProvider.overrideWithValue(AsyncValue.data([note])),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: IncidentLoggerScreen(showAppBar: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final deleteButtonFinder = find.byTooltip('Delete Note');
    expect(deleteButtonFinder, findsOneWidget);

    final iconButtonFinder = find.ancestor(
      of: find.byIcon(Icons.delete_outline),
      matching: find.byType(IconButton),
    );
    expect(iconButtonFinder, findsOneWidget);

    final iconButton = tester.widget<IconButton>(iconButtonFinder);
    expect(iconButton.tooltip, equals('Delete Note'));
  });

  testWidgets('IncidentLoggerScreen search field shows clear button when typed and clears search query on tap', (WidgetTester tester) async {
    final notes = [
      IncidentNote(
        id: 'note-1',
        sku: 'RE-VRC-24-0001',
        teamNumber: '1234A',
        matchId: 'Q1',
        ruleCodesJson: '["G1"]',
        severity: 'minor',
        notes: 'Minor rule warning',
        refereeName: 'Ref 1',
        deviceId: 'dev1',
        isDeleted: false,
        isSynced: true,
        version: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      IncidentNote(
        id: 'note-2',
        sku: 'RE-VRC-24-0001',
        teamNumber: '5678B',
        matchId: 'Q2',
        ruleCodesJson: '["SG1"]',
        severity: 'major',
        notes: 'Major violation',
        refereeName: 'Ref 1',
        deviceId: 'dev1',
        isDeleted: false,
        isSynced: true,
        version: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentNotesProvider.overrideWithValue(AsyncValue.data(notes)),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: IncidentLoggerScreen(showAppBar: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), '5678');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(find.text('5678B'), findsOneWidget);
    expect(find.text('1234A'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsNothing);
    expect(find.text('1234A'), findsOneWidget);
    expect(find.text('5678B'), findsOneWidget);
  });

  testWidgets('MatchScheduleScreen search field shows clear button when typed and clears search query on tap', (WidgetTester tester) async {
    const matches = [
      Matche(
        matchId: 'm1',
        divisionId: 1,
        sku: 'RE-V5RC-26-4487',
        name: 'Qualifier #1',
        field: 'Field 1',
        scheduledTime: '09:00 AM',
        redTeamsJson: '["1114A", "2056A"]',
        blueTeamsJson: '["217A", "148A"]',
      ),
      Matche(
        matchId: 'm2',
        divisionId: 1,
        sku: 'RE-V5RC-26-4487',
        name: 'Qualifier #12',
        field: 'Field 2',
        scheduledTime: '09:30 AM',
        redTeamsJson: '["9999X", "8888Y"]',
        blueTeamsJson: '["7777Z", "6666W"]',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentMatchesProvider.overrideWith((ref) => Stream.value(matches)),
          activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: MatchScheduleScreen(showAppBar: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Q12');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsOneWidget);
    expect(find.text('9999X'), findsOneWidget);
    expect(find.text('1114A'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear search'), findsNothing);
    expect(find.text('1114A'), findsOneWidget);
    expect(find.text('9999X'), findsOneWidget);
  });
}
