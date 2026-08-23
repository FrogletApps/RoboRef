import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/sync_settings_controller.dart';
import '../../incidents/state/incident_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(syncSettingsProvider);
    _skuController = TextEditingController(text: settings.currentSku);
    _nameController = TextEditingController(text: settings.refereeName);
    _serverController = TextEditingController(text: settings.serverUrl);
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(syncSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referee & Sync Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
          const SizedBox(height: 24),
          const Text(
            'Sync Server Configuration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect to a local venue server (Raspberry Pi on Wi-Fi) or Cloudflare Worker.',
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
          const SizedBox(height: 20),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ElevatedButton.icon(
            onPressed: settings.isSyncing
                ? null
                : () {
                    ref.read(incidentControllerProvider.notifier).triggerSync();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Triggered background sync...')),
                    );
                  },
            icon: const Icon(Icons.sync),
            label: const Text('Force Sync Now'),
          ),
        ],
      ),
    );
  }
}
