import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/features/rules/data/default_rules.dart';
import 'package:roboref/features/rules/screens/rules_screen.dart';
import 'package:roboref/features/rules/state/rules_disclaimer_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  group('Game Rules Data Tests', () {
    test('getGameRuleset returns valid rules for all programs', () {
      final v5rc = getGameRuleset('V5RC', '2026-2027');
      expect(v5rc.program, equals('V5RC'));
      expect(v5rc.rules.isNotEmpty, isTrue);
      expect(v5rc.rules.any((r) => r.code == '<G1>'), isTrue);
      expect(v5rc.rules.any((r) => r.code == '<SG1>'), isTrue);
      expect(v5rc.rules.any((r) => r.code == '<GG2>'), isTrue);
      expect(v5rc.rules.any((r) => r.code == '<S1>'), isTrue);
      expect(v5rc.rules.any((r) => r.code == '<R1>'), isTrue);
      expect(v5rc.findRule('GG2')?.title, equals("A Team's Robot should attend every Match"));
      expect(v5rc.findRule('SG1')?.title, equals('Starting a Match'));

      final viqrc = getGameRuleset('VIQRC', '2026-2027');
      expect(viqrc.program, equals('VIQRC'));
      expect(viqrc.rules.isNotEmpty, isTrue);
      expect(viqrc.rules.any((r) => r.code == '<GG2>'), isTrue);

      final vexu = getGameRuleset('VEX U', '2026-2027');
      expect(vexu.program, equals('VEX U'));
      expect(vexu.rules.any((r) => r.code == '<VUG1>'), isTrue);

      final vexai = getGameRuleset('VEX AI', '2026-2027');
      expect(vexai.program, equals('VEX AI'));
      expect(vexai.rules.isNotEmpty, isTrue);
      expect(vexai.rules.any((r) => r.code == '<SG1>'), isTrue);
    });
  });

  group('RulesScreen Widget Tests', () {
    testWidgets('renders rules screen, category chips, and filters by search query', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-26-8909',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeEventProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: RulesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check external links bar
      expect(find.text('V5RC Manual'), findsOneWidget);
      expect(find.text('Official Q&A'), findsOneWidget);

      // Check Disclaimer banner at the bottom
      expect(
        find.text('DISCLAIMER:  These are a summary of the official rules and are only for reference - check the game manual before you make a ruling.'),
        findsOneWidget,
      );

      // Check Category Chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'General Rules'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Specific Game Rules'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Safety Rules'), findsOneWidget);

      // Verify rules list displays rule SG1 (first in list)
      expect(find.text('<SG1>'), findsOneWidget);

      // Tap Specific Game Rules chip
      await tester.tap(find.widgetWithText(FilterChip, 'Specific Game Rules'));
      await tester.pumpAndSettle();
      expect(find.text('<SG1>'), findsOneWidget);

      // Tap All chip to reset
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      // Search for specific rule code e.g. GG2 (A Team's Robot should attend every Match)
      await tester.enterText(find.byType(TextField), 'GG2');
      await tester.pumpAndSettle();

      expect(find.text('<GG2>'), findsOneWidget);
      expect(find.text("A Team's Robot should attend every Match"), findsOneWidget);
      expect(find.text('<G1>'), findsNothing);

      // Tap rule card to open bottom sheet detail view
      await tester.tap(find.text('<GG2>'));
      await tester.pumpAndSettle();

      expect(find.text('View in Manual'), findsOneWidget);
      expect(find.text('Search Q&A'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byType(ElevatedButton).last); // Or tap back / barrier
      await tester.pumpAndSettle();
    });
  });

  group('Rules Disclaimer Tests', () {
    test('RulesDisclaimerNotifier initializes empty and loads dismissed SKUs from prefs', () async {
      SharedPreferences.setMockInitialValues({
        'rules_disclaimer_dismissed_skus': ['RE-V5RC-26-1111', 'RE-VIQRC-26-2222'],
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = RulesDisclaimerNotifier(prefs);

      expect(notifier.isDismissed('RE-V5RC-26-1111'), isTrue);
      expect(notifier.isDismissed('re-v5rc-26-1111'), isTrue);
      expect(notifier.isDismissed('RE-VIQRC-26-2222'), isTrue);
      expect(notifier.isDismissed('RE-OTHER-SKU'), isFalse);
    });

    test('RulesDisclaimerNotifier dismiss and reset work and persist to prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = RulesDisclaimerNotifier(prefs);

      expect(notifier.isDismissed('RE-EVENT-1'), isFalse);
      await notifier.dismiss('RE-EVENT-1');
      expect(notifier.isDismissed('RE-EVENT-1'), isTrue);
      expect(prefs.getStringList('rules_disclaimer_dismissed_skus'), contains('RE-EVENT-1'));

      await notifier.reset('RE-EVENT-1');
      expect(notifier.isDismissed('RE-EVENT-1'), isFalse);
      expect(prefs.getStringList('rules_disclaimer_dismissed_skus')?.contains('RE-EVENT-1') ?? false, isFalse);
    });

    testWidgets('RulesScreen allows dismissing disclaimer, persists for current event, and displays for new event', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'EVENT-ALPHA',
      });
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: RulesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final disclaimerFinder = find.textContaining('DISCLAIMER:');
      final dismissButtonFinder = find.byTooltip('Dismiss disclaimer');

      // Disclaimer and dismiss button should initially be visible
      expect(disclaimerFinder, findsOneWidget);
      expect(dismissButtonFinder, findsOneWidget);

      // Tap the dismiss button
      await tester.tap(dismissButtonFinder);
      await tester.pumpAndSettle();

      // Disclaimer should now be dismissed
      expect(disclaimerFinder, findsNothing);
      expect(dismissButtonFinder, findsNothing);
      expect(prefs.getStringList('rules_disclaimer_dismissed_skus'), contains('EVENT-ALPHA'));

      // Switch to a new event
      container.read(syncSettingsProvider.notifier).setSku('EVENT-BETA');
      await tester.pumpAndSettle();

      // Disclaimer should now show again for the new event
      expect(disclaimerFinder, findsOneWidget);
      expect(dismissButtonFinder, findsOneWidget);

      // Dismiss disclaimer for the new event
      await tester.tap(dismissButtonFinder);
      await tester.pumpAndSettle();
      expect(disclaimerFinder, findsNothing);
      expect(prefs.getStringList('rules_disclaimer_dismissed_skus'), containsAll(['EVENT-ALPHA', 'EVENT-BETA']));

      // Switch back to EVENT-ALPHA
      container.read(syncSettingsProvider.notifier).setSku('EVENT-ALPHA');
      await tester.pumpAndSettle();

      // Should remain dismissed for EVENT-ALPHA
      expect(disclaimerFinder, findsNothing);
    });
  });
}
