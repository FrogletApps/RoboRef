import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/sku_utils.dart';
import '../../event_selection/state/event_controller.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../models/share_models.dart';
import '../state/share_controller.dart';

class EventShareSheet extends ConsumerStatefulWidget {
  final String sku;

  const EventShareSheet({
    super.key,
    required this.sku,
  });

  @override
  ConsumerState<EventShareSheet> createState() => _EventShareSheetState();
}

class _EventShareSheetState extends ConsumerState<EventShareSheet> {
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(shareControllerProvider.notifier).loadEventShareState(widget.sku);
      }
    });
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shareState = ref.watch(shareControllerProvider);
    final settings = ref.watch(syncSettingsProvider);
    final activeEventAsync = ref.watch(activeEventProvider);
    final event = activeEventAsync.value;
    final eventName = (event != null && event.sku == widget.sku && event.name.isNotEmpty)
        ? event.name
        : widget.sku;
    final skuColor = getSkuColor(widget.sku);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: skuColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: skuColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    widget.sku,
                    style: TextStyle(
                      color: skuColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.eventShareTitle,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        eventName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Content
          Flexible(
            child: shareState.isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    shrinkWrap: true,
                    children: [
                      // Error display
                      if (shareState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  shareState.errorMessage ?? '',
                                  style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Existing Share Conflict Warning Box
                      if (shareState.isConflict && shareState.existingShares.isNotEmpty) ...[
                        _buildConflictCard(context, shareState),
                        const SizedBox(height: 16),
                      ],

                      // 1. If Local Only:
                      if (!shareState.isShared &&
                          !(shareState.isConflict && shareState.existingShares.isNotEmpty)) ...[
                        _buildLocalOnlyView(context, settings),
                      ],

                      // 2. If Shared Online:
                      if (shareState.isShared) ...[
                        _buildSharedOnlineView(context, shareState, settings, isDark),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// View when event is strictly local-only
  Widget _buildLocalOnlyView(BuildContext context, SyncSettingsState settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Local Only Status Card
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.eventShareLocalOnlyBadge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.eventShareLocalOnlyTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.eventShareLocalOnlyDescription,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Prominent "Share Event Online" button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.vividGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isChecking
              ? null
              : () async {
                  setState(() => _isChecking = true);
                  await ref.read(shareControllerProvider.notifier).createShare(widget.sku);
                  if (mounted) setState(() => _isChecking = false);
                },
          icon: _isChecking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.share, size: 20),
          label: Text(
            _isChecking
                ? context.l10n.eventShareCheckingServerButton
                : context.l10n.commonShareEventOnline,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),

        // Or Join via Share Code
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                context.l10n.eventShareOrJoinExistingDivider,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _joinCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: context.l10n.eventShareEnterCodeLabel,
                  hintText: context.l10n.eventShareEnterCodeHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: const Icon(Icons.pin),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onPressed: () async {
                final code = _joinCodeController.text.trim().toUpperCase();
                if (code.isEmpty) return;
                final success = await ref
                    .read(shareControllerProvider.notifier)
                    .joinShare(shareId: code, sku: widget.sku);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.eventShareJoinedSuccessSnackbar)),
                  );
                }
              },
              child: Text(context.l10n.eventShareJoinButton),
            ),
          ],
        ),
      ],
    );
  }

  /// Warning Card when another referee has already shared this event SKU
  Widget _buildConflictCard(BuildContext context, EventShareState shareState) {
    final existing = shareState.existingShares.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text(
                context.l10n.eventShareConflictTitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.eventShareConflictBody(
              widget.sku,
              existing.adminRefereeName,
              existing.participantCount,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vividGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final success = await ref
                        .read(shareControllerProvider.notifier)
                        .joinShare(shareId: existing.id, sku: widget.sku);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.eventShareJoinedAdminSnackbar(existing.adminRefereeName))),
                      );
                    }
                  },
                  icon: const Icon(Icons.group_add, size: 18),
                  label: Text(context.l10n.eventShareJoinAdminButton(existing.adminRefereeName)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(shareControllerProvider.notifier).loadEventShareState(widget.sku);
                },
                child: Text(context.l10n.commonCancel),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(shareControllerProvider.notifier)
                      .createShare(widget.sku, force: true);
                },
                child: Text(
                  context.l10n.eventShareCreateSeparateButton,
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// View when event is shared online (either as Admin or Member)
  Widget _buildSharedOnlineView(
    BuildContext context,
    EventShareState shareState,
    SyncSettingsState settings,
    bool isDark,
  ) {
    final isAdmin = shareState.role == ShareRole.admin;
    final serverType = getLocalizedServerTypeDisplayName(context, settings.serverUrl);
    final shareId = shareState.shareId ?? '';
    final joinUrl = buildJoinUrl(
      shareId: shareId,
      sku: widget.sku,
      serverUrl: settings.serverUrl,
    );
    final participantCount = shareState.participants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status Badge Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isAdmin
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAdmin
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.cloud_done,
                color: isAdmin ? Colors.green : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin
                          ? context.l10n.eventShareStatusAdminTitle(serverType)
                          : context.l10n.eventShareStatusMemberTitle(serverType),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isAdmin ? Colors.green : Colors.blue,
                      ),
                    ),
                    Text(
                      isAdmin
                          ? context.l10n.eventShareStatusAdminDescription(serverType)
                          : context.l10n.eventShareStatusMemberDescription(
                              shareState.adminRefereeName ?? context.l10n.commonHeadReferee,
                              serverType,
                            ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // QR Code & Join Code Card
        Card(
          elevation: 2,
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  context.l10n.eventShareScanToJoinTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: QrImageView(
                    data: joinUrl,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.eventShareCodePrefix,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SelectableText(
                        shareId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: context.l10n.eventShareCopyCodeTooltip,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.eventShareCodeCopiedSnackbar)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: joinUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.eventShareJoinLinkCopiedSnackbar)),
                    );
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: Text(context.l10n.eventShareCopyJoinLinkButton),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Connected Participants List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.eventShareConnectedRefereesTitle(participantCount),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: context.l10n.eventShareNameHistoryTooltip,
                  onPressed: () => _showAllPreviousNamesDialog(context, shareState.participants),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: context.l10n.eventShareRefreshParticipantsTooltip,
              onPressed: () => ref.read(shareControllerProvider.notifier).refreshShareStatus(widget.sku),
            ),
          ],
        ),
        const SizedBox(height: 6),

        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shareState.participants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final participant = shareState.participants[idx];
              final isMe = participant.deviceId == settings.deviceId;
              final isItemAdmin = participant.role == ShareRole.admin;

              return ListTile(
                dense: true,
                onTap: () => _showRefereePreviousNamesDialog(context, participant),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isItemAdmin ? Colors.green.shade700 : Colors.blue.shade700,
                  child: Icon(
                    isItemAdmin ? Icons.shield : Icons.person,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.refereeName,
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(context.l10n.eventShareYouBadge, style: const TextStyle(fontSize: 10)),
                      ),
                    ],
                    if (isItemAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context.l10n.eventShareAdminBadge,
                          style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 18),
                      tooltip: context.l10n.eventSharePreviousNamesForTooltip(participant.refereeName),
                      onPressed: () => _showRefereePreviousNamesDialog(context, participant),
                    ),
                    if (isAdmin && !isMe)
                      IconButton(
                        icon: const Icon(Icons.person_remove_outlined, size: 18, color: Colors.redAccent),
                        tooltip: context.l10n.eventShareRemoveParticipantTooltip(participant.refereeName),
                        onPressed: () => _confirmRemoveParticipant(context, participant),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Leave / Close Share Button
        if (isAdmin) ...[
          // Admin leave button (prevented if other participants exist)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _handleAdminLeave(context, participantCount),
            icon: const Icon(Icons.delete_forever, size: 20),
            label: Text(context.l10n.eventShareCloseDeleteButton),
          ),
          if (participantCount > 1) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.eventShareAdminCannotLeaveNote,
              style: const TextStyle(fontSize: 11.5, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ],
        ] else ...[
          // Member leave button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _confirmMemberLeave(context),
            icon: const Icon(Icons.exit_to_app, size: 20),
            label: Text(context.l10n.eventShareLeaveEventButton),
          ),
        ],
      ],
    );
  }

  void _confirmRemoveParticipant(BuildContext context, ShareParticipantModel participant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.eventShareRemoveParticipantDialogTitle(participant.refereeName)),
        content: Text(
          ctx.l10n.eventShareRemoveParticipantDialogBody(participant.refereeName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(shareControllerProvider.notifier)
                  .removeParticipant(sku: widget.sku, targetDeviceId: participant.deviceId);
            },
            child: Text(ctx.l10n.commonRemove),
          ),
        ],
      ),
    );
  }

  void _handleAdminLeave(BuildContext context, int participantCount) {
    if (participantCount > 1) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.block, color: Colors.red),
              const SizedBox(width: 8),
              Text(ctx.l10n.eventShareCannotLeaveDialogTitle),
            ],
          ),
          content: Text(
            ctx.l10n.eventShareCannotLeaveDialogBody(participantCount),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.l10n.commonOk),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.eventShareCloseDeleteDialogTitle),
        content: Text(
          ctx.l10n.eventShareCloseDeleteDialogBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await ref.read(shareControllerProvider.notifier).leaveShare(widget.sku);
              if (result.success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.eventShareClosedDeletedSnackbar)),
                );
              }
            },
            child: Text(ctx.l10n.eventShareCloseDeleteConfirmButton),
          ),
        ],
      ),
    );
  }

  void _confirmMemberLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.eventShareLeaveDialogTitle),
        content: Text(
          ctx.l10n.eventShareLeaveDialogBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await ref.read(shareControllerProvider.notifier).leaveShare(widget.sku);
              if (result.success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.eventShareLeftSessionSnackbar)),
                );
              }
            },
            child: Text(ctx.l10n.eventShareLeaveConfirmButton),
          ),
        ],
      ),
    );
  }

  void _showRefereePreviousNamesDialog(BuildContext context, ShareParticipantModel participant) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.history, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dialogContext.l10n.eventShareNameHistoryDialogTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dialogContext.l10n.eventShareCurrentNameLabel(participant.refereeName),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  dialogContext.l10n.eventSharePreviousNamesLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (participant.previousNames.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogContext.l10n.eventShareNoPreviousNamesForReferee,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final name in participant.previousNames) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.commonClose),
            ),
          ],
        );
      },
    );
  }

  void _showAllPreviousNamesDialog(BuildContext context, List<ShareParticipantModel> participants) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final anyWithPrevious = participants.any((p) => p.previousNames.isNotEmpty);
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.history, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dialogContext.l10n.eventShareAllNameHistoryDialogTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!anyWithPrevious)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dialogContext.l10n.eventShareNoPreviousNamesForAny,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (int i = 0; i < participants.length; i++) ...[
                      if (i > 0) const Divider(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  participants[i].refereeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (participants[i].role == ShareRole.admin) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    dialogContext.l10n.eventShareAdminBadge,
                                    style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (participants[i].previousNames.isEmpty)
                            Text(
                              dialogContext.l10n.eventShareNoPreviousNamesItem,
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                            )
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: participants[i].previousNames.map((name) {
                                return Chip(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                  label: Text(name, style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.commonClose),
            ),
          ],
        );
      },
    );
  }
}
