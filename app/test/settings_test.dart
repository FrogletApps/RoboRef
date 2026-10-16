import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roboref/core/utils/sku_utils.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/home/screens/changelog_screen.dart';
import 'package:roboref/features/settings/screens/settings_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('URI Helper & URL Normalization', () {
    test('buildHealthCheckUri formats candidate endpoints correctly', () {
      expect(
        buildHealthCheckUri('http://roboref.local:8080')?.toString(),
        equals('http://roboref.local:8080/api/health'),
      );
      expect(
        buildHealthCheckUri('http://localhost:8080')?.toString(),
        equals('http://localhost:8080/api/health'),
      );
      expect(
        buildHealthCheckUri('http://roboref.local:8080/')?.toString(),
        equals('http://roboref.local:8080/api/health'),
      );
      expect(
        buildHealthCheckUri('roboref.local:8080')?.toString(),
        equals('http://roboref.local:8080/api/health'),
      );
      expect(
        buildHealthCheckUri('https://test.roboref.app')?.toString(),
        equals('https://test.roboref.app/api/health'),
      );
      expect(
        buildHealthCheckUri('https://test.roboref.app/api/health')?.toString(),
        equals('https://test.roboref.app/api/health'),
      );
      expect(buildHealthCheckUri(''), isNull);
      expect(buildHealthCheckUri('   '), isNull);
    });

    test('resolveDefaultServerUrl returns http://localhost:8080 for local environment', () {
      expect(
        resolveDefaultServerUrl(environment: AppEnvironment.local, isWeb: false),
        equals('http://localhost:8080'),
      );
    });

    test('resolveDefaultServerUrl returns https://test.roboref.app for test environment', () {
      expect(
        resolveDefaultServerUrl(environment: AppEnvironment.test, isWeb: false),
        equals('https://test.roboref.app'),
      );
    });

    test('resolveDefaultServerUrl returns https://roboref.app for production environment', () {
      expect(
        resolveDefaultServerUrl(environment: AppEnvironment.production, isWeb: false),
        equals('https://roboref.app'),
      );
      expect(
        resolveDefaultServerUrl(
          environment: AppEnvironment.production,
          isWeb: true,
          webOrigin: 'https://roboref.app',
        ),
        equals('https://roboref.app'),
      );
    });

    test('resolveDefaultServerUrl honors event-specific stored preferences over global preferences', () async {
      SharedPreferences.setMockInitialValues({
        'server_url': 'https://roboref.app',
        'server_url_RE-V5RC-24-1234': 'http://192.168.1.99:8080',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(
        resolveDefaultServerUrl(prefs: prefs, sku: 'RE-V5RC-24-1234'),
        equals('http://192.168.1.99:8080'),
      );
      expect(
        resolveDefaultServerUrl(prefs: prefs, sku: 'RE-V5RC-24-9999'),
        equals('https://roboref.app'),
      );
    });

    test('SyncSettingsNotifier updates and saves serverUrl per event SKU', () async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'SKU-A',
        'server_url_SKU-A': 'http://server-a.local:8080',
        'server_url_SKU-B': 'http://server-b.local:8080',
      });
      final testPrefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(testPrefs),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(syncSettingsProvider.notifier);
      expect(container.read(syncSettingsProvider).currentSku, equals('SKU-A'));
      expect(container.read(syncSettingsProvider).serverUrl, equals('http://server-a.local:8080'));

      notifier.setSku('SKU-B');
      expect(container.read(syncSettingsProvider).currentSku, equals('SKU-B'));
      expect(container.read(syncSettingsProvider).serverUrl, equals('http://server-b.local:8080'));

      notifier.setServerUrl('http://new-b.local:8080');
      expect(container.read(syncSettingsProvider).serverUrl, equals('http://new-b.local:8080'));
      expect(testPrefs.getString('server_url_SKU-B'), equals('http://new-b.local:8080'));

      notifier.setSku('SKU-A');
      expect(container.read(syncSettingsProvider).serverUrl, equals('http://server-a.local:8080'));
    });
  });

  group('SyncSettingsNotifier Server Health Checks', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'server_url': 'http://roboref.local:8080',
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
      });
      prefs = await SharedPreferences.getInstance();
    });

    test('successfully detects Venue LAN connection (HTTP 200)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(syncSettingsProvider.notifier);
      final result = await notifier.checkServerHealth('http://roboref.local:8080');

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(ServerConnectionStatus.connectedLocal));
      expect(result.message, contains('Venue LAN'));
      expect(container.read(syncSettingsProvider).connectionStatus, equals(ServerConnectionStatus.connectedLocal));
      expect(container.read(syncSettingsProvider).lastConnectionSuccess, isTrue);
      expect(container.read(syncSettingsProvider).lastConnectionMessage, contains('Venue LAN'));
    });

    test('successfully detects Localhost Server connection (HTTP 200)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(syncSettingsProvider.notifier);
      final result = await notifier.checkServerHealth('http://localhost:8080');

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(ServerConnectionStatus.connectedLocal));
      expect(result.message, contains('Local Server'));
      expect(container.read(syncSettingsProvider).connectionStatus, equals(ServerConnectionStatus.connectedLocal));
      expect(container.read(syncSettingsProvider).lastConnectionSuccess, isTrue);
      expect(container.read(syncSettingsProvider).lastConnectionMessage, contains('Local Server'));
    });

    test('successfully detects Cloud Server connection (HTTP 200)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(syncSettingsProvider.notifier);
      final result = await notifier.checkServerHealth('https://test.roboref.app');

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(ServerConnectionStatus.connectedCloud));
      expect(result.message, contains('Cloud Server'));
      expect(container.read(syncSettingsProvider).connectionStatus, equals(ServerConnectionStatus.connectedCloud));
      expect(container.read(syncSettingsProvider).lastConnectionSuccess, isTrue);
      expect(container.read(syncSettingsProvider).lastConnectionMessage, contains('Cloud Server'));
    });

    test('handles HTTP 500 error response gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(syncSettingsProvider.notifier);
      final result = await notifier.checkServerHealth('http://roboref.local:8080');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(ServerConnectionStatus.unreachable));
      expect(result.message, contains('500'));
      expect(container.read(syncSettingsProvider).connectionStatus, equals(ServerConnectionStatus.unreachable));
      expect(container.read(syncSettingsProvider).lastConnectionSuccess, isFalse);
    });

    test('handles TimeoutException / network failure gracefully', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Connection timed out');
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(syncSettingsProvider.notifier);
      final result = await notifier.checkServerHealth('http://roboref.local:8080');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(ServerConnectionStatus.unreachable));
      expect(result.message, contains('timed out'));
      expect(container.read(syncSettingsProvider).connectionStatus, equals(ServerConnectionStatus.unreachable));
      expect(container.read(syncSettingsProvider).lastConnectionSuccess, isFalse);
    });

    test('handles empty server URL gracefully', () async {
      final mockClient = MockClient((request) async => http.Response('ok', 200));
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(syncSettingsProvider.notifier);
      final result = await notifier.checkServerHealth('');

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('empty'));
      expect(container.read(syncSettingsProvider).connectionStatus, equals(ServerConnectionStatus.unreachable));
    });
  });

  group('SettingsScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'server_url': 'http://roboref.local:8080',
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('event manage page when shared as admin renders dropdown mode, switches to custom URL, and tests connection', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(true),
          shareId: const Value('ABC123'),
          shareRole: const Value('admin'),
        ),
      );

      int healthRequests = 0;
      final completer = Completer<http.Response>();
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          healthRequests++;
          if (healthRequests == 1) {
            return http.Response('{"status":"ok"}', 200);
          }
          return await completer.future;
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Dropdown exists
      expect(find.text('Sync Server Mode'), findsOneWidget);

      // Custom URL field should not be visible when Venue LAN is selected
      expect(find.text('Custom Server URL'), findsNothing);

      // 2. Select Custom option from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom Server URL').last);
      await tester.pumpAndSettle();

      // Custom URL textfield should now appear
      expect(find.widgetWithText(TextField, 'Custom Server URL'), findsOneWidget);

      // 3. Tap Test Connection and verify in-flight and success state
      final testConnFinder = find.byIcon(Icons.wifi_find);
      expect(testConnFinder, findsOneWidget);
      await tester.tap(testConnFinder);
      await tester.pump(); // In-flight

      // Progress message should be displayed while request is in flight
      expect(find.textContaining('Testing connection'), findsOneWidget);

      // Complete async request
      completer.complete(http.Response('{"status":"ok"}', 200));
      await tester.pumpAndSettle();

      // Verify success SnackBar is displayed
      expect(find.textContaining('Connection successful'), findsOneWidget);
    });

    testWidgets('shows failure SnackBar when connection test fails on event manage page as admin', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(true),
          shareId: const Value('ABC123'),
          shareRole: const Value('admin'),
        ),
      );

      final failingClient = MockClient((request) async {
        throw TimeoutException('Network unreachable');
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsHttpClientProvider.overrideWithValue(failingClient),
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final testConnFinder = find.byIcon(Icons.wifi_find);
      expect(testConnFinder, findsOneWidget);

      await tester.tap(testConnFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify failure SnackBar is displayed
      expect(find.textContaining('Connection failed'), findsOneWidget);
    });

    testWidgets('event manage page when unshared displays Sharing Not Enabled card and hides Sync Server Configuration', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(false),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sharing Not Enabled'), findsOneWidget);
      expect(find.text('Share Event Online'), findsOneWidget);
      expect(find.text('Sync Server Configuration'), findsNothing);
      expect(find.text('Sync Server Mode'), findsNothing);
    });

    testWidgets('event manage page when shared as member displays host-managed banner and read-only server URL', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(true),
          shareId: const Value('ABC123'),
          shareRole: const Value('member'),
          adminRefereeName: const Value('Lead Host'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sync Server Configuration'), findsOneWidget);
      expect(find.textContaining('Managed by Host (Lead Host)'), findsOneWidget);
      expect(find.text('Sync Server Mode'), findsNothing); // Admin only
      expect(find.widgetWithText(ElevatedButton, 'Sync Now'), findsOneWidget);
    });

    testWidgets('renders main settings page without Sync Server Configuration', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Referee Setup is present
      expect(find.text('Referee Setup'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Referee Display Name'), findsOneWidget);

      // Verify Tournament SKU field is NOT present
      expect(find.widgetWithText(TextField, 'Tournament SKU'), findsNothing);
      expect(find.text('Tournament & Referee Setup'), findsNothing);

      // Verify Sync Server Configuration section is NOT present on main settings page
      expect(find.text('Sync Server Configuration'), findsNothing);
      expect(find.text('Sync Server Mode'), findsNothing);
      expect(find.byIcon(Icons.wifi_find), findsNothing);
    });

    testWidgets('defaults to Custom Server URL on event manage page when running on local system without saved preference', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
        // No server_url stored
      });
      final freshPrefs = await SharedPreferences.getInstance();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(true),
          shareId: const Value('ABC123'),
          shareRole: const Value('admin'),
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(freshPrefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
          syncSettingsEnvironmentProvider.overrideWithValue(AppEnvironment.local),
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Dropdown defaults to Custom Server URL
      expect(find.text('Custom Server URL'), findsWidgets);

      // Custom URL text field should be visible with default value http://localhost:8080
      final customFieldFinder = find.widgetWithText(TextField, 'Custom Server URL');
      expect(customFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(customFieldFinder);
      expect(textField.controller?.text, equals('http://localhost:8080'));
    });

    testWidgets('defaults to Cloud Server on event manage page when running in production without saved preference', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
        // No server_url stored
      });
      final freshPrefs = await SharedPreferences.getInstance();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(true),
          shareId: const Value('ABC123'),
          shareRole: const Value('admin'),
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(freshPrefs),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
          syncSettingsEnvironmentProvider.overrideWithValue(AppEnvironment.production),
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Dropdown displays Cloud Server (https://roboref.app)
      expect(find.text('Cloud Server (https://roboref.app)'), findsOneWidget);

      // Custom URL textfield should NOT be displayed when Cloud Server is selected
      expect(find.widgetWithText(TextField, 'Custom Server URL'), findsNothing);

      // Experimental features toggle should NOT be displayed in live releases
      expect(find.text('Experimental Features'), findsNothing);
      expect(find.text('Enable extra features that may not work as intended'), findsNothing);
    });

    testWidgets('displays "About RoboRef" and does NOT display "Event Information" when on general settings', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find About RoboRef label
      expect(find.text('About RoboRef'), findsOneWidget);
      // "Event Information" and "VEX Events Page" should not be present
      expect(find.text('Event Information'), findsNothing);
      expect(find.text('VEX Events Page'), findsNothing);
    });

    testWidgets('displays "Event Information" section above "About RoboRef" with "VEX Events Page" tile when on event manage page', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both sections must exist
      expect(find.text('Event Information'), findsOneWidget);
      expect(find.text('About RoboRef'), findsOneWidget);

      // Verify "Event Information" appears above "About RoboRef"
      final eventInfoPos = tester.getTopLeft(find.text('Event Information')).dy;
      final aboutPos = tester.getTopLeft(find.text('About RoboRef')).dy;
      expect(eventInfoPos, lessThan(aboutPos), reason: 'Event Information must be positioned above About RoboRef');

      // VEX Events Page tile exists and has public icon
      final vexEventsTile = find.widgetWithText(ListTile, 'VEX Events Page');
      expect(vexEventsTile, findsOneWidget);
      expect(find.descendant(of: vexEventsTile, matching: find.byIcon(Icons.public)), findsOneWidget);

      // Tap VEX Events Page tile
      await tester.tap(vexEventsTile);
      await tester.pump();
    });

    testWidgets('toggling Experimental Features prompts confirmation warning and gates Import Event Data', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
        'experimental_features_enabled': false,
      });
      final freshPrefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(freshPrefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Checkbox is present and unchecked
      final checkboxFinder = find.byType(CheckboxListTile);
      expect(checkboxFinder, findsOneWidget);
      final checkboxWidget = tester.widget<CheckboxListTile>(checkboxFinder);
      expect(checkboxWidget.value, isFalse);

      // Import Event Data button is not present
      expect(find.text('Import Event Data'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Import Event Data (TM CSV)'), findsNothing);

      // Tap the checkbox to enable
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed with required warning text
      expect(find.text('Warning!  Experimental Features!'), findsOneWidget);
      expect(find.text('Ticking this will enable extra features that may not work as intended'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Enable'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed, still unchecked, Import Event Data still hidden
      expect(find.text('Warning!  Experimental Features!'), findsNothing);
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isFalse);
      expect(find.text('Import Event Data'), findsNothing);
      expect(container.read(syncSettingsProvider).experimentalFeaturesEnabled, isFalse);

      // Tap checkbox again, this time tap Enable
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(find.text('Warning!  Experimental Features!'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Enable'));
      await tester.pumpAndSettle();

      // Now experimentalFeaturesEnabled is true
      expect(container.read(syncSettingsProvider).experimentalFeaturesEnabled, isTrue);
      expect(freshPrefs.getBool('experimental_features_enabled'), isTrue);
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isTrue);

      // Import Event Data section and button are now revealed
      expect(find.text('Import Event Data'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Import Event Data (TM CSV)'), findsOneWidget);

      // Tap checkbox again to uncheck (should disable immediately without dialog)
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      expect(find.text('Warning!  Experimental Features!'), findsNothing);
      expect(container.read(syncSettingsProvider).experimentalFeaturesEnabled, isFalse);
      expect(freshPrefs.getBool('experimental_features_enabled'), isFalse);
      expect(find.text('Import Event Data'), findsNothing);
    });
  });

  group('SyncSettingsNotifier Experimental Features Unit Tests', () {
    test('defaults to false and toggles state with persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final notifier = container.read(syncSettingsProvider.notifier);
      expect(container.read(syncSettingsProvider).experimentalFeaturesEnabled, isFalse);

      notifier.setExperimentalFeaturesEnabled(true);
      expect(container.read(syncSettingsProvider).experimentalFeaturesEnabled, isTrue);
      expect(prefs.getBool('experimental_features_enabled'), isTrue);

      notifier.setExperimentalFeaturesEnabled(false);
      expect(container.read(syncSettingsProvider).experimentalFeaturesEnabled, isFalse);
      expect(prefs.getBool('experimental_features_enabled'), isFalse);
    });
  });

  group('SettingsScreen About RoboRef Section Tests', () {
    testWidgets('displays version card, Change Log tile, and Privacy Policy tile', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      PackageInfo.setMockInitialValues(
        appName: 'RoboRef',
        packageName: 'app.roboref',
        version: '2026.10.11',
        buildNumber: '157',
        buildSignature: '',
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About RoboRef'), findsOneWidget);
      expect(find.text('Current Version'), findsOneWidget);
      expect(find.text('v2026.10.11+157'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Change Log'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Privacy Policy'), findsOneWidget);
    });

    testWidgets('copies version to clipboard when copy button is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(
              overrideVersion: '2026.10.11+999',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('v2026.10.11+999'), findsOneWidget);

      final copyButton = find.widgetWithText(TextButton, 'Copy');
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump();

      expect(find.text('Version copied to clipboard'), findsOneWidget);
    });

    testWidgets('adapts version card layout responsively across wide, medium, and small screens (DPR 2.75, width < 330px)', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      // 1. Wide screen (800px) - Single line layout: RELEASE + Version on left, Copy button on right
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(overrideVersion: '2026.10.16+167'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final releaseFinder = find.text('RELEASE');
      final versionFinder = find.text('v2026.10.16+167');
      final copyBtnFinder = find.widgetWithText(TextButton, 'Copy');

      expect(releaseFinder, findsOneWidget);
      expect(versionFinder, findsOneWidget);
      expect(copyBtnFinder, findsOneWidget);

      final releasePosWide = tester.getTopLeft(releaseFinder);
      final versionPosWide = tester.getTopLeft(versionFinder);
      final copyPosWide = tester.getTopLeft(copyBtnFinder);

      // On wide screen, RELEASE and version are horizontally arranged next to each other on the same line
      expect((releasePosWide.dy - versionPosWide.dy).abs(), lessThan(10.0));
      expect(releasePosWide.dx, lessThan(versionPosWide.dx));
      expect(versionPosWide.dx, lessThan(copyPosWide.dx));

      // 2. Medium screen (500px in test environment with Ahem font) - RELEASE text goes above version / copy row
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final releasePosMedium = tester.getTopLeft(releaseFinder);
      final versionPosMedium = tester.getTopLeft(versionFinder);
      final copyPosMedium = tester.getTopLeft(copyBtnFinder);

      // RELEASE is above version and copy button
      expect(releasePosMedium.dy, lessThan(versionPosMedium.dy));
      // Version and copy button share the same row
      expect((versionPosMedium.dy - copyPosMedium.dy).abs(), lessThan(10.0));
      expect(versionPosMedium.dx, lessThan(copyPosMedium.dx));

      // 3. Small screen with DPR 2.75 and horizontal resolution < 330px (e.g. 320px)
      // RELEASE above version, and copy button on another line below that
      tester.view.physicalSize = const Size(320 * 2.75, 1200 * 2.75);
      tester.view.devicePixelRatio = 2.75;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final releasePosSmall = tester.getTopLeft(releaseFinder);
      final versionPosSmall = tester.getTopLeft(versionFinder);
      final copyPosSmall = tester.getTopLeft(copyBtnFinder);

      // Stage 3 vertical hierarchy: RELEASE < version < Copy button
      expect(releasePosSmall.dy, lessThan(versionPosSmall.dy));
      expect(versionPosSmall.dy, lessThan(copyPosSmall.dy));

      // Tap Copy button in small screen layout and verify copying works
      await tester.tap(copyBtnFinder);
      await tester.pump();
      expect(find.text('Version copied to clipboard'), findsOneWidget);
    });

    testWidgets('navigates to ChangeLogScreen when Change Log tile is tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final changelogTile = find.widgetWithText(ListTile, 'Change Log');
      expect(changelogTile, findsOneWidget);

      await tester.tap(changelogTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ChangeLogScreen), findsOneWidget);
      expect(find.text('Change Log'), findsWidgets);
    });
  });

  group('SettingsScreen Sync & Sharing and Section Order Tests', () {
    testWidgets('does not display Advanced Settings label on main settings in test env without Sync Server', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsEnvironmentProvider.overrideWithValue(AppEnvironment.test),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Advanced Settings'), findsNothing);
      expect(find.text('About RoboRef'), findsOneWidget);
      expect(find.text('Sync Server Configuration'), findsNothing);
      expect(find.text('Sync & Sharing'), findsNothing);
      expect(find.text('Event Information'), findsNothing);
      expect(find.text('Experimental Features'), findsOneWidget);

      // On main settings page in test env:
      // Dividers between: Appearance & Referee Setup, Referee Setup & About RoboRef, About RoboRef & Experimental Features
      expect(find.byType(Divider), findsNWidgets(3));
      final appearancePos = tester.getTopLeft(find.text('Appearance')).dy;
      final refereePos = tester.getTopLeft(find.text('Referee Setup')).dy;
      final aboutPos = tester.getTopLeft(find.text('About RoboRef')).dy;
      final experimentalPos = tester.getTopLeft(find.text('Experimental Features')).dy;

      final divider0Pos = tester.getTopLeft(find.byType(Divider).at(0)).dy;
      final divider1Pos = tester.getTopLeft(find.byType(Divider).at(1)).dy;
      final divider2Pos = tester.getTopLeft(find.byType(Divider).at(2)).dy;

      expect(appearancePos, lessThan(divider0Pos));
      expect(divider0Pos, lessThan(refereePos));
      expect(refereePos, lessThan(divider1Pos));
      expect(divider1Pos, lessThan(aboutPos));
      expect(aboutPos, lessThan(divider2Pos));
      expect(divider2Pos, lessThan(experimentalPos));
    });

    testWidgets('displays dividers between all sections on event manage page when shared', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
      });
      final prefs = await SharedPreferences.getInstance();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(true),
          shareId: const Value('ABC123'),
          shareRole: const Value('admin'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsEnvironmentProvider.overrideWithValue(AppEnvironment.production),
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Advanced Settings'), findsNothing);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Referee Setup'), findsOneWidget);
      expect(find.text('Sync Server Configuration'), findsOneWidget);
      expect(find.text('Event Information'), findsOneWidget);
      expect(find.text('About RoboRef'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(4));

      final appearancePos = tester.getTopLeft(find.text('Appearance')).dy;
      final refereePos = tester.getTopLeft(find.text('Referee Setup')).dy;
      final syncServerPos = tester.getTopLeft(find.text('Sync Server Configuration')).dy;
      final eventInfoPos = tester.getTopLeft(find.text('Event Information')).dy;
      final aboutPos = tester.getTopLeft(find.text('About RoboRef')).dy;

      final divider0Pos = tester.getTopLeft(find.byType(Divider).at(0)).dy;
      final divider1Pos = tester.getTopLeft(find.byType(Divider).at(1)).dy;
      final divider2Pos = tester.getTopLeft(find.byType(Divider).at(2)).dy;
      final divider3Pos = tester.getTopLeft(find.byType(Divider).at(3)).dy;

      expect(appearancePos, lessThan(divider0Pos), reason: 'Appearance must be above Divider 0');
      expect(divider0Pos, lessThan(refereePos), reason: 'Divider 0 must be above Referee Setup');
      expect(refereePos, lessThan(divider1Pos), reason: 'Referee Setup must be above Divider 1');
      expect(divider1Pos, lessThan(syncServerPos), reason: 'Divider 1 must be above Sync Server Configuration');
      expect(syncServerPos, lessThan(divider2Pos), reason: 'Sync Server Configuration must be above Divider 2');
      expect(divider2Pos, lessThan(eventInfoPos), reason: 'Divider 2 must be above Event Information');
      expect(eventInfoPos, lessThan(divider3Pos), reason: 'Event Information must be above Divider 3');
      expect(divider3Pos, lessThan(aboutPos), reason: 'Divider 3 must be above About RoboRef');
    });

    testWidgets('displays dividers between all sections on event manage page when not shared', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
      });
      final prefs = await SharedPreferences.getInstance();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-1234',
          name: 'Test Tournament',
          program: 'V5RC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: 1000,
          isShared: const Value(false),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsEnvironmentProvider.overrideWithValue(AppEnvironment.production),
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(isEventManagePage: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Advanced Settings'), findsNothing);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Referee Setup'), findsOneWidget);
      expect(find.text('Sync & Sharing'), findsOneWidget);
      expect(find.text('Sharing Not Enabled'), findsOneWidget);
      expect(find.text('Event Information'), findsOneWidget);
      expect(find.text('About RoboRef'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(4));

      final appearancePos = tester.getTopLeft(find.text('Appearance')).dy;
      final refereePos = tester.getTopLeft(find.text('Referee Setup')).dy;
      final syncSharingPos = tester.getTopLeft(find.text('Sync & Sharing')).dy;
      final eventInfoPos = tester.getTopLeft(find.text('Event Information')).dy;
      final aboutPos = tester.getTopLeft(find.text('About RoboRef')).dy;

      final divider0Pos = tester.getTopLeft(find.byType(Divider).at(0)).dy;
      final divider1Pos = tester.getTopLeft(find.byType(Divider).at(1)).dy;
      final divider2Pos = tester.getTopLeft(find.byType(Divider).at(2)).dy;
      final divider3Pos = tester.getTopLeft(find.byType(Divider).at(3)).dy;

      expect(appearancePos, lessThan(divider0Pos), reason: 'Appearance must be above Divider 0');
      expect(divider0Pos, lessThan(refereePos), reason: 'Divider 0 must be above Referee Setup');
      expect(refereePos, lessThan(divider1Pos), reason: 'Referee Setup must be above Divider 1');
      expect(divider1Pos, lessThan(syncSharingPos), reason: 'Divider 1 must be above Sync & Sharing');
      expect(syncSharingPos, lessThan(divider2Pos), reason: 'Sync & Sharing must be above Divider 2');
      expect(divider2Pos, lessThan(eventInfoPos), reason: 'Divider 2 must be above Event Information');
      expect(eventInfoPos, lessThan(divider3Pos), reason: 'Event Information must be above Divider 3');
      expect(divider3Pos, lessThan(aboutPos), reason: 'Divider 3 must be above About RoboRef');
    });
  });
}

