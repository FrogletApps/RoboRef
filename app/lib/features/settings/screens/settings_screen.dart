import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/sync_settings_controller.dart';
import '../../incidents/state/incident_controller.dart';
import '../../event_data/screens/event_import_sheet.dart';

class SettingsScreen extends StatefulWidget {
  final bool showAppBar;

  const SettingsScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _serverController;
  bool _initialized = false;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(syncSettingsProvider);

        if (!_initialized) {
          _skuController = TextEditingController(text: settings.currentSku);
          _nameController = TextEditingController(text: settings.refereeName);
          _serverController = TextEditingController(text: settings.serverUrl);
          _initialized = true;
        }

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: const Text('Referee & Sync Settings'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Tournament Setup Section
              const Text(
                'Tournament & Referee Setup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _skuController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tournament SKU',
                  hintText: 'e.g. RE-V5RC-24-1234',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) => ref.read(syncSettingsProvider.notifier).setSku(val.trim().toUpperCase()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Referee Display Name',
                  hintText: 'e.g. Field 1 Head Referee',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) => ref.read(syncSettingsProvider.notifier).setRefereeName(val.trim()),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
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
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Load Event Data (VEXEvents & TM CSV)'),
              ),
              const SizedBox(height: 24),

              // Sync Server Section
              const Text(
                'Sync Server Configuration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Preferred setup: Connect to the venue LAN server (Raspberry Pi on Wi-Fi at http://roboref.local:8080) or Cloudflare Worker.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'Sync Server URL',
                  hintText: 'http://roboref.local:8080 or https://sync.roboref.fyi',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) => ref.read(syncSettingsProvider.notifier).setServerUrl(val.trim()),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Server Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                          _buildConnectionBadge(settings.connectionStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sync Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                          if (settings.isSyncing)
                            const Row(
                              children: [
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 6),
                                Text('Syncing...', style: TextStyle(color: Colors.blue)),
                              ],
                            )
                          else
                            const Text('Idle / Ready', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Device UUID: ${settings.deviceId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      if (settings.lastSyncTime != null) ...[
                        const SizedBox(height: 4),
                        Text('Last sync: ${settings.lastSyncTime}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                      if (settings.lastError != null) ...[
                        const SizedBox(height: 6),
                        Text('Error: ${settings.lastError}', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: settings.isSyncing
                          ? null
                          : () {
                              ref.read(incidentControllerProvider.notifier).triggerSync();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Triggered background sync...')),
                              );
                            },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(syncSettingsProvider.notifier).checkServerHealth();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Testing server connection...')),
                      );
                    },
                    icon: const Icon(Icons.wifi_find),
                    label: const Text('Test Connection'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionBadge(ServerConnectionStatus status) {
    switch (status) {
      case ServerConnectionStatus.connectedLocal:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi, size: 14, color: Colors.green.shade900),
              const SizedBox(width: 4),
              Text(
                'Venue LAN (roboref.local)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
              ),
            ],
          ),
        );
      case ServerConnectionStatus.connectedCloud:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done, size: 14, color: Colors.blue.shade900),
              const SizedBox(width: 4),
              Text(
                'Cloud Server',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
              ),
            ],
          ),
        );
      case ServerConnectionStatus.unreachable:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 14, color: Colors.red.shade900),
              const SizedBox(width: 4),
              Text(
                'Offline / Unreachable',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
              ),
            ],
          ),
        );
      case ServerConnectionStatus.unknown:
        return const Text('Checking...', style: TextStyle(color: Colors.grey, fontSize: 12));
    }
  }
}
