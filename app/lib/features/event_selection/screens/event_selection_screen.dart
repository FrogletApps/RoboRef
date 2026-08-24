import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sku_utils.dart';
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
  String? _errorMessage;
  List<EventModel> _apiEvents = [];
  bool _isImporting = false;
  String? _importingSku;

  final List<String> _programs = const ['All', 'V5RC', 'VIQRC', 'VEX U', 'VEX AI'];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchEvents();
    });
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(vexEventsClientProvider);

    try {
      final results = await client.searchEvents(
        query: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
        program: _selectedProgram != 'All' ? _selectedProgram : null,
        perPage: 30,
      );

      if (mounted) {
        setState(() {
          _apiEvents = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _handleEventSelection(EventModel event) async {
    setState(() {
      _isImporting = true;
      _importingSku = event.sku;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await ref.read(eventControllerProvider.notifier).importAndSelectEvent(event: event);

    if (mounted) {
      setState(() {
        _isImporting = false;
        _importingSku = null;
      });

      if (result.success) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Selected "${result.eventName ?? event.sku}" (${result.teamsCount} teams, ${result.matchesCount} matches)',
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
      } else {
        // Even if deep schedule fetch failed (e.g. timeout), select event basic metadata
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
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Switched to ${event.sku} (Schedule sync pending: ${result.errorMessage})'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanQuery = _searchQuery.trim().toUpperCase();
    final isCustomSkuValid = isValidSku(cleanQuery);

    // Filter fallback list if API is unreachable or empty
    final fallbackFiltered = preloadedEvents.where((e) {
      if (_selectedProgram != 'All') {
        final prog = _selectedProgram.toUpperCase();
        final eventProg = e.program.toUpperCase();
        final matches = (eventProg == prog) ||
            (prog == 'VEX U' && eventProg == 'VURC') ||
            (prog == 'VURC' && eventProg == 'VEX U') ||
            (prog == 'VEX AI' && (eventProg == 'VAIRC' || eventProg == 'VAIC')) ||
            (prog == 'VAIRC' && eventProg == 'VEX AI');
        if (!matches) return false;
      }
      if (cleanQuery.isEmpty) return true;

      final skuMatch = e.sku.toUpperCase().contains(cleanQuery);
      final nameMatch = e.name.toUpperCase().contains(cleanQuery);
      final venueMatch = e.venue?.toUpperCase().contains(cleanQuery) ?? false;
      final cityMatch = e.city?.toUpperCase().contains(cleanQuery) ?? false;

      return skuMatch || nameMatch || venueMatch || cityMatch;
    }).toList();

    final displayEvents = _apiEvents.isNotEmpty ? _apiEvents : fallbackFiltered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick An Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Events',
            onPressed: _fetchEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                const SizedBox(height: 12),

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
                              _selectedProgram = selected ? program : 'All';
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
              onRefresh: _fetchEvents,
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
                          onPressed: _isImporting
                              ? null
                              : () async {
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

                  // Section Title & Result Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isEmpty ? 'Live & Featured Tournaments' : 'Matching Events',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
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
                            Text('Fetching live events from VEX Events API...', style: TextStyle(color: Colors.grey)),
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
                                  ? 'Could not connect to sync server.'
                                  : 'No tournaments found matching your search.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'You can type any valid SKU (e.g. RE-V5RC-24-1234) to add it directly.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _fetchEvents,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    ...displayEvents.map((event) {
                      final color = getSkuColor(event.sku);
                      final dateRange = formatEventDateRange(event.startDate, event.endDate);
                      final isCurrentImporting = _isImporting && _importingSku == event.sku;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isImporting ? null : () => _handleEventSelection(event),
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
                                    if (isCurrentImporting)
                                      const Row(
                                        children: [
                                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                          SizedBox(width: 6),
                                          Text('Loading schedule...', style: TextStyle(fontSize: 12, color: Colors.blue)),
                                        ],
                                      )
                                    else if (dateRange.isNotEmpty)
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

                                // Venue / City
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

