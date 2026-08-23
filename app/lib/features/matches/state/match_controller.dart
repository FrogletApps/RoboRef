import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';

// Stream of matches for the currently active tournament SKU
final activeTournamentMatchesProvider = StreamProvider.autoDispose<List<Matche>>((ref) {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(syncSettingsProvider);
  return db.watchMatchesForSku(settings.currentSku);
});
