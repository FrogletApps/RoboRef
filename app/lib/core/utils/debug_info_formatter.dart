import 'package:flutter/foundation.dart';

import 'server_info_sanitizer.dart';
import 'sku_utils.dart';
import '../../features/settings/state/sync_settings_controller.dart';

/// Formats a human-readable platform label (e.g. `Android`, `iOS`, `Web App (Windows)`).
String formatPlatformName({
  bool isWeb = kIsWeb,
  TargetPlatform? targetPlatform,
}) {
  final platform = targetPlatform ?? defaultTargetPlatform;
  final osName = switch (platform) {
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.windows => 'Windows',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.fuchsia => 'Fuchsia',
  };

  if (isWeb) {
    return 'Web App ($osName)';
  }
  return osName;
}

/// Formats an [AppEnvironment] into a concise human-readable label.
String formatAppEnvironmentLabel(AppEnvironment env) {
  switch (env) {
    case AppEnvironment.local:
      return 'Local';
    case AppEnvironment.test:
      return 'Test';
    case AppEnvironment.production:
      return 'Live';
  }
}

/// Determines whether the configured sync server is a Live, Test, Local, or Custom server.
String resolveServerEnvironmentLabel({
  required String serverUrl,
  String? serverName,
  String? explicitServerEnvironment,
}) {
  final explicit = sanitizeServerText(explicitServerEnvironment, maxLength: 24)
      ?.toLowerCase();
  if (explicit != null) {
    if (explicit == 'live' || explicit == 'prod' || explicit == 'production') {
      return 'Live';
    }
    if (explicit == 'test' || explicit == 'staging') {
      return 'Test';
    }
    if (explicit == 'local' || explicit == 'dev' || explicit == 'development') {
      return 'Local';
    }
  }

  final normalizedUrl = normalizeServerBaseUrl(serverUrl);
  if (normalizedUrl.isEmpty) {
    return 'Unknown';
  }

  final uri = Uri.tryParse(normalizedUrl);
  final host = (uri?.host ?? '').trim().toLowerCase();

  if (host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host.endsWith('.local') ||
      RegExp(r'^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)')
          .hasMatch(host)) {
    return 'Local';
  }

  if (host == 'roboref.app' ||
      host == 'www.roboref.app' ||
      host == 'roboref.fyi' ||
      host == 'www.roboref.fyi') {
    return 'Live';
  }

  if (host.startsWith('test.') ||
      host.endsWith('.workers.dev') ||
      host.contains('-test.')) {
    return 'Test';
  }

  final cleanName = sanitizeServerName(serverName)?.toLowerCase() ?? '';
  if (cleanName.contains('(test)') || cleanName.contains(' test')) {
    return 'Test';
  }
  if (cleanName.contains('(live)') || cleanName.contains('(prod)')) {
    return 'Live';
  }

  return 'Custom';
}

/// Extracts the safe current web origin (without query parameters or fragments) when on Web.
String? resolveCurrentWebUrl({
  bool isWeb = kIsWeb,
  Uri? currentUri,
}) {
  if (!isWeb) return null;
  try {
    final uri = currentUri ?? Uri.base;
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    if (uri.host.isEmpty) return null;
    final origin = uri.origin;
    return sanitizeServerText(origin, maxLength: 128);
  } catch (_) {
    return null;
  }
}

/// Builds a sanitized, structured debug information block for the Settings "Copy Info" action.
String buildDebugInfoText({
  required String appVersion,
  required AppEnvironment appEnvironment,
  required String serverUrl,
  required ServerConnectionStatus connectionStatus,
  String? serverName,
  String? serverVersion,
  String? serverEnvironment,
  bool isWeb = kIsWeb,
  TargetPlatform? targetPlatform,
  Uri? currentUri,
}) {
  final cleanAppVersion = appVersion.trim();
  final formattedAppVersion = cleanAppVersion.startsWith('v')
      ? cleanAppVersion
      : 'v$cleanAppVersion';

  final sanitizedServerName = sanitizeServerName(serverName);
  final sanitizedServerVersion = sanitizeServerVersion(serverVersion);
  final sanitizedServerUrl = sanitizeServerText(
    normalizeServerBaseUrl(serverUrl),
    maxLength: 128,
  );
  final serverVersionDisplay = sanitizedServerVersion ??
      (connectionStatus == ServerConnectionStatus.unknown
          ? 'Checking...'
          : 'Unavailable');

  final platformLabel = formatPlatformName(
    isWeb: isWeb,
    targetPlatform: targetPlatform,
  );
  final currentWebUrl = resolveCurrentWebUrl(
    isWeb: isWeb,
    currentUri: currentUri,
  );
  final serverEnvLabel = resolveServerEnvironmentLabel(
    serverUrl: serverUrl,
    serverName: sanitizedServerName,
    explicitServerEnvironment: serverEnvironment,
  );

  final lines = <String>[
    'RoboRef: $formattedAppVersion',
    'App Environment: ${formatAppEnvironmentLabel(appEnvironment)}',
    'Platform: $platformLabel',
    if (currentWebUrl != null) 'Current URL: $currentWebUrl',
    'Server: ${sanitizedServerName ?? 'Unknown'}',
    'Server Version: $serverVersionDisplay',
    'Server URL: ${sanitizedServerUrl ?? 'Not configured'}',
    'Server Environment: $serverEnvLabel',
  ];

  return lines.join('\n');
}
