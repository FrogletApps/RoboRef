import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/screens/incident_logger_screen.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/matches/screens/match_schedule_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDb;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'current_sku': 'RE-V5RC-26-4487',
      'referee_name': 'Head Referee Jane',
      'device_id': 'test-device-uuid',
      'server_url': 'http://127.0.0.1:8080',
    });
    prefs = await SharedPreferences.getInstance();
    testDb = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );

    // Seed test teams
    await testDb.into(testDb.teams).insert(
      const TeamsCompanion(
        sku: Value('RE-V5RC-26-4487'),
        teamNumber: Value('1114A'),
        teamName: Value('Simbotics'),
      ),
    );
    await testDb.into(testDb.teams).insert(
      const TeamsCompanion(
        sku: Value('RE-V5RC-26-4487'),
        teamNumber: Value('2056A'),
        teamName: Value('OP Robotics'),
      ),
    );

    // Seed test match
    await testDb.into(testDb.matches).insert(
      MatchesCompanion(
        matchId: const Value('m1'),
        divisionId: const Value(1),
        sku: const Value('RE-V5RC-26-4487'),
        name: const Value('Q12'),
        field: const Value('Field 1'),
        scheduledTime: const Value('09:30 AM'),
        redTeamsJson: Value(jsonEncode(['1114A', '2056A'])),
        blueTeamsJson: Value(jsonEncode(['217A', '148A'])),
      ),
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('AddIncidentSheet pre-fills initialMatch and displays match teams', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddIncidentSheet(
              initialMatch: 'Q12',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Match field has initial value 'Q12'
    final matchField = find.widgetWithText(TextField, 'Q12');
    expect(matchField, findsOneWidget);

    // Verify match teams chips are shown for 1114A, 2056A, 217A, 148A
    expect(find.text('Teams in match:'), findsOneWidget);
    expect(find.text('1114A'), findsOneWidget);
    expect(find.text('2056A'), findsOneWidget);
    expect(find.text('217A'), findsOneWidget);
    expect(find.text('148A'), findsOneWidget);

    // Tap on team chip 1114A
    await tester.tap(find.text('1114A'));
    await tester.pumpAndSettle();

    // Verify Team Number field now contains 1114A
    final teamField = find.widgetWithText(TextField, '1114A');
    expect(teamField, findsOneWidget);

    // Enter note and submit
    await tester.enterText(
      find.widgetWithText(TextField, 'Describe details, warnings given, or match conditions...'),
      'Entanglement warning',
    );
    await tester.pumpAndSettle();

    final saveButton = find.text('Save & Sync Incident');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    // Verify saved note in database
    final notes = await (testDb.select(testDb.incidentNotes)).get();
    expect(notes.length, equals(1));
    expect(notes.first.matchId, equals('Q12'));
    expect(notes.first.teamNumber, equals('1114A'));
    expect(notes.first.notes, equals('Entanglement warning'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('MatchScheduleScreen opens AddIncidentSheet with pre-filled match and team', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: MatchScheduleScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Match card for Q 12 should be visible
    expect(find.text('Q 12'), findsOneWidget);
    expect(find.text('Field 1'), findsOneWidget);

    // Tap on match Q 12
    await tester.tap(find.text('Q 12'));
    await tester.pumpAndSettle();

    // Match actions modal should be shown
    expect(find.text('Actions for Q 12'), findsOneWidget);
    expect(find.text('Log Incident Note for Q 12'), findsOneWidget);
    expect(find.text('Pre-fills match number into note'), findsOneWidget);

    // Tap on action chip for team 2056A
    final chip2056 = find.widgetWithText(ActionChip, '2056A');
    expect(chip2056, findsOneWidget);
    await tester.tap(chip2056);
    await tester.pumpAndSettle();

    // AddIncidentSheet should open with both Q 12 and 2056A pre-filled
    expect(find.text('Log Match Incident / Rule Note'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Q 12'), findsOneWidget);
    expect(find.widgetWithText(TextField, '2056A'), findsOneWidget);

    // Save incident
    final saveButton = find.text('Save & Sync Incident');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final notes = await (testDb.select(testDb.incidentNotes)).get();
    expect(notes.length, equals(1));
    expect(notes.first.matchId, equals('Q 12'));
    expect(notes.first.teamNumber, equals('2056A'));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('AddIncidentSheet allows selecting multiple rules with Quick Reference Guide summaries', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddIncidentSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Select team
    await tester.enterText(
      find.widgetWithText(TextField, 'Team Number *'),
      '1114A',
    );
    await tester.pumpAndSettle();

    // Click "Show More Rules" button to open RuleSelectionSheet
    final selectRulesBtn = find.widgetWithText(OutlinedButton, 'Show More Rules');
    expect(selectRulesBtn, findsOneWidget);
    await tester.tap(selectRulesBtn);
    await tester.pumpAndSettle();

    // In RuleSelectionSheet modal, verify title and search for GG2
    expect(find.text('Select Rule Violations'), findsOneWidget);
    expect(find.text('V5RC Override (138 rules)'), findsOneWidget);

    // Search GG2
    final searchInput = find.widgetWithText(TextField, 'Search by rule code (SG1, GG2...) or summary...');
    expect(searchInput, findsOneWidget);
    await tester.enterText(searchInput, 'GG2');
    await tester.pumpAndSettle();

    expect(find.text('<GG2>'), findsOneWidget);
    expect(find.text("A Team's Robot should attend every Match"), findsOneWidget);

    // Tap to select GG2
    await tester.tap(find.text("A Team's Robot should attend every Match"));
    await tester.pumpAndSettle();

    // Clear search and search for SG1
    await tester.enterText(searchInput, 'SG1');
    await tester.pumpAndSettle();

    expect(find.text('<SG1>'), findsOneWidget);
    expect(find.text('Starting a Match'), findsOneWidget);

    // Tap to select SG1
    await tester.tap(find.text('Starting a Match'));
    await tester.pumpAndSettle();

    // Tap Done button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Done (2)'));
    await tester.pumpAndSettle();

    // Verify selected rule chips are shown consistently as selected FilterChips
    expect(find.widgetWithText(FilterChip, "<SG1> Starting a Match"), findsOneWidget);
    expect(find.widgetWithText(FilterChip, "<GG2> A Team's Robot should attend every Match"), findsOneWidget);

    // Total chips rendered: 2 selected + 4 unselected = 6 total chips
    expect(find.byType(FilterChip), findsNWidgets(6));

    // Save note
    final saveButton = find.text('Save & Sync Incident');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    // Verify database record has both rule codes
    final notes = await (testDb.select(testDb.incidentNotes)).get();
    expect(notes.length, equals(1));
    final decodedRules = (jsonDecode(notes.first.ruleCodesJson) as List).cast<String>();
    expect(decodedRules.contains('<SG1>') || decodedRules.contains('SG1'), isTrue);
    expect(decodedRules.contains('<GG2>') || decodedRules.contains('GG2'), isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('AddIncidentSheet allows submitting note with zero rules', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddIncidentSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // With 0 selected rules, exactly 6 unselected candidate chips are shown
    expect(find.byType(FilterChip), findsNWidgets(6));

    // Enter team number only
    await tester.enterText(
      find.widgetWithText(TextField, 'Team Number *'),
      '2056A',
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Describe details, warnings given, or match conditions...'),
      'General sportsmanship note without specific rule infraction',
    );
    await tester.pumpAndSettle();

    // Save note with no rules selected
    final saveButton = find.text('Save & Sync Incident');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final notes = await (testDb.select(testDb.incidentNotes)).get();
    expect(notes.length, equals(1));
    final decodedRules = (jsonDecode(notes.first.ruleCodesJson) as List);
    expect(decodedRules.isEmpty, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('AddIncidentSheet displays consistent chips with max 6 unselected chips and unlimited selected chips', (WidgetTester tester) async {
    // Seed existing notes at this event with GG16 (3 times), S5 (2 times), and SC1 (1 time)
    await testDb.into(testDb.incidentNotes).insert(
      IncidentNotesCompanion(
        id: const Value('n1'),
        sku: const Value('RE-V5RC-26-4487'),
        teamNumber: const Value('1114A'),
        severity: const Value('warning'),
        notes: const Value('Note 1'),
        refereeName: const Value('Ref A'),
        deviceId: const Value('d1'),
        ruleCodesJson: Value(jsonEncode(['<GG16>'])),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await testDb.into(testDb.incidentNotes).insert(
      IncidentNotesCompanion(
        id: const Value('n2'),
        sku: const Value('RE-V5RC-26-4487'),
        teamNumber: const Value('2056A'),
        severity: const Value('warning'),
        notes: const Value('Note 2'),
        refereeName: const Value('Ref A'),
        deviceId: const Value('d1'),
        ruleCodesJson: Value(jsonEncode(['<GG16>', '<S5>'])),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await testDb.into(testDb.incidentNotes).insert(
      IncidentNotesCompanion(
        id: const Value('n3'),
        sku: const Value('RE-V5RC-26-4487'),
        teamNumber: const Value('217A'),
        severity: const Value('warning'),
        notes: const Value('Note 3'),
        refereeName: const Value('Ref A'),
        deviceId: const Value('d1'),
        ruleCodesJson: Value(jsonEncode(['<GG16>', '<S5>'])),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddIncidentSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 0 selected -> 6 unselected chips total
    expect(find.byType(FilterChip), findsNWidgets(6));
    expect(find.widgetWithText(FilterChip, "<GG16> You can't force an opponent into a penalty"), findsOneWidget);
    expect(find.widgetWithText(FilterChip, "<S5> Wear safety glasses"), findsOneWidget);

    // Verify "Show More Rules" button is present below the chips
    expect(find.widgetWithText(OutlinedButton, 'Show More Rules'), findsOneWidget);

    // Tap on GG16 filter chip directly (1 selected)
    await tester.tap(find.widgetWithText(FilterChip, "<GG16> You can't force an opponent into a penalty"));
    await tester.pumpAndSettle();

    // Now 1 selected + 5 unselected = 6 chips total
    expect(find.byType(FilterChip), findsNWidgets(6));

    // Tap on S5 filter chip directly (2 selected)
    await tester.tap(find.widgetWithText(FilterChip, "<S5> Wear safety glasses"));
    await tester.pumpAndSettle();

    // Now 2 selected + 4 unselected = 6 chips total
    expect(find.byType(FilterChip), findsNWidgets(6));

    // Open "Show More Rules" and select 5 more rules (total 7 selected)
    await tester.tap(find.widgetWithText(OutlinedButton, 'Show More Rules'));
    await tester.pumpAndSettle();

    final searchInput = find.widgetWithText(TextField, 'Search by rule code (SG1, GG2...) or summary...');
    for (final code in ['SG1', 'SG2', 'SG3', 'GG1', 'GG2']) {
      await tester.enterText(searchInput, code);
      await tester.pumpAndSettle();
      await tester.tap(find.text('<$code>'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.widgetWithText(ElevatedButton, 'Done (7)'));
    await tester.pumpAndSettle();

    // When 7 are selected (which is > 6), all 7 selected chips are visible (no limit), and 0 unselected chips
    expect(find.byType(FilterChip), findsNWidgets(7));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('MatchScheduleScreen renders alliance labels and team pills', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const MaterialApp(
          home: MatchScheduleScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify RED and BLUE labels are rendered
    expect(find.text('RED'), findsOneWidget);
    expect(find.text('BLUE'), findsOneWidget);

    // Verify team pills
    expect(find.text('1114A'), findsOneWidget);
    expect(find.text('2056A'), findsOneWidget);
    expect(find.text('217A'), findsOneWidget);
    expect(find.text('148A'), findsOneWidget);

    // Verify no edit note icon in match schedule
    expect(find.byIcon(Icons.edit_note), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
