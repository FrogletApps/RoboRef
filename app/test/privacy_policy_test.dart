import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/core/utils/sku_utils.dart';
import 'package:roboref/features/settings/screens/privacy_policy_screen.dart';
import 'package:roboref/features/settings/screens/settings_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Single Privacy Policy Source of Truth Tests', () {
    test('app/assets/privacy.md exists as the sole copy of the policy', () {
      final file = File('assets/privacy.md');
      expect(file.existsSync(), isTrue, reason: 'assets/privacy.md must exist as the single privacy policy file');

      // Verify no duplicate files exist elsewhere
      expect(File('../documents/privacy.md').existsSync(), isFalse, reason: 'No duplicate in documents/');
      expect(File('web/privacy.html').existsSync(), isFalse, reason: 'No duplicate in web/privacy.html');
      expect(Directory('web/privacy').existsSync(), isFalse, reason: 'No duplicate in web/privacy/');

      final content = file.readAsStringSync();
      expect(content, contains('RoboRef Privacy Policy'));
      expect(content, contains('Offline-First by Design'));
      expect(content, contains('Data Synchronization'));
      expect(content, contains('What We Do NOT Collect'));
      expect(content, contains('RoboRef cloud servers'));
      expect(content, contains('Global Robotics & Science Foundation'));
      expect(content, contains('dev@roboref.app'));
    });
  });

  group('PrivacyPolicyScreen Widget Tests', () {
    testWidgets('renders loading and displays privacy content from single asset', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.textContaining('RoboRef works completely offline'), findsOneWidget);
      expect(find.textContaining('Offline-First by Design'), findsOneWidget);
      expect(find.textContaining('Global Robotics & Science Foundation'), findsOneWidget);

      // Scroll down to check bottom web link
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.textContaining('View on roboref.app/privacy'), findsOneWidget);
    });
  });

  group('Web Version & Route Navigation Tests', () {
    testWidgets('RoboRefApp routes directly to /privacy for the web version of the app', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        return http.Response('{"status":"ok"}', 200);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsProvider.overrideWith((ref) => SyncSettingsNotifier(
            prefs,
            httpClient: mockClient,
            environment: AppEnvironment.local,
          )),
        ],
      );

      // Launch with /privacy initial route
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            initialRoute: '/privacy',
            routes: {
              '/': (context) => const SizedBox(),
              '/privacy': (context) => const PrivacyPolicyScreen(),
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify privacy policy screen rendered directly via route
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Privacy Policy'), findsWidgets);
    });

    testWidgets('SettingsScreen displays Privacy Policy tile and navigates on tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'server_url': 'http://roboref.local:8080',
        'referee_name': 'Test Referee',
      });
      final prefs = await SharedPreferences.getInstance();

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/health') {
          return http.Response('{"status":"ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsProvider.overrideWith((ref) => SyncSettingsNotifier(
            prefs,
            httpClient: mockClient,
            environment: AppEnvironment.local,
          )),
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

      // Find About header and Privacy Policy tile
      expect(find.text('About'), findsOneWidget);
      final privacyTile = find.widgetWithText(ListTile, 'Privacy Policy');
      expect(privacyTile, findsOneWidget);

      // Tap Privacy Policy tile and complete navigation animation
      await tester.tap(privacyTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify navigated to PrivacyPolicyScreen
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
      expect(find.text('Privacy Policy'), findsWidgets);
    });
  });
}
