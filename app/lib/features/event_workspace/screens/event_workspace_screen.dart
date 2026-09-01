import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../event_data/screens/event_import_sheet.dart';
import '../../event_selection/state/event_controller.dart';
import '../../incidents/screens/incident_logger_screen.dart';
import '../../incidents/state/incident_controller.dart';
import '../../matches/screens/match_schedule_screen.dart';
import '../../rules/screens/rules_screen.dart';
import '../../teams/screens/team_list_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/state/sync_settings_controller.dart';

import '../../sharing/widgets/event_share_sheet.dart';
import '../../sharing/state/share_controller.dart';
import '../../sharing/models/share_models.dart';

class EventWorkspaceScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const EventWorkspaceScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<EventWorkspaceScreen> createState() => _EventWorkspaceScreenState();
}

class _EventWorkspaceScreenState extends ConsumerState<EventWorkspaceScreen> {
  late int _currentIndex;
  Timer? _pollingTimer;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    Future.microtask(() {
      if (mounted) {
        final currentSku = ref.read(syncSettingsProvider).currentSku;
        ref.read(shareControllerProvider.notifier).loadEventShareState(currentSku);
      }
    });

    _startPollingTimer();

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _checkSyncIfShared(quiet: true);
      },
    );
  }

  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        _checkSyncIfShared(quiet: true);
      }
    });
  }

  void _checkSyncIfShared({bool quiet = true}) {
    if (!mounted) return;
    final shareState = ref.read(shareControllerProvider);
    if (shareState.isShared) {
      ref.read(incidentControllerProvider.notifier).triggerSync(quiet: quiet);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _lifecycleListener?.dispose();
    super.dispose();
  }

  void _showImportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const EventImportSheet(),
    );
  }

  void _showShareSheet(BuildContext context, String sku) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EventShareSheet(sku: sku),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(syncSettingsProvider);
    final shareState = ref.watch(shareControllerProvider);
    final activeEventAsync = ref.watch(activeEventProvider);
    final event = activeEventAsync.valueOrNull;
    final eventName = (event?.name.isNotEmpty ?? false) ? event!.name : settings.currentSku;

    final screens = const [
      MatchScheduleScreen(showAppBar: false),
      TeamListScreen(showAppBar: false),
      IncidentLoggerScreen(showAppBar: false),
      RulesScreen(showAppBar: false),
      SettingsScreen(showAppBar: false),
    ];

    final titles = [
      'Match Schedule',
      'Team Histories',
      'RoboRef',
      'Game Rules',
      'Manage & Sync',
    ];

    List<Widget> buildActions() {
      final List<Widget> list = [];

      switch (_currentIndex) {
        case 0: // Matches
          list.add(
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Load / Import Schedule',
              onPressed: () => _showImportSheet(context),
            ),
          );
          break;
        case 1: // Teams
          list.add(
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Load / Import Teams',
              onPressed: () => _showImportSheet(context),
            ),
          );
          break;
        case 2: // Incidents
          list.add(
            IconButton(
              icon: settings.isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sync Notes',
              onPressed: settings.isSyncing
                  ? null
                  : () {
                      ref.read(incidentControllerProvider.notifier).triggerSync();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Syncing notes...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
            ),
          );
          break;
        default:
          break;
      }

      // Share Event button available in header
      // Check both reactive event record and shareState
      final isEventShared = event?.isShared ?? shareState.isShared;
      final role = (event?.shareRole != null ? ShareRole.fromString(event!.shareRole) : null) ?? shareState.role;

      list.add(
        IconButton(
          icon: Icon(
            isEventShared
                ? (role == ShareRole.admin ? Icons.admin_panel_settings : Icons.cloud_done)
                : Icons.share_outlined,
            color: isEventShared ? Colors.lightGreenAccent : null,
          ),
          tooltip: isEventShared
              ? 'Shared Online (${shareState.participants.isNotEmpty ? shareState.participants.length : 1} connected)'
              : 'Share Event Online',
          onPressed: () => _showShareSheet(context, settings.currentSku),
        ),
      );

      return list;
    }


    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              eventName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: buildActions(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          if (idx == 1 || idx == 2 || idx == 4) {
            _checkSyncIfShared(quiet: true);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Rules',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Manage',
          ),
        ],
      ),
    );
  }
}
