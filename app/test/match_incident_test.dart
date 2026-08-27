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
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(testDb),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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
    await tester.enterText(find.widgetWithText(TextField, 'Describe details, warnings given, or match conditions...'), 'Entanglement warning');
    await tester.pumpAndSettle();

    final saveButton = find.text('Save & Sync Incident');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify saved note in database
    final notes = await (testDb.select(testDb.incidentNotes)).get();
    expect(notes.length, equals(1));
    expect(notes.first.matchId, equals('Q12'));
    expect(notes.first.teamNumber, equals('1114A'));
    expect(notes.first.notes, equals('Entanglement warning'));

    container.dispose();
  });

  testWidgets('MatchScheduleScreen opens AddIncidentSheet with pre-filled match and team', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(testDb),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MatchScheduleScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Match card for Q12 should be visible
    expect(find.text('Q12'), findsOneWidget);
    expect(find.text('Field 1'), findsOneWidget);

    // Tap on match Q12
    await tester.tap(find.text('Q12'));
    await tester.pumpAndSettle();

    // Match actions modal should be shown
    expect(find.text('Actions for Q12'), findsOneWidget);
    expect(find.text('Log Incident Note for Q12'), findsOneWidget);
    expect(find.text('Pre-fills match number into note'), findsOneWidget);

    // Tap on action chip for team 2056A
    final chip2056 = find.widgetWithText(ActionChip, '2056A');
    expect(chip2056, findsOneWidget);
    await tester.tap(chip2056);
    await tester.pumpAndSettle();

    // AddIncidentSheet should open with both Q12 and 2056A pre-filled
    expect(find.text('Log Match Incident / Rule Note'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Q12'), findsOneWidget);
    expect(find.widgetWithText(TextField, '2056A'), findsOneWidget);

    // Save incident
    final saveButton = find.text('Save & Sync Incident');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final notes = await (testDb.select(testDb.incidentNotes)).get();
    expect(notes.length, equals(1));
    expect(notes.first.matchId, equals('Q12'));
    expect(notes.first.teamNumber, equals('2056A'));

    container.dispose();
  });
}
