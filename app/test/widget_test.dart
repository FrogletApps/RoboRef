import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roboref/main.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_data/services/vex_events_client.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('RoboRefApp Hierarchical Navigation test (Home Hub -> Event Workspace)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'current_sku': 'TEST-SKU-2026',
      'referee_name': 'Test Referee',
      'device_id': 'test-device-uuid',
      'server_url': 'http://127.0.0.1:8080',
    });

    final prefs = await SharedPreferences.getInstance();
    final testDb = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );

    final mockHttpClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 1,
              'sku': 'RE-V5RC-26-4487',
              'name': '2026 Regional Tournament',
              'program': {'code': 'V5RC'},
              'start': '2026-08-22T00:00:00Z',
              'end': '2026-08-23T00:00:00Z',
              'location': {'city': 'Beijing'},
            }
          ]
        }),
        200,
      );
    });

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(testDb),
        syncSettingsProvider.overrideWith((ref) => SyncSettingsNotifier(prefs, httpClient: mockHttpClient)),
        vexEventsClientProvider.overrideWithValue(
          VexEventsClient(
            client: mockHttpClient,
            serverUrl: 'http://127.0.0.1:8080',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RoboRefApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Home Screen has NO bottom navigation bar
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Incidents'), findsNothing);
    expect(find.text('Matches'), findsNothing);
    expect(find.text('Teams'), findsNothing);

    // Verify Home Screen quick actions and primary action
    expect(find.text('Change Log'), findsOneWidget);
    expect(find.text('Share RoboRef'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget); // In Quick Actions
    expect(find.text('Add a new event'), findsOneWidget);
    expect(find.text('Recent Tournaments'), findsNothing);
    expect(find.text('Browse All'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Welcome to RoboRef!'), findsOneWidget);

    // 2. Test navigating to Event Selection Screen
    await tester.tap(find.text('Add a new event'));
    await tester.pumpAndSettle();

    expect(find.text('Pick An Event'), findsOneWidget);
    expect(find.text('Search by SKU (RE-...) or event name'), findsOneWidget);

    // 3. Test selecting a live event
    expect(find.text('RE-V5RC-26-4487'), findsOneWidget);
    await tester.tap(find.text('RE-V5RC-26-4487'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify selecting an event immediately navigates to the Event Workspace displaying the 5 tabs in order
    expect(find.byType(NavigationBar), findsOneWidget);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 0); // Matches is default tab (index 0)
    expect(navBar.destinations.length, 5);
    expect((navBar.destinations[0] as NavigationDestination).label, 'Matches');
    expect((navBar.destinations[1] as NavigationDestination).label, 'Teams');
    expect((navBar.destinations[2] as NavigationDestination).label, 'Incidents');
    expect((navBar.destinations[3] as NavigationDestination).label, 'Rules');
    expect((navBar.destinations[4] as NavigationDestination).label, 'Manage');

    expect(find.text('Match Schedule'), findsOneWidget);

    // 4. Test navigating back to Home Hub
    await tester.pageBack();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Verify returning to home and recent list displays the selected tournament with header
    expect(find.text('Recent Tournaments'), findsOneWidget);
    expect(find.widgetWithText(Card, 'RE-V5RC-26-4487'), findsOneWidget);
    expect(find.text('ACTIVE'), findsNothing);
    expect(find.text('Welcome to RoboRef!'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing); // Back on Home screen without bottom nav

    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
