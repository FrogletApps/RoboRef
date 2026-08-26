import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sku_utils.dart';
import '../../event_workspace/screens/event_workspace_screen.dart';
import '../models/event_model.dart';
import '../state/event_controller.dart';

class EventSelectionScreen extends ConsumerStatefulWidget {
  const EventSelectionScreen({super.key});

  @override
  ConsumerState<EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends ConsumerState<EventSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedProgram = 'All';
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
    final cleanQuery = _searchQuery.trim();

    try {
      final results = await client.searchEvents(
        query: cleanQuery.isNotEmpty ? cleanQuery : null,
        program: _selectedProgram != 'All' ? _selectedProgram : null,
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
    final cleanQuery = _searchQuery.trim().toUpperCase();
    final isCustomSkuValid = isValidSku(cleanQuery);

    // Client-side text filter over API results if query is typed
    List<EventModel> filteredApiEvents = _apiEvents;

    final isDirectSkuQuery = cleanQuery.startsWith('RE-');
    if (_selectedProgram != 'All' && !isDirectSkuQuery) {
      filteredApiEvents = filteredApiEvents
          .where((e) => isEventMatchingProgram(
                program: e.program,
                sku: e.sku,
                selectedProgram: _selectedProgram,
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
        return nameMatch || skuMatch || venueMatch || cityMatch || regionMatch;
      }).toList();
    }

    final displayEvents = filteredApiEvents;

    final dateRangeLabel = formatEventDateRange(
      _startDate.toIso8601String(),
      _endDate.toIso8601String(),
    );

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
                      final isSelected = _selectedProgram == program;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(program),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (program == 'All') {
                                _selectedProgram = 'All';
                              } else {
                                _selectedProgram = selected ? program : 'All';
                              }
                            });
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

                  // Section Header: Timing context & Result count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _searchQuery.isEmpty
                                  ? (_daysForward <= 7 ? 'Events This Week & Current' : 'Upcoming Events')
                                  : 'Matching Events',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (dateRangeLabel.isNotEmpty && _searchQuery.isEmpty)
                              Text(
                                dateRangeLabel,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          '${displayEvents.length} events',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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
                      final dateRange = formatEventDateRange(event.startDate, event.endDate);

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
                        label: Text(_isLoadingMore ? 'Loading More...' : 'Load More Upcoming (+30 Days)'),
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

