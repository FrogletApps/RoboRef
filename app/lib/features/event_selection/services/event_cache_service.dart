import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/sku_utils.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../models/event_model.dart';

class EventCacheService {
  final SharedPreferences? prefs;

  static const String cacheKey = 'cached_vex_events';

  EventCacheService(this.prefs);

  /// Parse the end date (or fallback to start date) of an event
  static DateTime? parseEventEndDate(EventModel event) {
    final endStr = event.endDate.isNotEmpty ? event.endDate : event.startDate;
    if (endStr.isEmpty) return null;
    final dt = DateTime.tryParse(endStr);
    if (dt == null) return null;
    // If it's just a date without time (e.g. 2026-08-30), treat end as end of that day: 23:59:59
    if (endStr.length == 10 && !endStr.contains('T')) {
      return DateTime(dt.year, dt.month, dt.day, 23, 59, 59);
    }
    return dt;
  }

  /// Check whether an event ended more than 7 days ago relative to referenceTime (or now)
  static bool isEndedMoreThanAWeekAgo(EventModel event, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final end = parseEventEndDate(event);
    if (end == null) return false;
    final cutoff = now.subtract(const Duration(days: 7));
    return end.isBefore(cutoff);
  }

  /// Retrieve cached events from local storage, omitting any events ended more than a week ago
  List<EventModel> getCachedEvents({DateTime? referenceTime}) {
    try {
      final jsonStr = prefs?.getString(cacheKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return [];
      }

      final List<dynamic> rawList = jsonDecode(jsonStr);
      final events = rawList
          .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
          .where((event) => !isEndedMoreThanAWeekAgo(event, referenceTime: referenceTime))
          .toList();

      // Sort chronologically by start date
      events.sort((a, b) {
        final aDate = DateTime.tryParse(a.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

      return events;
    } catch (_) {
      return [];
    }
  }

  /// Persist a list of events to cache, filtering out events that ended more than a week ago
  Future<void> saveCachedEvents(List<EventModel> events, {DateTime? referenceTime}) async {
    if (prefs == null) return;

    try {
      final validEvents = events
          .where((e) => !isEndedMoreThanAWeekAgo(e, referenceTime: referenceTime))
          .toList();

      // Deduplicate by uppercase SKU (keeping the last occurrence)
      final map = <String, EventModel>{};
      for (final e in validEvents) {
        map[e.sku.toUpperCase()] = e;
      }

      final encoded = jsonEncode(map.values.map((e) => e.toJson()).toList());
      await prefs!.setString(cacheKey, encoded);
    } catch (_) {}
  }

  /// Check if an event falls within the scope of a specific search/filter query
  bool _isEventInScope(
    EventModel event, {
    String? program,
    String? region,
    String? division,
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    // 1. Program filter
    if (program != null && program != 'All') {
      if (!isEventMatchingProgram(
        program: event.program,
        sku: event.sku,
        selectedProgram: program,
      )) {
        return false;
      }
    }

    // 2. Region / Division filter
    if (region != null && region != 'All') {
      final target = region.toUpperCase().trim();
      final c = event.country?.toUpperCase() ?? '';
      final r = event.region?.toUpperCase() ?? '';
      final v = event.venue?.toUpperCase() ?? '';
      final city = event.city?.toUpperCase() ?? '';

      final matchesRegion = c == target ||
          c.contains(target) ||
          r == target ||
          r.contains(target) ||
          v.contains(target) ||
          city.contains(target);

      if (!matchesRegion) return false;
    }

    // 3. Date window
    if (windowStart != null || windowEnd != null) {
      final start = DateTime.tryParse(event.startDate);
      final end = DateTime.tryParse(event.endDate) ?? start;

      if (start != null && end != null) {
        if (windowStart != null && end.isBefore(windowStart)) return false;
        if (windowEnd != null && start.isAfter(windowEnd)) return false;
      }
    }

    return true;
  }

  /// Updates the cached list with remote events.
  /// Any event that was previously cached in this scope but missing from [remoteEvents]
  /// is removed from persistent cache (since it was removed upstream).
  /// Events outside this query scope or not ended >1 week ago are preserved.
  Future<List<EventModel>> updateCacheWithRemoteEvents({
    required List<EventModel> remoteEvents,
    String? query,
    String? program,
    String? region,
    String? division,
    DateTime? windowStart,
    DateTime? windowEnd,
    DateTime? referenceTime,
  }) async {
    final existing = getCachedEvents(referenceTime: referenceTime);
    final isSpecificTextSearch = query != null && query.trim().isNotEmpty;

    // Build map of existing events by SKU
    final eventMap = <String, EventModel>{};
    for (final e in existing) {
      eventMap[e.sku.toUpperCase()] = e;
    }

    final remoteSkus = remoteEvents.map((e) => e.sku.toUpperCase()).toSet();

    // If this is a general/window fetch (not a specific text search),
    // remove cached events within this scope that were omitted from remote response
    if (!isSpecificTextSearch) {
      final skusToRemove = <String>[];
      for (final entry in eventMap.entries) {
        final cached = entry.value;
        if (_isEventInScope(
          cached,
          program: program,
          region: region,
          division: division,
          windowStart: windowStart,
          windowEnd: windowEnd,
        )) {
          if (!remoteSkus.contains(entry.key)) {
            skusToRemove.add(entry.key);
          }
        }
      }

      for (final sku in skusToRemove) {
        eventMap.remove(sku);
      }
    }

    // Upsert remote events
    for (final remote in remoteEvents) {
      if (!isEndedMoreThanAWeekAgo(remote, referenceTime: referenceTime)) {
        eventMap[remote.sku.toUpperCase()] = remote;
      }
    }

    final updatedList = eventMap.values.toList();
    await saveCachedEvents(updatedList, referenceTime: referenceTime);
    return updatedList;
  }

  /// Remove a specific SKU from cache
  Future<void> removeEvent(String sku) async {
    final clean = sku.trim().toUpperCase();
    final current = getCachedEvents();
    final remaining = current.where((e) => e.sku.toUpperCase() != clean).toList();
    await saveCachedEvents(remaining);
  }

  /// Clear all cached events
  Future<void> clearCache() async {
    await prefs?.remove(cacheKey);
  }
}

final eventCacheServiceProvider = Provider<EventCacheService>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return EventCacheService(prefs);
  } catch (_) {
    return EventCacheService(null);
  }
});
