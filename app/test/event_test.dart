import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';

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
}
