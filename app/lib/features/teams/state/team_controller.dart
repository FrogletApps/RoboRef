import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/team_utils.dart';
import '../../../database/app_database.dart';
import '../../event_data/services/vex_events_client.dart';
import '../../event_selection/state/event_controller.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';

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
        errorMessage: 'Refresh already in progress',
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
