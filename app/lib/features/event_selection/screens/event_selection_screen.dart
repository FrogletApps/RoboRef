import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/event_regions.dart';
import '../../../core/utils/sku_utils.dart';
import '../../event_workspace/screens/event_workspace_screen.dart';
import '../models/event_model.dart';
import '../services/event_cache_service.dart';
import '../state/event_controller.dart';
import '../state/event_filter_controller.dart';
import '../widgets/event_filters_bar.dart';

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
  bool _isUpdating = false;
  String? _errorMessage;
  List<EventModel> _apiEvents = [];
  final Set<String> _sessionVisibleSkus = {};

  // Date range: currently active (past 3 days) or over the next week (7 days)
  late DateTime _startDate;
  late DateTime _endDate;
  int _daysForward = 7;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = now.subtract(const Duration(days: 3));
    _endDate = now.add(Duration(days: _daysForward));
    _loadFromCache();
    _fetchEvents();
  }

  void _loadFromCache() {
    try {
      final cacheService = ref.read(eventCacheServiceProvider);
      final cached = cacheService.getCachedEvents();
      if (cached.isNotEmpty) {
        _apiEvents = cached;
        for (final e in cached) {
          _sessionVisibleSkus.add(e.sku.toUpperCase());
        }
        _isLoading = false;
      } else {
        _isLoading = true;
      }
    } catch (_) {
      _isLoading = true;
    }
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

  Future<void> _fetchEvents({
    bool isLoadMore = false,
    bool isExplicitReload = false,
  }) async {
    if (!mounted) return;
    setState(() {
      if (isLoadMore) {
        _isLoadingMore = true;
      } else if (_apiEvents.isEmpty) {
        _isLoading = true;
        _errorMessage = null;
      } else {
        _isUpdating = true;
        _errorMessage = null;
      }
    });

    final client = ref.read(vexEventsClientProvider);
    final filters = ref.read(eventFiltersProvider);
    final cleanQuery = _searchQuery.trim();
    final apiRegionTargets = _resolveApiRegionTargets(filters);

    try {
      final results = await client.searchEvents(
        query: cleanQuery.isNotEmpty ? cleanQuery : null,
        programs: filters.programs,
        regions: apiRegionTargets,
        start: isSkuQuery(cleanQuery) ? null : _startDate,
        end: isSkuQuery(cleanQuery) ? null : _endDate,
        perPage: 50,
        forceRefresh: isExplicitReload,
      );

      if (!mounted) return;

      // 1. Update persistent cache:
      // Removed events (missing from results within the query scope) are pruned from cache
      // so they will NOT appear next time the list is viewed.
      try {
        final cacheService = ref.read(eventCacheServiceProvider);
        if (isLoadMore) {
          final currentCached = cacheService.getCachedEvents();
          final merged = [...currentCached, ...results];
          await cacheService.saveCachedEvents(merged);
        } else {
          await cacheService.updateCacheWithRemoteEvents(
            remoteEvents: results,
            query: cleanQuery.isNotEmpty ? cleanQuery : null,
            programs: filters.programs,
            regions: filters.regions,
            divisions: filters.divisions,
            windowStart: isSkuQuery(cleanQuery) ? null : _startDate,
            windowEnd: isSkuQuery(cleanQuery) ? null : _endDate,
          );
        }
      } catch (_) {}

      // 2. Update UI list (_apiEvents):
      // "If an event has been removed then don't visibly remove this from the UI
      // if it's visible to the user, just remove it before the next time the list is viewed."
      final updatedMap = <String, EventModel>{};

      if (isLoadMore) {
        for (final e in _apiEvents) {
          updatedMap[e.sku.toUpperCase()] = e;
        }
        for (final e in results) {
          updatedMap[e.sku.toUpperCase()] = e;
          _sessionVisibleSkus.add(e.sku.toUpperCase());
        }
      } else {
        // Upsert new results from remote
        for (final e in results) {
          updatedMap[e.sku.toUpperCase()] = e;
          _sessionVisibleSkus.add(e.sku.toUpperCase());
        }

        // For any event that was already visible to the user in this screen session,
        // retain it in UI so it does not visibly vanish while the user is viewing it!
        for (final existing in _apiEvents) {
          final sku = existing.sku.toUpperCase();
          if (_sessionVisibleSkus.contains(sku) && !updatedMap.containsKey(sku)) {
            updatedMap[sku] = existing;
          }
        }
      }

      final mergedList = updatedMap.values.toList();
      mergedList.sort((a, b) {
        final aDate = DateTime.tryParse(a.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse(b.startDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

      setState(() {
        _apiEvents = mergedList;
        _isLoading = false;
        _isLoadingMore = false;
        _isUpdating = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isUpdating = false;
          if (_apiEvents.isEmpty) {
            _errorMessage = e.toString();
          }
        });

        if (isExplicitReload && _apiEvents.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.eventSelectionShowingCachedEvents),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  List<String> _resolveApiRegionTargets(EventFiltersState filters) {
    if (filters.regions.isEmpty) return const [];
    final targets = <String>[];
    for (final region in filters.regions) {
      final config = getRegionDivisionConfig(region);
      if (config != null) {
        final selectedDivs =
            filters.divisions.where(config.divisions.contains).toList();
        if (selectedDivs.isNotEmpty) {
          targets.addAll(selectedDivs);
          continue;
        }
      }
      targets.add(region);
    }
    return targets;
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
    final l10n = context.l10n;

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
                l10n.eventSelectionLoadingTournamentData(event.sku),
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
              l10n.eventSelectionLoadedTournamentSummary(
                result.eventName ?? event.sku,
                result.teamsCount,
                result.matchesCount,
              ),
            ),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (result.errorMessage != null) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.eventSelectionLoadNotePrefix(result.errorMessage!)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(eventFiltersProvider);
    final selectedPrograms = filters.programs;
    final selectedRegions = filters.regions;
    final selectedDivisions = filters.divisions;

    final cleanQuery = _searchQuery.trim().toUpperCase();
    final isCustomSkuValid = isValidSku(cleanQuery);

    // Client-side text filter over API results if query is typed
    List<EventModel> filteredApiEvents = _apiEvents;

    final isDirectSkuQuery = isSkuQuery(cleanQuery);
    if (selectedPrograms.isNotEmpty && !isDirectSkuQuery) {
      filteredApiEvents = filteredApiEvents
          .where((e) => isEventMatchingPrograms(
                program: e.program,
                sku: e.sku,
                selectedPrograms: selectedPrograms,
              ))
          .toList();
    }

    if ((selectedRegions.isNotEmpty || selectedDivisions.isNotEmpty) &&
        !isDirectSkuQuery) {
      filteredApiEvents = filteredApiEvents
          .where((e) => isEventMatchingRegionAndDivisions(
                country: e.country,
                region: e.region,
                city: e.city,
                venue: e.venue,
                selectedRegions: selectedRegions,
                selectedDivisions: selectedDivisions,
              ))
          .toList();
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
    final searchSummary = context.l10n.eventSelectionFoundEventsSummary(
      displayEvents.length,
      yDateStr,
      zDateStr,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.eventSelectionTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.eventSelectionReloadTooltip,
            onPressed: () => _fetchEvents(isExplicitReload: true),
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
                    hintText: context.l10n.eventSelectionSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: context.l10n.commonClearSearch,
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
                EventFiltersBar(onFiltersChanged: _fetchEvents),
              ],
            ),
          ),

          // Search Results / Tournament List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchEvents(isExplicitReload: true),
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
                        subtitle: Text(context.l10n.eventSelectionAddCustomSchedule(getSkuProgram(cleanQuery))),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final prog = getSkuProgram(cleanQuery);
                            await _handleEventSelection(
                              EventModel(
                                sku: cleanQuery,
                                name: context.l10n.eventSelectionCustomTournamentName(prog, cleanQuery),
                                program: prog,
                                season: '2026-2027',
                                startDate: DateTime.now().toIso8601String(),
                                endDate: DateTime.now().toIso8601String(),
                              ),
                            );
                          },
                          child: Text(context.l10n.eventSelectionAddAndSelect),
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
                      Text(
                        context.l10n.eventSelectionEventsHeader,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searchSummary,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      if (_isLoading || _isUpdating) ...[
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

                  // Loading indicator or empty state
                  if (_isLoading && displayEvents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(context.l10n.eventSelectionLoadingEvents, style: const TextStyle(color: Colors.grey)),
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
                                  ? context.l10n.eventSelectionProxyError
                                  : context.l10n.eventSelectionNoEventsFound,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.eventSelectionNoEventsSubtitle,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _loadMoreEvents,
                                  icon: const Icon(Icons.date_range, size: 16),
                                  label: Text(context.l10n.eventSelectionSearchNext30Days),
                                ),
                                if (_errorMessage != null)
                                  OutlinedButton.icon(
                                    onPressed: () => _fetchEvents(),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text(context.l10n.commonRetry),
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
                        label: Text(
                          _isLoadingMore
                              ? context.l10n.eventSelectionLoadingMoreEvents
                              : context.l10n.eventSelectionLoadMoreEvents,
                        ),
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
}
