import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../incidents/state/incident_controller.dart';
import '../../incidents/screens/incident_logger_screen.dart';
import '../../incidents/widgets/severity_badge.dart';
import '../state/team_controller.dart';
import '../../event_data/screens/event_import_sheet.dart';
import '../../settings/state/sync_settings_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/team_utils.dart';
import '../../../core/utils/match_utils.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final notesAsync = ref.watch(activeTournamentNotesProvider);
        final registeredTeamsAsync = ref.watch(activeTournamentTeamsProvider);
        final settings = ref.watch(syncSettingsProvider);
        final isReloading = ref.watch(teamListControllerProvider);
        final sortState = ref.watch(teamSortProvider);
        final colorScheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: Text(context.l10n.workspaceTitleTeamHistories),
                  actions: [
                    IconButton(
                      icon: isReloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      tooltip: context.l10n.workspaceRefreshTeamsTooltip,
                      onPressed: isReloading
                          ? null
                          : () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.workspaceCheckingTeamUpdates),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                              final result = await ref.read(teamListControllerProvider.notifier).refreshTeams();
                              if (context.mounted) {
                                if (result.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.teamsCount > 0
                                            ? context.l10n.workspaceUpdatedTeams(result.teamsCount)
                                            : context.l10n.workspaceTeamListUpToDate,
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result.errorMessage ?? context.l10n.workspaceFailedToUpdateTeams),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                    if (settings.experimentalFeaturesEnabled)
                      IconButton(
                        icon: const Icon(Icons.download),
                        tooltip: context.l10n.workspaceImportTeamsTooltip,
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.l10n.teamListSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: context.l10n.commonClearSearch,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
              ),
              _buildSortBar(context, ref, sortState),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final result = await ref.read(teamListControllerProvider.notifier).refreshTeams();
                    if (context.mounted) {
                      if (result.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.teamsCount > 0
                                  ? context.l10n.workspaceUpdatedTeams(result.teamsCount)
                                  : context.l10n.workspaceTeamListUpToDate,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.errorMessage ?? context.l10n.workspaceFailedToUpdateTeams),
                            backgroundColor: Theme.of(context).colorScheme.error,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  child: notesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(child: Text(context.l10n.teamListErrorLoading('$err'))),
                        ),
                      ),
                    ),
                    data: (notes) {
                      final registeredTeams = registeredTeamsAsync.value ?? [];
                      final Map<String, List<dynamic>> teamNotes = {};
                      for (final note in notes) {
                        teamNotes.putIfAbsent(note.teamNumber, () => []).add(note);
                      }

                      final Map<String, Team> teamByNumber = {
                        for (final t in registeredTeams) t.teamNumber: t,
                      };

                      final Set<String> allTeamNumbers = {
                        ...teamNotes.keys,
                        ...teamByNumber.keys,
                      };

                      final entries = allTeamNumbers.map((teamNum) {
                        final registered = teamByNumber[teamNum];
                        return TeamListEntry(
                          teamNumber: teamNum,
                          teamName: registered?.teamName,
                          school: registered?.organization,
                          rank: registered?.rank,
                        );
                      }).where((entry) {
                        return matchesTeamSearch(
                          query: _search,
                          teamNumber: entry.teamNumber,
                          teamName: entry.teamName,
                          school: entry.school,
                        );
                      }).toList()
                        ..sort(
                          (a, b) => compareTeamEntries(
                            a,
                            b,
                            sortBy: sortState.field,
                            ascending: sortState.ascending,
                          ),
                        );

                      if (entries.isEmpty) {
                        return LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Symbols.groups, size: 64, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        _search.isEmpty
                                            ? context.l10n.teamListEmpty
                                            : context.l10n.teamListNoTeamsMatching(_search),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final team = entry.teamNumber;
                          final list = teamNotes[team] ?? [];
                          final teamName = normalizeTeamDisplayName(entry.teamName, team);
                          final school = normalizeTeamSchool(entry.school);
                          final teamRank = entry.rank;

                          final majorCount = list.where((n) => n.severity == 'major' || n.severity == 'disabled').length;

                          final textColor = majorCount > 0
                              ? Colors.red.shade900
                              : colorScheme.onPrimaryContainer;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: majorCount > 0
                                    ? Colors.red.shade100
                                    : colorScheme.primaryContainer,
                                child: _buildRankAvatar(context, teamRank, textColor),
                              ),
                              title: Row(
                                children: [
                                  Text(team, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (teamName != null) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        teamName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: school != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            ExcludeSemantics(
                                              child: Icon(
                                                Icons.school_outlined,
                                                size: 14,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                school,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(context.l10n.teamListNoteCount(list.length)),
                                      ],
                                    )
                                  : Text(
                                      context.l10n.teamListNoteCount(list.length),
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
                                        context.l10n.teamListMajorCountBadge(majorCount),
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () {
                                _showTeamHistory(
                                  context,
                                  team,
                                  list,
                                  teamName: teamName,
                                  school: school,
                                );
                              },
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

  String _sortFieldLabel(BuildContext context, TeamSortField field) {
    switch (field) {
      case TeamSortField.number:
        return context.l10n.teamListSortOptionNumber;
      case TeamSortField.rank:
        return context.l10n.teamListSortOptionRank;
      case TeamSortField.name:
        return context.l10n.teamListSortOptionName;
      case TeamSortField.school:
        return context.l10n.teamListSortOptionSchool;
    }
  }

  Widget _buildSortBar(
    BuildContext context,
    WidgetRef ref,
    TeamSortState sortState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.sort,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              for (final field in TeamSortField.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Builder(
                    builder: (context) {
                      final isSelected = sortState.field == field;
                      final label = _sortFieldLabel(context, field);
                      final tooltip = isSelected
                          ? (sortState.ascending
                              ? context.l10n.teamListSortFieldActiveAscendingTooltip(label)
                              : context.l10n.teamListSortFieldActiveDescendingTooltip(label))
                          : context.l10n.teamListSortFieldTooltip(label);

                      return ChoiceChip(
                        key: ValueKey('team_sort_chip_${field.name}'),
                        selected: isSelected,
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        tooltip: tooltip,
                        backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        selectedColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              ExcludeSemantics(
                                child: Icon(
                                  sortState.ascending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ],
                        ),
                        onSelected: (_) {
                          ref.read(teamSortProvider.notifier).selectSortField(field);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankAvatar(BuildContext context, int? teamRank, Color textColor) {
    if (teamRank == null) {
      return Text(
        '-',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      );
    }

    final langCode = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final suffix = langCode == 'en' ? getOrdinalSuffix(teamRank) : '';
    final numFontSize = teamRank > 99 ? 13.0 : (teamRank > 9 ? 15.5 : 17.5);
    final suffixFontSize = teamRank > 99 ? 8.0 : (teamRank > 9 ? 9.5 : 10.5);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$teamRank',
              style: TextStyle(
                fontSize: numFontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.0,
              ),
            ),
            if (suffix.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.5),
                child: Text(
                  suffix,
                  style: TextStyle(
                    fontSize: suffixFontSize,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTeamHistory(
    BuildContext context,
    String teamNumber,
    List<dynamic> notes, {
    String? teamName,
    String? school,
  }) {
    final subtitleParts = <String>[
      if (teamName != null && teamName.isNotEmpty) teamName,
      if (school != null && school.isNotEmpty) school,
    ];

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ctx.l10n.teamListTeamHistoryTitle(teamNumber),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (subtitleParts.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitleParts.join(' • '),
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                    icon: const Icon(Symbols.note_stack_add, size: 18),
                    label: Text(ctx.l10n.commonAddNote),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (notes.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(ctx.l10n.teamListNoNotesForTeam),
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
                                  note.matchId != null && note.matchId!.isNotEmpty
                                      ? formatMatchShortName(note.matchId!)
                                      : c.l10n.teamListGeneralNote,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SeverityBadge(severity: note.severity),
                              ],
                            ),
                            if (ruleCodes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                c.l10n.teamListRulesList(ruleCodes.join(', ')),
                                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                            if (note.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(note.notes),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c.l10n.teamListByReferee(note.refereeName),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: c.l10n.incidentsEditNoteTooltip,
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (sheetCtx) => AddIncidentSheet(existingNote: note),
                                    );
                                  },
                                ),
                              ],
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
