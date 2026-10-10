import 'dart:async';
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

class ShareController extends Notifier<EventShareState> {
  AppDatabase get _db => ref.read(databaseProvider);
  SyncSettingsState get _settings => ref.read(syncSettingsProvider);

  ShareClient get _client => ShareClient(
        baseUrl: _settings.serverUrl,
        httpClient: ref.read(syncSettingsHttpClientProvider),
      );

  Timer? _nameDebounceTimer;
  String? _lastCommittedName;

  @override
  EventShareState build() {
    _lastCommittedName = ref.read(syncSettingsProvider).refereeName.trim();

    ref.listen<SyncSettingsState>(syncSettingsProvider, (previous, next) {
      if (previous?.currentSku != next.currentSku) {
        loadEventShareState(next.currentSku);
      }
      if (previous != null &&
          previous.refereeName.trim() != next.refereeName.trim() &&
          next.refereeName.trim().isNotEmpty) {
        _onRefereeNameChanged(next.refereeName.trim());
      }
    });

    final currentSku = ref.read(syncSettingsProvider).currentSku;
    Future.microtask(() {
      if (ref.mounted) {
        loadEventShareState(currentSku);
      }
    });
    return EventShareState(sku: currentSku);
  }

  void _onRefereeNameChanged(String newName) {
    _nameDebounceTimer?.cancel();
    _nameDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      flushRefereeNameChange();
    });
  }

  void flushRefereeNameChange() {
    _nameDebounceTimer?.cancel();
    final currentName = ref.read(syncSettingsProvider).refereeName.trim();
    if (currentName.isEmpty || currentName == _lastCommittedName) return;
    _lastCommittedName = currentName;
    updateRefereeName(currentName);
  }

  /// Update referee name across all connected events and on the remote sync server
  Future<void> updateRefereeName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final deviceId = _settings.deviceId;

    // 1. If currently active share, update in local state immediately
    if (state.isShared) {
      final updatedParticipants = state.participants.map((p) {
        if (p.deviceId == deviceId && p.refereeName != trimmed) {
          final previousNames = List<String>.from(p.previousNames);
          if (p.refereeName.isNotEmpty && !previousNames.contains(p.refereeName)) {
            previousNames.add(p.refereeName);
          }
          return ShareParticipantModel(
            deviceId: p.deviceId,
            refereeName: trimmed,
            role: p.role,
            joinedAt: p.joinedAt,
            previousNames: previousNames,
          );
        }
        return p;
      }).toList();

      final newAdminName = state.role == ShareRole.admin ? trimmed : state.adminRefereeName;

      state = state.copyWith(
        participants: updatedParticipants,
        adminRefereeName: newAdminName,
      );

      if (state.role == ShareRole.admin) {
        await _db.updateAdminRefereeName(state.sku, trimmed);
      }
    }

    // 2. Fetch all shared events in local DB and update server & DB
    try {
      final sharedEvents = await _db.getSharedEvents();
      final visitedShareIds = <String>{};

      for (final event in sharedEvents) {
        if (event.shareRole == 'admin') {
          await _db.updateAdminRefereeName(event.sku, trimmed);
        }
        if (event.shareId != null) {
          visitedShareIds.add(event.shareId!);
          final updatedSession = await _client.updateRefereeName(
            deviceId: deviceId,
            refereeName: trimmed,
            shareId: event.shareId,
            sku: event.sku,
          );
          if (updatedSession != null && event.sku == state.sku) {
            state = state.copyWith(
              participants: updatedSession.participants,
              adminRefereeName: updatedSession.adminRefereeName,
            );
          }
        }
      }

      // Also ensure current active share is updated on server if not in sharedEvents list
      if (state.isShared && state.shareId != null && !visitedShareIds.contains(state.shareId)) {
        final updatedSession = await _client.updateRefereeName(
          deviceId: deviceId,
          refereeName: trimmed,
          shareId: state.shareId,
          sku: state.sku,
        );
        if (updatedSession != null) {
          state = state.copyWith(
            participants: updatedSession.participants,
            adminRefereeName: updatedSession.adminRefereeName,
          );
        }
      }
    } catch (_) {}
  }

  /// Load persistent share state from local database for an event SKU
  Future<void> loadEventShareState(String sku) async {
    if (!ref.mounted) return;
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
    NotifierProvider<ShareController, EventShareState>(ShareController.new);
