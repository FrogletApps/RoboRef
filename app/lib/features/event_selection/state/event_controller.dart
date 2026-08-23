import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../../../core/utils/sku_utils.dart';
import '../models/event_model.dart';

/// Stream of recent events for the home screen
final recentEventsStreamProvider = StreamProvider.autoDispose<List<Event>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchRecentEvents(limit: 20);
});

/// Active event details provider
final activeEventProvider = FutureProvider.autoDispose<Event?>((ref) async {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(syncSettingsProvider);
  return db.getEventBySku(settings.currentSku);
});

/// Curated/preloaded World & Signature events for easy discovery
const List<EventModel> preloadedEvents = [
  EventModel(
    sku: 'RE-V5RC-24-8909',
    name: '2026 VEX Robotics World Championship - VRC High School',
    program: 'V5RC',
    season: '2026-2027',
    startDate: '2026-04-25T08:00:00Z',
    endDate: '2026-04-28T18:00:00Z',
    venue: 'Kay Bailey Hutchison Convention Center',
    city: 'Dallas',
    region: 'Texas',
  ),
  EventModel(
    sku: 'RE-V5RC-24-8910',
    name: '2026 VEX Robotics World Championship - VRC Middle School',
    program: 'V5RC',
    season: '2026-2027',
    startDate: '2026-04-29T08:00:00Z',
    endDate: '2026-05-02T18:00:00Z',
    venue: 'Kay Bailey Hutchison Convention Center',
    city: 'Dallas',
    region: 'Texas',
  ),
  EventModel(
    sku: 'RE-VIQRC-24-8913',
    name: '2026 VEX Robotics World Championship - VIQRC Elementary School',
    program: 'VIQRC',
    season: '2026-2027',
    startDate: '2026-05-03T08:00:00Z',
    endDate: '2026-05-05T18:00:00Z',
    venue: 'Kay Bailey Hutchison Convention Center',
    city: 'Dallas',
    region: 'Texas',
  ),
  EventModel(
    sku: 'RE-VIQRC-24-8914',
    name: '2026 VEX Robotics World Championship - VIQRC Middle School',
    program: 'VIQRC',
    season: '2026-2027',
    startDate: '2026-05-06T08:00:00Z',
    endDate: '2026-05-08T18:00:00Z',
    venue: 'Kay Bailey Hutchison Convention Center',
    city: 'Dallas',
    region: 'Texas',
  ),
  EventModel(
    sku: 'RE-VURC-24-8911',
    name: '2026 VEX Robotics World Championship - VEX U',
    program: 'VEX U',
    season: '2026-2027',
    startDate: '2026-04-25T08:00:00Z',
    endDate: '2026-04-28T18:00:00Z',
    venue: 'Kay Bailey Hutchison Convention Center',
    city: 'Dallas',
    region: 'Texas',
  ),
  EventModel(
    sku: 'RE-VAIRC-24-8912',
    name: '2026 VEX Robotics World Championship - VEX AI',
    program: 'VEX AI',
    season: '2026-2027',
    startDate: '2026-04-25T08:00:00Z',
    endDate: '2026-04-28T18:00:00Z',
    venue: 'Kay Bailey Hutchison Convention Center',
    city: 'Dallas',
    region: 'Texas',
  ),
];

class EventController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  EventController(this.ref) : super(const AsyncValue.data(null));

  AppDatabase get _db => ref.read(databaseProvider);

  /// Select an event, saving it to database and updating active SKU
  Future<void> selectEvent({
    required String sku,
    required String name,
    required String program,
    required String season,
    required String startDate,
    required String endDate,
    String? venue,
    String? city,
    String? region,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Upsert into database
    await _db.upsertEvent(
      EventsCompanion(
        sku: Value(cleanSku),
        name: Value(name),
        program: Value(program),
        season: Value(season),
        startDate: Value(startDate),
        endDate: Value(endDate),
        venue: Value(venue),
        city: Value(city),
        region: Value(region),
        isHidden: const Value(false),
        updatedAt: Value(now),
      ),
    );

    // 2. Set current SKU in sync settings
    ref.read(syncSettingsProvider.notifier).setSku(cleanSku);
  }

  /// Add a custom or manual event
  Future<void> addManualEvent({
    required String sku,
    String? name,
    String? program,
    String? venue,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    final detectedProg = program ?? getSkuProgram(cleanSku);
    final eventName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : '$detectedProg Tournament ($cleanSku)';
    final now = DateTime.now().toIso8601String();

    await selectEvent(
      sku: cleanSku,
      name: eventName,
      program: detectedProg,
      season: '2026-2027',
      startDate: now,
      endDate: now,
      venue: venue,
    );
  }

  /// Hide an event from the recent list
  Future<void> hideEvent(String sku) async {
    await _db.hideEvent(sku);
  }

  /// Delete an event completely
  Future<void> deleteEvent(String sku) async {
    await _db.deleteEvent(sku);
  }
}

final eventControllerProvider =
    StateNotifierProvider<EventController, AsyncValue<void>>((ref) {
  return EventController(ref);
});
