import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../settings/state/sync_settings_controller.dart';
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
    required String baseUrl,
    this.httpClient,
  }) : baseUrl = normalizeServerBaseUrl(baseUrl);

  http.Client get _client => httpClient ?? http.Client();

  Map<String, dynamic>? _tryDecodeMap(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  /// Check active shares on server for a tournament SKU
  Future<List<ActiveShareSummary>> checkActiveShares(String sku) async {
    if (baseUrl.isEmpty) return [];
    try {
      final uri = Uri.parse('$baseUrl/api/share/check').replace(
        queryParameters: {'sku': sku},
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = _tryDecodeMap(response.body);
        final rawShares = data?['activeShares'];
        if (rawShares is List) {
          return rawShares
              .whereType<Map>()
              .map((s) => ActiveShareSummary.fromJson(Map<String, dynamic>.from(s)))
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
    if (baseUrl.isEmpty) {
      return CreateShareResult(
        success: false,
        errorMessage: 'Sync server URL is not configured',
      );
    }
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

      final data = _tryDecodeMap(response.body);
      final rawSession = data?['session'];

      if (response.statusCode == 200 &&
          data != null &&
          data['success'] == true &&
          rawSession is Map) {
        return CreateShareResult(
          success: true,
          session: ShareSessionModel.fromJson(Map<String, dynamic>.from(rawSession)),
        );
      } else if (response.statusCode == 409 &&
          data != null &&
          data['error'] == 'SHARE_ALREADY_EXISTS') {
        final rawExisting = data['existingShares'];
        final existing = rawExisting is List
            ? rawExisting
                .whereType<Map>()
                .map((s) => ActiveShareSummary.fromJson(Map<String, dynamic>.from(s)))
                .toList()
            : <ActiveShareSummary>[];
        return CreateShareResult(
          success: false,
          isConflict: true,
          conflictMessage: data['message']?.toString(),
          existingShares: existing,
        );
      } else {
        final serverError = data?['error']?.toString();
        return CreateShareResult(
          success: false,
          errorMessage: (serverError != null && serverError.isNotEmpty)
              ? serverError
              : 'Failed to create share session (HTTP ${response.statusCode})',
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
    if (baseUrl.isEmpty) return null;
    try {
      final uri = Uri.parse('$baseUrl/api/share/status').replace(
        queryParameters: {
          'shareId': shareId,
          if (deviceId != null) 'deviceId': deviceId,
        },
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = _tryDecodeMap(response.body);
        final rawSession = data?['session'];
        if (rawSession is Map) {
          return ShareSessionModel.fromJson(Map<String, dynamic>.from(rawSession));
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
    if (baseUrl.isEmpty) return null;
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
        final data = _tryDecodeMap(response.body);
        final rawSession = data?['session'];
        if (rawSession is Map) {
          return ShareSessionModel.fromJson(Map<String, dynamic>.from(rawSession));
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
    if (baseUrl.isEmpty) {
      return LeaveShareResult(
        success: false,
        errorMessage: 'Sync server URL is not configured',
      );
    }
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

      final data = _tryDecodeMap(response.body);

      if (response.statusCode == 200 && data != null) {
        return LeaveShareResult(
          success: true,
          deleted: data['deleted'] == true,
          remainingCount: (data['remainingCount'] is num)
              ? (data['remainingCount'] as num).toInt()
              : 0,
        );
      } else if (response.statusCode == 400 &&
          data != null &&
          data['error'] == 'ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS') {
        return LeaveShareResult(
          success: false,
          isAdminBlocked: true,
          errorMessage: data['message']?.toString() ??
              'The admin cannot leave while other referees are in the session.',
        );
      } else {
        final serverError = data?['error']?.toString();
        return LeaveShareResult(
          success: false,
          errorMessage: (serverError != null && serverError.isNotEmpty)
              ? serverError
              : 'Failed to leave share session',
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
    if (baseUrl.isEmpty) return null;
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
        final data = _tryDecodeMap(response.body);
        final rawSession = data?['session'];
        if (rawSession is Map) {
          return ShareSessionModel.fromJson(Map<String, dynamic>.from(rawSession));
        }
      }
    } catch (_) {}
    return null;
  }

  /// Update referee name across connected sessions
  Future<ShareSessionModel?> updateRefereeName({
    required String deviceId,
    required String refereeName,
    String? shareId,
    String? sku,
  }) async {
    if (baseUrl.isEmpty) return null;
    try {
      final uri = Uri.parse('$baseUrl/api/share/update-name');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (shareId != null) 'shareId': shareId,
              if (sku != null) 'sku': sku,
              'deviceId': deviceId,
              'refereeName': refereeName,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = _tryDecodeMap(response.body);
        final rawSession = data?['session'];
        if (rawSession is Map) {
          return ShareSessionModel.fromJson(Map<String, dynamic>.from(rawSession));
        }
      }
    } catch (_) {}
    return null;
  }
}
