import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/match_controller.dart';
import '../../incidents/state/incident_controller.dart';
import '../../event_data/screens/event_import_sheet.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../../incidents/screens/incident_logger_screen.dart';

class MatchScheduleScreen extends StatefulWidget {
  const MatchScheduleScreen({super.key});

  @override
  State<MatchScheduleScreen> createState() => _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends State<MatchScheduleScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final matchesAsync = ref.watch(activeTournamentMatchesProvider);
        final notesAsync = ref.watch(activeTournamentNotesProvider);
        final settings = ref.watch(syncSettingsProvider);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                const Text('Match Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  settings.currentSku,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Load / Import Schedule',
                onPressed: () => _showImportSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search / Filter
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by match (e.g. Q12) or team...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toUpperCase()),
                ),
              ),

              // Match List
              Expanded(
                child: matchesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading matches: $err')),
                  data: (matches) {
                    final notes = notesAsync.valueOrNull ?? [];
                    final Set<String> teamsWithWarnings = {};
                    for (final n in notes) {
                      if (n.severity == 'warning' || n.severity == 'major' || n.severity == 'd_q') {
                        teamsWithWarnings.add(n.teamNumber);
                      }
                    }

                    final filtered = matches.where((m) {
                      if (_searchQuery.isEmpty) return true;
                      final nameMatch = m.name.toUpperCase().contains(_searchQuery);
                      final redMatch = m.redTeamsJson.toUpperCase().contains(_searchQuery);
                      final blueMatch = m.blueTeamsJson.toUpperCase().contains(_searchQuery);
                      return nameMatch || redMatch || blueMatch;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              matches.isEmpty
                                  ? 'No match schedule loaded yet.'
                                  : 'No matches found matching "$_searchQuery"',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showImportSheet(context),
                              icon: const Icon(Icons.cloud_download),
                              label: const Text('Fetch or Import Schedule'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final match = filtered[index];
                        List<dynamic> redTeams = [];
                        List<dynamic> blueTeams = [];

                        try {
                          redTeams = jsonDecode(match.redTeamsJson);
                          blueTeams = jsonDecode(match.blueTeamsJson);
                        } catch (_) {}

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showMatchActions(context, match.name, redTeams, blueTeams),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        match.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Row(
                                        children: [
                                          if (match.field != null && match.field!.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                match.field!,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          if (match.scheduledTime != null && match.scheduledTime!.isNotEmpty)
                                            Text(
                                              match.scheduledTime!,
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Red Alliance
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade700,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'RED',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          children: redTeams.map((team) {
                                            final hasWarning = teamsWithWarnings.contains(team.toString());
                                            return _buildTeamPill(team.toString(), Colors.red.shade900, hasWarning);
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Blue Alliance
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade700,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'BLUE',
                                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 8,
                                          children: blueTeams.map((team) {
                                            final hasWarning = teamsWithWarnings.contains(team.toString());
                                            return _buildTeamPill(team.toString(), Colors.blue.shade900, hasWarning);
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamPill(String teamNumber, Color color, bool hasWarning) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: hasWarning ? Colors.amber.shade700 : color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            teamNumber,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
          if (hasWarning) ...[
            const SizedBox(width: 4),
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber.shade800),
          ],
        ],
      ),
    );
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

  void _showMatchActions(BuildContext context, String matchName, List<dynamic> redTeams, List<dynamic> blueTeams) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actions for $matchName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_alert, color: Colors.blue),
                title: const Text('Log Incident Note for this Match'),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (c) => const AddIncidentSheet(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
