import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/matches/screens/match_schedule_screen.dart';
import 'package:roboref/features/matches/state/match_controller.dart';
import 'package:roboref/features/teams/screens/team_list_screen.dart';
import 'package:roboref/features/teams/state/team_controller.dart';
import 'package:roboref/features/incidents/screens/incident_logger_screen.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  late SharedPreferences prefs;
  late AppDatabase testDb;

  setUp(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({
      'current_sku': 'TEST-SKU',
    });
    prefs = await SharedPreferences.getInstance();
    testDb = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('MatchScheduleScreen empty state icon matches Symbols.format_list_numbered', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
          activeTournamentMatchesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: MatchScheduleScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.format_list_numbered), findsOneWidget);
    expect(find.text('No match schedule loaded yet.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('TeamListScreen empty state icon matches Symbols.groups', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
          activeTournamentTeamsProvider.overrideWith((ref) => Stream.value([])),
          activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: TeamListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.groups), findsOneWidget);
    expect(find.text('No team notes yet.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('IncidentLoggerScreen empty state icon matches Symbols.note_stack', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
          activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: IncidentLoggerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.note_stack), findsOneWidget);
    expect(find.text('No notes logged yet for this tournament.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
