import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';

// Stream of registered tournament teams for the active SKU
final activeTournamentTeamsProvider = StreamProvider.autoDispose<List<Team>>((ref) {
  try {
    final db = ref.watch(databaseProvider);
    final settings = ref.watch(syncSettingsProvider);
    return db.watchTeamsForSku(settings.currentSku).handleError((_) => <Team>[]);
  } catch (_) {
    return Stream.value(<Team>[]);
  }
});
