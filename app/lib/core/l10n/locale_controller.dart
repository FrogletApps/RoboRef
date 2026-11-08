import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/state/sync_settings_controller.dart';

/// Represents a selectable language/locale option in Settings.
class LocaleOption {
  final String code; // 'system' or locale tag like 'en', 'en_GB', 'en_US'
  final Locale? locale;
  final String nativeName;

  const LocaleOption({
    required this.code,
    required this.locale,
    required this.nativeName,
  });
}

/// Supported locale options available in the Settings language dropdown.
/// Additional languages automatically appear as their translations are added.
const List<LocaleOption> supportedLocaleOptions = [
  LocaleOption(code: 'en', locale: Locale('en'), nativeName: 'English'),
  LocaleOption(code: 'en_GB', locale: Locale('en', 'GB'), nativeName: 'English (UK)'),
  LocaleOption(code: 'en_US', locale: Locale('en', 'US'), nativeName: 'English (US)'),
  LocaleOption(code: 'en_AU', locale: Locale('en', 'AU'), nativeName: 'English (Australia)'),
  LocaleOption(code: 'en_CA', locale: Locale('en', 'CA'), nativeName: 'English (Canada)'),
  LocaleOption(code: 'en_NZ', locale: Locale('en', 'NZ'), nativeName: 'English (New Zealand)'),
];

/// Converts a [Locale] to its canonical underscore tag (e.g. `'en_GB'` or `'en'`),
/// or `'system'` if `null`.
String localeToOptionCode(Locale? locale) {
  if (locale == null) return 'system';
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    final full = '${locale.languageCode}_${locale.countryCode}';
    if (supportedLocaleOptions.any((o) => o.code == full)) {
      return full;
    }
  }
  return locale.languageCode;
}

/// Parses a stored locale tag (e.g. `'en_GB'`, `'en'`, or `'system'`) into a [Locale?].
Locale? parseLocaleCode(String? code) {
  if (code == null || code.trim().isEmpty || code == 'system') {
    return null;
  }
  final parts = code.trim().split(RegExp(r'[_-]'));
  if (parts.length >= 2 && parts[1].isNotEmpty) {
    return Locale(parts[0], parts[1]);
  }
  return Locale(parts[0]);
}

class LocaleNotifier extends Notifier<Locale?> {
  static const String key = 'app_locale';

  SharedPreferences? get _prefs {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  @override
  Locale? build() {
    SharedPreferences? prefs;
    try {
      prefs = ref.watch(sharedPreferencesProvider);
    } catch (_) {}
    final saved = prefs?.getString(key);
    final locale = parseLocaleCode(saved);
    _syncIntlLocale(locale);
    return locale;
  }

  void setLocale(Locale? locale) {
    state = locale;
    if (locale == null) {
      _prefs?.setString(key, 'system');
    } else if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      _prefs?.setString(key, '${locale.languageCode}_${locale.countryCode}');
    } else {
      _prefs?.setString(key, locale.languageCode);
    }
    _syncIntlLocale(locale);
  }

  void setLocaleByCode(String code) {
    setLocale(parseLocaleCode(code));
  }

  static void _syncIntlLocale(Locale? locale) {
    try {
      final effective = locale ?? PlatformDispatcher.instance.locale;
      final resolved = effective.countryCode != null && effective.countryCode!.isNotEmpty
          ? '${effective.languageCode}_${effective.countryCode}'
          : effective.languageCode;
      Intl.defaultLocale = resolved;
    } catch (_) {
      Intl.defaultLocale = 'en_US';
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
