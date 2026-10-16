import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../event_data/services/vex_events_client.dart';
import '../../event_selection/state/event_controller.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';

// Stream of matches for the currently active tournament SKU
final activeTournamentMatchesProvider = StreamProvider.autoDispose<List<Matche>>((ref) {
  try {
    final db = ref.watch(databaseProvider);
    final settings = ref.watch(syncSettingsProvider);
    return db.watchMatchesForSku(settings.currentSku).handleError((_) => <Matche>[]);
  } catch (_) {
    return Stream.value(<Matche>[]);
  }
});

class MatchScheduleController extends Notifier<bool> {
  @override
  bool build() => false;

  AppDatabase get _db => ref.read(databaseProvider);
  VexEventsClient get _client => ref.read(vexEventsClientProvider);

  /// Look for updates to the matches list for the active SKU
  Future<VexEventsFetchResult> refreshMatches({String? sku}) async {
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
        fetchTeams: false,
        fetchMatches: true,
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

final matchScheduleControllerProvider =
    NotifierProvider<MatchScheduleController, bool>(MatchScheduleController.new);
