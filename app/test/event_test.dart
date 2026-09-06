import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roboref/features/event_data/services/vex_events_client.dart';
import 'package:roboref/features/event_selection/screens/event_selection_screen.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/features/event_selection/state/event_filter_controller.dart';
import 'package:roboref/features/event_data/screens/event_import_sheet.dart';
import 'package:roboref/features/event_selection/models/event_model.dart';
import 'package:roboref/features/event_selection/services/event_cache_service.dart';

void main() {
  group('AppDatabase Event Operations', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('can upsert, stream, hide, and unhide events', () async {
      // 1. Insert an event
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-V5RC-24-8909',
          name: '2026 VEX Robotics World Championship',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-04-25T08:00:00Z',
          endDate: '2026-04-28T18:00:00Z',
          venue: const Value('Kay Bailey Hutchison Convention Center'),
          city: const Value('Dallas'),
          region: const Value('Texas'),
          updatedAt: 1000,
        ),
      );

      // 2. Query by SKU
      final event = await db.getEventBySku('RE-V5RC-24-8909');
      expect(event, isNotNull);
      expect(event!.name, equals('2026 VEX Robotics World Championship'));
      expect(event.program, equals('V5RC'));
      expect(event.venue, equals('Kay Bailey Hutchison Convention Center'));

      // 3. Check recent events stream
      var recent = await db.watchRecentEvents().first;
      expect(recent.length, equals(1));
      expect(recent.first.sku, equals('RE-V5RC-24-8909'));

      // 4. Hide event
      await db.hideEvent('RE-V5RC-24-8909');
      recent = await db.watchRecentEvents().first;
      expect(recent.isEmpty, isTrue);

      // 5. Unhide event
      await db.unhideEvent('RE-V5RC-24-8909');
      recent = await db.watchRecentEvents().first;
      expect(recent.length, equals(1));
    });
  });

  group('Live VEX Events & Event Selection Screen Tests', () {
    testWidgets('EventSelectionScreen renders correct program chips and filters properly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-8909',
      });
      final prefs = await SharedPreferences.getInstance();
      final testDb = AppDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );

      final mockHttpClient = MockClient((request) async {
        final progList = request.url.queryParametersAll['program[]'] ?? [];
        final List<Map<String, dynamic>> all = [
          {
            'id': 1,
            'sku': 'RE-V5RC-24-8909',
            'name': '2026 VEX Robotics World Championship - VRC High School',
            'program': {'code': 'V5RC'},
            'start': '2026-04-25T08:00:00Z',
            'end': '2026-04-28T18:00:00Z',
          },
          {
            'id': 2,
            'sku': 'RE-VIQRC-24-8913',
            'name': '2026 VEX Robotics World Championship - VIQRC Elementary School',
            'program': {'code': 'VIQRC'},
            'start': '2026-05-03T08:00:00Z',
            'end': '2026-05-05T18:00:00Z',
          },
          {
            'id': 3,
            'sku': 'RE-VAIRC-24-8912',
            'name': '2026 VEX Robotics World Championship - VEX AI',
            'program': {'code': 'VEX AI'},
            'start': '2026-04-25T08:00:00Z',
            'end': '2026-04-28T18:00:00Z',
          },
        ];

        final filtered = (progList.contains('57') || progList.contains('58'))
            ? all.where((e) => (e['program'] as Map)['code'] == 'VEX AI').toList()
            : all;

        return http.Response(
          jsonEncode({'data': filtered}),
          200,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            vexEventsClientProvider.overrideWithValue(
              VexEventsClient(
                client: mockHttpClient,
                serverUrl: 'http://127.0.0.1:8080',
              ),
            ),
          ],
          child: const MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Check Program Filter Chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'V5RC'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'VIQRC'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'VEX U'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'VEX AI'), findsOneWidget);

      // Verify Events title and search summary label
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Found 3 events between Apr 25, 2026 and May 5, 2026'), findsOneWidget);

      // Verify preloaded list contains V5RC and VIQRC events
      expect(find.text('RE-V5RC-24-8909'), findsOneWidget);
      expect(find.text('RE-VIQRC-24-8913'), findsOneWidget);

      // Tap VEX AI filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'VEX AI'));
      await tester.pumpAndSettle();

      // Verify only VEX AI event is shown
      expect(find.text('RE-VAIRC-24-8912'), findsOneWidget);
      expect(find.text('RE-V5RC-24-8909'), findsNothing);
      expect(find.text('RE-VIQRC-24-8913'), findsNothing);

      // Tap VIQRC filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'VIQRC'));
      await tester.pumpAndSettle();

      // Verify only VIQRC event is shown
      expect(find.text('RE-VIQRC-24-8913'), findsOneWidget);
      expect(find.text('RE-V5RC-24-8909'), findsNothing);
      expect(find.text('RE-VAIRC-24-8912'), findsNothing);

      // Tap All filter chip
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      // Verify all events are shown again
      expect(find.text('RE-V5RC-24-8909'), findsOneWidget);
      expect(find.text('RE-VIQRC-24-8913'), findsOneWidget);
      expect(find.text('RE-VAIRC-24-8912'), findsOneWidget);

      await testDb.close();
    });

    testWidgets('EventSelectionScreen supports Region and dynamic CountryDivision filtering with Taiwan', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final testDb = AppDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );

      final mockHttpClient = MockClient((request) async {
        final regionParam = request.url.queryParameters['region'];
        final List<Map<String, dynamic>> all = [
          {
            'id': 1,
            'sku': 'RE-V5RC-24-1111',
            'name': 'Texas Championship Qualifier',
            'program': {'code': 'V5RC'},
            'start': '2026-04-25T08:00:00Z',
            'end': '2026-04-28T18:00:00Z',
            'location': {'city': 'Dallas', 'region': 'Texas', 'country': 'United States'},
          },
          {
            'id': 2,
            'sku': 'RE-V5RC-24-2222',
            'name': 'California Open Tournament',
            'program': {'code': 'V5RC'},
            'start': '2026-05-03T08:00:00Z',
            'end': '2026-05-05T18:00:00Z',
            'location': {'city': 'San Jose', 'region': 'California', 'country': 'United States'},
          },
          {
            'id': 3,
            'sku': 'RE-VIQRC-24-3333',
            'name': 'UK National Championship',
            'program': {'code': 'VIQRC'},
            'start': '2026-04-25T08:00:00Z',
            'end': '2026-04-28T18:00:00Z',
            'location': {'city': 'Telford', 'region': 'England', 'country': 'United Kingdom'},
          },
          {
            'id': 4,
            'sku': 'RE-V5RC-24-4444',
            'name': 'Ontario Provincial Championship',
            'program': {'code': 'V5RC'},
            'start': '2026-04-25T08:00:00Z',
            'end': '2026-04-28T18:00:00Z',
            'location': {'city': 'Toronto', 'region': 'Ontario', 'country': 'Canada'},
          },
          {
            'id': 5,
            'sku': 'RE-V5RC-24-5555',
            'name': 'Formosa VEX Open',
            'program': {'code': 'V5RC'},
            'start': '2026-04-25T08:00:00Z',
            'end': '2026-04-28T18:00:00Z',
            'location': {'city': 'Taipei', 'region': 'Taiwan', 'country': 'Chinese Taipei'},
          },
        ];

        final filtered = regionParam != null && regionParam.isNotEmpty
            ? all.where((e) {
                final loc = e['location'] as Map<String, dynamic>;
                if (regionParam == 'Taiwan' || regionParam == 'Chinese Taipei') {
                  return loc['country'] == 'Taiwan' || loc['country'] == 'Chinese Taipei' || loc['region'] == 'Taiwan';
                }
                return loc['region'] == regionParam || loc['country'] == regionParam;
              }).toList()
            : all;

        return http.Response(
          jsonEncode({'data': filtered}),
          200,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            vexEventsClientProvider.overrideWithValue(
              VexEventsClient(
                client: mockHttpClient,
                serverUrl: 'http://127.0.0.1:8080',
              ),
            ),
          ],
          child: const MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // 1. Initial State: "All Regions" chip is visible, no division chip shown, all 5 events present
      expect(find.text('All Regions'), findsOneWidget);
      expect(find.text('All States'), findsNothing);
      expect(find.text('All Provinces'), findsNothing);
      expect(find.text('RE-V5RC-24-1111'), findsOneWidget);
      expect(find.text('RE-V5RC-24-2222'), findsOneWidget);
      expect(find.text('RE-VIQRC-24-3333'), findsOneWidget);
      expect(find.text('RE-V5RC-24-4444'), findsOneWidget);
      expect(find.text('RE-V5RC-24-5555'), findsOneWidget);

      // 2. Open Region Picker and search "Chinese Taipei" shorthand -> displays "Taiwan"
      await tester.tap(find.text('All Regions'));
      await tester.pumpAndSettle();

      expect(find.text('Filter by Region'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Search region (e.g. United States, UK, Australia)...'), 'Chinese Taipei');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ListTile, 'Taiwan'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Chinese Taipei'), findsNothing);

      // 3. Select Taiwan -> filters to Taiwan event (matching Chinese Taipei country in API)
      await tester.tap(find.widgetWithText(ListTile, 'Taiwan'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.text('Region: Taiwan'), findsOneWidget);
      expect(find.text('RE-V5RC-24-5555'), findsOneWidget);
      expect(find.text('RE-V5RC-24-1111'), findsNothing);

      // 4. Open Region Picker and search USA shorthand
      await tester.tap(find.text('Region: Taiwan'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Search region (e.g. United States, UK, Australia)...'), 'USA');
      await tester.pumpAndSettle();

      expect(find.text('United States'), findsOneWidget);
      expect(find.text('Canada'), findsNothing);

      // 5. Select United States -> reveals "All States" division chip
      await tester.tap(find.widgetWithText(ListTile, 'United States'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.text('Region: United States'), findsOneWidget);
      expect(find.text('All States'), findsOneWidget);
      expect(find.text('RE-V5RC-24-1111'), findsOneWidget);
      expect(find.text('RE-V5RC-24-2222'), findsOneWidget);
      expect(find.text('RE-VIQRC-24-3333'), findsNothing);
      expect(find.text('RE-V5RC-24-4444'), findsNothing);

      // 6. Tap "All States" to open Division Picker
      await tester.tap(find.text('All States'));
      await tester.pumpAndSettle();

      expect(find.text('Filter by State'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Search states (e.g. Texas, TX)...'), 'TX');
      await tester.pumpAndSettle();

      expect(find.text('Texas'), findsOneWidget);
      expect(find.text('California'), findsNothing);

      // 7. Select Texas -> displays only Texas event
      await tester.tap(find.widgetWithText(ListTile, 'Texas'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.text('State: Texas'), findsOneWidget);
      expect(find.text('RE-V5RC-24-1111'), findsOneWidget);
      expect(find.text('RE-V5RC-24-2222'), findsNothing);

      // 8. Test switching to Canada -> displays "All Provinces" chip
      await tester.tap(find.text('Region: United States'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Search region (e.g. United States, UK, Australia)...'), 'Canada');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Canada'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.text('Region: Canada'), findsOneWidget);
      expect(find.text('All Provinces'), findsOneWidget);
      expect(find.text('RE-V5RC-24-4444'), findsOneWidget);

      // 9. Test switching to Australia -> NO division / states chip shown
      await tester.tap(find.text('Region: Canada'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Search region (e.g. United States, UK, Australia)...'), 'Australia');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Australia'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.text('Region: Australia'), findsOneWidget);
      expect(find.text('All States'), findsNothing);
      expect(find.text('All Provinces'), findsNothing);

      // 10. Tap Reset Filters -> resets all filters back to All Regions
      expect(find.text('Reset Filters'), findsOneWidget);
      await tester.tap(find.text('Reset Filters'));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.text('All Regions'), findsOneWidget);
      expect(find.text('RE-V5RC-24-1111'), findsOneWidget);
      expect(find.text('RE-V5RC-24-2222'), findsOneWidget);
      expect(find.text('RE-VIQRC-24-3333'), findsOneWidget);
      await testDb.close();
    });

    test('EventFiltersNotifier loads, updates, and persists filters in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'event_filter_program': 'VIQRC',
        'event_filter_region': 'United Kingdom',
        'event_filter_division': 'All',
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = EventFiltersNotifier(prefs);

      expect(notifier.state.program, equals('VIQRC'));
      expect(notifier.state.region, equals('United Kingdom'));
      expect(notifier.state.division, equals('All'));

      notifier.setProgram('V5RC');
      expect(prefs.getString(EventFiltersNotifier.keyProgram), equals('V5RC'));

      notifier.setRegion('United States');
      expect(prefs.getString(EventFiltersNotifier.keyRegion), equals('United States'));
      expect(prefs.getString(EventFiltersNotifier.keyDivision), equals('All'));

      notifier.setDivision('Texas');
      expect(prefs.getString(EventFiltersNotifier.keyDivision), equals('Texas'));

      notifier.resetFilters();
      expect(prefs.getString(EventFiltersNotifier.keyProgram), equals('All'));
      expect(prefs.getString(EventFiltersNotifier.keyRegion), equals('All'));
      expect(prefs.getString(EventFiltersNotifier.keyDivision), equals('All'));
    });
  });

  group('EventImportSheet Widget Tests', () {
    testWidgets('renders Load Tournament Data with TM CSV import and without VEX Events tab', (tester) async {
      SharedPreferences.setMockInitialValues({'current_sku': 'RE-V5RC-24-1111'});
      final prefs = await SharedPreferences.getInstance();
      final testDb = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          syncSettingsProvider.overrideWith((ref) => SyncSettingsNotifier(prefs)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: EventImportSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Load Tournament Data'), findsOneWidget);
      expect(find.text('Paste Tournament Manager (TM) export data below.'), findsOneWidget);
      expect(find.text('Teams CSV'), findsOneWidget);
      expect(find.text('Match Schedule CSV'), findsOneWidget);
      expect(find.text('VEX Events'), findsNothing);
      expect(find.text('Fetch Tournament Data'), findsNothing);

      await testDb.close();
    });
  });

  group('EventSelectionScreen Caching Tests', () {
    testWidgets('loads and displays cached events immediately without waiting for network', (WidgetTester tester) async {
      final now = DateTime.now();
      final validEvents = [
        EventModel(
          id: 101,
          sku: 'RE-CACHE-01',
          name: 'Instant Cached Event 1',
          program: 'V5RC',
          season: '2026-2027',
          startDate: now.add(const Duration(days: 1)).toIso8601String(),
          endDate: now.add(const Duration(days: 2)).toIso8601String(),
        ),
        EventModel(
          id: 102,
          sku: 'RE-CACHE-02',
          name: 'Instant Cached Event 2',
          program: 'V5RC',
          season: '2026-2027',
          startDate: now.add(const Duration(days: 3)).toIso8601String(),
          endDate: now.add(const Duration(days: 4)).toIso8601String(),
        ),
      ];

      SharedPreferences.setMockInitialValues({
        EventCacheService.cacheKey: jsonEncode(validEvents.map((e) => e.toJson()).toList()),
      });
      final prefs = await SharedPreferences.getInstance();
      final testDb = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

      // Mock client that delays response
      final mockHttpClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            vexEventsClientProvider.overrideWithValue(
              VexEventsClient(
                client: mockHttpClient,
                serverUrl: 'http://127.0.0.1:8080',
              ),
            ),
          ],
          child: const MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      // On the very first frame before network resolves, cached events are already visible!
      await tester.pump();
      expect(find.text('RE-CACHE-01'), findsOneWidget);
      expect(find.text('RE-CACHE-02'), findsOneWidget);
      expect(find.text('Instant Cached Event 1'), findsOneWidget);

      // Settle network delay
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 250));
      });
      await tester.pumpAndSettle();

      await testDb.close();
    });

    testWidgets('does not visibly remove an event from UI if removed upstream, but removes it before next view', (WidgetTester tester) async {
      final now = DateTime.now();
      final initialCachedEvents = [
        EventModel(
          id: 201,
          sku: 'RE-STAY-01',
          name: 'Tournament Stay',
          program: 'V5RC',
          season: '2026-2027',
          startDate: now.add(const Duration(days: 1)).toIso8601String(),
          endDate: now.add(const Duration(days: 2)).toIso8601String(),
        ),
        EventModel(
          id: 202,
          sku: 'RE-UPSTREAM-REMOVED',
          name: 'Tournament Removed Upstream',
          program: 'V5RC',
          season: '2026-2027',
          startDate: now.add(const Duration(days: 2)).toIso8601String(),
          endDate: now.add(const Duration(days: 3)).toIso8601String(),
        ),
      ];

      SharedPreferences.setMockInitialValues({
        EventCacheService.cacheKey: jsonEncode(initialCachedEvents.map((e) => e.toJson()).toList()),
      });
      final prefs = await SharedPreferences.getInstance();
      final testDb = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

      // Mock server returns RE-STAY-01 and RE-NEW-03 (RE-UPSTREAM-REMOVED was deleted on server)
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 201,
                'sku': 'RE-STAY-01',
                'name': 'Tournament Stay Updated',
                'program': {'code': 'V5RC'},
                'start': now.add(const Duration(days: 1)).toIso8601String(),
                'end': now.add(const Duration(days: 2)).toIso8601String(),
              },
              {
                'id': 203,
                'sku': 'RE-NEW-03',
                'name': 'Tournament New',
                'program': {'code': 'V5RC'},
                'start': now.add(const Duration(days: 3)).toIso8601String(),
                'end': now.add(const Duration(days: 4)).toIso8601String(),
              },
            ],
          }),
          200,
        );
      });

      // 1. First View: Screen loads with cached events and receives remote update
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            vexEventsClientProvider.overrideWithValue(
              VexEventsClient(
                client: mockHttpClient,
                serverUrl: 'http://127.0.0.1:8080',
              ),
            ),
          ],
          child: const MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // In current UI: RE-UPSTREAM-REMOVED is NOT visibly removed because it was visible to the user!
      expect(find.text('RE-UPSTREAM-REMOVED'), findsOneWidget);
      expect(find.text('RE-STAY-01'), findsOneWidget);
      expect(find.text('RE-NEW-03'), findsOneWidget);

      // BUT in persistent cache: RE-UPSTREAM-REMOVED HAS been removed!
      final cacheService = EventCacheService(prefs);
      final cacheAfterUpdate = cacheService.getCachedEvents();
      expect(cacheAfterUpdate.any((e) => e.sku == 'RE-UPSTREAM-REMOVED'), isFalse);
      expect(cacheAfterUpdate.any((e) => e.sku == 'RE-STAY-01'), isTrue);
      expect(cacheAfterUpdate.any((e) => e.sku == 'RE-NEW-03'), isTrue);

      // 2. Next Time Viewed: When user navigates to the screen anew, removed event is no longer visible
      // Unmount first, then mount a new EventSelectionScreen with UniqueKey
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            vexEventsClientProvider.overrideWithValue(
              VexEventsClient(
                client: mockHttpClient,
                serverUrl: 'http://127.0.0.1:8080',
              ),
            ),
          ],
          child: const MaterialApp(
            home: EventSelectionScreen(key: ValueKey('new_view_session')),
          ),
        ),
      );
      await tester.pump();

      // RE-UPSTREAM-REMOVED is not in cache, so it is never shown!
      expect(find.text('RE-UPSTREAM-REMOVED'), findsNothing);
      expect(find.text('RE-STAY-01'), findsOneWidget);
      expect(find.text('RE-NEW-03'), findsOneWidget);

      await testDb.close();
    });

    testWidgets('offline resilience: cached events remain visible when network fails', (WidgetTester tester) async {
      final now = DateTime.now();
      final initialCachedEvents = [
        EventModel(
          id: 301,
          sku: 'RE-OFFLINE-01',
          name: 'Offline Tournament Event',
          program: 'V5RC',
          season: '2026-2027',
          startDate: now.add(const Duration(days: 1)).toIso8601String(),
          endDate: now.add(const Duration(days: 2)).toIso8601String(),
        ),
      ];

      SharedPreferences.setMockInitialValues({
        EventCacheService.cacheKey: jsonEncode(initialCachedEvents.map((e) => e.toJson()).toList()),
      });
      final prefs = await SharedPreferences.getInstance();
      final testDb = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

      // Mock server returns network failure (e.g. 500 or throws)
      final mockHttpClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            vexEventsClientProvider.overrideWithValue(
              VexEventsClient(
                client: mockHttpClient,
                serverUrl: 'http://127.0.0.1:8080',
              ),
            ),
          ],
          child: const MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      // Event is still displayed, and no error message replaced the event list!
      expect(find.text('RE-OFFLINE-01'), findsOneWidget);
      expect(find.text('Offline Tournament Event'), findsOneWidget);
      await testDb.close();
    });

    testWidgets('EventSelectionScreen recognizes VE- SKU input and displays custom event card', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final testDb = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));

      final mockHttpClient = MockClient((request) async {
        return http.Response(jsonEncode({'data': []}), 200);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(testDb),
            vexEventsClientProvider.overrideWithValue(
              VexEventsClient(client: mockHttpClient),
            ),
          ],
          child: const MaterialApp(
            home: EventSelectionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter VE-IQ SKU
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'VE-IQ-26-65627');
      await tester.pumpAndSettle();

      expect(find.text('Add & Select'), findsOneWidget);
      expect(find.text('Add & fetch custom VIQRC tournament schedule'), findsOneWidget);

      // Enter VE-V5 SKU
      await tester.enterText(searchField, 'VE-V5-26-65764');
      await tester.pumpAndSettle();

      expect(find.text('Add & Select'), findsOneWidget);
      expect(find.text('Add & fetch custom V5RC tournament schedule'), findsOneWidget);

      // Enter VE-U SKU
      await tester.enterText(searchField, 'VE-U-26-65535');
      await tester.pumpAndSettle();

      expect(find.text('Add & Select'), findsOneWidget);
      expect(find.text('Add & fetch custom VEX U tournament schedule'), findsOneWidget);

      await testDb.close();
    });
  });
}

