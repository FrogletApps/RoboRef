import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sku_utils.dart';
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

  final List<String> _programs = const ['All', 'V5RC', 'VIQRC', 'VEX U', 'VEX AI'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanQuery = _searchQuery.trim().toUpperCase();
    final isCustomSkuValid = isValidSku(cleanQuery);

    // Filter preloaded events
    final filteredEvents = preloadedEvents.where((e) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick An Event'),
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Direct SKU Entry Card (if user typed a valid custom SKU)
                if (isCustomSkuValid && !filteredEvents.any((e) => e.sku.toUpperCase() == cleanQuery)) ...[
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
                      subtitle: Text('Add custom ${getSkuProgram(cleanQuery)} tournament'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          await ref.read(eventControllerProvider.notifier).addManualEvent(
                                sku: cleanQuery,
                              );
                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Selected tournament $cleanQuery')),
                            );
                          }
                        },
                        child: const Text('Add & Select'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _searchQuery.isEmpty ? 'Championship & Featured Events' : 'Matching Events',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),

                // Event List Items
                if (filteredEvents.isEmpty && !isCustomSkuValid)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No tournaments found matching your query.'),
                          const SizedBox(height: 6),
                          const Text(
                            'You can type any valid SKU (e.g. RE-V5RC-24-1234) to add it.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredEvents.map((event) {
                    final color = getSkuColor(event.sku);
                    final dateRange = formatEventDateRange(event.startDate, event.endDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
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
                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Switched to ${event.sku}')),
                            );
                          }
                        },
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
        ],
      ),
    );
  }
}
