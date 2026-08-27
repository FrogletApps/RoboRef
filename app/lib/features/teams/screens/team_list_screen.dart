import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../incidents/state/incident_controller.dart';
import '../../incidents/screens/incident_logger_screen.dart';
import '../../incidents/widgets/severity_badge.dart';
import '../state/team_controller.dart';
import '../../event_data/screens/event_import_sheet.dart';
import '../../../core/utils/team_utils.dart';

class TeamListScreen extends StatefulWidget {
  final bool showAppBar;

  const TeamListScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<TeamListScreen> createState() => _TeamListScreenState();
}

class _TeamListScreenState extends State<TeamListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notesAsync = ref.watch(activeTournamentNotesProvider);
        final registeredTeamsAsync = ref.watch(activeTournamentTeamsProvider);

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: const Text('Team Histories'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Load / Import Teams',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) => const EventImportSheet(),
                        );
                      },
                    ),
                  ],
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search teams...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim().toUpperCase()),
                ),
              ),
              Expanded(
                child: notesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error loading teams: $err')),
                  data: (notes) {
                    final registeredTeams = registeredTeamsAsync.valueOrNull ?? [];
                    final Map<String, List<dynamic>> teamNotes = {};
                    for (final note in notes) {
                      teamNotes.putIfAbsent(note.teamNumber, () => []).add(note);
                    }

                    final Set<String> allTeamNumbers = {
                      ...teamNotes.keys,
                      ...registeredTeams.map((t) => t.teamNumber),
                    };

                    final teams = allTeamNumbers
                        .where((t) => _search.isEmpty || t.contains(_search))
                        .toList()
                      ..sort(compareTeamNumbers);

                    final Map<String, String> teamNames = {
                      for (final t in registeredTeams) t.teamNumber: t.teamName,
                    };

                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _search.isEmpty
                                  ? 'No team incident records yet.'
                                  : 'No teams matching "$_search"',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        final list = teamNotes[team] ?? [];
                        final teamName = teamNames[team];

                        final warningCount = list.where((n) => n.severity == 'warning').length;
                        final majorCount = list.where((n) => n.severity == 'major' || n.severity == 'd_q').length;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: majorCount > 0
                                  ? Colors.red.shade100
                                  : (warningCount > 0
                                      ? Colors.amber.shade100
                                      : Theme.of(context).colorScheme.primaryContainer),
                              child: Text(
                                team.length > 3 ? team.substring(0, 3) : team,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: majorCount > 0
                                      ? Colors.red.shade900
                                      : (warningCount > 0
                                          ? Colors.amber.shade900
                                          : Theme.of(context).colorScheme.onPrimaryContainer),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(team, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (teamName != null && teamName.isNotEmpty && teamName != 'Team $team') ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      teamName,
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              list.isEmpty ? 'No incident notes logged' : '${list.length} incident note(s)',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (majorCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$majorCount MAJOR',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (warningCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$warningCount WARN',
                                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              _showTeamHistory(context, team, list);
                            },
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

  void _showTeamHistory(BuildContext context, String teamNumber, List<dynamic> notes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Team $teamNumber History',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (c) => AddIncidentSheet(initialTeam: teamNumber),
                      );
                    },
                    icon: const Icon(Icons.add_alert, size: 18),
                    label: const Text('Log Incident'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No logged incidents for this team yet.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: notes.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (c, i) {
                      final note = notes[i];
                      List<dynamic> ruleCodes = [];
                      try {
                        ruleCodes = jsonDecode(note.ruleCodesJson);
                      } catch (_) {}

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  note.matchId ?? 'General Note',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SeverityBadge(severity: note.severity),
                              ],
                            ),
                            if (ruleCodes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Rules: ${ruleCodes.join(", ")}',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (note.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(note.notes),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'By ${note.refereeName}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            ),
                          ],
                        ),
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
}
