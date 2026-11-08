import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../services/csv_import_service.dart';
import '../../incidents/state/incident_controller.dart';
import '../../settings/state/sync_settings_controller.dart';

class EventImportSheet extends ConsumerStatefulWidget {
  const EventImportSheet({super.key});

  @override
  ConsumerState<EventImportSheet> createState() => _EventImportSheetState();
}

class _EventImportSheetState extends ConsumerState<EventImportSheet> {
  final _csvController = TextEditingController();

  bool _isLoading = false;
  String? _statusMessage;
  bool _isError = false;
  String _csvType = 'teams'; // 'teams' | 'matches'

  @override
  void dispose() {
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
      child: SingleChildScrollView(
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
              context.l10n.csvImportTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.csvImportSubtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
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
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'teams', label: Text(context.l10n.csvImportSegmentTeams)),
                ButtonSegment(value: 'matches', label: Text(context.l10n.csvImportSegmentMatches)),
              ],
              selected: {_csvType},
              onSelectionChanged: (val) => setState(() => _csvType = val.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _csvController,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: _csvType == 'teams'
                    ? context.l10n.csvImportPasteTeamsLabel
                    : context.l10n.csvImportPasteMatchesLabel,
                hintText: _csvType == 'teams'
                    ? context.l10n.csvImportPasteTeamsHint
                    : context.l10n.csvImportPasteMatchesHint,
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
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.file_upload_outlined),
                label: Text(
                  _isLoading
                      ? context.l10n.csvImportImportingButton
                      : (_csvType == 'teams'
                          ? context.l10n.csvImportImportTeamsButton
                          : context.l10n.csvImportImportMatchesButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCsvImport() async {
    final sku = ref.read(syncSettingsProvider).currentSku.trim().toUpperCase();
    final csv = _csvController.text.trim();

    if (sku.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = context.l10n.csvImportNoSkuSelected;
      });
      return;
    }

    if (csv.isEmpty) {
      setState(() {
        _isError = true;
        _statusMessage = context.l10n.csvImportEmptyContent;
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
              ? context.l10n.csvImportTeamsSuccess(result.teamsImported)
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
              ? context.l10n.csvImportMatchesSuccess(result.matchesImported)
              : result.errorMessage;
        });
      }
    }
  }
}
