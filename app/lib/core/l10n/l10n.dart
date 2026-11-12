import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_en.dart';
import 'locale_controller.dart';

export '../../l10n/app_localizations.dart';
export 'locale_controller.dart';

final AppLocalizations _fallbackL10n = AppLocalizationsEn();

/// Resolves [AppLocalizations] without a [BuildContext] (for controllers/services).
/// Falls back to English if the device/selected locale is not yet translated.
AppLocalizations lookupL10n([Locale? locale]) {
  try {
    final target = locale ?? PlatformDispatcher.instance.locale;
    return lookupAppLocalizations(target);
  } catch (_) {
    return _fallbackL10n;
  }
}

/// Riverpod provider exposing [AppLocalizations] reactive to [localeProvider].
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  Locale? selected;
  try {
    selected = ref.watch(localeProvider);
  } catch (_) {}
  return lookupL10n(selected);
});

extension AppLocalizationsX on BuildContext {
  /// Convenient access to [AppLocalizations], with a safe fallback to English
  /// when mounted inside a test harness that omits `AppLocalizations.delegate`.
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _fallbackL10n;
}

/// Loads a localized text/markdown asset with graceful fallback to the base asset path.
/// For example, given `'assets/privacy.md'` and locale `Locale('fr', 'CA')`, tries:
/// 1. `'assets/privacy_fr_CA.md'`
/// 2. `'assets/privacy_fr.md'`
/// 3. `'assets/privacy.md'`
Future<String> loadLocalizedAssetString(
  String baseAssetPath, {
  Locale? locale,
  AssetBundle? bundle,
}) async {
  final effectiveBundle = bundle ?? rootBundle;
  final effectiveLocale = locale;

  if (effectiveLocale != null &&
      effectiveLocale.languageCode.isNotEmpty &&
      effectiveLocale.languageCode != 'en') {
    final dotIdx = baseAssetPath.lastIndexOf('.');
    final prefix = dotIdx != -1 ? baseAssetPath.substring(0, dotIdx) : baseAssetPath;
    final ext = dotIdx != -1 ? baseAssetPath.substring(dotIdx) : '';

    final candidates = <String>[
      if (effectiveLocale.countryCode != null && effectiveLocale.countryCode!.isNotEmpty)
        '${prefix}_${effectiveLocale.languageCode}_${effectiveLocale.countryCode}$ext',
      '${prefix}_${effectiveLocale.languageCode}$ext',
    ];

    for (final candidate in candidates) {
      try {
        return await effectiveBundle.loadString(candidate);
      } catch (_) {
        // Fallback to next candidate
      }
    }
  }

  return await effectiveBundle.loadString(baseAssetPath);
}

/// Translates a canonical VEX rule group category name into its localized display label,
/// while preserving the canonical `rule.group` string on [RuleModel] for color/filter matching.
String localizeRuleGroup(BuildContext context, String group) {
  final l10n = context.l10n;
  switch (group.trim()) {
    case 'All':
      return l10n.commonAll;
    case 'Specific Game Rules':
      return l10n.ruleGroupSpecificGame;
    case 'Scoring Rules':
      return l10n.ruleGroupScoring;
    case 'General Game Rules':
      return l10n.ruleGroupGeneralGame;
    case 'General Rules':
      return l10n.ruleGroupGeneral;
    case 'Safety Rules':
      return l10n.ruleGroupSafety;
    case 'Robot Rules':
      return l10n.ruleGroupRobot;
    case 'Robot Skills Challenge Rules':
      return l10n.ruleGroupRobotSkills;
    case 'Tournament Rules':
      return l10n.ruleGroupTournament;
    case 'VEX U Game Rules':
      return l10n.ruleGroupVexUGame;
    case 'VEX U Robot Rules':
      return l10n.ruleGroupVexURobot;
    case 'VEX U Robot Skills Challenge Rules':
      return l10n.ruleGroupVexUSkills;
    case 'VEX U Tournament Rules':
      return l10n.ruleGroupVexUTournament;
    case 'Custom':
      return l10n.commonCustom;
    default:
      return group;
  }
}

/// Returns the localized display label for an incident note severity.
String localizeSeverity(
  BuildContext context,
  String severity, {
  bool uppercaseBadge = false,
}) {
  final l10n = context.l10n;
  switch (severity.trim().toLowerCase()) {
    case 'disabled':
      return uppercaseBadge ? l10n.severityBadgeDisabled : l10n.severityDisabled;
    case 'major':
      return uppercaseBadge ? l10n.severityBadgeMajor : l10n.severityMajor;
    case 'inspection':
      return uppercaseBadge ? l10n.severityBadgeInspection : l10n.severityInspection;
    case 'minor':
      return uppercaseBadge ? l10n.severityBadgeMinor : l10n.severityMinor;
    case 'general':
    default:
      return uppercaseBadge ? l10n.severityBadgeGeneral : l10n.severityGeneral;
  }
}
