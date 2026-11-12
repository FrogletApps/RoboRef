import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/match_controller.dart';
import '../../event_data/screens/event_import_sheet.dart';
import '../../event_selection/state/event_controller.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../../incidents/screens/incident_logger_screen.dart';
import '../../incidents/state/incident_controller.dart';
import '../../rules/data/default_rules.dart';
import '../../rules/models/rule_model.dart';
import '../../../database/app_database.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/team_utils.dart';
import '../../../core/utils/match_utils.dart';
import '../../../core/utils/sku_utils.dart';

class MatchScheduleScreen extends StatefulWidget {
  final bool showAppBar;

  const MatchScheduleScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<MatchScheduleScreen> createState() => _MatchScheduleScreenState();
}

class _MatchScheduleScreenState extends State<MatchScheduleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefreshMatches(
    BuildContext context,
    WidgetRef ref, {
    bool showCheckingSnackBar = true,
  }) async {
    if (showCheckingSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.workspaceCheckingMatchUpdates),
          duration: const Duration(seconds: 1),
        ),
      );
    }
    final result = await ref.read(matchScheduleControllerProvider.notifier).refreshMatches();
    if (context.mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.matchesCount > 0
                  ? context.l10n.workspaceUpdatedMatches(result.matchesCount)
                  : context.l10n.workspaceMatchScheduleUpToDate,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? context.l10n.workspaceFailedToUpdateMatches),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final matchesAsync = ref.watch(activeTournamentMatchesProvider);
        final settings = ref.watch(syncSettingsProvider);
        final isReloading = ref.watch(matchScheduleControllerProvider);

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: Column(
                    children: [
                      Text(context.l10n.workspaceTitleMatchSchedule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        settings.currentSku,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: isReloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      tooltip: context.l10n.workspaceRefreshMatchesTooltip,
                      onPressed: isReloading
                          ? null
                          : () => _handleRefreshMatches(context, ref),
                    ),
                    if (settings.experimentalFeaturesEnabled)
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: context.l10n.workspaceImportScheduleTooltip,
                        onPressed: () => _showImportSheet(context),
                      ),
                  ],
                )
              : null,
          body: Column(
            children: [
              // Search / Filter
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.l10n.matchScheduleSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: context.l10n.commonClearSearch,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
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
                child: RefreshIndicator(
                  onRefresh: () => _handleRefreshMatches(context, ref, showCheckingSnackBar: false),
                  child: matchesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(child: Text(context.l10n.matchScheduleErrorLoading('$err'))),
                        ),
                      ),
                    ),
                    data: (matches) {
                      final filtered = matches.where((m) {
                        if (_searchQuery.isEmpty) return true;
                        final nameUpper = m.name.toUpperCase();
                        final shortCode = getMatchShortCode(m.name).toUpperCase();
                        final cleanQuery = _searchQuery.replaceAll(' ', '');
                        final nameMatch = nameUpper.contains(_searchQuery) ||
                            shortCode.contains(_searchQuery) ||
                            nameUpper.replaceAll(' ', '').contains(cleanQuery) ||
                            shortCode.replaceAll(' ', '').contains(cleanQuery);
                        final redMatch = m.redTeamsJson.toUpperCase().contains(_searchQuery);
                        final blueMatch = m.blueTeamsJson.toUpperCase().contains(_searchQuery);
                        return nameMatch || redMatch || blueMatch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Symbols.format_list_numbered, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      matches.isEmpty
                                          ? context.l10n.matchScheduleEmpty
                                          : context.l10n.matchScheduleNoMatchesMatching(_searchQuery),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                    ),
                                    if (matches.isEmpty) ...[
                                      const SizedBox(height: 16),
                                      FilledButton.tonalIcon(
                                        onPressed: isReloading
                                            ? null
                                            : () => _handleRefreshMatches(context, ref),
                                        style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 44),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                                        icon: isReloading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : const Icon(Icons.refresh),
                                        label: Text(
                                          isReloading
                                              ? context.l10n.matchScheduleCheckingButton
                                              : context.l10n.matchScheduleCheckButton,
                                        ),
                                      ),
                                    ],
                                    if (settings.experimentalFeaturesEnabled) ...[
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _showImportSheet(context),
                                        icon: const Icon(Icons.cloud_download),
                                        label: Text(context.l10n.matchScheduleFetchOrImportButton),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final match = filtered[index];
                        List<dynamic> redTeams = [];
                        List<dynamic> blueTeams = [];

                        try {
                          redTeams = (jsonDecode(match.redTeamsJson) as List).map((e) => e.toString()).toList()..sort(compareTeamNumbers);
                          blueTeams = (jsonDecode(match.blueTeamsJson) as List).map((e) => e.toString()).toList()..sort(compareTeamNumbers);
                        } catch (_) {}

                        final scheduleInfo = formatMatchScheduleDateTime(
                          match.scheduledTime,
                          context: context,
                        );

                        return Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showMatchActions(context, match.name, redTeams, blueTeams),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Left side: Match number and Teams / Alliances
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatMatchShortName(match.name),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          if (redTeams.isNotEmpty || blueTeams.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            if (blueTeams.isEmpty) ...[
                                              // Single Alliance (e.g. VEX IQ Teamwork Challenge)
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildAllianceLabel(context.l10n.matchScheduleAllianceTeams, Theme.of(context).colorScheme.primary, width: 50),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: redTeams.map((team) {
                                                        return _buildTeamPill(team.toString(), Theme.of(context).colorScheme.primary);
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ] else ...[
                                              // Red Alliance
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildAllianceLabel(context.l10n.matchScheduleAllianceRed, Colors.red.shade700),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: redTeams.map((team) {
                                                        return _buildTeamPill(team.toString(), Colors.red.shade700);
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),

                                              // Blue Alliance
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildAllianceLabel(context.l10n.matchScheduleAllianceBlue, Colors.blue.shade700),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: blueTeams.map((team) {
                                                        return _buildTeamPill(team.toString(), Colors.blue.shade700);
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Right side: Field at top right, Date and Time at bottom right
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Top right: Field name
                                        if (match.field != null && match.field!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              match.field!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),

                                        // Bottom right: Date & Time
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (scheduleInfo.date != null && scheduleInfo.date!.isNotEmpty)
                                              Text(
                                                scheduleInfo.date!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            if (scheduleInfo.time != null && scheduleInfo.time!.isNotEmpty) ...[
                                              if (scheduleInfo.date != null && scheduleInfo.date!.isNotEmpty)
                                                const SizedBox(height: 1),
                                              Text(
                                                scheduleInfo.time!,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
          ),
        );
      },
    );
  }

  Widget _buildAllianceLabel(String text, Color color, {double width = 44}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamPill(String teamNumber, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        teamNumber,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
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
    final displayMatchName = formatMatchShortName(matchName);
    final sortedRedTeams = List<String>.from(redTeams.map((e) => e.toString()))..sort(compareTeamNumbers);
    final sortedBlueTeams = List<String>.from(blueTeams.map((e) => e.toString()))..sort(compareTeamNumbers);
    final isSingleAlliance = sortedBlueTeams.isEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final notes = ref.watch(activeTournamentNotesProvider).value ?? [];
            final settings = ref.watch(syncSettingsProvider);
            final activeEventAsync = ref.watch(activeEventProvider);
            final program = activeEventAsync.value?.program ?? getSkuProgram(settings.currentSku);
            final season = activeEventAsync.value?.season ?? '2026-2027';
            final ruleset = getGameRuleset(
              program,
              season,
              locale: Localizations.maybeLocaleOf(context),
            );
            final fullMatchName = localizeMatchName(context, matchName);

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    Text(
                      fullMatchName.isNotEmpty ? fullMatchName : displayMatchName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (sortedRedTeams.isEmpty && sortedBlueTeams.isEmpty)
                      Text(
                        context.l10n.matchScheduleNoTeamsAssigned,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...sortedRedTeams.map((teamStr) => _buildMatchTeamDetailsCard(
                                    context: context,
                                    sheetContext: ctx,
                                    teamNumber: teamStr,
                                    displayMatchName: displayMatchName,
                                    allianceColor: isSingleAlliance
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.red.shade700,
                                    allNotes: notes,
                                    ruleset: ruleset,
                                  )),
                              ...sortedBlueTeams.map((teamStr) => _buildMatchTeamDetailsCard(
                                    context: context,
                                    sheetContext: ctx,
                                    teamNumber: teamStr,
                                    displayMatchName: displayMatchName,
                                    allianceColor: Colors.blue.shade700,
                                    allNotes: notes,
                                    ruleset: ruleset,
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMatchTeamDetailsCard({
    required BuildContext context,
    required BuildContext sheetContext,
    required String teamNumber,
    required String displayMatchName,
    required Color allianceColor,
    required List<IncidentNote> allNotes,
    required GameRuleset ruleset,
  }) {
    final teamUpper = teamNumber.trim().toUpperCase();
    final teamNotes = allNotes.where((n) => n.teamNumber.trim().toUpperCase() == teamUpper).toList();

    const severityOrder = ['major', 'disabled', 'minor', 'inspection', 'general'];
    final Map<({String severity, String? ruleCode}), int> violationCounts = {};

    for (final note in teamNotes) {
      final sev = note.severity.trim().toLowerCase();
      final normalizedSev = severityOrder.contains(sev) ? sev : 'general';

      final List<String> noteRuleCodes = [];
      try {
        final decoded = jsonDecode(note.ruleCodesJson);
        if (decoded is List) {
          for (final item in decoded) {
            final rawCode = item.toString().trim();
            if (rawCode.isEmpty) continue;
            final matchedRule = ruleset.findRule(rawCode);
            final code = matchedRule?.code ??
                (rawCode.startsWith('<') && rawCode.endsWith('>')
                    ? rawCode.toUpperCase()
                    : '<${rawCode.replaceAll(RegExp(r'[<>]'), '').toUpperCase()}>');
            noteRuleCodes.add(code);
          }
        }
      } catch (_) {}

      if (noteRuleCodes.isEmpty) {
        final key = (severity: normalizedSev, ruleCode: null);
        violationCounts[key] = (violationCounts[key] ?? 0) + 1;
      } else {
        for (final code in noteRuleCodes) {
          final key = (severity: normalizedSev, ruleCode: code);
          violationCounts[key] = (violationCounts[key] ?? 0) + 1;
        }
      }
    }

    final violationEntries = violationCounts.entries.toList()
      ..sort((a, b) {
        final sevDiff = severityOrder.indexOf(a.key.severity).compareTo(severityOrder.indexOf(b.key.severity));
        if (sevDiff != 0) return sevDiff;
        if (a.key.ruleCode != null && b.key.ruleCode == null) return -1;
        if (a.key.ruleCode == null && b.key.ruleCode != null) return 1;
        final countDiff = b.value.compareTo(a.value);
        if (countDiff != 0) return countDiff;
        return (a.key.ruleCode ?? '').compareTo(b.key.ruleCode ?? '');
      });

    return Container(
      key: ValueKey('match_team_$teamNumber'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allianceColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTeamPill(teamNumber, allianceColor),
              FilledButton.tonalIcon(
                key: ValueKey('add_note_$teamNumber'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (c) => AddIncidentSheet(
                      initialMatch: displayMatchName,
                      initialTeam: teamNumber,
                    ),
                  );
                },
                icon: const Icon(Symbols.note_stack_add, size: 16),
                label: Text(context.l10n.commonAddNote),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (teamNotes.isEmpty)
            Text(
              context.l10n.matchScheduleNoNotesLogged,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: violationEntries
                  .map((entry) => _buildViolationPill(
                        context: context,
                        ruleset: ruleset,
                        severity: entry.key.severity,
                        ruleCode: entry.key.ruleCode,
                        count: entry.value,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildViolationPill({
    required BuildContext context,
    required GameRuleset ruleset,
    required String severity,
    required String? ruleCode,
    required int count,
  }) {
    Color bg;
    Color fg;
    final String typeLabel = localizeSeverity(context, severity);

    switch (severity.toLowerCase()) {
      case 'major':
        bg = Colors.red.shade900;
        fg = Colors.white;
        break;
      case 'minor':
        bg = Colors.yellow.shade600;
        fg = Colors.black87;
        break;
      case 'disabled':
        bg = Colors.purple.shade700;
        fg = Colors.white;
        break;
      case 'inspection':
        bg = Colors.teal.shade700;
        fg = Colors.white;
        break;
      case 'general':
      default:
        bg = Colors.blueGrey.shade100;
        fg = Colors.blueGrey.shade900;
        break;
    }

    final displayText = ruleCode != null && ruleCode.isNotEmpty
        ? '$typeLabel $ruleCode ×$count'
        : '$typeLabel ×$count';

    final matchedRule = ruleCode != null ? ruleset.findRule(ruleCode) : null;
    final summary = matchedRule?.summary;
    final tooltipMessage = summary != null && summary.isNotEmpty
        ? '$typeLabel ${matchedRule!.code}: $summary ($count)'
        : displayText;

    return Tooltip(
      message: tooltipMessage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
