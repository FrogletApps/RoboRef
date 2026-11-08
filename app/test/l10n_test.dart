import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roboref/core/l10n/l10n.dart';
import 'package:roboref/core/l10n/locale_controller.dart';
import 'package:roboref/core/utils/match_utils.dart';
import 'package:roboref/features/rules/data/default_rules.dart';
import 'package:roboref/features/rules/models/rule_model.dart';
import 'package:roboref/features/settings/screens/settings_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:roboref/l10n/app_localizations.dart';

void main() {
  group('Internationalization (i18n) & Localization Tests', () {
    test('parseLocaleCode and localeToOptionCode round-trip', () {
      expect(parseLocaleCode(null), isNull);
      expect(parseLocaleCode(''), isNull);
      expect(parseLocaleCode('system'), isNull);
      expect(parseLocaleCode('en'), const Locale('en'));
      expect(parseLocaleCode('zh_TW'), const Locale('zh', 'TW'));

      expect(localeToOptionCode(null), 'system');
      expect(localeToOptionCode(const Locale('en')), 'en');
      expect(localeToOptionCode(const Locale('zh', 'TW')), 'zh_TW');
    });

    test('LocaleController persists and restores selected locale in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(localeProvider), isNull);

      await container.read(localeProvider.notifier).setLocale(const Locale('en'));
      expect(container.read(localeProvider), const Locale('en'));
      expect(prefs.getString('selected_locale'), 'en');

      await container.read(localeProvider.notifier).setLocaleByCode('system');
      expect(container.read(localeProvider), isNull);
      expect(prefs.getString('selected_locale'), isNull);
    });

    test('ICU pluralization and parameterized strings format accurately', () {
      final l10n = lookupL10n(const Locale('en'));

      expect(l10n.teamListNoteCount(0), 'No notes logged');
      expect(l10n.teamListNoteCount(1), '1 note(s)');
      expect(l10n.teamListNoteCount(4), '4 note(s)');

      expect(l10n.ruleSelectionSubtitle('V5RC', 'High Stakes', 1), 'V5RC High Stakes (1 rule)');
      expect(l10n.ruleSelectionSubtitle('V5RC', 'High Stakes', 42), 'V5RC High Stakes (42 rules)');

      expect(
        l10n.eventShareConflictDescription('RE-V5RC-26-1000', 'Alice', 1),
        'A shared session for RE-V5RC-26-1000 is already active on the network, hosted by Alice with 1 participant.',
      );
      expect(
        l10n.eventShareConflictDescription('RE-V5RC-26-1000', 'Alice', 3),
        'A shared session for RE-V5RC-26-1000 is already active on the network, hosted by Alice with 3 participants.',
      );
    });

    testWidgets('context.l10n resolves in bare MaterialApp (fallback) and with delegates', (tester) async {
      late String bareTitle;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              bareTitle = context.l10n.appTitle;
              return Text(bareTitle);
            },
          ),
        ),
      );
      expect(bareTitle, 'RoboRef');

      late String delegateTitle;
      late String formattedMatch;
      late String severityBadge;
      late String ruleGroupLabel;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              delegateTitle = context.l10n.appTitle;
              formattedMatch = localizeMatchName(context, 'Q15');
              severityBadge = localizeSeverity(context, 'major', uppercaseBadge: true);
              ruleGroupLabel = localizeRuleGroup(context, 'Specific Game Rules');
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(delegateTitle, 'RoboRef');
      expect(formattedMatch, 'Qualification 15');
      expect(severityBadge, 'MAJOR VIOLATION');
      expect(ruleGroupLabel, 'Specific Game Rules');
    });

    test('registerLocalizedRuleset hook overrides ruleset for registered locale and falls back to English', () {
      const customSpanishRuleset = GameRuleset(
        program: 'V5RC',
        season: '2026-2027',
        gameTitle: 'Juego de Prueba',
        manualUrl: 'https://link.vex.com/docs/26-27/v5rc-game-manual',
        qaUrl: 'https://www.robotevents.com/V5RC/2026-2027/QA',
        rules: [
          RuleItem(
            code: '<G1>',
            title: 'Tratar a todos con respeto.',
            group: 'General Game Rules',
            summary: 'Todos los participantes deben comportarse con respeto.',
          ),
        ],
      );

      registerLocalizedRuleset('es', 'V5RC', customSpanishRuleset);

      final esRuleset = getGameRuleset('V5RC', '2026-2027', locale: const Locale('es', 'MX'));
      expect(esRuleset.gameTitle, 'Juego de Prueba');
      expect(esRuleset.rules.first.title, 'Tratar a todos con respeto.');

      final frFallbackRuleset = getGameRuleset('V5RC', '2026-2027', locale: const Locale('fr'));
      expect(frFallbackRuleset.program, 'V5RC');
      expect(frFallbackRuleset.gameTitle, isNot('Juego de Prueba'));
    });

    testWidgets('SettingsScreen displays Language dropdown under Appearance and updates localeProvider', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('language_dropdown_system')));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsWidgets);
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      expect(prefs.getString('selected_locale'), 'en');
      expect(find.byKey(const ValueKey('language_dropdown_en')), findsOneWidget);
    });
  });
}
