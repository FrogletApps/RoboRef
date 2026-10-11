import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/sku_utils.dart';
import '../state/sync_settings_controller.dart';
import '../../home/screens/changelog_screen.dart';
import '../../incidents/state/incident_controller.dart';
import '../../event_data/screens/event_import_sheet.dart';
import '../../event_selection/state/event_controller.dart';
import '../../sharing/models/share_models.dart';
import '../../sharing/state/share_controller.dart';
import '../../sharing/widgets/event_share_sheet.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  final bool? isEventManagePage;
  final String? eventSku;
  final String? overrideVersion;

  const SettingsScreen({
    super.key,
    this.showAppBar = true,
    this.isEventManagePage,
    this.eventSku,
    this.overrideVersion,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _serverController;
  bool _initialized = false;
  String _selectedServerOption = 'cloud';
  bool _isTestingConnection = false;
  String _version = '2026.10.11+157';

  @override
  void initState() {
    super.initState();
    if (widget.overrideVersion != null) {
      _version = widget.overrideVersion!;
    } else {
      _loadAppVersion();
    }
    Future.microtask(() {
      if (mounted) {
        final currentSku = (widget.eventSku ?? ref.read(syncSettingsProvider).currentSku).trim().toUpperCase();
        if (currentSku.isNotEmpty) {
          ref.read(shareControllerProvider.notifier).loadEventShareState(currentSku);
        }
      }
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        if (info.buildNumber.isNotEmpty) {
          _version = '${info.version}+${info.buildNumber}';
        } else {
          _version = info.version;
        }
      });
    } catch (_) {
      // Fallback to default version if platform channel is unavailable (e.g. tests)
    }
  }

  bool get _isEventManagePage => widget.isEventManagePage ?? !widget.showAppBar;

  Future<void> _openExternalUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: urlString));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link copied to clipboard: $urlString'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      ref.read(shareControllerProvider.notifier).flushRefereeNameChange();
    } catch (_) {}
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
        final currentSku = (widget.eventSku ?? settings.currentSku).trim().toUpperCase();
        final shareState = ref.watch(shareControllerProvider);
        final activeEventAsync = ref.watch(activeEventProvider);
        final event = activeEventAsync.value;

        final isEventShared = _isEventManagePage && (
          (event != null && event.sku == currentSku && event.isShared) ||
          (shareState.sku == currentSku && shareState.isShared)
        );
        final isShareAdmin = _isEventManagePage && isEventShared && (
          (event != null && event.sku == currentSku && event.shareRole == 'admin') ||
          (shareState.sku == currentSku && shareState.role == ShareRole.admin)
        );
        final adminName = (event?.adminRefereeName?.isNotEmpty ?? false)
            ? event!.adminRefereeName!
            : (shareState.adminRefereeName ?? 'Head Referee');

        final vexEventsUrl = currentSku.isNotEmpty
            ? 'https://events.vex.com/$currentSku.html'
            : 'https://events.vex.com';
        final env = ref.watch(syncSettingsEnvironmentProvider) ?? getAppEnvironment();
        final cloudUrl = (env == AppEnvironment.test) ? 'https://test.roboref.app' : 'https://roboref.app';
        const venueLanUrl = 'http://roboref.local:8080';

        if (!_initialized) {
          _nameController = TextEditingController(text: settings.refereeName);
          _serverController = TextEditingController(text: settings.serverUrl);
          _selectedServerOption = _getOptionForUrl(settings.serverUrl, cloudUrl, venueLanUrl);
          _initialized = true;
        } else {
          if (_serverController.text != settings.serverUrl && !_isTestingConnection) {
            _serverController.text = settings.serverUrl;
            _selectedServerOption = _getOptionForUrl(settings.serverUrl, cloudUrl, venueLanUrl);
          }
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
                onSubmitted: (_) => ref.read(shareControllerProvider.notifier).flushRefereeNameChange(),
              ),
              const SizedBox(height: 24),

              // Event Information Section (if on the manage page for the event)
              if (_isEventManagePage) ...[
                const Text(
                  'Event Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.public,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text(
                      'VEX Events Page',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _openExternalUrl(context, vexEventsUrl),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
              ],

              // About RoboRef Section
              const Text(
                'About RoboRef',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildVersionCard(context, Theme.of(context).brightness == Brightness.dark),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.history_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Change Log',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangeLogScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.shield_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ),
              // Experimental Features Section (only shown in local or test deployments)
              if (env == AppEnvironment.local || env == AppEnvironment.test) ...[
                const SizedBox(height: 24),
                const Text(
                  'Experimental Features',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'Enable extra features that may not work as intended',
                    ),
                    value: settings.experimentalFeaturesEnabled,
                    onChanged: (val) async {
                      if (val == true) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Warning!  Experimental Features!'),
                            content: const Text(
                              'Ticking this will enable extra features that may not work as intended',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Enable'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          ref.read(syncSettingsProvider.notifier).setExperimentalFeaturesEnabled(true);
                        }
                      } else {
                        ref.read(syncSettingsProvider.notifier).setExperimentalFeaturesEnabled(false);
                      }
                    },
                  ),
                ),

                if (settings.experimentalFeaturesEnabled) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Import Event Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'This feature is experimental and may not work as intended',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
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
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import Event Data (TM CSV)'),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            const SizedBox(height: 16),
          ],
        ),
        );
      },
    );
  }

  Widget _buildConnectionBadge(ServerConnectionStatus status, [String? serverUrl]) {
    switch (status) {
      case ServerConnectionStatus.connectedLocal:
        final urlLower = (serverUrl ?? '').toLowerCase();
        final isLocalhost = urlLower.contains('localhost') || urlLower.contains('127.0.0.1');
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
                isLocalhost ? 'Local Server (localhost)' : 'Venue LAN (roboref.local)',
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

  /// Version Card with Copy button
  Widget _buildVersionCard(BuildContext context, bool isDark) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Version',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Use this to let a developer know what version you are using if you encounter an issue.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'RELEASE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'v$_version',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _version));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Version copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

