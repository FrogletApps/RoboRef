import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/event_regions.dart';
import '../../../core/utils/sku_utils.dart';
import '../../event_workspace/screens/event_workspace_screen.dart';
import '../models/event_model.dart';
import '../state/event_controller.dart';
import '../state/event_filter_controller.dart';

class EventSelectionScreen extends ConsumerStatefulWidget {
  const EventSelectionScreen({super.key});

  @override
  ConsumerState<EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends ConsumerState<EventSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<EventModel> _apiEvents = [];

  // Date range: currently active (past 3 days) or over the next week (7 days)
  late DateTime _startDate;
  late DateTime _endDate;
  int _daysForward = 7;

  final List<String> _programs = const ['All', 'V5RC', 'VIQRC', 'VEX U', 'VEX AI'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 3));
    _endDate = now.add(Duration(days: _daysForward));
    _fetchEvents();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _fetchEvents();
    });
  }

  Future<void> _fetchEvents({bool isLoadMore = false}) async {
    if (!mounted) return;
    setState(() {
      if (isLoadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    final client = ref.read(vexEventsClientProvider);
    final filters = ref.read(eventFiltersProvider);
    final cleanQuery = _searchQuery.trim();

    try {
      final results = await client.searchEvents(
        query: cleanQuery.isNotEmpty ? cleanQuery : null,
        program: filters.program != 'All' ? filters.program : null,
        region: filters.division != 'All'
            ? filters.division
            : (filters.region != 'All' ? filters.region : null),
        start: cleanQuery.toUpperCase().startsWith('RE-') ? null : _startDate,
        end: cleanQuery.toUpperCase().startsWith('RE-') ? null : _endDate,
        perPage: 50,
      );

      if (mounted) {
        setState(() {
          _apiEvents = results;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _loadMoreEvents() {
    setState(() {
      _daysForward += 30;
      _endDate = DateTime.now().add(Duration(days: _daysForward));
    });
    _fetchEvents(isLoadMore: true);
  }

  Future<void> _handleEventSelection(EventModel event) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 1. Instantly select event and store metadata in SQLite and Riverpod
    try {
      await ref.read(eventControllerProvider.notifier).selectEvent(
            sku: event.sku,
            name: event.name,
            program: event.program,
            season: event.season,
            startDate: event.startDate,
            endDate: event.endDate,
            venue: event.venue,
            city: event.city,
            region: event.region,
          );
    } catch (_) {}

    // 2. Navigate immediately to the Event Workspace screen
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const EventWorkspaceScreen()),
    );

    // 3. Show loading notification
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading teams and match schedule for ${event.sku}...',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    // 4. Ingest tournament schedule & rosters asynchronously from VEX Events
    ref.read(eventControllerProvider.notifier).importAndSelectEvent(event: event).then((result) {
      if (result.success) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Loaded "${result.eventName ?? event.sku}" (${result.teamsCount} teams, ${result.matchesCount} matches)',
            ),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (result.errorMessage != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Note: ${result.errorMessage}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(eventFiltersProvider);
    final selectedProgram = filters.program;
    final selectedRegion = filters.region;
    final selectedDivision = filters.division;

    final cleanQuery = _searchQuery.trim().toUpperCase();
    final isCustomSkuValid = isValidSku(cleanQuery);

    // Client-side text filter over API results if query is typed
    List<EventModel> filteredApiEvents = _apiEvents;

    final isDirectSkuQuery = cleanQuery.startsWith('RE-');
    if (selectedProgram != 'All' && !isDirectSkuQuery) {
      filteredApiEvents = filteredApiEvents
          .where((e) => isEventMatchingProgram(
                program: e.program,
                sku: e.sku,
                selectedProgram: selectedProgram,
              ))
          .toList();
    }

    if (selectedRegion != 'All' && !isDirectSkuQuery) {
      final targetRegion = selectedRegion.toUpperCase().trim();
      final isTaiwan = targetRegion == 'TAIWAN' || targetRegion == 'CHINESE TAIPEI';
      final isUS = targetRegion == 'UNITED STATES' || targetRegion == 'USA' || targetRegion == 'US';
      final isCanada = targetRegion == 'CANADA' || targetRegion == 'CA';
      final isAustralia = targetRegion == 'AUSTRALIA' || targetRegion == 'AU';
      final isUK = targetRegion == 'UNITED KINGDOM' || targetRegion == 'UK' || targetRegion == 'GB';

      filteredApiEvents = filteredApiEvents.where((e) {
        final country = e.country?.toUpperCase() ?? '';
        final region = e.region?.toUpperCase() ?? '';
        final city = e.city?.toUpperCase() ?? '';
        final venue = e.venue?.toUpperCase() ?? '';

        if (isTaiwan) {
          return country == 'TAIWAN' ||
              country == 'CHINESE TAIPEI' ||
              country.contains('TAIPEI') ||
              region == 'TAIWAN' ||
              region == 'CHINESE TAIPEI' ||
              region.contains('TAIPEI') ||
              city.contains('TAIPEI') ||
              venue.contains('TAIPEI');
        }

        if (isUS) {
          return country == 'UNITED STATES' ||
              country == 'USA' ||
              country == 'US' ||
              country.contains('UNITED STATES') ||
              region == 'UNITED STATES';
        }

        if (isCanada) {
          return country == 'CANADA' ||
              country.contains('CANADA') ||
              region == 'CANADA';
        }

        if (isAustralia) {
          return country == 'AUSTRALIA' ||
              country.contains('AUSTRALIA') ||
              region == 'AUSTRALIA';
        }

        if (isUK) {
          return country == 'UNITED KINGDOM' ||
              country == 'GREAT BRITAIN' ||
              country == 'UK' ||
              region == 'ENGLAND' ||
              region == 'SCOTLAND' ||
              region == 'WALES' ||
              region == 'NORTHERN IRELAND' ||
              region == 'UNITED KINGDOM' ||
              country.contains('UNITED KINGDOM') ||
              country.contains('GREAT BRITAIN') ||
              country.contains('UK') ||
              region.contains('ENGLAND') ||
              region.contains('SCOTLAND') ||
              region.contains('WALES') ||
              region.contains('NORTHERN IRELAND') ||
              region.contains('UNITED KINGDOM');
        }

        return country == targetRegion ||
            country.contains(targetRegion) ||
            region == targetRegion ||
            region.contains(targetRegion) ||
            city.contains(targetRegion) ||
            venue.contains(targetRegion);
      }).toList();
    }

    if (selectedDivision != 'All' && !isDirectSkuQuery) {
      final targetDivision = selectedDivision.toUpperCase().trim();
      filteredApiEvents = filteredApiEvents.where((e) {
        final region = e.region?.toUpperCase() ?? '';
        final city = e.city?.toUpperCase() ?? '';
        final venue = e.venue?.toUpperCase() ?? '';
        return region == targetDivision ||
            region.contains(targetDivision) ||
            city.contains(targetDivision) ||
            venue.contains(targetDivision);
      }).toList();
    }

    if (cleanQuery.isNotEmpty && !isDirectSkuQuery) {
      filteredApiEvents = filteredApiEvents.where((e) {
        final nameMatch = e.name.toUpperCase().contains(cleanQuery);
        final skuMatch = e.sku.toUpperCase().contains(cleanQuery);
        final venueMatch = e.venue?.toUpperCase().contains(cleanQuery) ?? false;
        final cityMatch = e.city?.toUpperCase().contains(cleanQuery) ?? false;
        final regionMatch = e.region?.toUpperCase().contains(cleanQuery) ?? false;
        final countryMatch = e.country?.toUpperCase().contains(cleanQuery) ?? false;
        return nameMatch || skuMatch || venueMatch || cityMatch || regionMatch || countryMatch;
      }).toList();
    }

    final displayEvents = filteredApiEvents;

    DateTime? firstDate;
    DateTime? lastDate;

    if (displayEvents.isNotEmpty) {
      for (final e in displayEvents) {
        final start = DateTime.tryParse(e.startDate);
        final end = DateTime.tryParse(e.endDate) ?? start;
        if (start != null) {
          if (firstDate == null || start.isBefore(firstDate)) {
            firstDate = start;
          }
        }
        if (end != null) {
          if (lastDate == null || end.isAfter(lastDate)) {
            lastDate = end;
          }
        }
      }
    }

    firstDate ??= _startDate;
    lastDate ??= _endDate;

    final locale = getUserLocale(context);
    final yDateStr = formatEventDate(firstDate.toIso8601String(), locale);
    final zDateStr = formatEventDate(lastDate.toIso8601String(), locale);
    final searchSummary = 'Found ${displayEvents.length} events between $yDateStr and $zDateStr';

    final divisionConfig = getRegionDivisionConfig(selectedRegion);
    final hasActiveFilters = selectedProgram != 'All' ||
        selectedRegion != 'All' ||
        selectedDivision != 'All';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick An Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Events',
            onPressed: () => _fetchEvents(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search by SKU (RE-...) or event name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
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
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 10),

                // Program Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _programs.map((program) {
                      final isSelected = selectedProgram == program;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(program),
                          selected: isSelected,
                          onSelected: (selected) {
                            ref.read(eventFiltersProvider.notifier).setProgram(
                                  program == 'All' ? 'All' : (selected ? program : 'All'),
                                );
                            _fetchEvents();
                          },
                          showCheckmark: false,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          selectedColor: program == 'VIQRC'
                              ? const Color(0xFF1E88E5)
                              : program == 'V5RC' || program == 'VEX U'
                                  ? const Color(0xFFD32F2F)
                                  : program == 'VEX AI'
                                      ? const Color(0xFF8E24AA)
                                      : Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Region & CountryDivision Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Region Chip
                      FilterChip(
                        avatar: Icon(
                          selectedRegion == 'All' ? Icons.public_outlined : Icons.public,
                          size: 16,
                          color: selectedRegion != 'All'
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          selectedRegion == 'All' ? 'All Regions' : 'Region: $selectedRegion',
                        ),
                        selected: selectedRegion != 'All',
                        showCheckmark: false,
                        onSelected: (_) => _showRegionPickerModal(context, selectedRegion),
                        deleteIcon: selectedRegion != 'All'
                            ? Icon(
                                Icons.close,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : const Icon(Icons.arrow_drop_down, size: 18),
                        onDeleted: selectedRegion != 'All'
                            ? () {
                                ref.read(eventFiltersProvider.notifier).setRegion('All');
                                _fetchEvents();
                              }
                            : () => _showRegionPickerModal(context, selectedRegion),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: selectedRegion != 'All' ? Theme.of(context).colorScheme.onPrimary : null,
                          fontWeight: selectedRegion != 'All' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),

                      // Division Chip (e.g. State, Province) if configured for region
                      if (divisionConfig != null) ...[
                        const SizedBox(width: 8),
                        FilterChip(
                          avatar: Icon(
                            selectedDivision == 'All' ? Icons.place_outlined : Icons.place,
                            size: 16,
                            color: selectedDivision != 'All'
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            selectedDivision == 'All'
                                ? 'All ${divisionConfig.pluralLabel}'
                                : '${divisionConfig.singularLabel}: $selectedDivision',
                          ),
                          selected: selectedDivision != 'All',
                          showCheckmark: false,
                          onSelected: (_) => _showDivisionPickerModal(context, divisionConfig, selectedDivision),
                          deleteIcon: selectedDivision != 'All'
                            ? Icon(
                                Icons.close,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : const Icon(Icons.arrow_drop_down, size: 18),
                        onDeleted: selectedDivision != 'All'
                            ? () {
                                ref.read(eventFiltersProvider.notifier).setDivision('All');
                                _fetchEvents();
                              }
                            : () => _showDivisionPickerModal(context, divisionConfig, selectedDivision),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: selectedDivision != 'All' ? Theme.of(context).colorScheme.onPrimary : null,
                          fontWeight: selectedDivision != 'All' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],

                    // Reset Filters Button
                    if (hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          ref.read(eventFiltersProvider.notifier).resetFilters();
                          _fetchEvents();
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Reset', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                  ),
                ),
              ],
            ),
          ),

          // Search Results / Tournament List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchEvents(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Direct SKU Entry Card (if user typed a valid custom SKU)
                  if (isCustomSkuValid && !displayEvents.any((e) => e.sku.toUpperCase() == cleanQuery)) ...[
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: getSkuColor(cleanQuery),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                        title: Text(
                          cleanQuery,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                        subtitle: Text('Add & fetch custom ${getSkuProgram(cleanQuery)} tournament schedule'),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            await _handleEventSelection(
                              EventModel(
                                sku: cleanQuery,
                                name: '${getSkuProgram(cleanQuery)} Tournament ($cleanQuery)',
                                program: getSkuProgram(cleanQuery),
                                season: '2026-2027',
                                startDate: DateTime.now().toIso8601String(),
                                endDate: DateTime.now().toIso8601String(),
                              ),
                            );
                          },
                          child: const Text('Add & Select'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Section Header: Title & Search Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Events',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searchSummary,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      if (_isLoading) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Loading shimmer or empty state
                  if (_isLoading && displayEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading live events from VEX Events...', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else if (displayEvents.isEmpty && !isCustomSkuValid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage != null
                                  ? 'Could not connect to VEX Events proxy.'
                                  : 'No events found in this date window.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Try loading a wider date range or entering a SKU directly.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _loadMoreEvents,
                                  icon: const Icon(Icons.date_range, size: 16),
                                  label: const Text('Search Next 30 Days'),
                                ),
                                if (_errorMessage != null)
                                  OutlinedButton.icon(
                                    onPressed: () => _fetchEvents(),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...displayEvents.map((event) {
                      final color = getSkuColor(event.sku);
                      final dateRange = formatEventDateRange(event.startDate, event.endDate, locale);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _handleEventSelection(event),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Row: SKU Badge + Dates
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: color.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        event.sku,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    if (dateRange.isNotEmpty)
                                      Text(
                                        dateRange,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Event Name
                                Text(
                                  event.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),

                                // Venue / City Location
                                if (event.venue != null || event.city != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          [event.venue, event.city, event.region]
                                              .where((s) => s != null && s.isNotEmpty)
                                              .join(', '),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  // Load More Button
                  if (!_isLoading && displayEvents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _isLoadingMore ? null : _loadMoreEvents,
                        icon: _isLoadingMore
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.expand_more, size: 18),
                        label: Text(_isLoadingMore ? 'Loading More Events...' : 'Load More Events'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegionPickerModal(BuildContext context, String currentRegion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _RegionPickerSheet(
          selectedRegion: currentRegion,
          onRegionSelected: (region) {
            Navigator.of(ctx).pop();
            ref.read(eventFiltersProvider.notifier).setRegion(region);
            _fetchEvents();
          },
        );
      },
    );
  }

  void _showDivisionPickerModal(BuildContext context, RegionDivisionConfig config, String currentDivision) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _DivisionPickerSheet(
          config: config,
          selectedDivision: currentDivision,
          onDivisionSelected: (division) {
            Navigator.of(ctx).pop();
            ref.read(eventFiltersProvider.notifier).setDivision(division);
            _fetchEvents();
          },
        );
      },
    );
  }
}

class _RegionPickerSheet extends StatefulWidget {
  final String selectedRegion;
  final ValueChanged<String> onRegionSelected;

  const _RegionPickerSheet({
    required this.selectedRegion,
    required this.onRegionSelected,
  });

  @override
  State<_RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<_RegionPickerSheet> {
  final TextEditingController _filterController = TextEditingController();
  final List<String> _allRegions = getSortedVexRegions();
  String _filterText = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterText.trim().toUpperCase();

    List<String> visibleRegions = _allRegions.where((region) {
      if (query.isEmpty) return true;
      final upper = region.toUpperCase();
      if (upper.contains(query)) return true;

      final aliasTarget = regionAliases[query]?.toUpperCase();
      if (aliasTarget != null && (upper == aliasTarget || upper.contains(aliasTarget))) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Region',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _filterController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search region (e.g. United States, UK, Australia)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _filterText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
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
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
              child: visibleRegions.isEmpty && query.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No regions matching "$_filterText"',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: visibleRegions.length + (query.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (query.isEmpty && index == 0) {
                          final isSelected = widget.selectedRegion == 'All';
                          return ListTile(
                            leading: Icon(
                              Icons.public,
                              color: isSelected ? theme.colorScheme.primary : Colors.grey,
                            ),
                            title: Text(
                              'All Regions',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                            onTap: () => widget.onRegionSelected('All'),
                          );
                        }

                        final regionIndex = query.isEmpty ? index - 1 : index;
                        final region = visibleRegions[regionIndex];
                        final isSelected = widget.selectedRegion == region;

                        return ListTile(
                          leading: Icon(
                            Icons.public,
                            size: 20,
                            color: isSelected ? theme.colorScheme.primary : Colors.grey,
                          ),
                          title: Text(
                            region,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : null,
                            ),
                          ),
                          trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                          onTap: () => widget.onRegionSelected(region),
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

class _DivisionPickerSheet extends StatefulWidget {
  final CountryDivisionConfig config;
  final String selectedDivision;
  final ValueChanged<String> onDivisionSelected;

  const _DivisionPickerSheet({
    required this.config,
    required this.selectedDivision,
    required this.onDivisionSelected,
  });

  @override
  State<_DivisionPickerSheet> createState() => _DivisionPickerSheetState();
}

class _DivisionPickerSheetState extends State<_DivisionPickerSheet> {
  final TextEditingController _filterController = TextEditingController();
  late final List<String> _allDivisions;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _allDivisions = List<String>.from(widget.config.divisions)..sort((a, b) => a.compareTo(b));
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterText.trim().toUpperCase();

    List<String> visibleDivisions = _allDivisions.where((div) {
      if (query.isEmpty) return true;
      final upper = div.toUpperCase();
      if (upper.contains(query)) return true;

      final aliasTarget = divisionAliases[query]?.toUpperCase();
      if (aliasTarget != null && (upper == aliasTarget || upper.contains(aliasTarget))) {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by ${widget.config.singularLabel}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _filterController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.config.pluralLabel.toLowerCase()} (e.g. Texas, TX)...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _filterText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
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
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
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
                            Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No ${widget.config.pluralLabel.toLowerCase()} matching "$_filterText"',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: visibleDivisions.length + (query.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (query.isEmpty && index == 0) {
                          final isSelected = widget.selectedDivision == 'All';
                          return ListTile(
                            leading: Icon(
                              Icons.place,
                              color: isSelected ? theme.colorScheme.primary : Colors.grey,
                            ),
                            title: Text(
                              'All ${widget.config.pluralLabel}',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.colorScheme.primary : null,
                              ),
                            ),
                            trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                            onTap: () => widget.onDivisionSelected('All'),
                          );
                        }

                        final divIndex = query.isEmpty ? index - 1 : index;
                        final divName = visibleDivisions[divIndex];
                        final isSelected = widget.selectedDivision == divName;

                        return ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: isSelected ? theme.colorScheme.primary : Colors.grey,
                          ),
                          title: Text(
                            divName,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : null,
                            ),
                          ),
                          trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                          onTap: () => widget.onDivisionSelected(divName),
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

