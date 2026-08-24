import 'package:flutter/foundation.dart';
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
  final bool isSyncing;
  final String? lastSyncTime;
  final String? lastError;
  final ServerConnectionStatus connectionStatus;

  SyncSettingsState({
    required this.currentSku,
    required this.refereeName,
    required this.deviceId,
    required this.serverUrl,
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastError,
    this.connectionStatus = ServerConnectionStatus.unknown,
  });

  SyncSettingsState copyWith({
    String? currentSku,
    String? refereeName,
    String? deviceId,
    String? serverUrl,
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
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}

class SyncSettingsNotifier extends StateNotifier<SyncSettingsState> {
  final SharedPreferences prefs;

  static String _getDefaultServerUrl(SharedPreferences prefs) {
    final stored = prefs.getString('server_url');
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin.startsWith('http')) {
          return origin;
        }
      } catch (_) {}
    }
    return 'http://roboref.local:8080';
  }

  SyncSettingsNotifier(this.prefs)
      : super(SyncSettingsState(
          currentSku: prefs.getString('current_sku') ?? 'DEMO-EVENT-2026',
          refereeName: prefs.getString('referee_name') ?? 'Head Referee',
          deviceId: prefs.getString('device_id') ?? const Uuid().v4(),
          serverUrl: _getDefaultServerUrl(prefs),
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
