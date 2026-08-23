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
  testWidgets('RoboRefApp initial screen smoke test', (WidgetTester tester) async {
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

    // Verify main header and navigation destinations are rendered
    expect(find.text('RoboRef'), findsOneWidget);
    expect(find.text('TEST-SKU-2026'), findsOneWidget);
    expect(find.text('Incidents'), findsOneWidget);
    expect(find.text('Teams'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await testDb.close();
  });
}
