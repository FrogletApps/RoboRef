import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SyncSettingsState {
  final String currentSku;
  final String refereeName;
  final String deviceId;
  final String serverUrl;
  final bool isSyncing;
  final String? lastSyncTime;
  final String? lastError;

  SyncSettingsState({
    required this.currentSku,
    required this.refereeName,
    required this.deviceId,
    required this.serverUrl,
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastError,
  });

  SyncSettingsState copyWith({
    String? currentSku,
    String? refereeName,
    String? deviceId,
    String? serverUrl,
    bool? isSyncing,
    String? lastSyncTime,
    String? lastError,
  }) {
    return SyncSettingsState(
      currentSku: currentSku ?? this.currentSku,
      refereeName: refereeName ?? this.refereeName,
      deviceId: deviceId ?? this.deviceId,
      serverUrl: serverUrl ?? this.serverUrl,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
    );
  }
}

class SyncSettingsNotifier extends StateNotifier<SyncSettingsState> {
  final SharedPreferences prefs;

  SyncSettingsNotifier(this.prefs)
      : super(SyncSettingsState(
          currentSku: prefs.getString('current_sku') ?? 'DEMO-EVENT-2026',
          refereeName: prefs.getString('referee_name') ?? 'Head Referee',
          deviceId: prefs.getString('device_id') ?? const Uuid().v4(),
          serverUrl: prefs.getString('server_url') ?? 'http://127.0.0.1:8080',
        )) {
    if (!prefs.containsKey('device_id')) {
      prefs.setString('device_id', state.deviceId);
    }
  }

  void setSku(String sku) {
    prefs.setString('current_sku', sku);
    state = state.copyWith(currentSku: sku);
  }

  void setRefereeName(String name) {
    prefs.setString('referee_name', name);
    state = state.copyWith(refereeName: name);
  }

  void setServerUrl(String url) {
    prefs.setString('server_url', url);
    state = state.copyWith(serverUrl: url);
  }

  void setSyncing(bool syncing, {String? error}) {
    state = state.copyWith(
      isSyncing: syncing,
      lastError: error,
      lastSyncTime: syncing ? state.lastSyncTime : DateTime.now().toIso8601String(),
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main()');
});

final syncSettingsProvider =
    StateNotifierProvider<SyncSettingsNotifier, SyncSettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncSettingsNotifier(prefs);
});
