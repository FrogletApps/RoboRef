import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../settings/state/sync_settings_controller.dart';

class RulesDisclaimerNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences? prefs;
  static const String keyDismissedSkus = 'rules_disclaimer_dismissed_skus';

  RulesDisclaimerNotifier(this.prefs) : super(_loadDismissedSkus(prefs));

  static Set<String> _loadDismissedSkus(SharedPreferences? prefs) {
    if (prefs == null) return <String>{};
    final list = prefs.getStringList(keyDismissedSkus) ?? <String>[];
    return list.map((s) => s.trim().toUpperCase()).where((s) => s.isNotEmpty).toSet();
  }

  bool isDismissed(String sku) {
    final clean = sku.trim().toUpperCase();
    if (clean.isEmpty) return false;
    return state.contains(clean);
  }

  Future<void> dismiss(String sku) async {
    final clean = sku.trim().toUpperCase();
    if (clean.isEmpty || state.contains(clean)) return;
    final updated = {...state, clean};
    state = updated;
    await prefs?.setStringList(keyDismissedSkus, updated.toList());
  }

  Future<void> reset(String sku) async {
    final clean = sku.trim().toUpperCase();
    if (!state.contains(clean)) return;
    final updated = Set<String>.from(state)..remove(clean);
    state = updated;
    await prefs?.setStringList(keyDismissedSkus, updated.toList());
  }
}

final rulesDisclaimerProvider =
    StateNotifierProvider<RulesDisclaimerNotifier, Set<String>>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return RulesDisclaimerNotifier(prefs);
  } catch (_) {
    return RulesDisclaimerNotifier(null);
  }
});
