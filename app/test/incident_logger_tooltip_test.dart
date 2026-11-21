import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/features/incidents/screens/incident_logger_screen.dart';
import 'package:roboref/features/matches/screens/match_schedule_screen.dart';
import 'package:roboref/features/matches/state/match_controller.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:roboref/features/teams/screens/team_list_screen.dart';

void main() {
  testWidgets('IncidentLoggerScreen edit and delete IconButtons have tooltips "Edit Note" and "Delete Note"', (WidgetTester tester) async {
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

    final editButtonFinder = find.byTooltip('Edit Note');
    expect(editButtonFinder, findsOneWidget);

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

  testWidgets('IncidentLoggerScreen can edit a saved note with pre-filled values and overwrite it on save', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'current_sku': 'RE-V5RC-26-4487',
      'referee_name': 'Head Referee Jane',
      'device_id': 'test-device-uuid',
      'server_url': 'http://127.0.0.1:8080',
    });
    final prefs = await SharedPreferences.getInstance();
    final testDb = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(testDb.close);

    final initialTime = DateTime.now().millisecondsSinceEpoch - 5000;
    await testDb.into(testDb.incidentNotes).insert(
      IncidentNotesCompanion(
        id: const Value('edit-note-1'),
        sku: const Value('RE-V5RC-26-4487'),
        teamNumber: const Value('1114A'),
        matchId: const Value('Q12'),
        ruleCodesJson: Value(jsonEncode(['<SG1>'])),
        severity: const Value('minor'),
        notes: const Value('Initial entanglement warning'),
        refereeName: const Value('Head Referee Jane'),
        deviceId: const Value('test-device-uuid'),
        createdAt: Value(initialTime),
        updatedAt: Value(initialTime),
        isDeleted: const Value(false),
        version: const Value(1),
        isSynced: const Value(true),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: IncidentLoggerScreen(showAppBar: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1114A'), findsOneWidget);
    expect(find.text('Q 12'), findsOneWidget);
    expect(find.text('Initial entanglement warning'), findsOneWidget);

    // Tap the Edit Note button
    await tester.tap(find.byTooltip('Edit Note'));
    await tester.pumpAndSettle();

    // Window should say "Edit Note" at the top
    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.text('New Note'), findsNothing);

    // Pre-existing information should be pre-filled
    expect(find.widgetWithText(TextField, '1114A'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Q12'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Initial entanglement warning'), findsOneWidget);

    final segmentedBtn = tester.widget<SegmentedButton<String>>(find.byType(SegmentedButton<String>));
    expect(segmentedBtn.selected, equals({'minor'}));

    final sg1Chip = tester.widget<FilterChip>(find.widgetWithText(FilterChip, '<SG1> Starting a Match'));
    expect(sg1Chip.selected, isTrue);

    // Modify fields: change team to 2056A, match to Q15, severity to Major, add <GG2>, update notes
    await tester.enterText(find.widgetWithText(TextField, '1114A'), '2056A');
    await tester.enterText(find.widgetWithText(TextField, 'Q12'), 'Q15');
    await tester.enterText(
      find.widgetWithText(TextField, 'Initial entanglement warning'),
      'Upgraded to major violation after replay check',
    );
    await tester.tap(find.text('Major'));
    await tester.pumpAndSettle();

    final gg2ChipFinder = find.widgetWithText(FilterChip, "<GG2> A Team's Robot should attend every Match");
    await tester.ensureVisible(gg2ChipFinder);
    await tester.tap(gg2ChipFinder);
    await tester.pumpAndSettle();

    // Save edited note
    final saveButton = find.text('Save Note');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    // Verify note was overwritten in database (still 1 note with the same id)
    final savedNotes = await testDb.select(testDb.incidentNotes).get();
    expect(savedNotes.length, 1);
    expect(savedNotes.first.id, 'edit-note-1');
    expect(savedNotes.first.teamNumber, '2056A');
    expect(savedNotes.first.matchId, 'Q15');
    expect(savedNotes.first.severity, 'major');
    expect(savedNotes.first.notes, 'Upgraded to major violation after replay check');
    expect(jsonDecode(savedNotes.first.ruleCodesJson), containsAll(['<SG1>', '<GG2>']));

    // Verify UI updated with overwritten note
    expect(find.text('2056A'), findsOneWidget);
    expect(find.text('Q 15'), findsOneWidget);
    expect(find.text('Upgraded to major violation after replay check'), findsOneWidget);
    expect(find.text('Initial entanglement warning'), findsNothing);
  });

  testWidgets('TeamListScreen Team History sheet allows editing a saved note', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'current_sku': 'RE-V5RC-26-4487',
      'referee_name': 'Head Referee Jane',
      'device_id': 'test-device-uuid',
      'server_url': 'http://127.0.0.1:8080',
    });
    final prefs = await SharedPreferences.getInstance();
    final testDb = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
    addTearDown(testDb.close);

    final initialTime = DateTime.now().millisecondsSinceEpoch - 5000;
    await testDb.into(testDb.incidentNotes).insert(
      IncidentNotesCompanion(
        id: const Value('team-hist-note-1'),
        sku: const Value('RE-V5RC-26-4487'),
        teamNumber: const Value('1114A'),
        matchId: const Value('Q3'),
        ruleCodesJson: Value(jsonEncode(['<S1>'])),
        severity: const Value('general'),
        notes: const Value('Original team history note'),
        refereeName: const Value('Head Referee Jane'),
        deviceId: const Value('test-device-uuid'),
        createdAt: Value(initialTime),
        updatedAt: Value(initialTime),
        isDeleted: const Value(false),
        version: const Value(1),
        isSynced: const Value(true),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: TeamListScreen(showAppBar: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on team 1114A to open Team History sheet
    await tester.tap(find.text('1114A'));
    await tester.pumpAndSettle();

    expect(find.text('Team 1114A History'), findsOneWidget);
    expect(find.text('Original team history note'), findsOneWidget);
    expect(find.byTooltip('Edit Note'), findsOneWidget);

    // Tap Edit Note inside Team History sheet
    await tester.tap(find.byTooltip('Edit Note'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1114A'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Q3'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Original team history note'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Original team history note'),
      'Edited from team history sheet',
    );
    final saveButton = find.text('Save Note');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final savedNotes = await testDb.select(testDb.incidentNotes).get();
    expect(savedNotes.length, 1);
    expect(savedNotes.first.id, 'team-hist-note-1');
    expect(savedNotes.first.notes, 'Edited from team history sheet');
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
