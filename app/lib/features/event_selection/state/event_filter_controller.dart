import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../settings/state/sync_settings_controller.dart';

class EventFiltersState {
  final String program;
  final String region;
  final String division;

  const EventFiltersState({
    this.program = 'All',
    this.region = 'All',
    this.division = 'All',
  });

  EventFiltersState copyWith({
    String? program,
    String? region,
    String? division,
  }) {
    return EventFiltersState(
      program: program ?? this.program,
      region: region ?? this.region,
      division: division ?? this.division,
    );
  }
}

class EventFiltersNotifier extends StateNotifier<EventFiltersState> {
  final SharedPreferences? prefs;

  static const String keyProgram = 'event_filter_program';
  static const String keyRegion = 'event_filter_region';
  static const String keyDivision = 'event_filter_division';

  EventFiltersNotifier(this.prefs)
      : super(EventFiltersState(
          program: prefs?.getString(keyProgram) ?? 'All',
          region: prefs?.getString(keyRegion) ?? 'All',
          division: prefs?.getString(keyDivision) ?? 'All',
        ));

  void setProgram(String program) {
    state = state.copyWith(program: program);
    prefs?.setString(keyProgram, program);
  }

  void setRegion(String region) {
    state = state.copyWith(region: region, division: 'All');
    prefs?.setString(keyRegion, region);
    prefs?.setString(keyDivision, 'All');
  }

  void setDivision(String division) {
    state = state.copyWith(division: division);
    prefs?.setString(keyDivision, division);
  }

  void resetFilters() {
    state = const EventFiltersState(program: 'All', region: 'All', division: 'All');
    prefs?.setString(keyProgram, 'All');
    prefs?.setString(keyRegion, 'All');
    prefs?.setString(keyDivision, 'All');
  }
}

final eventFiltersProvider =
    StateNotifierProvider<EventFiltersNotifier, EventFiltersState>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return EventFiltersNotifier(prefs);
  } catch (_) {
    return EventFiltersNotifier(null);
  }
});
