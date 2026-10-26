import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../database/app_database.dart';
import '../../features/settings/state/sync_settings_controller.dart';

class SyncResult {
  final bool success;
  final int latestVersion;
  final int syncedCount;
  final String? errorMessage;

  SyncResult({
    required this.success,
    required this.latestVersion,
    required this.syncedCount,
    this.errorMessage,
  });
}

class SyncClient {
  final String baseUrl;
  final String deviceId;

  SyncClient({
    required String baseUrl,
    required this.deviceId,
  }) : baseUrl = normalizeServerBaseUrl(baseUrl);

  // Pull new notes updated on server since localVersion
  Future<List<Map<String, dynamic>>> pullChanges({
    required String sku,
    required int sinceVersion,
  }) async {
    if (baseUrl.isEmpty) return [];
    try {
      final uri = Uri.parse('$baseUrl/api/sync/pull').replace(
        queryParameters: {
          'sku': sku,
          'since': sinceVersion.toString(),
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['changes'] is List) {
          return (data['changes'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (e) {
      // Offline / server unreachable - gracefully return empty list
    }
    return [];
  }

  // Push local dirty/unsynced incident notes to server
  Future<SyncResult> pushChanges({
    required String sku,
    required List<IncidentNote> localNotes,
  }) async {
    if (localNotes.isEmpty) {
      return SyncResult(success: true, latestVersion: 0, syncedCount: 0);
    }
    if (baseUrl.isEmpty) {
      return SyncResult(
        success: false,
        latestVersion: 0,
        syncedCount: 0,
        errorMessage: 'Sync server URL is not configured',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/api/sync/push');
      final payload = {
        'sku': sku,
        'deviceId': deviceId,
        'changes': localNotes.map((n) => {
          'id': n.id,
          'sku': n.sku,
          'teamNumber': n.teamNumber,
          'matchId': n.matchId,
          'ruleCodes': jsonDecode(n.ruleCodesJson),
          'severity': n.severity,
          'notes': n.notes,
          'refereeName': n.refereeName,
          'deviceId': n.deviceId,
          'createdAt': n.createdAt,
          'updatedAt': n.updatedAt,
          'isDeleted': n.isDeleted,
          'version': n.version,
        }).toList(),
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final map = data is Map ? data : const {};
        return SyncResult(
          success: true,
          latestVersion: (map['latestVersion'] is num) ? (map['latestVersion'] as num).toInt() : 0,
          syncedCount: (map['appliedCount'] is num) ? (map['appliedCount'] as num).toInt() : localNotes.length,
        );
      } else {
        return SyncResult(
          success: false,
          latestVersion: 0,
          syncedCount: 0,
          errorMessage: 'Server responded with status ${response.statusCode}',
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        latestVersion: 0,
        syncedCount: 0,
        errorMessage: e.toString(),
      );
    }
  }
}
