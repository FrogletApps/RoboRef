import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/sku_utils.dart';

enum ServerConnectionStatus {
  unknown,
  connectedLocal,
  connectedCloud,
  unreachable,
}

class ServerHealthResult {
  final bool isSuccess;
  final ServerConnectionStatus status;
  final String message;
  final int? statusCode;
  final Duration? latency;

  const ServerHealthResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.statusCode,
    this.latency,
  });
}

Uri? buildHealthCheckUri(String rawUrl) {
  var url = rawUrl.trim();
  if (url.isEmpty) return null;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'http://$url';
  }
  url = url.replaceAll(RegExp(r'/+$'), '');
  if (url.endsWith('/api/health')) {
    return Uri.tryParse(url);
  }
  return Uri.tryParse('$url/api/health');
}

/// Resolves the default sync server URL based on persistent storage or active environment.
String resolveDefaultServerUrl({
  SharedPreferences? prefs,
  AppEnvironment? environment,
  String? webOrigin,
  bool isWeb = kIsWeb,
}) {
  final stored = prefs?.getString('server_url');
  if (stored != null && stored.trim().isNotEmpty) {
    return stored.trim();
  }

  final env = environment ?? getAppEnvironment();
  switch (env) {
    case AppEnvironment.local:
      return 'http://localhost:8080';
    case AppEnvironment.test:
      if (isWeb) {
        try {
          final origin = webOrigin ?? (Uri.base.origin.startsWith('http') ? Uri.base.origin : null);
          if (origin != null && (origin.contains('test.') || origin.contains('workers.dev'))) {
            return origin;
          }
        } catch (_) {}
      }
      return 'https://test.roboref.app';
    case AppEnvironment.production:
      if (isWeb) {
        try {
          final origin = webOrigin ?? (Uri.base.origin.startsWith('http') ? Uri.base.origin : null);
          if (origin != null &&
              !origin.contains('localhost') &&
              !origin.contains('127.0.0.1') &&
              !origin.endsWith('.local')) {
            return origin;
          }
        } catch (_) {}
      }
      return 'http://roboref.local:8080';
  }
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
  final String? lastConnectionMessage;
  final bool? lastConnectionSuccess;

  SyncSettingsState({
    required this.currentSku,
    required this.refereeName,
    required this.deviceId,
    required this.serverUrl,
    this.isSyncing = false,
    this.lastSyncTime,
    this.lastError,
    this.connectionStatus = ServerConnectionStatus.unknown,
    this.lastConnectionMessage,
    this.lastConnectionSuccess,
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
    String? lastConnectionMessage,
    bool? lastConnectionSuccess,
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
      lastConnectionMessage: lastConnectionMessage ?? this.lastConnectionMessage,
      lastConnectionSuccess: lastConnectionSuccess ?? this.lastConnectionSuccess,
    );
  }
}

class SyncSettingsNotifier extends StateNotifier<SyncSettingsState> {
  final SharedPreferences prefs;
  final http.Client? httpClient;

  SyncSettingsNotifier(this.prefs, {this.httpClient, AppEnvironment? environment})
      : super(SyncSettingsState(
          currentSku: prefs.getString('current_sku') ?? 'DEMO-EVENT-2026',
          refereeName: prefs.getString('referee_name') ?? 'Head Referee',
          deviceId: prefs.getString('device_id') ?? const Uuid().v4(),
          serverUrl: resolveDefaultServerUrl(prefs: prefs, environment: environment),
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

  Future<ServerHealthResult> checkServerHealth([String? testUrl]) async {
    final targetUrl = testUrl != null ? testUrl.trim() : state.serverUrl.trim();

    if (targetUrl.isEmpty) {
      const result = ServerHealthResult(
        isSuccess: false,
        status: ServerConnectionStatus.unreachable,
        message: 'Server URL is empty',
      );
      state = state.copyWith(
        connectionStatus: ServerConnectionStatus.unreachable,
        lastConnectionMessage: 'Server URL is empty',
        lastConnectionSuccess: false,
      );
      return result;
    }

    final uri = buildHealthCheckUri(targetUrl);
    if (uri == null) {
      const result = ServerHealthResult(
        isSuccess: false,
        status: ServerConnectionStatus.unreachable,
        message: 'Invalid server URL format',
      );
      state = state.copyWith(
        connectionStatus: ServerConnectionStatus.unreachable,
        lastConnectionMessage: 'Invalid server URL format',
        lastConnectionSuccess: false,
      );
      return result;
    }

    final stopwatch = Stopwatch()..start();
    try {
      final client = httpClient ?? http.Client();
      final res = await client.get(uri).timeout(const Duration(seconds: 4));
      stopwatch.stop();

      if (res.statusCode == 200) {
        final hostLower = uri.host.toLowerCase();
        final isLocal = hostLower.contains('roboref.local') ||
            hostLower == '127.0.0.1' ||
            hostLower == 'localhost' ||
            hostLower.startsWith('192.168.') ||
            hostLower.startsWith('10.') ||
            hostLower.startsWith('172.');
        final status = isLocal
            ? ServerConnectionStatus.connectedLocal
            : ServerConnectionStatus.connectedCloud;
        final isLocalhost = hostLower == 'localhost' || hostLower == '127.0.0.1';
        final serverType = isLocalhost
            ? 'Local Server'
            : (isLocal ? 'Venue LAN' : 'Cloud Server');
        final latencyMs = stopwatch.elapsedMilliseconds;
        final msg = 'Connected to $serverType ($latencyMs ms)';

        state = state.copyWith(
          connectionStatus: status,
          lastConnectionMessage: msg,
          lastConnectionSuccess: true,
        );

        return ServerHealthResult(
          isSuccess: true,
          status: status,
          message: msg,
          statusCode: res.statusCode,
          latency: stopwatch.elapsed,
        );
      } else {
        final msg = 'Server reachable but returned HTTP ${res.statusCode}';
        state = state.copyWith(
          connectionStatus: ServerConnectionStatus.unreachable,
          lastConnectionMessage: msg,
          lastConnectionSuccess: false,
        );
        return ServerHealthResult(
          isSuccess: false,
          status: ServerConnectionStatus.unreachable,
          message: msg,
          statusCode: res.statusCode,
          latency: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      String errorMsg = 'Could not reach server';
      final eStr = e.toString().toLowerCase();
      if (eStr.contains('timeoutexception') || eStr.contains('timed out')) {
        errorMsg = 'Connection timed out (server unreachable)';
      } else if (eStr.contains('socketexception') ||
          eStr.contains('failed host lookup') ||
          eStr.contains('connection refused')) {
        errorMsg = 'Connection refused / host unreachable';
      } else if (eStr.contains('clientexception')) {
        errorMsg = 'Network or CORS error connecting to server';
      } else if (eStr.contains('formatexception')) {
        errorMsg = 'Invalid server URL format';
      }

      state = state.copyWith(
        connectionStatus: ServerConnectionStatus.unreachable,
        lastConnectionMessage: errorMsg,
        lastConnectionSuccess: false,
      );

      return ServerHealthResult(
        isSuccess: false,
        status: ServerConnectionStatus.unreachable,
        message: errorMsg,
        latency: stopwatch.elapsed,
      );
    }
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
