import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/state/sync_settings_controller.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String key = 'theme_mode';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _loadThemeMode(prefs);
  }

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final modeStr = prefs.getString(key);
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    switch (mode) {
      case ThemeMode.light:
        _prefs.setString(key, 'light');
        break;
      case ThemeMode.dark:
        _prefs.setString(key, 'dark');
        break;
      case ThemeMode.system:
        _prefs.setString(key, 'system');
        break;
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
