import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state/incident_controller.dart';
import '../widgets/severity_badge.dart';
import '../widgets/rule_selection_sheet.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../../event_selection/state/event_controller.dart';
import '../../rules/data/default_rules.dart';
import '../../rules/models/rule_model.dart';
import '../../teams/state/team_controller.dart';
import '../../matches/state/match_controller.dart';
import '../../../core/utils/team_utils.dart';
import '../../../core/utils/match_utils.dart';
import '../../../core/utils/sku_utils.dart';

class IncidentLoggerScreen extends StatefulWidget {
  final bool showAppBar;

  const IncidentLoggerScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<IncidentLoggerScreen> createState() => _IncidentLoggerScreenState();
}

class _IncidentLoggerScreenState extends State<IncidentLoggerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notesAsync = ref.watch(activeTournamentNotesProvider);
        final settings = ref.watch(syncSettingsProvider);
        final activeEventAsync = ref.watch(activeEventProvider);
        final program = activeEventAsync.value?.program ?? getSkuProgram(settings.currentSku);
        final season = activeEventAsync.value?.season ?? '2026-2027';
        final ruleset = getGameRuleset(program, season);

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: Column(
                    children: [
                      const Text('RoboRef', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        settings.currentSku,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
                      ),
                    ],
                  ),
                  actions: [
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
                                const SnackBar(content: Text('Syncing with referee network...'), duration: Duration(seconds: 1)),
                              );
                            },
                    ),
                  ],
                )
              : null,
      body: Column(
        children: [
          // Search / Filter bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by team number, rule, or notes...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Incident Notes List
          Expanded(
            child: notesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading notes: $err')),
              data: (notes) {
                final filtered = notes.where((note) {
                  if (_searchQuery.isEmpty) return true;
                  final matchQuery = note.matchId?.toLowerCase().contains(_searchQuery) ?? false;
                  final teamQuery = note.teamNumber.toLowerCase().contains(_searchQuery);
                  final notesQuery = note.notes.toLowerCase().contains(_searchQuery);
                  final rulesQuery = note.ruleCodesJson.toLowerCase().contains(_searchQuery);
                  return teamQuery || matchQuery || notesQuery || rulesQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notes, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No incident notes logged yet for this tournament.'
                              : 'No matching notes found.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
                    final note = filtered[index];
                    List<dynamic> ruleCodes = [];
                    try {
                      ruleCodes = jsonDecode(note.ruleCodesJson);
                    } catch (_) {}

                    final formattedDate = DateFormat('HH:mm:ss').format(
                      DateTime.fromMillisecondsSinceEpoch(note.updatedAt),
                    );

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        note.teamNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    if (note.matchId != null && note.matchId!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        formatMatchShortName(note.matchId!),
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                                SeverityBadge(severity: note.severity),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (ruleCodes.isNotEmpty) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: ruleCodes.map((rule) {
                                  final ruleStr = rule.toString();
                                  final matchedRule = ruleset.findRule(ruleStr);
                                  final summary = matchedRule?.summary;
                                  final displayText = summary != null ? '${matchedRule!.code} $summary' : ruleStr;
                                  return Tooltip(
                                    message: summary != null ? '${matchedRule!.code}: $summary' : ruleStr,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        displayText,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (note.notes.isNotEmpty)
                              Text(
                                note.notes,
                                style: const TextStyle(fontSize: 14),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Logged by ${note.refereeName} at $formattedDate',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(context, ref, note.id),
                                ),
                              ],
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIncidentDialog(context),
        icon: const Icon(Icons.add_alert),
        label: const Text('Log Incident'),
      ),
    );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Incident Note?'),
        content: const Text('Are you sure you want to remove this incident log?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(incidentControllerProvider.notifier).deleteNote(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddIncidentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const AddIncidentSheet(),
    );
  }
}

class AddIncidentSheet extends StatefulWidget {
  final String? initialMatch;
  final String? initialTeam;

  const AddIncidentSheet({
    super.key,
    this.initialMatch,
    this.initialTeam,
  });

  @override
  State<AddIncidentSheet> createState() => _AddIncidentSheetState();
}

class _AddIncidentSheetState extends State<AddIncidentSheet> {
  late final TextEditingController _teamController;
  late final TextEditingController _matchController;
  final _notesController = TextEditingController();

  String _severity = 'warning';
  final Set<String> _selectedRules = {};

  @override
  void initState() {
    super.initState();
    _teamController = TextEditingController(text: widget.initialTeam ?? '');
    _matchController = TextEditingController(text: widget.initialMatch ?? '');
  }

  @override
  void dispose() {
    _teamController.dispose();
    _matchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final registeredTeams = ref.watch(activeTournamentTeamsProvider).valueOrNull ?? [];
        final tournamentMatches = ref.watch(activeTournamentMatchesProvider).valueOrNull ?? [];
        final tournamentNotes = ref.watch(activeTournamentNotesProvider).valueOrNull ?? [];
        final settings = ref.watch(syncSettingsProvider);
        final activeEventAsync = ref.watch(activeEventProvider);

        final program = activeEventAsync.value?.program ?? getSkuProgram(settings.currentSku);
        final season = activeEventAsync.value?.season ?? '2026-2027';
        final ruleset = getGameRuleset(program, season);

        final teamNumbers = registeredTeams.map((t) => t.teamNumber).toList()..sort(compareTeamNumbers);
        final matchNames = tournamentMatches.map((m) => formatMatchShortName(m.name)).toList();

        // Calculate most commonly selected rules from the event so far
        final Map<String, int> ruleCounts = {};
        for (final note in tournamentNotes) {
          try {
            final codes = jsonDecode(note.ruleCodesJson);
            if (codes is List) {
              for (final c in codes) {
                final clean = c.toString().replaceAll(RegExp(r'[<>]'), '').trim().toUpperCase();
                if (clean.isNotEmpty) {
                  ruleCounts[clean] = (ruleCounts[clean] ?? 0) + 1;
                }
              }
            }
          } catch (_) {}
        }

        // Calculate all candidate rules ranked by event frequency first, then default candidate rules, then full ruleset
        final List<RuleModel> allRankedRules = [];
        if (ruleCounts.isNotEmpty) {
          final sortedCodes = ruleCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          for (final entry in sortedCodes) {
            final r = ruleset.findRule(entry.key);
            if (r != null && !allRankedRules.contains(r)) {
              allRankedRules.add(r);
            }
          }
        }

        const defaultCandidateCodes = ['SG1', 'SG2', 'GG2', 'GG14', 'G1', 'S1', 'R1', 'T1'];
        for (final code in defaultCandidateCodes) {
          final r = ruleset.findRule(code);
          if (r != null && !allRankedRules.contains(r)) {
            allRankedRules.add(r);
          }
        }

        for (final r in ruleset.rules) {
          if (!allRankedRules.contains(r)) {
            allRankedRules.add(r);
          }
        }

        // Build list of all selected rule models (no limit)
        final List<RuleModel> selectedRuleModels = [];
        for (final code in _selectedRules) {
          final r = ruleset.findRule(code);
          if (r != null) {
            if (!selectedRuleModels.contains(r)) {
              selectedRuleModels.add(r);
            }
          } else {
            selectedRuleModels.add(RuleModel(
              code: code.startsWith('<') ? code : '<$code>',
              title: '',
              description: '',
              group: 'Custom',
            ));
          }
        }

        // Unselected chips to show: maximum of 6 unselected chips, decreasing as selected chips increase
        final int unselectedCount = (6 - selectedRuleModels.length).clamp(0, 6);
        final List<RuleModel> unselectedRuleModels = allRankedRules
            .where((r) => !_selectedRules.contains(r.code) &&
                          !_selectedRules.contains(r.cleanCode) &&
                          !_selectedRules.contains(r.formattedCode))
            .take(unselectedCount)
            .toList();

        // Combined visible chips (selected ones first with no limit, followed by unselected ones)
        final visibleRuleChips = [
          ...selectedRuleModels.map((r) => (rule: r, isSelected: true)),
          ...unselectedRuleModels.map((r) => (rule: r, isSelected: false)),
        ];

        // Extract teams involved in the selected match if any
        final currentMatchQuery = _matchController.text.trim().toLowerCase();
        List<String> matchTeams = [];
        if (currentMatchQuery.isNotEmpty) {
          final cleanCurrent = currentMatchQuery.replaceAll(' ', '');
          final matchedMatch = tournamentMatches.cast<dynamic>().firstWhere(
            (m) {
              final mName = m.name.toString().toLowerCase();
              final short = getMatchShortCode(m.name.toString()).toLowerCase();
              return mName == currentMatchQuery ||
                  short == currentMatchQuery ||
                  mName.replaceAll(' ', '') == cleanCurrent ||
                  short.replaceAll(' ', '') == cleanCurrent;
            },
            orElse: () => null,
          );
          if (matchedMatch != null) {
            try {
              final red = (jsonDecode(matchedMatch.redTeamsJson) as List).map((e) => e.toString()).toList()..sort(compareTeamNumbers);
              final blue = (jsonDecode(matchedMatch.blueTeamsJson) as List).map((e) => e.toString()).toList()..sort(compareTeamNumbers);
              matchTeams = [...red, ...blue];
            } catch (_) {}
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const Text(
                  'Log Match Incident / Rule Note',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Autocomplete
                    Expanded(
                      child: Autocomplete<String>(
                        key: ValueKey('team_autocomplete_${_teamController.text}'),
                        initialValue: TextEditingValue(text: _teamController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            if (matchTeams.isNotEmpty) {
                              return matchTeams;
                            }
                            return teamNumbers.take(15);
                          }
                          final query = textEditingValue.text.toLowerCase();
                          final filtered = teamNumbers.where((String option) {
                            return option.toLowerCase().contains(query);
                          }).toList();
                          if (matchTeams.isNotEmpty) {
                            filtered.sort((a, b) {
                              final aInMatch = matchTeams.contains(a);
                              final bInMatch = matchTeams.contains(b);
                              if (aInMatch && !bInMatch) return -1;
                              if (!aInMatch && bInMatch) return 1;
                              return compareTeamNumbers(a, b);
                            });
                          } else {
                            filtered.sort(compareTeamNumbers);
                          }
                          return filtered;
                        },
                        onSelected: (String selection) {
                          _teamController.text = selection;
                          setState(() {});
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Team Number *',
                              hintText: 'e.g. 1234A',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => _teamController.text = v,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Match Autocomplete
                    Expanded(
                      child: Autocomplete<String>(
                        key: ValueKey('match_autocomplete_${_matchController.text}'),
                        initialValue: TextEditingValue(text: _matchController.text),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return matchNames.take(15);
                          }
                          final query = textEditingValue.text.trim().toLowerCase();
                          final cleanQuery = query.replaceAll(' ', '');
                          return matchNames.where((String option) {
                            final optLower = option.toLowerCase();
                            final optShort = getMatchShortCode(option).toLowerCase();
                            return optLower.contains(query) ||
                                optShort.contains(query) ||
                                optLower.replaceAll(' ', '').contains(cleanQuery) ||
                                optShort.replaceAll(' ', '').contains(cleanQuery);
                          });
                        },
                        onSelected: (String selection) {
                          _matchController.text = selection;
                          setState(() {});
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Match (Optional)',
                              hintText: 'e.g. Q42',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) {
                              _matchController.text = v;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (matchTeams.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Teams in match:',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      ...matchTeams.map((team) {
                        final isSelected = _teamController.text.trim().toUpperCase() == team.toUpperCase();
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(team, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _teamController.text = selected ? team : '';
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Severity Level', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'minor', label: Text('Minor')),
                    ButtonSegment(value: 'warning', label: Text('Warning')),
                    ButtonSegment(value: 'major', label: Text('Major')),
                    ButtonSegment(value: 'd_q', label: Text('DQ')),
                  ],
                  selected: {_severity},
                  onSelectionChanged: (val) => setState(() => _severity = val.first),
                ),
                const SizedBox(height: 16),
                const Text('Rule Violations', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                // Consistent Rule Chips (all selected rules with no limit + up to (6 - selected.length) unselected candidate rules)
                if (visibleRuleChips.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: visibleRuleChips.map((item) {
                      final rule = item.rule;
                      final isSelected = item.isSelected;
                      final label = rule.title.isNotEmpty ? '${rule.code} ${rule.title}' : rule.code;

                      return FilterChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRules.add(rule.code);
                            } else {
                              _selectedRules.remove(rule.code);
                              _selectedRules.remove(rule.cleanCode);
                              _selectedRules.remove(rule.formattedCode);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // "Show More Rules" button positioned below the most commonly selected rules
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Show More Rules'),
                    onPressed: () async {
                      final updated = await RuleSelectionSheet.show(
                        context,
                        ruleset: ruleset,
                        initialSelectedRules: _selectedRules,
                      );
                      if (updated != null) {
                        setState(() {
                          _selectedRules
                            ..clear()
                            ..addAll(updated);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Referee Notes / Context',
                    hintText: 'Describe details, warnings given, or match conditions...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final team = _teamController.text.trim();
                      if (team.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a team number')),
                        );
                        return;
                      }

                      ref.read(incidentControllerProvider.notifier).addNote(
                        teamNumber: team,
                        matchId: _matchController.text.trim().isEmpty ? null : _matchController.text.trim(),
                        ruleCodes: _selectedRules.toList(),
                        severity: _severity,
                        notes: _notesController.text.trim(),
                      );

                      Navigator.pop(context);
                    },
                    child: const Text('Save & Sync Incident', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
