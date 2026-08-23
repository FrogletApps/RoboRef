import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../database/app_database.dart';

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
    required this.baseUrl,
    required this.deviceId,
  });

  // Pull new notes updated on server since localVersion
  Future<List<Map<String, dynamic>>> pullChanges({
    required String sku,
    required int sinceVersion,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/sync/pull?sku=$sku&since=$sinceVersion');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['changes'] is List) {
          return List<Map<String, dynamic>>.from(data['changes']);
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
        return SyncResult(
          success: true,
          latestVersion: data['latestVersion'] ?? 0,
          syncedCount: data['appliedCount'] ?? localNotes.length,
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
