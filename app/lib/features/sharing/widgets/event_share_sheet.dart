import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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

  String _buildJoinUrl(String shareId, String sku, String serverUrl) {
    final cleanUrl = serverUrl.contains('roboref.app')
        ? 'https://roboref.app'
        : serverUrl.replaceAll(RegExp(r'/+$'), '');
    return '$cleanUrl?joinShare=$shareId&sku=$sku';
  }

  @override
  Widget build(BuildContext context) {
    final shareState = ref.watch(shareControllerProvider);
    final settings = ref.watch(syncSettingsProvider);
    final activeEventAsync = ref.watch(activeEventProvider);
    final event = activeEventAsync.valueOrNull;
    final eventName = (event?.name.isNotEmpty ?? false) ? event!.name : widget.sku;
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
                      const Text(
                        'Event Sharing & Sync',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                  shareState.errorMessage!,
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
                      if (!shareState.isShared && !shareState.isConflict) ...[
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'LOCAL ONLY',
                          style: TextStyle(
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
              const Text(
                'Notes are stored entirely locally on this device.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'To collaborate with alliance referees and scorekeepers, share this event online to synchronize notes in real time.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
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
            _isChecking ? 'Checking Server...' : 'Share Event Online',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),

        // Or Join via Share Code
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'OR JOIN AN EXISTING SHARE',
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _joinCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Enter 6-Digit Share Code',
                  hintText: 'e.g. ABC123',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.pin),
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
                    const SnackBar(content: Text('Joined shared session successfully!')),
                  );
                }
              },
              child: const Text('Join'),
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
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              Text(
                'Existing Share Session Found',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A shared session for ${widget.sku} is already active on the network, hosted by ${existing.adminRefereeName} with ${existing.participantCount} participant${existing.participantCount == 1 ? '' : 's'}.',
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
                        SnackBar(content: Text('Joined ${existing.adminRefereeName}\'s session')),
                      );
                    }
                  },
                  icon: const Icon(Icons.group_add, size: 18),
                  label: Text('Join ${existing.adminRefereeName}'),
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
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(shareControllerProvider.notifier)
                      .createShare(widget.sku, force: true);
                },
                child: const Text(
                  'Create Separate Share Anyway',
                  style: TextStyle(color: Colors.orange),
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
    final serverType = getServerTypeDisplayName(settings.serverUrl);
    final shareId = shareState.shareId ?? '';
    final joinUrl = _buildJoinUrl(shareId, widget.sku, settings.serverUrl);
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
                      isAdmin ? 'Sharing: $serverType (Host / Admin)' : 'Sharing: $serverType (Member)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isAdmin ? Colors.green : Colors.blue,
                      ),
                    ),
                    Text(
                      isAdmin
                          ? 'You are the admin on $serverType. You can invite referees and manage participants.'
                          : 'Hosted by ${shareState.adminRefereeName ?? "Head Referee"} on $serverType. Notes synchronize automatically.',
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
                const Text(
                  'Scan to Join Share Session',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                      const Text(
                        'Share Code: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                        tooltip: 'Copy Share Code',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share code copied to clipboard!')),
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
                      const SnackBar(content: Text('Join link copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Copy Join Link'),
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
            Text(
              'Connected Referees ($participantCount)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Refresh participant list',
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
                    Text(
                      participant.refereeName,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13.5,
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
                        child: const Text('You', style: TextStyle(fontSize: 10)),
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
                        child: const Text(
                          'Admin',
                          style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: (isAdmin && !isMe)
                    ? IconButton(
                        icon: const Icon(Icons.person_remove_outlined, size: 18, color: Colors.redAccent),
                        tooltip: 'Remove ${participant.refereeName}',
                        onPressed: () => _confirmRemoveParticipant(context, participant),
                      )
                    : null,
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
            label: const Text('Close & Delete Share Session'),
          ),
          if (participantCount > 1) ...[
            const SizedBox(height: 6),
            const Text(
              'Note: The admin cannot leave until all other referees have left or been removed.',
              style: TextStyle(fontSize: 11.5, color: Colors.orange),
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
            label: const Text('Leave Shared Event'),
          ),
        ],
      ],
    );
  }

  void _confirmRemoveParticipant(BuildContext context, ShareParticipantModel participant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${participant.refereeName}?'),
        content: Text(
          'Are you sure you want to remove ${participant.refereeName} from this shared session? They will stop syncing new notes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref
                  .read(shareControllerProvider.notifier)
                  .removeParticipant(sku: widget.sku, targetDeviceId: participant.deviceId);
            },
            child: const Text('Remove'),
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
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 8),
              Text('Cannot Leave Share'),
            ],
          ),
          content: Text(
            'You cannot leave or close this session while $participantCount other referees are connected. Please remove all participants first or wait for them to leave.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close & Delete Share?'),
        content: const Text(
          'Closing the session will delete it from the sync server and purge cloud notes. Your local notes will remain safely on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await ref.read(shareControllerProvider.notifier).leaveShare(widget.sku);
              if (result.success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share session closed and cloud data deleted.')),
                );
              }
            },
            child: const Text('Close & Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmMemberLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Shared Event?'),
        content: const Text(
          'You will disconnect from this share session and stop receiving sync updates. Your local notes will remain on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await ref.read(shareControllerProvider.notifier).leaveShare(widget.sku);
              if (result.success && context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Left shared event session.')),
                );
              }
            },
            child: const Text('Leave Event'),
          ),
        ],
      ),
    );
  }
}
