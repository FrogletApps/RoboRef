import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/features/home/screens/changelog_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChangeLog Parsing', () {
    test('parses standard markdown changelog with bold titles and inline code', () {
      const sample = '''
# Change Log

## 23 August 2026

- **Clean-Slate Rebuild**: Complete ground-up rebuild using Flutter.
- **Venue LAN Sync Priority (`roboref.local`)**: Default connection.
- Simple bullet without bold title.

## 20 August 2026

- **Initial Commit**: Project initialized.
''';

      final releases = parseChangeLog(sample);
      expect(releases.length, 2);
      expect(releases[0].title, '23 August 2026');
      expect(releases[0].items.length, 3);
      expect(releases[0].items[0].boldTitle, 'Clean-Slate Rebuild');
      expect(releases[0].items[0].description, 'Complete ground-up rebuild using Flutter.');
      expect(releases[0].items[1].boldTitle, 'Venue LAN Sync Priority (`roboref.local`)');
      expect(releases[0].items[2].boldTitle, isNull);
      expect(releases[0].items[2].description, 'Simple bullet without bold title.');

      expect(releases[1].title, '20 August 2026');
      expect(releases[1].items.length, 1);
      expect(releases[1].items[0].boldTitle, 'Initial Commit');
    });

    test('parses actual documents/changeLog.md file', () async {
      final raw = await rootBundle.loadString('../documents/changeLog.md');
      final releases = parseChangeLog(raw);

      expect(releases.isNotEmpty, isTrue);
      expect(releases.first.title, '23 August 2026');
      expect(releases.first.items.length, greaterThanOrEqualTo(7));
    });
  });

  group('ChangeLogScreen Widget Tests', () {
    testWidgets('renders ChangeLogScreen, version card, and changelog items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangeLogScreen(),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.text('Change Log'), findsOneWidget);

      // Check Version Card
      expect(find.text('Current Version'), findsOneWidget);
      expect(find.text('v1.0.0+1'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // Check Release History
      expect(find.text('Release History'), findsOneWidget);
      expect(find.text('23 August 2026'), findsOneWidget);

      // Check that changelog entries from documents/changeLog.md are displayed
      expect(find.textContaining('Clean-Slate Rebuild', findRichText: true), findsOneWidget);
      expect(find.textContaining('roboref.local', findRichText: true), findsWidgets);
    });

    testWidgets('filters items when search query is entered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangeLogScreen(),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Search for specific keyword
      await tester.enterText(find.byType(TextField), 'VEXEvents');
      await tester.pumpAndSettle();

      expect(find.textContaining('VEXEvents', findRichText: true), findsWidgets);

      // Search for something non-existent
      await tester.enterText(find.byType(TextField), 'xyznonexistent123');
      await tester.pumpAndSettle();

      expect(find.textContaining('No changelog entries found'), findsOneWidget);
      expect(find.text('Clear search'), findsOneWidget);

      // Clear search
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Clean-Slate Rebuild', findRichText: true), findsOneWidget);
    });

    testWidgets('copies version to clipboard when copy button is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangeLogScreen(),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      final copyButton = find.widgetWithText(TextButton, 'Copy');
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pump(); // Start snackbar animation

      expect(find.text('Version copied to clipboard'), findsOneWidget);
    });

    testWidgets('renders error view on failed asset load and allows retry', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangeLogScreen(
            changelogAssetPath: 'invalid/path/nonexistent.md',
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('Unable to load change log'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
