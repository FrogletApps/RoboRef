import 'package:flutter/material.dart';
import '../../rules/models/rule_model.dart';

/// Material 3 modal bottom sheet for searching and selecting multiple rule violations
/// with exact summaries from the Game Manual "Quick Reference Guide".
class RuleSelectionSheet extends StatefulWidget {
  final GameRuleset ruleset;
  final Set<String> initialSelectedRules;

  const RuleSelectionSheet({
    super.key,
    required this.ruleset,
    required this.initialSelectedRules,
  });

  static Future<Set<String>?> show(
    BuildContext context, {
    required GameRuleset ruleset,
    required Set<String> initialSelectedRules,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RuleSelectionSheet(
        ruleset: ruleset,
        initialSelectedRules: initialSelectedRules,
      ),
    );
  }

  @override
  State<RuleSelectionSheet> createState() => _RuleSelectionSheetState();
}

class _RuleSelectionSheetState extends State<RuleSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  late final Set<String> _selectedRules;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _selectedRules = Set<String>.from(widget.initialSelectedRules);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getGroupColor(BuildContext context, String group) {
    final g = group.toLowerCase();
    if (g.contains('specific')) {
      return const Color(0xFF2563EB); // Blue
    } else if (g.contains('general game')) {
      return const Color(0xFF7C3AED); // Purple
    } else if (g.contains('safety')) {
      return const Color(0xFFDC2626); // Red
    } else if (g.contains('robot rules') || g.contains('inspection')) {
      return const Color(0xFFD97706); // Amber
    } else if (g.contains('scoring')) {
      return const Color(0xFF059669); // Emerald
    } else if (g.contains('tournament')) {
      return const Color(0xFF4B5563); // Gray
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final groups = ['All', ...widget.ruleset.rules.map((r) => r.group).toSet()];

    final cleanQuery = _searchQuery.trim().toUpperCase();
    final filteredRules = widget.ruleset.rules.where((r) {
      if (_selectedCategory != 'All' && r.group != _selectedCategory) {
        return false;
      }
      if (cleanQuery.isEmpty) return true;
      final codeMatch = r.code.toUpperCase().contains(cleanQuery) ||
          r.cleanCode.toUpperCase().contains(cleanQuery);
      final titleMatch = r.title.toUpperCase().contains(cleanQuery);
      final groupMatch = r.group.toUpperCase().contains(cleanQuery);
      return codeMatch || titleMatch || groupMatch;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle Bar
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header Title & Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Rule Violations',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.ruleset.program} ${widget.ruleset.gameTitle} (${widget.ruleset.rules.length} rules)',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedRules.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedRules.clear()),
                      child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => Navigator.pop(context, _selectedRules),
                    child: Text('Done (${_selectedRules.length})'),
                  ),
                ],
              ),
            ),

            const Divider(height: 12),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search by rule code (SG1, GG2...) or summary...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
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
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Category Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: groups.map((g) {
                    final isSelected = _selectedCategory == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        label: Text(g),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? g : 'All';
                          });
                        },
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Rules List
            Expanded(
              child: filteredRules.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'No matching rules found',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for another rule code or keyword.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      itemCount: filteredRules.length,
                      itemBuilder: (context, index) {
                        final rule = filteredRules[index];
                        final isSelected = _selectedRules.contains(rule.code) ||
                            _selectedRules.contains(rule.cleanCode) ||
                            _selectedRules.contains(rule.formattedCode);
                        final badgeColor = _getGroupColor(context, rule.group);

                        return Card(
                          elevation: isSelected ? 1.5 : 0,
                          margin: const EdgeInsets.only(bottom: 6.0),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                                  : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedRules.remove(rule.code);
                                  _selectedRules.remove(rule.cleanCode);
                                  _selectedRules.remove(rule.formattedCode);
                                } else {
                                  _selectedRules.add(rule.code);
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedRules.add(rule.code);
                                        } else {
                                          _selectedRules.remove(rule.code);
                                          _selectedRules.remove(rule.cleanCode);
                                          _selectedRules.remove(rule.formattedCode);
                                        }
                                      });
                                    },
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      rule.code,
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          rule.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          rule.group,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
