import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/vex_events_client.dart';
import '../services/csv_import_service.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';

class EventImportSheet extends ConsumerStatefulWidget {
  const EventImportSheet({super.key});

  @override
  ConsumerState<EventImportSheet> createState() => _EventImportSheetState();
}

class _EventImportSheetState extends ConsumerState<EventImportSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _skuController;
  final _csvController = TextEditingController();

  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;
  String _csvType = 'teams'; // 'teams' | 'matches'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final settings = ref.read(syncSettingsProvider);
    _skuController = TextEditingController(text: settings.currentSku);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _skuController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
            'Load Tournament Data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.cloud_download), text: 'VEXEvents API'),
              Tab(icon: Icon(Icons.table_chart), text: 'TM / CSV Import'),
            ],
          ),
          const SizedBox(height: 16),
          if (_statusMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                border: Border.all(color: _isError ? Colors.red.shade300 : Colors.green.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: _isError ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _isError ? Colors.red.shade900 : Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: VEX Events / RobotEvents API
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fetch teams & match schedule directly from VEXEvents / RobotEvents public endpoints.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _skuController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Tournament SKU',
                          hintText: 'e.g. RE-V5RC-24-1234',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _handleVexEventsFetch,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(_isLoading ? 'Fetching Schedule...' : 'Fetch Tournament Data'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab 2: Manual CSV Import
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paste Tournament Manager (TM) export data below.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'teams', label: Text('Teams CSV')),
                          ButtonSegment(value: 'matches', label: Text('Match Schedule CSV')),
                        ],
                        selected: {_csvType},
                        onSelectionChanged: (val) => setState(() => _csvType = val.first),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _csvController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          labelText: _csvType == 'teams' ? 'Paste Teams CSV Text' : 'Paste Matches CSV Text',
                          hintText: _csvType == 'teams'
                              ? 'Number, Name, City, State, Country\n1234A, RoboKnights, Austin, TX, USA'
                              : 'Match, Field, Time, Red 1, Red 2, Blue 1, Blue 2\nQ1, Field 1, 09:00, 1234A, 5678B, 9012C, 3456D',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _handleCsvImport,
                          icon: const Icon(Icons.file_upload_outlined),
                          label: Text('Import ${_csvType == "teams" ? "Teams" : "Matches"} CSV'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVexEventsFetch() async {
    final sku = _skuController.text.trim().toUpperCase();
    if (sku.isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final db = ref.read(databaseProvider);
    final settings = ref.read(syncSettingsProvider);
    final client = VexEventsClient(
      apiKey: settings.vexApiKey,
      serverUrl: settings.serverUrl,
    );

    final result = await client.fetchTournamentData(sku: sku, db: db);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isError = !result.success;
        if (result.success) {
          ref.read(syncSettingsProvider.notifier).setSku(sku);
          _statusMessage = 'Loaded "${result.eventName}": ${result.teamsCount} teams and ${result.matchesCount} matches imported into local database!';
        } else {
          _statusMessage = result.errorMessage ?? 'Failed to load tournament data.';
        }
      });
    }
  }

  Future<void> _handleCsvImport() async {
    final sku = _skuController.text.trim().toUpperCase();
    final csv = _csvController.text.trim();

    if (csv.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = 'Please paste CSV content to import.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final db = ref.read(databaseProvider);

    if (_csvType == 'teams') {
      final result = await CsvImportService.importTeamsCsv(csvContent: csv, sku: sku, db: db);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = !result.success;
          _statusMessage = result.success
              ? 'Successfully imported ${result.teamsImported} teams!'
              : result.errorMessage;
        });
      }
    } else {
      final result = await CsvImportService.importMatchesCsv(csvContent: csv, sku: sku, db: db);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = !result.success;
          _statusMessage = result.success
              ? 'Successfully imported ${result.matchesImported} matches!'
              : result.errorMessage;
        });
      }
    }
  }
}
