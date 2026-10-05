import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_workspace/screens/event_workspace_screen.dart';
import 'package:roboref/features/matches/screens/match_schedule_screen.dart';
import 'package:roboref/features/matches/state/match_controller.dart';
import 'package:roboref/features/teams/screens/team_list_screen.dart';
import 'package:roboref/features/teams/state/team_controller.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/features/settings/screens/settings_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase testDb;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    testDb = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  group('MatchScheduleScreen experimental features gating', () {
    testWidgets('hides import buttons when experimentalFeaturesEnabled is false', (tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'TEST-SKU',
        'experimental_features_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            activeTournamentMatchesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: MatchScheduleScreen(showAppBar: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Load / Import Schedule'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Fetch or Import Schedule'), findsNothing);
      expect(find.text('No match schedule has been loaded yet.'), findsOneWidget);
    });

    testWidgets('shows import buttons when experimentalFeaturesEnabled is true', (tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'TEST-SKU',
        'experimental_features_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            activeTournamentMatchesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: MatchScheduleScreen(showAppBar: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Load / Import Schedule'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Fetch or Import Schedule'), findsOneWidget);
    });
  });

  group('TeamListScreen experimental features gating', () {
    testWidgets('hides Load / Import Teams button when experimentalFeaturesEnabled is false', (tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'TEST-SKU',
        'experimental_features_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            activeTournamentTeamsProvider.overrideWith((ref) => Stream.value([])),
            activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: TeamListScreen(showAppBar: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Load / Import Teams'), findsNothing);
    });

    testWidgets('shows Load / Import Teams button when experimentalFeaturesEnabled is true', (tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'TEST-SKU',
        'experimental_features_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            activeTournamentTeamsProvider.overrideWith((ref) => Stream.value([])),
            activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: TeamListScreen(showAppBar: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Load / Import Teams'), findsOneWidget);
    });
  });

  group('EventWorkspaceScreen experimental features gating', () {
    testWidgets('hides header import buttons across tabs when experimentalFeaturesEnabled is false', (tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'TEST-SKU',
        'experimental_features_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            activeTournamentMatchesProvider.overrideWith((ref) => Stream.value([])),
            activeTournamentTeamsProvider.overrideWith((ref) => Stream.value([])),
            activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
            activeEventProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: EventWorkspaceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Matches tab (index 0)
      expect(find.byTooltip('Load / Import Schedule'), findsNothing);

      // Switch to Teams tab (index 1)
      await tester.tap(find.text('Teams'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Load / Import Teams'), findsNothing);
    });

    testWidgets('shows header import buttons across tabs when experimentalFeaturesEnabled is true', (tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'TEST-SKU',
        'experimental_features_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            activeTournamentMatchesProvider.overrideWith((ref) => Stream.value([])),
            activeTournamentTeamsProvider.overrideWith((ref) => Stream.value([])),
            activeTournamentNotesProvider.overrideWith((ref) => Stream.value([])),
            activeEventProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: EventWorkspaceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Matches tab (index 0)
      expect(find.byTooltip('Load / Import Schedule'), findsOneWidget);

      // Switch to Teams tab (index 1)
      await tester.tap(find.text('Teams'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Load / Import Teams'), findsOneWidget);
    });
  });

  group('SettingsScreen Experimental Features Flow', () {
    testWidgets('shows warning dialog on enabling and toggles visibility of TM CSV import', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'current_sku': 'TEST-SKU',
        'experimental_features_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state: Checkbox is unchecked, TM CSV button is absent
      final checkboxFinder = find.byType(CheckboxListTile);
      expect(checkboxFinder, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isFalse);
      expect(find.text('Import Event Data (TM CSV)'), findsNothing);

      // Tap checkbox to enable
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Warning dialog appears
      expect(find.text('Warning!  Experimental Features!'), findsOneWidget);
      expect(find.text('Ticking this will enable extra features that may not work as intended'), findsOneWidget);

      // Cancel keeps it disabled
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Warning!  Experimental Features!'), findsNothing);
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isFalse);
      expect(find.text('Import Event Data (TM CSV)'), findsNothing);

      // Tap checkbox again and confirm Enable
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Enable'));
      await tester.pumpAndSettle();

      // Checkbox is checked and button is revealed
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isTrue);
      expect(find.text('Import Event Data (TM CSV)'), findsOneWidget);

      // Untick disables immediately
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isFalse);
      expect(find.text('Import Event Data (TM CSV)'), findsNothing);
    });
  });
}
