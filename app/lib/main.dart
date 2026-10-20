import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/sku_utils.dart';
import 'features/home/screens/home_screen.dart';
import 'features/settings/screens/privacy_policy_screen.dart';
import 'features/settings/state/sync_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against unhandled platform errors stalling the pipeline
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Uncaught Flutter Error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform Error: $error\n$stack');
    return true;
  };

  try {
    await initializeDateFormatting().timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('initializeDateFormatting timed out or encountered an issue: $e');
  }

  try {
    final platformLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final resolvedLocale = platformLocale.countryCode != null && platformLocale.countryCode!.isNotEmpty
        ? '${platformLocale.languageCode}_${platformLocale.countryCode}'
        : platformLocale.languageCode;
    Intl.defaultLocale = resolvedLocale;
  } catch (_) {
    Intl.defaultLocale = 'en_US';
  }

  // Resilient SharedPreferences initialization with a 4-second timeout and fallback
  late final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 4),
    );
  } catch (e) {
    debugPrint('SharedPreferences.getInstance initial attempt failed or timed out ($e), attempting emergency fallback');
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = await SharedPreferences.getInstance();
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const RoboRefApp(),
    ),
  );
}

class RoboRefApp extends ConsumerWidget {
  const RoboRefApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: getAppTitle(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('en', 'US'),
        Locale('en', 'AU'),
        Locale('en', 'CA'),
        Locale('en', 'NZ'),
        Locale('en'),
        Locale('es'),
        Locale('fr'),
        Locale('de'),
        Locale('zh'),
        Locale('ja'),
        Locale('ko'),
        Locale('ar'),
        Locale('pt'),
        Locale('it'),
        Locale('ru'),
        Locale('hi'),
        Locale('vi'),
        Locale('th'),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          final resolvedLocale = deviceLocale.countryCode != null && deviceLocale.countryCode!.isNotEmpty
              ? '${deviceLocale.languageCode}_${deviceLocale.countryCode}'
              : deviceLocale.languageCode;
          Intl.defaultLocale = resolvedLocale;
          return deviceLocale;
        }
        return supportedLocales.first;
      },
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/privacy': (_) => const PrivacyPolicyScreen(),
      },
    );
  }
}
