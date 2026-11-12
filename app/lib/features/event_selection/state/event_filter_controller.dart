import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/event_regions.dart';
import '../../settings/state/sync_settings_controller.dart';

class EventFiltersState {
  final Set<String> programs;
  final Set<String> regions;
  final Set<String> divisions;

  const EventFiltersState({
    this.programs = const {},
    this.regions = const {},
    this.divisions = const {},
  });

  /// Single-value summary getters (returns 'All' when empty)
  String get program => programs.isEmpty
      ? 'All'
      : (programs.length == 1 ? programs.first : programs.join(','));

  String get region => regions.isEmpty
      ? 'All'
      : (regions.length == 1 ? regions.first : regions.join(','));

  String get division => divisions.isEmpty
      ? 'All'
      : (divisions.length == 1 ? divisions.first : divisions.join(','));

  bool get hasActiveFilters =>
      programs.isNotEmpty || regions.isNotEmpty || divisions.isNotEmpty;

  EventFiltersState copyWith({
    Set<String>? programs,
    Set<String>? regions,
    Set<String>? divisions,
  }) {
    return EventFiltersState(
      programs: programs ?? this.programs,
      regions: regions ?? this.regions,
      divisions: divisions ?? this.divisions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventFiltersState &&
        setEquals(other.programs, programs) &&
        setEquals(other.regions, regions) &&
        setEquals(other.divisions, divisions);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(programs),
        Object.hashAllUnordered(regions),
        Object.hashAllUnordered(divisions),
      );
}

class EventFiltersNotifier extends Notifier<EventFiltersState> {
  static const String keyProgram = 'event_filter_program';
  static const String keyRegion = 'event_filter_region';
  static const String keyDivision = 'event_filter_division';

  static const String keyPrograms = 'event_filter_programs';
  static const String keyRegions = 'event_filter_regions';
  static const String keyDivisions = 'event_filter_divisions';

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  static Set<String> _normalizeSet(Iterable<String> values) {
    return Set<String>.unmodifiable(
      values.map((v) => v.trim()).where((v) => v.isNotEmpty && v != 'All'),
    );
  }

  static Set<String> _readPersistedSet(
    SharedPreferences? prefs,
    String listKey,
    String legacyKey,
  ) {
    if (prefs == null) return const {};
    final list = prefs.getStringList(listKey);
    if (list != null) {
      return _normalizeSet(list);
    }
    final legacy = prefs.getString(legacyKey);
    if (legacy != null && legacy.trim().isNotEmpty && legacy.trim() != 'All') {
      return _normalizeSet([legacy]);
    }
    return const {};
  }

  static Set<String> _pruneDivisionsForRegions(
    Set<String> divisions,
    Set<String> regions,
  ) {
    if (divisions.isEmpty || regions.isEmpty) return const {};
    final allowedDivisions = <String>{};
    for (final region in regions) {
      final config = getRegionDivisionConfig(region);
      if (config != null) {
        allowedDivisions.addAll(config.divisions);
      }
    }
    return Set<String>.unmodifiable(
      divisions.where(allowedDivisions.contains),
    );
  }

  void _persistState(EventFiltersState next) {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setStringList(keyPrograms, next.programs.toList());
    prefs.setStringList(keyRegions, next.regions.toList());
    prefs.setStringList(keyDivisions, next.divisions.toList());
    prefs.setString(keyProgram, next.program);
    prefs.setString(keyRegion, next.region);
    prefs.setString(keyDivision, next.division);
  }

  @override
  EventFiltersState build() {
    SharedPreferences? prefs;
    try {
      prefs = ref.watch(sharedPreferencesProvider);
    } catch (_) {
      prefs = null;
    }
    final regions = _readPersistedSet(prefs, keyRegions, keyRegion);
    final rawDivisions = _readPersistedSet(prefs, keyDivisions, keyDivision);
    return EventFiltersState(
      programs: _readPersistedSet(prefs, keyPrograms, keyProgram),
      regions: regions,
      divisions: _pruneDivisionsForRegions(rawDivisions, regions),
    );
  }

  void toggleProgram(String program) {
    final clean = program.trim();
    if (clean.isEmpty || clean == 'All') {
      setPrograms(const {});
      return;
    }
    final next = Set<String>.from(state.programs);
    if (!next.add(clean)) {
      next.remove(clean);
    }
    setPrograms(next);
  }

  void setPrograms(Iterable<String> programs) {
    final next = state.copyWith(programs: _normalizeSet(programs));
    state = next;
    _persistState(next);
  }

  void setProgram(String program) {
    final clean = program.trim();
    setPrograms(clean.isEmpty || clean == 'All' ? const {} : {clean});
  }

  void toggleRegion(String region) {
    final clean = region.trim();
    if (clean.isEmpty || clean == 'All') {
      setRegions(const {});
      return;
    }
    final next = Set<String>.from(state.regions);
    if (!next.add(clean)) {
      next.remove(clean);
    }
    setRegions(next);
  }

  void setRegions(Iterable<String> regions) {
    final normalizedRegions = _normalizeSet(regions);
    final prunedDivisions = _pruneDivisionsForRegions(
      state.divisions,
      normalizedRegions,
    );
    final next = state.copyWith(
      regions: normalizedRegions,
      divisions: prunedDivisions,
    );
    state = next;
    _persistState(next);
  }

  void setRegion(String region) {
    final clean = region.trim();
    final nextRegions = _normalizeSet(
      clean.isEmpty || clean == 'All' ? const [] : [clean],
    );
    final next = state.copyWith(
      regions: nextRegions,
      divisions: const {},
    );
    state = next;
    _persistState(next);
  }

  void toggleDivision(String division) {
    final clean = division.trim();
    if (clean.isEmpty || clean == 'All') {
      setDivisions(const {});
      return;
    }
    final next = Set<String>.from(state.divisions);
    if (!next.add(clean)) {
      next.remove(clean);
    }
    setDivisions(next);
  }

  void setDivisions(Iterable<String> divisions) {
    final normalized = _normalizeSet(divisions);
    final next = state.copyWith(
      divisions: state.regions.isEmpty
          ? normalized
          : _pruneDivisionsForRegions(normalized, state.regions),
    );
    state = next;
    _persistState(next);
  }

  void setDivisionsForRegion(
    RegionDivisionConfig config,
    Iterable<String> selectedForConfig,
  ) {
    final configSet = config.divisions.toSet();
    final updated = state.divisions.where((d) => !configSet.contains(d)).toSet();
    for (final div in _normalizeSet(selectedForConfig)) {
      if (configSet.contains(div)) {
        updated.add(div);
      }
    }
    final next = state.copyWith(divisions: Set<String>.unmodifiable(updated));
    state = next;
    _persistState(next);
  }

  void clearDivisionsForRegion(RegionDivisionConfig config) {
    setDivisionsForRegion(config, const {});
  }

  void setDivision(String division) {
    final clean = division.trim();
    setDivisions(clean.isEmpty || clean == 'All' ? const {} : {clean});
  }

  void resetFilters() {
    const next = EventFiltersState();
    state = next;
    _persistState(next);
  }
}

final eventFiltersProvider =
    NotifierProvider<EventFiltersNotifier, EventFiltersState>(
  EventFiltersNotifier.new,
);
