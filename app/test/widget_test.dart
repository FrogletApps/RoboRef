import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:roboref/main.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  testWidgets('RoboRefApp HomeScreen initial render test', (WidgetTester tester) async {
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const RoboRefApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify navigation bar destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Incidents'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
    expect(find.text('Teams'), findsOneWidget);
    expect(find.text('Settings'), findsNWidgets(2)); // One in Quick Actions, one in Bottom Navigation

    // Verify Home Screen quick actions and primary action
    expect(find.text('Change Log'), findsOneWidget);
    expect(find.text('Share RoboRef'), findsOneWidget);
    expect(find.text('Add a new event'), findsOneWidget);
    expect(find.text('Recent Tournaments'), findsOneWidget);
    expect(find.text('Welcome to RoboRef!'), findsOneWidget);

    // Test navigating to Event Selection Screen
    await tester.tap(find.text('Add a new event'));
    await tester.pumpAndSettle();

    expect(find.text('Pick An Event'), findsOneWidget);
    expect(find.text('Search by SKU (RE-...) or event name'), findsOneWidget);

    // Test selecting a preloaded championship event
    expect(find.text('RE-V5RC-24-8909'), findsOneWidget);
    await tester.tap(find.text('RE-V5RC-24-8909'));
    await tester.pumpAndSettle();

    // Verify returning to home and recent list displays the selected tournament
    expect(find.text('RE-V5RC-24-8909'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);

    await testDb.close();
  });
}
