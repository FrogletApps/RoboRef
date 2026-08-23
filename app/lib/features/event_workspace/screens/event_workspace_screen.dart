import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../event_data/screens/event_import_sheet.dart';
import '../../incidents/screens/incident_logger_screen.dart';
import '../../incidents/state/incident_controller.dart';
import '../../matches/screens/match_schedule_screen.dart';
import '../../teams/screens/team_list_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/state/sync_settings_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(syncSettingsProvider);

    final screens = const [
      IncidentLoggerScreen(showAppBar: false),
      MatchScheduleScreen(showAppBar: false),
      TeamListScreen(showAppBar: false),
      SettingsScreen(showAppBar: false),
    ];

    final titles = [
      'RoboRef',
      'Match Schedule',
      'Team Histories',
      'Referee & Sync Settings',
    ];

    List<Widget> buildActions() {
      switch (_currentIndex) {
        case 0: // Incidents
          return [
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
                          content: Text('Syncing with referee network...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
            ),
          ];
        case 1: // Matches
          return [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Load / Import Schedule',
              onPressed: () => _showImportSheet(context),
            ),
          ];
        case 2: // Teams
          return [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Load / Import Teams',
              onPressed: () => _showImportSheet(context),
            ),
          ];
        default:
          return [];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              titles[_currentIndex],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              settings.currentSku,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
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
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Incidents',
          ),
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
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
