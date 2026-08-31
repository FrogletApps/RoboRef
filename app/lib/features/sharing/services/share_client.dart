import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/share_models.dart';

class CreateShareResult {
  final bool success;
  final ShareSessionModel? session;
  final bool isConflict;
  final String? conflictMessage;
  final List<ActiveShareSummary> existingShares;
  final String? errorMessage;

  CreateShareResult({
    required this.success,
    this.session,
    this.isConflict = false,
    this.conflictMessage,
    this.existingShares = const [],
    this.errorMessage,
  });
}

class LeaveShareResult {
  final bool success;
  final bool deleted;
  final int remainingCount;
  final bool isAdminBlocked;
  final String? errorMessage;

  LeaveShareResult({
    required this.success,
    this.deleted = false,
    this.remainingCount = 0,
    this.isAdminBlocked = false,
    this.errorMessage,
  });
}

class ShareClient {
  final String baseUrl;
  final http.Client? httpClient;

  ShareClient({
    required this.baseUrl,
    this.httpClient,
  });

  http.Client get _client => httpClient ?? http.Client();

  /// Check active shares on server for a tournament SKU
  Future<List<ActiveShareSummary>> checkActiveShares(String sku) async {
    try {
      final uri = Uri.parse('$baseUrl/api/share/check?sku=$sku');
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['activeShares'] is List) {
          return (data['activeShares'] as List)
              .map((s) => ActiveShareSummary.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Create a new share session for an event
  Future<CreateShareResult> createShareSession({
    required String sku,
    required String adminDeviceId,
    required String adminRefereeName,
    bool force = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/share/create');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'sku': sku,
              'adminDeviceId': adminDeviceId,
              'adminRefereeName': adminRefereeName,
              'force': force,
            }),
          )
          .timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return CreateShareResult(
          success: true,
          session: ShareSessionModel.fromJson(data['session'] as Map<String, dynamic>),
        );
      } else if (response.statusCode == 409 && data['error'] == 'SHARE_ALREADY_EXISTS') {
        final existing = (data['existingShares'] as List<dynamic>?)
                ?.map((s) => ActiveShareSummary.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [];
        return CreateShareResult(
          success: false,
          isConflict: true,
          conflictMessage: data['message'] as String?,
          existingShares: existing,
        );
      } else {
        return CreateShareResult(
          success: false,
          errorMessage: data['error'] as String? ?? 'Failed to create share session',
        );
      }
    } catch (e) {
      return CreateShareResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get status of a share session
  Future<ShareSessionModel?> getShareStatus(String shareId, {String? deviceId}) async {
    try {
      final queryParams = 'shareId=$shareId${deviceId != null ? '&deviceId=$deviceId' : ''}';
      final uri = Uri.parse('$baseUrl/api/share/status?$queryParams');
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['session'] is Map<String, dynamic>) {
          return ShareSessionModel.fromJson(data['session'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Join an existing share session
  Future<ShareSessionModel?> joinShareSession({
    required String shareId,
    required String deviceId,
    required String refereeName,
    String? sku,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/share/join');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'shareId': shareId,
              'sku': sku,
              'deviceId': deviceId,
              'refereeName': refereeName,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['session'] is Map<String, dynamic>) {
          return ShareSessionModel.fromJson(data['session'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Leave a share session
  Future<LeaveShareResult> leaveShareSession({
    required String shareId,
    required String deviceId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/share/leave');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'shareId': shareId,
              'deviceId': deviceId,
            }),
          )
          .timeout(const Duration(seconds: 6));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return LeaveShareResult(
          success: true,
          deleted: data['deleted'] as bool? ?? false,
          remainingCount: data['remainingCount'] as int? ?? 0,
        );
      } else if (response.statusCode == 400 &&
          data['error'] == 'ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS') {
        return LeaveShareResult(
          success: false,
          isAdminBlocked: true,
          errorMessage: data['message'] as String? ??
              'The admin cannot leave while other referees are in the session.',
        );
      } else {
        return LeaveShareResult(
          success: false,
          errorMessage: data['error'] as String? ?? 'Failed to leave share session',
        );
      }
    } catch (e) {
      return LeaveShareResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Admin removes a participant from the share session
  Future<ShareSessionModel?> removeParticipant({
    required String shareId,
    required String adminDeviceId,
    required String targetDeviceId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/share/remove-participant');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'shareId': shareId,
              'adminDeviceId': adminDeviceId,
              'targetDeviceId': targetDeviceId,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['session'] is Map<String, dynamic>) {
          return ShareSessionModel.fromJson(data['session'] as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }
}
