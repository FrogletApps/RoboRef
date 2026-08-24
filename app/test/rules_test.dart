import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roboref/features/rules/data/default_rules.dart';
import 'package:roboref/features/rules/screens/rules_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  group('Game Rules Data Tests', () {
    test('getGameRuleset returns valid rules for all programs', () {
      final v5rc = getGameRuleset('V5RC', '2026-2027');
      expect(v5rc.program, equals('V5RC'));
      expect(v5rc.rules.isNotEmpty, isTrue);
      expect(v5rc.rules.any((r) => r.code == '<G1>'), isTrue);
      expect(v5rc.rules.any((r) => r.code == '<SG1>'), isTrue);
      expect(v5rc.rules.any((r) => r.code == '<S1>'), isTrue);
      expect(v5rc.rules.any((r) => r.code == '<R1>'), isTrue);

      final viqrc = getGameRuleset('VIQRC', '2026-2027');
      expect(viqrc.program, equals('VIQRC'));
      expect(viqrc.rules.isNotEmpty, isTrue);

      final vexu = getGameRuleset('VEX U', '2026-2027');
      expect(vexu.program, equals('VEX U'));
      expect(vexu.rules.any((r) => r.code == '<VUG1>'), isTrue);

      final vexai = getGameRuleset('VEX AI', '2026-2027');
      expect(vexai.program, equals('VEX AI'));
      expect(vexai.rules.any((r) => r.code == '<VAIC1>'), isTrue);
    });
  });

  group('RulesScreen Widget Tests', () {
    testWidgets('renders rules screen, category chips, and filters by search query', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-V5RC-24-8909',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
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

      // Check Category Chips
      expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'General Rules'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Specific Game Rules'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Safety Rules'), findsOneWidget);

      // Verify rules list displays rule G1
      expect(find.text('<G1>'), findsOneWidget);

      // Tap Specific Game Rules chip
      await tester.tap(find.widgetWithText(FilterChip, 'Specific Game Rules'));
      await tester.pumpAndSettle();
      expect(find.text('<SG1>'), findsOneWidget);

      // Tap All chip to reset
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      // Search for specific rule code e.g. G14 (Pinning)
      await tester.enterText(find.byType(TextField), 'G14');
      await tester.pumpAndSettle();

      expect(find.text('<G14>'), findsOneWidget);
      expect(find.text('Pinning is limited to 5 seconds'), findsOneWidget);
      expect(find.text('<G1>'), findsNothing);

      // Tap rule card to open bottom sheet detail view
      await tester.tap(find.text('<G14>'));
      await tester.pumpAndSettle();

      expect(find.text('View in Manual'), findsOneWidget);
      expect(find.text('Search Q&A'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byType(ElevatedButton).last); // Or tap back / barrier
      await tester.pumpAndSettle();
    });
  });
}
