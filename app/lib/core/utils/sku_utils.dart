import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Regex matching official VEX Tournament SKUs
final RegExp skuRegex = RegExp(
  r'^RE-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC)-[0-9]{2}-[0-9]{4}$',
  caseSensitive: false,
);

/// Validate whether a string is a correctly formatted VEX SKU
bool isValidSku(String sku) {
  return skuRegex.hasMatch(sku.trim());
}

/// Check if the SKU represents a VEX IQ Robotics Competition event
bool isVIQRC(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('VIQRC') || upper.contains('VIQC');
}

/// Check if the SKU represents a VEX AI Robotics Competition event
bool isVAIRC(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('VAIRC') || upper.contains('VAIC') || upper.contains('VEX AI');
}

/// Check if the SKU represents a V5RC / VRC / VEX U competition event
bool isV5(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('V5RC') ||
      upper.contains('VRC') ||
      upper.contains('VEXU') ||
      upper.contains('VURC') ||
      upper.contains('V5');
}

/// Extract readable program code from SKU
String getSkuProgram(String? sku) {
  if (sku == null || sku.isEmpty) return 'VEX';
  if (isVIQRC(sku)) return 'VIQRC';
  if (isVAIRC(sku)) return 'VEX AI';
  if (sku.toUpperCase().contains('VEXU') || sku.toUpperCase().contains('VURC')) {
    return 'VEX U';
  }
  if (isV5(sku)) return 'V5RC';
  return 'VEX';
}

/// Check if an event matches a selected program filter ('All', 'V5RC', 'VIQRC', 'VEX U', 'VEX AI')
bool isEventMatchingProgram({
  required String? program,
  required String? sku,
  required String selectedProgram,
}) {
  if (selectedProgram == 'All') return true;

  final progUpper = (program ?? '').toUpperCase().trim();
  final skuUpper = (sku ?? '').toUpperCase().trim();

  switch (selectedProgram) {
    case 'VIQRC':
      return progUpper == 'VIQRC' ||
          progUpper == 'VIQC' ||
          isVIQRC(skuUpper) ||
          getSkuProgram(skuUpper) == 'VIQRC';

    case 'VEX U':
      return progUpper == 'VURC' ||
          progUpper == 'VEX U' ||
          progUpper == 'VEXU' ||
          skuUpper.contains('VEXU') ||
          skuUpper.contains('VURC') ||
          getSkuProgram(skuUpper) == 'VEX U';

    case 'VEX AI':
      return progUpper == 'VAIRC' ||
          progUpper == 'VAIC' ||
          progUpper == 'VEX AI' ||
          isVAIRC(skuUpper) ||
          getSkuProgram(skuUpper) == 'VEX AI';

    case 'V5RC':
      if (progUpper == 'VURC' ||
          progUpper == 'VEX U' ||
          progUpper == 'VEXU' ||
          skuUpper.contains('VEXU') ||
          skuUpper.contains('VURC')) {
        return false;
      }
      return progUpper == 'V5RC' ||
          progUpper == 'VRC' ||
          getSkuProgram(skuUpper) == 'V5RC' ||
          (!isVIQRC(skuUpper) && !isVAIRC(skuUpper) && isV5(skuUpper));

    default:
      return progUpper == selectedProgram.toUpperCase();
  }
}

/// Get primary color theme for SKU
Color getSkuColor(String? sku) {
  if (isVIQRC(sku)) {
    return const Color(0xFF42A5F5); // Blue
  }
  if (isVAIRC(sku)) {
    return const Color(0xFFAB47BC); // Purple for VEX AI
  }
  if (isV5(sku)) {
    return const Color(0xFFEF5350); // Red
  }
  return const Color(0xFF66BB6A); // Emerald
}

/// Get background badge tint for SKU
Color getSkuBadgeBackground(String? sku, BuildContext context) {
  final color = getSkuColor(sku);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return color.withValues(alpha: isDark ? 0.2 : 0.12);
}

/// Retrieve the user's active locale tag (e.g. 'en_GB', 'en_US', 'fr_FR')
String getUserLocale([BuildContext? context]) {
  if (context != null) {
    final loc = Localizations.maybeLocaleOf(context);
    if (loc != null) {
      if (loc.countryCode != null && loc.countryCode!.isNotEmpty) {
        return '${loc.languageCode}_${loc.countryCode}';
      }
      return loc.languageCode;
    }
  }

  try {
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (platformLocale.countryCode != null && platformLocale.countryCode!.isNotEmpty) {
      return '${platformLocale.languageCode}_${platformLocale.countryCode}';
    }
    return platformLocale.languageCode;
  } catch (_) {
    return Intl.getCurrentLocale();
  }
}

String _formatYMMMd(DateTime date, [String? locale]) {
  final targetLocale = (locale != null && locale.isNotEmpty && locale != 'en')
      ? locale
      : getUserLocale();

  try {
    return DateFormat.yMMMd(targetLocale).format(date);
  } catch (_) {
    try {
      return DateFormat.yMMMd().format(date);
    } catch (_) {
      return '${date.day} ${_monthName(date.month)} ${date.year}';
    }
  }
}

String _formatMMMd(DateTime date, [String? locale]) {
  final targetLocale = (locale != null && locale.isNotEmpty && locale != 'en')
      ? locale
      : getUserLocale();

  try {
    return DateFormat.MMMd(targetLocale).format(date);
  } catch (_) {
    try {
      return DateFormat.MMMd().format(date);
    } catch (_) {
      return '${date.day} ${_monthName(date.month)}';
    }
  }
}

String _monthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month >= 1 && month <= 12) return months[month - 1];
  return '';
}

/// Format start and end date strings (ISO or parseable) into a clean user-friendly range in the user's locale
String formatEventDateRange(String? startStr, String? endStr, [String? locale]) {
  final targetLocale = (locale != null && locale.isNotEmpty && locale != 'en')
      ? locale
      : getUserLocale();

  if (startStr == null || startStr.isEmpty) {
    if (endStr == null || endStr.isEmpty) return '';
    final end = DateTime.tryParse(endStr);
    return end != null ? _formatYMMMd(end, targetLocale) : endStr;
  }

  final start = DateTime.tryParse(startStr);
  if (start == null) return startStr;

  if (endStr == null || endStr.isEmpty) {
    return _formatYMMMd(start, targetLocale);
  }

  final end = DateTime.tryParse(endStr);
  if (end == null) {
    return _formatYMMMd(start, targetLocale);
  }

  // Same day
  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return _formatYMMMd(start, targetLocale);
  }

  // Same year
  if (start.year == end.year) {
    return '${_formatMMMd(start, targetLocale)} – ${_formatYMMMd(end, targetLocale)}';
  }

  // Different years
  return '${_formatYMMMd(start, targetLocale)} – ${_formatYMMMd(end, targetLocale)}';
}

/// Format a single date string (ISO or parseable) into a user-friendly date in the user's locale
String formatEventDate(String? dateStr, [String? locale]) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final date = DateTime.tryParse(dateStr);
  if (date == null) return dateStr;
  return _formatYMMMd(date, locale);
}

enum AppEnvironment {
  local,
  test,
  production,
}

/// Pure helper for determining the active [AppEnvironment].
/// Supports explicit compile-time environment flags, Web hostname detection, and platform modes.
AppEnvironment resolveAppEnvironment({
  String? compileEnv,
  String? host,
  bool isWeb = kIsWeb,
  bool isDebug = kDebugMode,
  bool isProfile = kProfileMode,
}) {
  // 1. Explicit compile-time environment flag (e.g. --dart-define=APP_ENV=test)
  if (compileEnv != null && compileEnv.isNotEmpty) {
    switch (compileEnv.trim().toLowerCase()) {
      case 'local':
      case 'dev':
      case 'development':
        return AppEnvironment.local;
      case 'test':
      case 'staging':
        return AppEnvironment.test;
      case 'live':
      case 'prod':
      case 'production':
        return AppEnvironment.production;
    }
  }

  // 2. Web runtime hostname detection
  if (isWeb) {
    final h = (host ?? '').trim().toLowerCase();
    if (h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '0.0.0.0' ||
        h.endsWith('.local') ||
        RegExp(r'^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)').hasMatch(h)) {
      return AppEnvironment.local;
    }
    if (h.startsWith('test.') || h.contains('test') || h.contains('workers.dev')) {
      return AppEnvironment.test;
    }
    return AppEnvironment.production;
  }

  // 3. Native platform modes
  if (isDebug) {
    return AppEnvironment.local;
  }
  if (isProfile) {
    return AppEnvironment.test;
  }
  return AppEnvironment.production;
}

/// Retrieve the active [AppEnvironment]
AppEnvironment getAppEnvironment() {
  const compileEnv = String.fromEnvironment('APP_ENV');
  final host = kIsWeb ? Uri.base.host : null;
  return resolveAppEnvironment(
    compileEnv: compileEnv,
    host: host,
    isWeb: kIsWeb,
    isDebug: kDebugMode,
    isProfile: kProfileMode,
  );
}

/// Retrieve the user-facing application title for the active or given environment.
/// Examples: 'RoboRef Local', 'RoboRef Test', 'RoboRef'
String getAppTitle([AppEnvironment? env]) {
  final environment = env ?? getAppEnvironment();
  switch (environment) {
    case AppEnvironment.local:
      return 'RoboRef Local';
    case AppEnvironment.test:
      return 'RoboRef Test';
    case AppEnvironment.production:
      return 'RoboRef';
  }
}

/// Categorize sync server URL as 'RoboRef Cloud Server' or 'Other Server'
String getServerTypeDisplayName(String serverUrl) {
  final clean = serverUrl.trim().toLowerCase();
  if (clean.contains('roboref.app') || clean.contains('roboref.fyi') || clean.contains('workers.dev')) {
    return 'RoboRef Cloud Server';
  }
  return 'Other Server';
}

