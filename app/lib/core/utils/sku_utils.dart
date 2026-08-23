import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Regex matching official VEX Tournament SKUs
final RegExp skuRegex = RegExp(
  r'^RE-(VRC|V5RC|VEXU|VURC|VIQRC|VIQC|VAIRC|ADC)-[0-9]{2}-[0-9]{4}$',
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

/// Check if the SKU represents a V5RC / VRC / VEX U competition event
bool isV5(String? sku) {
  if (sku == null || sku.isEmpty) return false;
  final upper = sku.toUpperCase();
  return upper.contains('V5RC') ||
      upper.contains('VRC') ||
      upper.contains('VEXU') ||
      upper.contains('VURC') ||
      upper.contains('VAIRC') ||
      upper.contains('V5');
}

/// Extract readable program code from SKU
String getSkuProgram(String? sku) {
  if (sku == null || sku.isEmpty) return 'VEX';
  if (isVIQRC(sku)) return 'VIQRC';
  if (sku.toUpperCase().contains('VEXU') || sku.toUpperCase().contains('VURC')) {
    return 'VEX U';
  }
  if (isV5(sku)) return 'V5RC';
  if (sku.toUpperCase().contains('ADC')) return 'ADC';
  return 'VEX';
}

/// Get primary color theme for SKU
Color getSkuColor(String? sku) {
  if (isVIQRC(sku)) {
    return const Color(0xFF42A5F5); // Blue
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

/// Format start and end date strings (ISO or parseable) into a clean user-friendly range
String formatEventDateRange(String? startStr, String? endStr) {
  if (startStr == null || startStr.isEmpty) {
    if (endStr == null || endStr.isEmpty) return '';
    final end = DateTime.tryParse(endStr);
    return end != null ? DateFormat('MMM d, yyyy').format(end) : endStr;
  }

  final start = DateTime.tryParse(startStr);
  if (start == null) return startStr;

  if (endStr == null || endStr.isEmpty) {
    return DateFormat('MMM d, yyyy').format(start);
  }

  final end = DateTime.tryParse(endStr);
  if (end == null) {
    return DateFormat('MMM d, yyyy').format(start);
  }

  // Same day
  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return DateFormat('MMM d, yyyy').format(start);
  }

  // Same month and year
  if (start.year == end.year && start.month == end.month) {
    return '${DateFormat('MMM d').format(start)} – ${DateFormat('d, yyyy').format(end)}';
  }

  // Same year, different months
  if (start.year == end.year) {
    return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
  }

  // Different years
  return '${DateFormat('MMM d, yyyy').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
}

enum AppEnvironment {
  local,
  test,
  production,
}

AppEnvironment getAppEnvironment() {
  if (kDebugMode) {
    return AppEnvironment.local;
  }
  if (kProfileMode) {
    return AppEnvironment.test;
  }
  return AppEnvironment.production;
}
