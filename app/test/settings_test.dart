import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      final notifier = SyncSettingsNotifier(prefs, httpClient: mockClient);
      final result = await notifier.checkServerHealth('http://roboref.local:8080');

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(ServerConnectionStatus.connectedLocal));
      expect(result.message, contains('Venue LAN'));
      expect(notifier.state.connectionStatus, equals(ServerConnectionStatus.connectedLocal));
      expect(notifier.state.lastConnectionSuccess, isTrue);
      expect(notifier.state.lastConnectionMessage, contains('Venue LAN'));
    });

    test('successfully detects Cloud Server connection (HTTP 200)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final notifier = SyncSettingsNotifier(prefs, httpClient: mockClient);
      final result = await notifier.checkServerHealth('https://test.roboref.app');

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(ServerConnectionStatus.connectedCloud));
      expect(result.message, contains('Cloud Server'));
      expect(notifier.state.connectionStatus, equals(ServerConnectionStatus.connectedCloud));
      expect(notifier.state.lastConnectionSuccess, isTrue);
      expect(notifier.state.lastConnectionMessage, contains('Cloud Server'));
    });

    test('handles HTTP 500 error response gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final notifier = SyncSettingsNotifier(prefs, httpClient: mockClient);
      final result = await notifier.checkServerHealth('http://roboref.local:8080');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(ServerConnectionStatus.unreachable));
      expect(result.message, contains('500'));
      expect(notifier.state.connectionStatus, equals(ServerConnectionStatus.unreachable));
      expect(notifier.state.lastConnectionSuccess, isFalse);
    });

    test('handles TimeoutException / network failure gracefully', () async {
      final mockClient = MockClient((request) async {
        throw TimeoutException('Connection timed out');
      });

      final notifier = SyncSettingsNotifier(prefs, httpClient: mockClient);
      final result = await notifier.checkServerHealth('http://roboref.local:8080');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(ServerConnectionStatus.unreachable));
      expect(result.message, contains('timed out'));
      expect(notifier.state.connectionStatus, equals(ServerConnectionStatus.unreachable));
      expect(notifier.state.lastConnectionSuccess, isFalse);
    });

    test('handles empty server URL gracefully', () async {
      final mockClient = MockClient((request) async => http.Response('ok', 200));
      final notifier = SyncSettingsNotifier(prefs, httpClient: mockClient);
      final result = await notifier.checkServerHealth('');

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('empty'));
      expect(notifier.state.connectionStatus, equals(ServerConnectionStatus.unreachable));
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

    testWidgets('renders dropdown mode, switches to custom URL, and tests connection', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsProvider.overrideWith((ref) => SyncSettingsNotifier(prefs, httpClient: mockClient)),
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
      final completer = Completer<http.Response>();
      final asyncClient = MockClient((request) async {
        return await completer.future;
      });

      final asyncContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsProvider.overrideWith((ref) => SyncSettingsNotifier(prefs, httpClient: asyncClient)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: asyncContainer,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap test connection
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

    testWidgets('shows failure SnackBar when connection test fails', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final failingClient = MockClient((request) async {
        throw TimeoutException('Network unreachable');
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsProvider.overrideWith((ref) => SyncSettingsNotifier(prefs, httpClient: failingClient)),
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

      final testConnFinder = find.byIcon(Icons.wifi_find);
      expect(testConnFinder, findsOneWidget);

      await tester.tap(testConnFinder);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify failure SnackBar is displayed
      expect(find.textContaining('Connection failed'), findsOneWidget);
    });

    testWidgets('renders Referee Setup section without Tournament SKU field', (tester) async {
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

      // Verify Import Event Data section
      expect(find.text('Import Event Data'), findsOneWidget);
      expect(find.text('This feature is experimental and may not work as intended'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Import Event Data (VEXEvents & TM CSV)'), findsOneWidget);

      // Verify Sync Server Configuration section
      expect(find.text('Sync Server Configuration'), findsOneWidget);
      expect(find.text('Connect to the cloud server or a server on your local network'), findsOneWidget);
      expect(find.text('Local Server (http://roboref.local:8080)'), findsOneWidget);
    });
  });
}
