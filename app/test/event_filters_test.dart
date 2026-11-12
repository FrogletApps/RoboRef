import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/features/event_selection/state/event_filter_controller.dart';
import 'package:roboref/features/event_selection/widgets/event_filters_bar.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:roboref/l10n/app_localizations.dart';

void main() {
  group('EventFiltersNotifier Multi-Select Tests', () {
    test('loads legacy single-string SharedPreferences filters into sets', () async {
      SharedPreferences.setMockInitialValues({
        'event_filter_program': 'VIQRC',
        'event_filter_region': 'United States',
        'event_filter_division': 'Texas',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(eventFiltersProvider);
      expect(state.programs, equals({'VIQRC'}));
      expect(state.regions, equals({'United States'}));
      expect(state.divisions, equals({'Texas'}));
      expect(state.program, equals('VIQRC'));
      expect(state.region, equals('United States'));
      expect(state.division, equals('Texas'));
      expect(state.hasActiveFilters, isTrue);
    });

    test('toggles multiple programs, persists StringLists, and reverts to All when empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(eventFiltersProvider.notifier);

      expect(container.read(eventFiltersProvider).programs, isEmpty);
      expect(container.read(eventFiltersProvider).program, equals('All'));

      notifier.toggleProgram('VIQRC');
      notifier.toggleProgram('V5RC');
      expect(container.read(eventFiltersProvider).programs, equals({'VIQRC', 'V5RC'}));
      expect(
        prefs.getStringList(EventFiltersNotifier.keyPrograms),
        containsAll(['VIQRC', 'V5RC']),
      );

      notifier.toggleProgram('VIQRC');
      expect(container.read(eventFiltersProvider).programs, equals({'V5RC'}));
      expect(container.read(eventFiltersProvider).program, equals('V5RC'));

      notifier.toggleProgram('V5RC');
      expect(container.read(eventFiltersProvider).programs, isEmpty);
      expect(container.read(eventFiltersProvider).program, equals('All'));
    });

    test('setRegions prunes divisions of deselected regions while preserving active ones', () async {
      SharedPreferences.setMockInitialValues({
        EventFiltersNotifier.keyRegions: ['United States', 'Canada'],
        EventFiltersNotifier.keyDivisions: ['Texas', 'California', 'Ontario'],
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(eventFiltersProvider.notifier);

      expect(
        container.read(eventFiltersProvider).divisions,
        equals({'Texas', 'California', 'Ontario'}),
      );

      // Deselect United States while keeping Canada -> Texas & California must be pruned, Ontario kept
      notifier.setRegions({'Canada'});
      expect(container.read(eventFiltersProvider).regions, equals({'Canada'}));
      expect(container.read(eventFiltersProvider).divisions, equals({'Ontario'}));
    });
  });

  group('EventFiltersBar Multi-Select Widget Tests', () {
    testWidgets('supports multi-select program chips and reverts to All on deselect', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      int filterChangeCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: EventFiltersBar(
                onFiltersChanged: () => filterChangeCount++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      FilterChip chipNamed(String label) =>
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));

      expect(chipNamed('All').selected, isTrue);
      expect(chipNamed('VIQRC').selected, isFalse);
      expect(chipNamed('V5RC').selected, isFalse);

      // Select VIQRC and V5RC together
      await tester.tap(find.widgetWithText(FilterChip, 'VIQRC'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'V5RC'));
      await tester.pumpAndSettle();

      expect(chipNamed('All').selected, isFalse);
      expect(chipNamed('VIQRC').selected, isTrue);
      expect(chipNamed('V5RC').selected, isTrue);
      expect(filterChangeCount, equals(2));

      // Tapping All clears multi-selected programs
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      expect(chipNamed('All').selected, isTrue);
      expect(chipNamed('VIQRC').selected, isFalse);
      expect(chipNamed('V5RC').selected, isFalse);
      expect(filterChangeCount, equals(3));
    });

    testWidgets('supports multi-select regions and per-region multi-select divisions', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      int filterChangeCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: EventFiltersBar(
                onFiltersChanged: () => filterChangeCount++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open RegionPickerSheet and select both United States and Canada
      await tester.tap(find.text('All Regions'));
      await tester.pumpAndSettle();

      expect(find.text('Filter by Region'), findsOneWidget);
      final regionSearchField = find.widgetWithText(
        TextField,
        'Search region (e.g. United States, UK, Australia)...',
      );
      await tester.enterText(regionSearchField, 'USA');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'United States'));
      await tester.pumpAndSettle();

      await tester.enterText(regionSearchField, 'Canada');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Canada'));
      await tester.pumpAndSettle();

      expect(find.text('Done (2)'), findsOneWidget);
      await tester.tap(find.text('Done (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Regions: 2 selected'), findsOneWidget);
      expect(find.text('All States'), findsOneWidget);
      expect(find.text('All Provinces'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);
      expect(filterChangeCount, equals(1));

      // Open States picker and select Texas and California
      await tester.tap(find.text('All States'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Search states (e.g. Texas, TX)...'),
        'TX',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Texas'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Search states (e.g. Texas, TX)...'),
        'California',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'California'));
      await tester.pumpAndSettle();

      expect(find.text('Done (2)'), findsOneWidget);
      await tester.tap(find.text('Done (2)'));
      await tester.pumpAndSettle();

      expect(find.text('States: 2 selected'), findsOneWidget);
      expect(find.text('All Provinces'), findsOneWidget);

      // Clear only States via its delete icon
      final statesCloseIcon = find.descendant(
        of: find.widgetWithText(FilterChip, 'States: 2 selected'),
        matching: find.byIcon(Icons.close),
      );
      await tester.ensureVisible(statesCloseIcon);
      await tester.pumpAndSettle();
      await tester.tap(statesCloseIcon);
      await tester.pumpAndSettle();

      expect(find.text('All States'), findsOneWidget);
      expect(find.text('Regions: 2 selected'), findsOneWidget);

      // Reset all filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      expect(find.text('All Regions'), findsOneWidget);
      expect(find.text('All States'), findsNothing);
      expect(find.text('All Provinces'), findsNothing);
      expect(find.text('Reset Filters'), findsNothing);
    });
  });
}
