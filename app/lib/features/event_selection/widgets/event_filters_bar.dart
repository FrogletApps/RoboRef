import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/event_regions.dart';
import '../state/event_filter_controller.dart';

/// Multi-select program, region, and division filter bar for [EventSelectionScreen].
class EventFiltersBar extends ConsumerWidget {
  static const List<String> programs = [
    'All',
    'V5RC',
    'VIQRC',
    'VEX U',
    'VEX AI',
  ];

  final VoidCallback onFiltersChanged;

  const EventFiltersBar({
    super.key,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(eventFiltersProvider);
    final selectedPrograms = filters.programs;
    final selectedRegions = filters.regions;
    final selectedDivisions = filters.divisions;

    final activeDivisionConfigs = vexRegions
        .where(selectedRegions.contains)
        .map(getRegionDivisionConfig)
        .whereType<RegionDivisionConfig>()
        .toList();
    final hasActiveFilters = filters.hasActiveFilters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Program Filter Chips (Multi-Select)
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: programs.map((program) {
                final isSelected = program == 'All'
                    ? selectedPrograms.isEmpty
                    : selectedPrograms.contains(program);
                final displayLabel =
                    program == 'All' ? context.l10n.commonAll : program;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(displayLabel),
                    selected: isSelected,
                    onSelected: (_) {
                      final notifier = ref.read(eventFiltersProvider.notifier);
                      if (program == 'All') {
                        notifier.setPrograms(const {});
                      } else {
                        notifier.toggleProgram(program);
                      }
                      onFiltersChanged();
                    },
                    showCheckmark: program != 'All',
                    checkmarkColor: Colors.white,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    selectedColor: _programChipColor(context, program),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Region & Division Filter Chips + Reset Button
        Row(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilterChip(
                        avatar: Icon(
                          selectedRegions.isEmpty
                              ? Icons.public_outlined
                              : Icons.public,
                          size: 16,
                          color: selectedRegions.isNotEmpty
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          selectedRegions.isEmpty
                              ? context.l10n.eventSelectionAllRegions
                              : selectedRegions.length == 1
                                  ? context.l10n.eventSelectionRegionSelected(
                                      selectedRegions.first,
                                    )
                                  : context.l10n.eventSelectionRegionsSelected(
                                      selectedRegions.length,
                                    ),
                        ),
                        selected: selectedRegions.isNotEmpty,
                        showCheckmark: false,
                        onSelected: (_) => _showRegionPickerModal(
                          context,
                          ref,
                          selectedRegions,
                        ),
                        deleteIcon: selectedRegions.isNotEmpty
                            ? Icon(
                                Icons.close,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : const Icon(Icons.arrow_drop_down, size: 18),
                        onDeleted: selectedRegions.isNotEmpty
                            ? () {
                                ref
                                    .read(eventFiltersProvider.notifier)
                                    .setRegions(const {});
                                onFiltersChanged();
                              }
                            : () => _showRegionPickerModal(
                                  context,
                                  ref,
                                  selectedRegions,
                                ),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: selectedRegions.isNotEmpty
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                          fontWeight: selectedRegions.isNotEmpty
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      for (final divisionConfig in activeDivisionConfigs) ...[
                        const SizedBox(width: 8),
                        _buildDivisionChip(
                          context,
                          ref,
                          divisionConfig,
                          selectedDivisions,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  ref.read(eventFiltersProvider.notifier).resetFilters();
                  onFiltersChanged();
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: Text(
                  context.l10n.eventSelectionResetFilters,
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDivisionChip(
    BuildContext context,
    WidgetRef ref,
    RegionDivisionConfig divisionConfig,
    Set<String> selectedDivisions,
  ) {
    final selectedForConfig = selectedDivisions
        .where(divisionConfig.divisions.contains)
        .toList()
      ..sort();
    final hasDivs = selectedForConfig.isNotEmpty;

    return FilterChip(
      avatar: Icon(
        hasDivs ? Icons.place : Icons.place_outlined,
        size: 16,
        color: hasDivs
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary,
      ),
      label: Text(divisionConfig.selectedMultiLabel(context, selectedForConfig)),
      selected: hasDivs,
      showCheckmark: false,
      onSelected: (_) => _showDivisionPickerModal(
        context,
        ref,
        divisionConfig,
        selectedForConfig.toSet(),
      ),
      deleteIcon: hasDivs
          ? Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            )
          : const Icon(Icons.arrow_drop_down, size: 18),
      onDeleted: hasDivs
          ? () {
              ref
                  .read(eventFiltersProvider.notifier)
                  .clearDivisionsForRegion(divisionConfig);
              onFiltersChanged();
            }
          : () => _showDivisionPickerModal(
                context,
                ref,
                divisionConfig,
                selectedForConfig.toSet(),
              ),
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: hasDivs ? Theme.of(context).colorScheme.onPrimary : null,
        fontWeight: hasDivs ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Color _programChipColor(BuildContext context, String program) {
    switch (program) {
      case 'VIQRC':
        return const Color(0xFF1E88E5);
      case 'V5RC':
      case 'VEX U':
        return const Color(0xFFD32F2F);
      case 'VEX AI':
        return const Color(0xFF8E24AA);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _showRegionPickerModal(
    BuildContext context,
    WidgetRef ref,
    Set<String> currentRegions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return RegionPickerSheet(
          selectedRegions: currentRegions,
          onRegionsApplied: (regions) {
            Navigator.of(ctx).pop();
            ref.read(eventFiltersProvider.notifier).setRegions(regions);
            onFiltersChanged();
          },
        );
      },
    );
  }

  void _showDivisionPickerModal(
    BuildContext context,
    WidgetRef ref,
    RegionDivisionConfig config,
    Set<String> currentDivisions,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DivisionPickerSheet(
          config: config,
          selectedDivisions: currentDivisions,
          onDivisionsApplied: (divisions) {
            Navigator.of(ctx).pop();
            ref
                .read(eventFiltersProvider.notifier)
                .setDivisionsForRegion(config, divisions);
            onFiltersChanged();
          },
        );
      },
    );
  }
}

class _MultiSelectPickerHeader extends StatelessWidget {
  final String title;
  final int selectedCount;
  final VoidCallback onClearAll;
  final VoidCallback onDone;
  final bool isMultiSelect;

  const _MultiSelectPickerHeader({
    required this.title,
    required this.selectedCount,
    required this.onClearAll,
    required this.onDone,
    this.isMultiSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isMultiSelect && selectedCount > 0)
                TextButton(
                  onPressed: onClearAll,
                  child: Text(context.l10n.commonClearAll),
                ),
              if (isMultiSelect) ...[
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: onDone,
                  child: Text(
                    selectedCount > 0
                        ? context.l10n.commonDoneCount(selectedCount)
                        : context.l10n.commonDone,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class RegionPickerSheet extends StatefulWidget {
  final Set<String> selectedRegions;
  final ValueChanged<Set<String>> onRegionsApplied;

  const RegionPickerSheet({
    super.key,
    required this.selectedRegions,
    required this.onRegionsApplied,
  });

  @override
  State<RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<RegionPickerSheet> {
  final TextEditingController _filterController = TextEditingController();
  final List<String> _allRegions = getSortedVexRegions();
  late final Set<String> _draftSelectedRegions;
  late bool _isMultiSelect;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _draftSelectedRegions = Set<String>.from(widget.selectedRegions);
    _isMultiSelect = widget.selectedRegions.length > 1;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _setMultiSelect(bool enabled) {
    setState(() {
      _isMultiSelect = enabled;
      if (!enabled && _draftSelectedRegions.length > 1) {
        final first = _draftSelectedRegions.first;
        _draftSelectedRegions
          ..clear()
          ..add(first);
      }
    });
  }

  void _toggleRegion(String region) {
    setState(() {
      if (!_draftSelectedRegions.add(region)) {
        _draftSelectedRegions.remove(region);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterText.trim().toUpperCase();

    final visibleRegions = _allRegions.where((region) {
      return isRegionMatchingQuery(region, _filterText);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        return Column(
          children: [
            _MultiSelectPickerHeader(
              title: context.l10n.eventSelectionFilterByRegion,
              selectedCount: _draftSelectedRegions.length,
              isMultiSelect: _isMultiSelect,
              onClearAll: () => setState(() => _draftSelectedRegions.clear()),
              onDone: () => widget.onRegionsApplied(_draftSelectedRegions),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: TextField(
                controller: _filterController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: context.l10n.eventSelectionSearchRegionHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _filterText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: context.l10n.commonClearSearch,
                          onPressed: () {
                            _filterController.clear();
                            setState(() {
                              _filterText = '';
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _filterText = val;
                  });
                },
              ),
            ),
            CheckboxListTile(
              value: _isMultiSelect,
              onChanged: (value) => _setMultiSelect(value ?? false),
              title: Text(
                context.l10n.eventSelectionEnableMultiselect,
                style: theme.textTheme.bodyMedium,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            const Divider(height: 1),
            Expanded(
              child: visibleRegions.isEmpty && query.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n
                                  .eventSelectionNoRegionsMatching(_filterText),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount:
                          visibleRegions.length + (query.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (query.isEmpty && index == 0) {
                          final isSelected = _draftSelectedRegions.isEmpty;
                          return ListTile(
                            leading: Icon(
                              Icons.public,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            ),
                            title: Text(
                              context.l10n.eventSelectionAllRegions,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              if (_isMultiSelect) {
                                setState(() => _draftSelectedRegions.clear());
                              } else {
                                widget.onRegionsApplied(const {});
                              }
                            },
                          );
                        }

                        final regionIndex = query.isEmpty ? index - 1 : index;
                        final region = visibleRegions[regionIndex];
                        final isSelected =
                            _draftSelectedRegions.contains(region);
                        final matchingDivisions =
                            getMatchingDivisionsForRegion(region, _filterText);

                        return ListTile(
                          leading: Icon(
                            Icons.public,
                            size: 20,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          title: Text(
                            region,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: (matchingDivisions.isNotEmpty &&
                                  !region.toUpperCase().contains(query))
                              ? Text(
                                  context.l10n.eventSelectionRegionIncludes(
                                    '${matchingDivisions.take(3).join(', ')}${matchingDivisions.length > 3 ? '...' : ''}',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                          trailing: _isMultiSelect
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (_) => _toggleRegion(region),
                                )
                              : (isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: theme.colorScheme.primary,
                                    )
                                  : null),
                          onTap: () {
                            if (_isMultiSelect) {
                              _toggleRegion(region);
                            } else {
                              widget.onRegionsApplied({region});
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class DivisionPickerSheet extends StatefulWidget {
  final RegionDivisionConfig config;
  final Set<String> selectedDivisions;
  final ValueChanged<Set<String>> onDivisionsApplied;

  const DivisionPickerSheet({
    super.key,
    required this.config,
    required this.selectedDivisions,
    required this.onDivisionsApplied,
  });

  @override
  State<DivisionPickerSheet> createState() => _DivisionPickerSheetState();
}

class _DivisionPickerSheetState extends State<DivisionPickerSheet> {
  final TextEditingController _filterController = TextEditingController();
  late final List<String> _allDivisions;
  late final Set<String> _draftSelectedDivisions;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _allDivisions = List<String>.from(widget.config.divisions)
      ..sort((a, b) => a.compareTo(b));
    _draftSelectedDivisions = Set<String>.from(widget.selectedDivisions);
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _toggleDivision(String division) {
    setState(() {
      if (!_draftSelectedDivisions.add(division)) {
        _draftSelectedDivisions.remove(division);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterText.trim().toUpperCase();

    final visibleDivisions = _allDivisions.where((div) {
      if (query.isEmpty) return true;
      final upper = div.toUpperCase();
      if (upper.contains(query)) return true;

      final aliasTarget = divisionAliases[query]?.toUpperCase();
      if (aliasTarget != null &&
          (upper == aliasTarget || upper.contains(aliasTarget))) {
        return true;
      }
      return false;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        return Column(
          children: [
            _MultiSelectPickerHeader(
              title: widget.config.filterByTitle(context),
              selectedCount: _draftSelectedDivisions.length,
              onClearAll: () => setState(() => _draftSelectedDivisions.clear()),
              onDone: () => widget.onDivisionsApplied(_draftSelectedDivisions),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _filterController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: widget.config.searchHint(context),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _filterText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: context.l10n.commonClearSearch,
                          onPressed: () {
                            _filterController.clear();
                            setState(() {
                              _filterText = '';
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _filterText = val;
                  });
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: visibleDivisions.isEmpty && query.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.config
                                  .noMatchingLabel(context, _filterText),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount:
                          visibleDivisions.length + (query.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (query.isEmpty && index == 0) {
                          final isSelected = _draftSelectedDivisions.isEmpty;
                          return ListTile(
                            leading: Icon(
                              Icons.place,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            ),
                            title: Text(
                              widget.config.allLabel(context),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () => setState(
                              () => _draftSelectedDivisions.clear(),
                            ),
                          );
                        }

                        final divIndex = query.isEmpty ? index - 1 : index;
                        final divName = visibleDivisions[divIndex];
                        final isSelected =
                            _draftSelectedDivisions.contains(divName);

                        return ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          title: Text(
                            divName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleDivision(divName),
                          ),
                          onTap: () => _toggleDivision(divName),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
