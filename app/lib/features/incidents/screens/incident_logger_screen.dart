import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../state/incident_controller.dart';
import '../widgets/severity_badge.dart';
import '../../settings/state/sync_settings_controller.dart';

class IncidentLoggerScreen extends ConsumerStatefulWidget {
  const IncidentLoggerScreen({super.key});

  @override
  ConsumerState<IncidentLoggerScreen> createState() => _IncidentLoggerScreenState();
}

class _IncidentLoggerScreenState extends ConsumerState<IncidentLoggerScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(activeTournamentNotesProvider);
    final settings = ref.watch(syncSettingsProvider);

    return Scaffold(
      appBar: AppBar(
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
      ),
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
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
                                        note.matchId!,
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
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      border: Border.all(color: Colors.blue.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      rule.toString(),
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
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
                                  onPressed: () => _confirmDelete(context, note.id),
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
  }

  void _confirmDelete(BuildContext context, String id) {
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

class AddIncidentSheet extends ConsumerStatefulWidget {
  const AddIncidentSheet({super.key});

  @override
  ConsumerState<AddIncidentSheet> createState() => _AddIncidentSheetState();
}

class _AddIncidentSheetState extends ConsumerState<AddIncidentSheet> {
  final _teamController = TextEditingController();
  final _matchController = TextEditingController();
  final _notesController = TextEditingController();

  String _severity = 'warning';
  final Set<String> _selectedRules = {};

  final List<String> _quickRules = [
    'G1 (Pinning)',
    'G12 (Entanglement)',
    'S1 (Safety)',
    'SG6 (Autonomous)',
    'R1 (Robot Inspection)',
    'T1 (Field Reset)',
  ];

  @override
  Widget build(BuildContext context) {
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
              children: [
                Expanded(
                  child: TextField(
                    controller: _teamController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Team Number *',
                      hintText: 'e.g. 1234A',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _matchController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Match (Optional)',
                      hintText: 'e.g. Q42',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
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
            const Text('Rule Infractions', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickRules.map((rule) {
                final isSelected = _selectedRules.contains(rule);
                return FilterChip(
                  label: Text(rule),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedRules.add(rule);
                      } else {
                        _selectedRules.remove(rule);
                      }
                    });
                  },
                );
              }).toList(),
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
  }
}
