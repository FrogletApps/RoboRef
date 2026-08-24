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
    });
  });
}
