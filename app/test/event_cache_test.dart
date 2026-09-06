import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/features/event_selection/models/event_model.dart';
import 'package:roboref/features/event_selection/services/event_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventModel serialization & equality', () {
    test('round-trips toJson and fromJson', () {
      final original = EventModel(
        id: 42,
        sku: 'RE-V5RC-26-1234',
        name: 'Championship Event',
        program: 'V5RC',
        season: '2026-2027',
        startDate: '2026-09-01T09:00:00Z',
        endDate: '2026-09-02T18:00:00Z',
        venue: 'Main Arena',
        city: 'Dallas',
        region: 'Texas',
        country: 'United States',
        divisions: const [
          DivisionModel(id: 1, name: 'Division 1', order: 1),
        ],
      );

      final jsonMap = original.toJson();
      final reconstructed = EventModel.fromJson(jsonMap);

      expect(reconstructed.id, equals(42));
      expect(reconstructed.sku, equals('RE-V5RC-26-1234'));
      expect(reconstructed.name, equals('Championship Event'));
      expect(reconstructed.program, equals('V5RC'));
      expect(reconstructed.season, equals('2026-2027'));
      expect(reconstructed.startDate, equals('2026-09-01T09:00:00Z'));
      expect(reconstructed.endDate, equals('2026-09-02T18:00:00Z'));
      expect(reconstructed.venue, equals('Main Arena'));
      expect(reconstructed.city, equals('Dallas'));
      expect(reconstructed.region, equals('Texas'));
      expect(reconstructed.country, equals('United States'));
      expect(reconstructed.divisions.length, equals(1));
      expect(reconstructed.divisions.first.name, equals('Division 1'));
      expect(reconstructed, equals(original));
    });
  });

  group('EventCacheService', () {
    late SharedPreferences prefs;
    late EventCacheService cacheService;
    final testNow = DateTime.parse('2026-09-10T12:00:00Z');

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cacheService = EventCacheService(prefs);
    });

    test('isEndedMoreThanAWeekAgo correctly detects events past 7-day cutoff', () {
      // 8 days before testNow -> ended > 1 week ago
      final oldEvent = EventModel(
        sku: 'RE-OLD-1',
        name: 'Old Event',
        program: 'V5RC',
        season: '2026-2027',
        startDate: '2026-09-01T09:00:00Z',
        endDate: '2026-09-02T18:00:00Z',
      );
      expect(
        EventCacheService.isEndedMoreThanAWeekAgo(oldEvent, referenceTime: testNow),
        isTrue,
      );

      // 4 days before testNow -> ended < 1 week ago
      final recentEvent = EventModel(
        sku: 'RE-RECENT-1',
        name: 'Recent Event',
        program: 'V5RC',
        season: '2026-2027',
        startDate: '2026-09-05T09:00:00Z',
        endDate: '2026-09-06T18:00:00Z',
      );
      expect(
        EventCacheService.isEndedMoreThanAWeekAgo(recentEvent, referenceTime: testNow),
        isFalse,
      );

      // Future event
      final futureEvent = EventModel(
        sku: 'RE-FUTURE-1',
        name: 'Future Event',
        program: 'V5RC',
        season: '2026-2027',
        startDate: '2026-09-15T09:00:00Z',
        endDate: '2026-09-16T18:00:00Z',
      );
      expect(
        EventCacheService.isEndedMoreThanAWeekAgo(futureEvent, referenceTime: testNow),
        isFalse,
      );
    });

    test('getCachedEvents excludes events that ended more than a week ago', () async {
      final events = [
        EventModel(
          sku: 'RE-OLD-1',
          name: 'Old Event 1',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-08-20T09:00:00Z',
          endDate: '2026-08-21T18:00:00Z',
        ),
        EventModel(
          sku: 'RE-RECENT-1',
          name: 'Recent Event 1',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-09-06T09:00:00Z',
          endDate: '2026-09-07T18:00:00Z',
        ),
        EventModel(
          sku: 'RE-FUTURE-1',
          name: 'Future Event 1',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-09-14T09:00:00Z',
          endDate: '2026-09-15T18:00:00Z',
        ),
      ];

      // Seed SharedPreferences directly
      await prefs.setString(
        EventCacheService.cacheKey,
        jsonEncode(events.map((e) => e.toJson()).toList()),
      );

      final cached = cacheService.getCachedEvents(referenceTime: testNow);
      expect(cached.length, equals(2));
      expect(cached.any((e) => e.sku == 'RE-OLD-1'), isFalse);
      expect(cached.any((e) => e.sku == 'RE-RECENT-1'), isTrue);
      expect(cached.any((e) => e.sku == 'RE-FUTURE-1'), isTrue);
    });

    test('updateCacheWithRemoteEvents removes removed events from persistent cache', () async {
      final initialEvents = [
        EventModel(
          sku: 'RE-KEEP-1',
          name: 'Keep Event',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-09-10T09:00:00Z',
          endDate: '2026-09-11T18:00:00Z',
        ),
        EventModel(
          sku: 'RE-REMOVED-1',
          name: 'Removed Event',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-09-10T09:00:00Z',
          endDate: '2026-09-11T18:00:00Z',
        ),
      ];

      await cacheService.saveCachedEvents(initialEvents, referenceTime: testNow);

      // Remote update only contains RE-KEEP-1 and a new RE-NEW-1 (RE-REMOVED-1 was removed upstream)
      final remoteEvents = [
        EventModel(
          sku: 'RE-KEEP-1',
          name: 'Keep Event Updated',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-09-10T09:00:00Z',
          endDate: '2026-09-11T18:00:00Z',
        ),
        EventModel(
          sku: 'RE-NEW-1',
          name: 'New Event',
          program: 'V5RC',
          season: '2026-2027',
          startDate: '2026-09-12T09:00:00Z',
          endDate: '2026-09-13T18:00:00Z',
        ),
      ];

      await cacheService.updateCacheWithRemoteEvents(
        remoteEvents: remoteEvents,
        program: 'All',
        region: 'All',
        windowStart: DateTime.parse('2026-09-07T00:00:00Z'),
        windowEnd: DateTime.parse('2026-09-17T00:00:00Z'),
        referenceTime: testNow,
      );

      final updatedCache = cacheService.getCachedEvents(referenceTime: testNow);
      expect(updatedCache.length, equals(2));
      expect(updatedCache.any((e) => e.sku == 'RE-REMOVED-1'), isFalse);
      expect(updatedCache.any((e) => e.sku == 'RE-KEEP-1'), isTrue);
      expect(updatedCache.any((e) => e.sku == 'RE-NEW-1'), isTrue);
      expect(updatedCache.firstWhere((e) => e.sku == 'RE-KEEP-1').name, equals('Keep Event Updated'));
    });
  });
}
