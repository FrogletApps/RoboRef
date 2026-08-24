import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

enum ServerConnectionStatus {
  unknown,
  connectedLocal,
  connectedCloud,
  unreachable,
}

class SyncSettingsState {
  final String currentSku;
  final String refereeName;
  final String deviceId;
  final String serverUrl;
  final String vexApiKey;
  final bool isSyncing;
  final String? lastSyncTime;
  final String? lastError;
  final ServerConnectionStatus connectionStatus;

  SyncSettingsState({
    required this.currentSku,
    required this.refereeName,
    required this.deviceId,
    required this.serverUrl,
    this.vexApiKey = '',
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastError,
    this.connectionStatus = ServerConnectionStatus.unknown,
  });

  bool get hasVexApiKey => vexApiKey.trim().isNotEmpty;

  SyncSettingsState copyWith({
    String? currentSku,
    String? refereeName,
    String? deviceId,
    String? serverUrl,
    String? vexApiKey,
    bool? isSyncing,
    String? lastSyncTime,
    String? lastError,
    ServerConnectionStatus? connectionStatus,
  }) {
    return SyncSettingsState(
      currentSku: currentSku ?? this.currentSku,
      refereeName: refereeName ?? this.refereeName,
      deviceId: deviceId ?? this.deviceId,
      serverUrl: serverUrl ?? this.serverUrl,
      vexApiKey: vexApiKey ?? this.vexApiKey,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      connectionStatus: connectionStatus ?? this.connectionStatus,
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
          serverUrl: prefs.getString('server_url') ?? 'http://roboref.local:8080',
          vexApiKey: prefs.getString('vex_api_key') ??
              const String.fromEnvironment('VEX_API_KEY',
                  defaultValue: String.fromEnvironment('ROBOTEVENTS_API_KEY', defaultValue: '')),
        )) {
    if (!prefs.containsKey('device_id')) {
      prefs.setString('device_id', state.deviceId);
    }
    checkServerHealth();
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
    checkServerHealth();
  }

  void setVexApiKey(String key) {
    var cleanKey = key.trim();
    if (cleanKey.toLowerCase().startsWith('bearer ')) {
      cleanKey = cleanKey.substring(7).trim();
    }
    prefs.setString('vex_api_key', cleanKey);
    state = state.copyWith(vexApiKey: cleanKey);
  }

  Future<bool> testVexApiKey(String key) async {
    var cleanKey = key.trim();
    if (cleanKey.toLowerCase().startsWith('bearer ')) {
      cleanKey = cleanKey.substring(7).trim();
    }
    if (cleanKey.isEmpty) return false;

    try {
      final uri = Uri.parse('https://www.robotevents.com/api/v2/events?per_page=1');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $cleanKey',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void setSyncing(bool syncing, {String? error}) {
    state = state.copyWith(
      isSyncing: syncing,
      lastError: error,
      lastSyncTime: syncing ? state.lastSyncTime : DateTime.now().toIso8601String(),
    );
  }

  Future<void> checkServerHealth() async {
    try {
      final uri = Uri.parse('${state.serverUrl}/api/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final isLocal = state.serverUrl.contains('roboref.local') ||
            state.serverUrl.contains('127.0.0.1') ||
            state.serverUrl.contains('192.168.') ||
            state.serverUrl.contains('10.') ||
            state.serverUrl.contains('localhost');
        state = state.copyWith(
          connectionStatus: isLocal
              ? ServerConnectionStatus.connectedLocal
              : ServerConnectionStatus.connectedCloud,
        );
        return;
      }
    } catch (_) {}
    state = state.copyWith(connectionStatus: ServerConnectionStatus.unreachable);
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
