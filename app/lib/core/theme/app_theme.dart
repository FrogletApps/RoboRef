import 'package:flutter/material.dart';

class AppTheme {
  /// Primary RoboRef brand green extracted from official SVG icon (#00731F)
  static const Color brandGreen = Color(0xFF00731F);

  /// Deep forest green used for icon borders and high-contrast accents (#004613)
  static const Color brandGreenDark = Color(0xFF004613);

  /// Vibrant emerald green for Dark Theme Material 3 high-contrast accessibility (#66E07A)
  static const Color brandGreenLight = Color(0xFF66E07A);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: Brightness.light,
      primary: brandGreen,
      secondary: const Color(0xFFD32F2F),
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: brandGreen,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandGreen,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brandGreen,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide.none,
      shape: StadiumBorder(),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: brandGreen,
      brightness: Brightness.dark,
      primary: brandGreenLight,
      secondary: const Color(0xFFEF5350),
      surface: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brandGreenLight,
      foregroundColor: Color(0xFF003824),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: const ChipThemeData(
      side: BorderSide.none,
      shape: StadiumBorder(),
    ),
  );
}
