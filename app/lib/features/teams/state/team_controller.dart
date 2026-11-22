import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/team_utils.dart';
import '../../../database/app_database.dart';
import '../../event_data/services/vex_events_client.dart';
import '../../event_selection/state/event_controller.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';

class TeamSortState {
  final TeamSortField field;
  final bool ascending;

  const TeamSortState({
    this.field = TeamSortField.number,
    this.ascending = true,
  });

  TeamSortState copyWith({
    TeamSortField? field,
    bool? ascending,
  }) {
    return TeamSortState(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamSortState &&
        other.field == field &&
        other.ascending == ascending;
  }

  @override
  int get hashCode => Object.hash(field, ascending);
}

class TeamSortController extends Notifier<TeamSortState> {
  static const String keySortField = 'team_list_sort_field';
  static const String keySortAscending = 'team_list_sort_ascending';

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  static TeamSortField _parseSortField(String? raw) {
    if (raw == null) return TeamSortField.number;
    for (final value in TeamSortField.values) {
      if (value.name == raw) return value;
    }
    return TeamSortField.number;
  }

  void _persist(TeamSortState next) {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(keySortField, next.field.name);
    prefs.setBool(keySortAscending, next.ascending);
  }

  @override
  TeamSortState build() {
    SharedPreferences? prefs;
    try {
      prefs = ref.watch(sharedPreferencesProvider);
    } catch (_) {
      prefs = null;
    }
    final field = _parseSortField(prefs?.getString(keySortField));
    final ascending = prefs?.getBool(keySortAscending) ?? true;
    return TeamSortState(field: field, ascending: ascending);
  }

  /// Selects [field]. If [field] is already active, toggles sort direction;
  /// otherwise switches to [field] in ascending order.
  void selectSortField(TeamSortField field) {
    final next = state.field == field
        ? state.copyWith(ascending: !state.ascending)
        : TeamSortState(field: field, ascending: true);
    state = next;
    _persist(next);
  }

  /// Explicitly sets both sort [field] and [ascending] direction.
  void setSort(TeamSortField field, {bool ascending = true}) {
    final next = TeamSortState(field: field, ascending: ascending);
    state = next;
    _persist(next);
  }
}

final teamSortProvider =
    NotifierProvider<TeamSortController, TeamSortState>(TeamSortController.new);

// Stream of registered tournament teams for the active SKU
final activeTournamentTeamsProvider = StreamProvider.autoDispose<List<Team>>((ref) {
  try {
    final db = ref.watch(databaseProvider);
    final settings = ref.watch(syncSettingsProvider);
    return db
        .watchTeamsForSku(settings.currentSku)
        .map((teams) => List<Team>.from(teams)..sort(compareTeams))
        .handleError((_) => <Team>[]);
  } catch (_) {
    return Stream.value(<Team>[]);
  }
});

class TeamListController extends Notifier<bool> {
  @override
  bool build() => false;

  AppDatabase get _db => ref.read(databaseProvider);
  VexEventsClient get _client => ref.read(vexEventsClientProvider);

  /// Look for updates to the teams list and rankings for the active SKU
  Future<VexEventsFetchResult> refreshTeams({
    String? sku,
    bool forceRefresh = true,
  }) async {
    if (state) {
      return VexEventsFetchResult(
        success: false,
        errorMessage: lookupL10n().errorRefreshAlreadyInProgress,
      );
    }

    state = true;
    final currentSku = sku ?? ref.read(syncSettingsProvider).currentSku;

    try {
      final result = await _client.fetchTournamentData(
        sku: currentSku,
        db: _db,
        fetchTeams: true,
        fetchMatches: false,
        forceRefresh: forceRefresh,
      );
      return result;
    } catch (e) {
      return VexEventsFetchResult(
        success: false,
        errorMessage: e.toString(),
      );
    } finally {
      state = false;
    }
  }
}

final teamListControllerProvider =
    NotifierProvider<TeamListController, bool>(TeamListController.new);
