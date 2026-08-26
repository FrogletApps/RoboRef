import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/state/sync_settings_controller.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences prefs;
  static const String key = 'theme_mode';

  ThemeModeNotifier(this.prefs) : super(_loadThemeMode(prefs));

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
        prefs.setString(key, 'light');
        break;
      case ThemeMode.dark:
        prefs.setString(key, 'dark');
        break;
      case ThemeMode.system:
        prefs.setString(key, 'system');
        break;
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});
