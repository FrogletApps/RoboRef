import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/core/theme/theme_controller.dart';
import 'package:roboref/features/settings/screens/settings_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:roboref/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeNotifier Unit Tests', () {
    test('defaults to ThemeMode.system when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = ThemeModeNotifier(prefs);
      expect(notifier.state, equals(ThemeMode.system));
    });

    test('loads saved light theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();

      final notifier = ThemeModeNotifier(prefs);
      expect(notifier.state, equals(ThemeMode.light));
    });

    test('loads saved dark theme mode from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
      final prefs = await SharedPreferences.getInstance();

      final notifier = ThemeModeNotifier(prefs);
      expect(notifier.state, equals(ThemeMode.dark));
    });

    test('setThemeMode updates state and persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final notifier = ThemeModeNotifier(prefs);
      expect(notifier.state, equals(ThemeMode.system));

      notifier.setThemeMode(ThemeMode.light);
      expect(notifier.state, equals(ThemeMode.light));
      expect(prefs.getString('theme_mode'), equals('light'));

      notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, equals(ThemeMode.dark));
      expect(prefs.getString('theme_mode'), equals('dark'));

      notifier.setThemeMode(ThemeMode.system);
      expect(notifier.state, equals(ThemeMode.system));
      expect(prefs.getString('theme_mode'), equals('system'));
    });
  });

  group('Theme Switcher Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'server_url': 'http://roboref.local:8080',
        'current_sku': 'RE-V5RC-24-1234',
        'referee_name': 'Test Referee',
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('renders Appearance section and allows switching themes in SettingsScreen', (tester) async {
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

      // Verify Appearance header and SegmentedButton options exist
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Device'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Verify initial default is system/Device
      expect(container.read(themeModeProvider), equals(ThemeMode.system));

      // Tap Light option
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(prefs.getString('theme_mode'), equals('light'));

      // Tap Dark option
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(prefs.getString('theme_mode'), equals('dark'));

      // Tap Device option
      await tester.tap(find.text('Device'));
      await tester.pumpAndSettle();

      expect(container.read(themeModeProvider), equals(ThemeMode.system));
      expect(prefs.getString('theme_mode'), equals('system'));

      container.dispose();
    });

    testWidgets('RoboRefApp reacts to themeModeProvider updates', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const RoboRefApp(),
        ),
      );
      await tester.pumpAndSettle();

      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
      MaterialApp app = tester.widget(materialAppFinder);
      expect(app.themeMode, equals(ThemeMode.system));

      // Update provider to light mode
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      app = tester.widget(materialAppFinder);
      expect(app.themeMode, equals(ThemeMode.light));

      // Update provider to dark mode
      container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      app = tester.widget(materialAppFinder);
      expect(app.themeMode, equals(ThemeMode.dark));

      container.dispose();
    });
  });
}
