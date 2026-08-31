import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../../incidents/state/incident_controller.dart';
import '../../../database/app_database.dart';
import '../models/share_models.dart';
import '../services/share_client.dart';

class EventShareState {
  final String sku;
  final bool isShared;
  final String? shareId;
  final ShareRole? role;
  final String? adminRefereeName;
  final String? adminDeviceId;
  final List<ShareParticipantModel> participants;
  final bool isLoading;
  final String? errorMessage;
  final bool isConflict;
  final String? conflictMessage;
  final List<ActiveShareSummary> existingShares;

  const EventShareState({
    required this.sku,
    this.isShared = false,
    this.shareId,
    this.role,
    this.adminRefereeName,
    this.adminDeviceId,
    this.participants = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isConflict = false,
    this.conflictMessage,
    this.existingShares = const [],
  });

  EventShareState copyWith({
    String? sku,
    bool? isShared,
    String? shareId,
    ShareRole? role,
    String? adminRefereeName,
    String? adminDeviceId,
    List<ShareParticipantModel>? participants,
    bool? isLoading,
    String? errorMessage,
    bool? isConflict,
    String? conflictMessage,
    List<ActiveShareSummary>? existingShares,
  }) {
    return EventShareState(
      sku: sku ?? this.sku,
      isShared: isShared ?? this.isShared,
      shareId: shareId ?? this.shareId,
      role: role ?? this.role,
      adminRefereeName: adminRefereeName ?? this.adminRefereeName,
      adminDeviceId: adminDeviceId ?? this.adminDeviceId,
      participants: participants ?? this.participants,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isConflict: isConflict ?? this.isConflict,
      conflictMessage: conflictMessage ?? this.conflictMessage,
      existingShares: existingShares ?? this.existingShares,
    );
  }
}

class ShareController extends StateNotifier<EventShareState> {
  final Ref ref;

  ShareController(this.ref)
      : super(EventShareState(
          sku: ref.read(syncSettingsProvider).currentSku,
        )) {
    ref.listen<SyncSettingsState>(syncSettingsProvider, (previous, next) {
      if (previous?.currentSku != next.currentSku) {
        loadEventShareState(next.currentSku);
      }
    });
    loadEventShareState(state.sku);
  }

  AppDatabase get _db => ref.read(databaseProvider);
  SyncSettingsState get _settings => ref.read(syncSettingsProvider);

  ShareClient get _client => ShareClient(
        baseUrl: _settings.serverUrl,
      );

  /// Load persistent share state from local database for an event SKU
  Future<void> loadEventShareState(String sku) async {
    state = state.copyWith(sku: sku, isLoading: true, errorMessage: null);

    try {
      final event = await _db.getEventBySku(sku);
      if (event != null && event.isShared && event.shareId != null) {
        final role = ShareRole.fromString(event.shareRole);
        state = state.copyWith(
          isShared: true,
          shareId: event.shareId,
          role: role,
          adminRefereeName: event.adminRefereeName,
          adminDeviceId: event.adminDeviceId,
          isLoading: false,
        );
        // Refresh live status from server
        refreshShareStatus(sku);
      } else {
        state = state.copyWith(
          isShared: false,
          shareId: null,
          role: null,
          adminRefereeName: null,
          adminDeviceId: null,
          participants: [],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Check active shares on server for existing share conflict detection
  Future<List<ActiveShareSummary>> checkActiveShares(String sku) async {
    return _client.checkActiveShares(sku);
  }

  /// Create a new share session for an event
  Future<CreateShareResult> createShare(String sku, {bool force = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isConflict: false);

    final result = await _client.createShareSession(
      sku: sku,
      adminDeviceId: _settings.deviceId,
      adminRefereeName: _settings.refereeName,
      force: force,
    );

    if (result.success && result.session != null) {
      final session = result.session!;
      await _db.updateEventShareState(
        sku,
        isShared: true,
        shareId: session.id,
        shareRole: 'admin',
        adminRefereeName: session.adminRefereeName,
        adminDeviceId: session.adminDeviceId,
      );

      state = state.copyWith(
        isShared: true,
        shareId: session.id,
        role: ShareRole.admin,
        adminRefereeName: session.adminRefereeName,
        adminDeviceId: session.adminDeviceId,
        participants: session.participants,
        isLoading: false,
        isConflict: false,
      );

      // Trigger initial push to sync server
      ref.read(incidentControllerProvider.notifier).triggerSync();
    } else if (result.isConflict) {
      state = state.copyWith(
        isLoading: false,
        isConflict: true,
        conflictMessage: result.conflictMessage,
        existingShares: result.existingShares,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage ?? 'Failed to create share',
      );
    }

    return result;
  }

  /// Join an existing share session
  Future<bool> joinShare({
    required String shareId,
    required String sku,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final session = await _client.joinShareSession(
      shareId: shareId.trim().toUpperCase(),
      sku: sku,
      deviceId: _settings.deviceId,
      refereeName: _settings.refereeName,
    );

    if (session != null) {
      final role = session.adminDeviceId == _settings.deviceId ? ShareRole.admin : ShareRole.member;
      await _db.updateEventShareState(
        sku,
        isShared: true,
        shareId: session.id,
        shareRole: role.name,
        adminRefereeName: session.adminRefereeName,
        adminDeviceId: session.adminDeviceId,
      );

      state = state.copyWith(
        isShared: true,
        shareId: session.id,
        role: role,
        adminRefereeName: session.adminRefereeName,
        adminDeviceId: session.adminDeviceId,
        participants: session.participants,
        isLoading: false,
        isConflict: false,
      );

      // Sync notes from server
      ref.read(incidentControllerProvider.notifier).triggerSync();
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not join share session. Check code or connection.',
      );
      return false;
    }
  }

  /// Leave the current share session
  Future<LeaveShareResult> leaveShare(String sku) async {
    final shareId = state.shareId;
    if (shareId == null) {
      return LeaveShareResult(success: true);
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _client.leaveShareSession(
      shareId: shareId,
      deviceId: _settings.deviceId,
    );

    if (result.success) {
      await _db.updateEventShareState(
        sku,
        isShared: false,
        shareId: null,
        shareRole: null,
        adminRefereeName: null,
        adminDeviceId: null,
      );

      state = state.copyWith(
        isShared: false,
        shareId: null,
        role: null,
        adminRefereeName: null,
        adminDeviceId: null,
        participants: [],
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      );
    }

    return result;
  }

  /// Admin removes/kicks a participant from the share session
  Future<bool> removeParticipant({
    required String sku,
    required String targetDeviceId,
  }) async {
    final shareId = state.shareId;
    if (shareId == null || state.role != ShareRole.admin) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final session = await _client.removeParticipant(
      shareId: shareId,
      adminDeviceId: _settings.deviceId,
      targetDeviceId: targetDeviceId,
    );

    if (session != null) {
      state = state.copyWith(
        participants: session.participants,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to remove participant',
      );
      return false;
    }
  }

  /// Refresh share status and participants list from server
  Future<void> refreshShareStatus(String sku) async {
    final shareId = state.shareId;
    if (shareId == null || !state.isShared) return;

    final session = await _client.getShareStatus(shareId, deviceId: _settings.deviceId);

    if (session != null) {
      final isStillMember = session.participants.any((p) => p.deviceId == _settings.deviceId);

      if (!isStillMember) {
        // Device was removed / kicked by admin
        await _db.updateEventShareState(
          sku,
          isShared: false,
          shareId: null,
          shareRole: null,
          adminRefereeName: null,
          adminDeviceId: null,
        );

        state = state.copyWith(
          isShared: false,
          shareId: null,
          role: null,
          adminRefereeName: null,
          adminDeviceId: null,
          participants: [],
          errorMessage: 'You were removed from this shared event session.',
        );
      } else {
        state = state.copyWith(
          participants: session.participants,
          adminRefereeName: session.adminRefereeName,
          adminDeviceId: session.adminDeviceId,
        );
      }
    }
  }
}

final shareControllerProvider =
    StateNotifierProvider<ShareController, EventShareState>((ref) {
  return ShareController(ref);
});
