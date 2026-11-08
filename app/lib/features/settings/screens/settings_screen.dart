import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/locale_controller.dart';
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
  String _version = '2026.10.16+167';

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
            content: Text(context.l10n.commonCannotOpenLink(urlString)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: urlString));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.commonLinkCopiedToClipboard(urlString)),
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
        final selectedLocale = ref.watch(localeProvider);
        final selectedLocaleCode = localeToOptionCode(selectedLocale);
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
            : (shareState.adminRefereeName ?? context.l10n.commonHeadReferee);

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
                  title: Text(context.l10n.settingsTitle),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Appearance Section
              Text(
                context.l10n.settingsAppearanceTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.settingsAppearanceDescription,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text(context.l10n.settingsThemeDevice),
                      icon: const Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text(context.l10n.settingsThemeLight),
                      icon: const Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text(context.l10n.settingsThemeDark),
                      icon: const Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (Set<ThemeMode> newSelection) {
                    ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
                  },
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('language_dropdown_$selectedLocaleCode'),
                initialValue: selectedLocaleCode,
                decoration: InputDecoration(
                  labelText: context.l10n.settingsLanguageLabel,
                  helperText: context.l10n.settingsLanguageDescription,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: const Icon(Icons.language_outlined),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: 'system',
                    child: Text(context.l10n.settingsLanguageSystem),
                  ),
                  ...supportedLocaleOptions.map(
                    (option) => DropdownMenuItem<String>(
                      value: option.code,
                      child: Text(option.displayName),
                    ),
                  ),
                ],
                onChanged: (newCode) {
                  if (newCode == null) return;
                  ref.read(localeProvider.notifier).setLocaleByCode(newCode);
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Referee Setup Section
              Text(
                context.l10n.settingsRefereeSetupTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.settingsRefereeDisplayNameLabel,
                  hintText: context.l10n.settingsRefereeDisplayNameHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) => ref.read(syncSettingsProvider.notifier).setRefereeName(val.trim()),
                onSubmitted: (_) => ref.read(shareControllerProvider.notifier).flushRefereeNameChange(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Sync & Sharing Section (on Event Manage Page when sharing is NOT enabled)
              if (_isEventManagePage && !isEventShared) ...[
                Text(
                  context.l10n.settingsSyncSharingTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_off_outlined, color: Colors.grey.shade600, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.settingsSharingNotEnabledTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.settingsSharingNotEnabledDescription,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (ctx) => EventShareSheet(sku: currentSku),
                            );
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: Text(context.l10n.commonShareEventOnline),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
              ],

              // Sync Server Configuration (ONLY visible when on event manage page AND sharing is enabled)
              if (_isEventManagePage && isEventShared) ...[
                Text(
                  context.l10n.settingsSyncServerConfigTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isShareAdmin
                      ? context.l10n.settingsSyncServerAdminSubtitle
                      : context.l10n.settingsSyncServerMemberSubtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),

                if (!isShareAdmin) ...[
                  // Member View: Notice that host manages the sync server
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 20, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.settingsManagedByHostNotice(adminName),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
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
                      leading: const Icon(Icons.dns_outlined),
                      title: Text(
                        settings.serverUrl,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        getLocalizedServerTypeDisplayName(context, settings.serverUrl),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                ] else ...[
                  // Admin View: Sync Server Mode Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedServerOption,
                    decoration: InputDecoration(
                      labelText: context.l10n.settingsSyncServerModeLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.dns_outlined),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'cloud',
                        child: Text(
                          context.l10n.settingsServerModeCloudOption(cloudUrl),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'lan',
                        child: Text(
                          context.l10n.settingsServerModeLanOption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text(context.l10n.settingsServerModeCustomOption),
                      ),
                    ],
                    onChanged: (newOption) {
                      if (newOption == null) return;
                      setState(() {
                        _selectedServerOption = newOption;
                        if (newOption == 'cloud') {
                          _serverController.text = cloudUrl;
                          ref.read(syncSettingsProvider.notifier).setServerUrl(cloudUrl, sku: currentSku);
                        } else if (newOption == 'lan') {
                          _serverController.text = venueLanUrl;
                          ref.read(syncSettingsProvider.notifier).setServerUrl(venueLanUrl, sku: currentSku);
                        } else if (newOption == 'custom') {
                          final current = _serverController.text.trim();
                          if (current.isEmpty || current == cloudUrl || current == venueLanUrl) {
                            const defaultCustom = 'http://localhost:8080';
                            _serverController.text = defaultCustom;
                            ref.read(syncSettingsProvider.notifier).setServerUrl(defaultCustom, sku: currentSku);
                          }
                        }
                      });
                    },
                  ),

                  // Custom Server URL free-text input
                  if (_selectedServerOption == 'custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _serverController,
                      decoration: InputDecoration(
                        labelText: context.l10n.settingsCustomServerUrlLabel,
                        hintText: context.l10n.settingsCustomServerUrlHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: const Icon(Icons.link),
                      ),
                      onChanged: (val) => ref.read(syncSettingsProvider.notifier).setServerUrl(val.trim(), sku: currentSku),
                    ),
                  ],
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
                            Text(context.l10n.settingsServerStatusLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            _buildConnectionBadge(context, settings.connectionStatus, settings.serverUrl),
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
                            Text(context.l10n.settingsSyncStatusLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (settings.isSyncing)
                              Row(
                                children: [
                                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                  const SizedBox(width: 6),
                                  Text(context.l10n.settingsSyncStatusSyncing, style: const TextStyle(color: Colors.blue)),
                                ],
                              )
                            else
                              Text(context.l10n.settingsSyncStatusIdle, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(context.l10n.settingsDeviceUuid(settings.deviceId), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        if (settings.lastSyncTime != null) ...[
                          const SizedBox(height: 4),
                          Text(context.l10n.settingsLastSync(settings.lastSyncTime!), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                        if (settings.lastError != null) ...[
                          const SizedBox(height: 6),
                          Text(context.l10n.settingsSyncError(settings.lastError!), style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
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
                                  SnackBar(content: Text(context.l10n.settingsTriggeredSyncSnackbar)),
                                );
                              },
                        icon: const Icon(Icons.sync),
                        label: Text(context.l10n.settingsSyncNowButton),
                      ),
                    ),
                    if (isShareAdmin) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isTestingConnection
                            ? null
                            : () async {
                                final targetUrl = _serverController.text.trim();
                                ref.read(syncSettingsProvider.notifier).setServerUrl(targetUrl, sku: currentSku);

                                setState(() => _isTestingConnection = true);

                                final messenger = ScaffoldMessenger.of(context);
                                final testingMsg = context.l10n.settingsTestingConnectionSnackbar(
                                  targetUrl.isEmpty ? context.l10n.commonServer : targetUrl,
                                );
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
                                            testingMsg,
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

                                if (!context.mounted) return;
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
                                                ? context.l10n.settingsConnectionSuccessfulSnackbar(result.message)
                                                : context.l10n.settingsConnectionFailedSnackbar(result.message),
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
                        label: Text(_isTestingConnection ? context.l10n.settingsTestingButton : context.l10n.settingsTestConnectionButton),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
              ],

              // Event Information Section (if on the manage page for the event)
              if (_isEventManagePage) ...[
                Text(
                  context.l10n.settingsEventInformationTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    title: Text(
                      context.l10n.settingsVexEventsPage,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              Text(
                context.l10n.settingsAboutRoboRefTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  title: Text(
                    context.l10n.changelogTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    Icons.code_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    context.l10n.settingsViewSource,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _openExternalUrl(context, 'https://github.com/FrogletApps/RoboRef'),
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
                  title: Text(
                    context.l10n.privacyPolicyTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                const Divider(),
                const SizedBox(height: 24),
                Text(
                  context.l10n.settingsExperimentalFeaturesTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    title: Text(
                      context.l10n.settingsExperimentalCheckboxLabel,
                    ),
                    value: settings.experimentalFeaturesEnabled,
                    onChanged: (val) async {
                      if (val == true) {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(ctx.l10n.settingsExperimentalWarningTitle),
                            content: Text(
                              ctx.l10n.settingsExperimentalWarningBody,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(ctx.l10n.commonCancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: Text(ctx.l10n.commonEnable),
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
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.settingsImportEventDataTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.settingsImportEventDataDisclaimer,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                    label: Text(context.l10n.settingsImportEventDataButton),
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

  Widget _buildConnectionBadge(BuildContext context, ServerConnectionStatus status, [String? serverUrl]) {
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
                isLocalhost ? context.l10n.settingsBadgeLocalhost : context.l10n.settingsBadgeVenueLan,
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
                context.l10n.serverTypeCloud,
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
                context.l10n.settingsBadgeOfflineUnreachable,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade900),
              ),
            ],
          ),
        );
      case ServerConnectionStatus.unknown:
        return Text(context.l10n.settingsBadgeChecking, style: const TextStyle(color: Colors.grey, fontSize: 12));
    }
  }

  Widget _buildReleaseBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        context.l10n.settingsReleaseBadge,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildVersionText(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        'v$_version',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: _version));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.settingsVersionCopied),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      icon: const Icon(Icons.copy, size: 16),
      label: Text(context.l10n.commonCopy),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );
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
                Expanded(
                  child: Text(
                    context.l10n.settingsCurrentVersionTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.settingsCurrentVersionDescription,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScaler = MediaQuery.textScalerOf(context);

                  final versionPainter = TextPainter(
                    text: TextSpan(
                      text: 'v$_version',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    textDirection: TextDirection.ltr,
                    textScaler: textScaler,
                  )..layout();

                  final badgePainter = TextPainter(
                    text: TextSpan(
                      text: context.l10n.settingsReleaseBadge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    textDirection: TextDirection.ltr,
                    textScaler: textScaler,
                  )..layout();

                  final copyPainter = TextPainter(
                    text: TextSpan(
                      text: context.l10n.commonCopy,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    textDirection: TextDirection.ltr,
                    textScaler: textScaler,
                  )..layout();

                  final badgeWidth = badgePainter.width + 12.0;
                  final versionWidth = versionPainter.width;
                  final copyBtnWidth = (copyPainter.width + 16.0 + 8.0 + 28.0).clamp(64.0, double.infinity);

                  const badgeVersionGap = 8.0;
                  const minHorizontalGap = 8.0;

                  final stage1NeededWidth = badgeWidth + badgeVersionGap + versionWidth + minHorizontalGap + copyBtnWidth;
                  final stage2NeededWidth = versionWidth + minHorizontalGap + copyBtnWidth;

                  if (constraints.maxWidth >= stage1NeededWidth) {
                    // Stage 1: Single line row
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildReleaseBadge(context),
                            const SizedBox(width: badgeVersionGap),
                            _buildVersionText(context),
                          ],
                        ),
                        _buildCopyButton(context),
                      ],
                    );
                  } else if (constraints.maxWidth >= stage2NeededWidth) {
                    // Stage 2: RELEASE badge above version number / copy button row
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildReleaseBadge(context),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(child: _buildVersionText(context)),
                            _buildCopyButton(context),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Stage 3: RELEASE badge above version number, and copy button on line below that
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildReleaseBadge(context),
                        const SizedBox(height: 6),
                        _buildVersionText(context),
                        const SizedBox(height: 4),
                        _buildCopyButton(context),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

