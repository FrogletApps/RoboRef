import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/sku_utils.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _serverController;
  bool _initialized = false;
  String _selectedServerOption = 'lan';
  bool _isTestingConnection = false;

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  String _getOptionForUrl(String url, String cloudUrl, String venueLanUrl) {
    final clean = url.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
    final cleanCloud = cloudUrl.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
    final cleanVenue = venueLanUrl.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');

    if (clean == cleanCloud ||
        clean == 'https://test.roboref.app' ||
        clean == 'http://test.roboref.app' ||
        clean == 'https://roboref.app' ||
        clean == 'http://roboref.app') {
      return 'cloud';
    }
    if (clean == cleanVenue ||
        clean == 'http://roboref.local:8080' ||
        clean == 'https://roboref.local:8080' ||
        clean == 'roboref.local:8080' ||
        clean == 'http://roboref.local' ||
        clean == 'https://roboref.local') {
      return 'lan';
    }
    return 'custom';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(syncSettingsProvider);
        final themeMode = ref.watch(themeModeProvider);
        final env = getAppEnvironment();
        final cloudUrl = (env == AppEnvironment.test) ? 'https://test.roboref.app' : 'https://roboref.app';
        const venueLanUrl = 'http://roboref.local:8080';

        if (!_initialized) {
          _nameController = TextEditingController(text: settings.refereeName);
          _serverController = TextEditingController(text: settings.serverUrl);
          _selectedServerOption = _getOptionForUrl(settings.serverUrl, cloudUrl, venueLanUrl);
          _initialized = true;
        }

        return Scaffold(
          appBar: widget.showAppBar
              ? AppBar(
                  title: const Text('Settings'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Appearance Section
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select theme mode. Device mode automatically follows your operating system light or dark setting.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('Device'),
                      icon: Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Referee Setup Section
              const Text(
                'Referee Setup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              // Sync Server Mode Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedServerOption,
                decoration: const InputDecoration(
                  labelText: 'Sync Server Mode',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'cloud',
                    child: Text(
                      'Cloud Server ($cloudUrl)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const DropdownMenuItem(
                    value: 'lan',
                    child: Text(
                      'Venue LAN (http://roboref.local:8080)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const DropdownMenuItem(
                    value: 'custom',
                    child: Text('Custom Server URL'),
                  ),
                ],
                onChanged: (newOption) {
                  if (newOption == null) return;
                  setState(() {
                    _selectedServerOption = newOption;
                    if (newOption == 'cloud') {
                      _serverController.text = cloudUrl;
                      ref.read(syncSettingsProvider.notifier).setServerUrl(cloudUrl);
                    } else if (newOption == 'lan') {
                      _serverController.text = venueLanUrl;
                      ref.read(syncSettingsProvider.notifier).setServerUrl(venueLanUrl);
                    }
                  });
                },
              ),

              // Custom Server URL free-text input
              if (_selectedServerOption == 'custom') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _serverController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Server URL',
                    hintText: 'e.g. http://192.168.1.50:8080 or https://sync.roboref.app',
                    border: OutlineInputBorder(),
                    isDense: true,
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: (val) => ref.read(syncSettingsProvider.notifier).setServerUrl(val.trim()),
                ),
              ],

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
                      if (settings.lastConnectionMessage != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              settings.lastConnectionSuccess == true
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              size: 14,
                              color: settings.lastConnectionSuccess == true
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                settings.lastConnectionMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: settings.lastConnectionSuccess == true
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                      onPressed: (settings.isSyncing || _isTestingConnection)
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
                    onPressed: _isTestingConnection
                        ? null
                        : () async {
                            final targetUrl = _serverController.text.trim();
                            ref.read(syncSettingsProvider.notifier).setServerUrl(targetUrl);

                            setState(() => _isTestingConnection = true);

                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
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
                                        'Testing connection to ${targetUrl.isEmpty ? 'server' : targetUrl}...',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            final result = await ref
                                .read(syncSettingsProvider.notifier)
                                .checkServerHealth(targetUrl);

                            if (!mounted) return;
                            setState(() => _isTestingConnection = false);

                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: result.isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                                content: Row(
                                  children: [
                                    Icon(
                                      result.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        result.isSuccess
                                            ? 'Connection successful: ${result.message}'
                                            : 'Connection failed: ${result.message}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                    icon: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
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

