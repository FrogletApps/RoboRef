import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/features/home/screens/changelog_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChangeLog Parsing', () {
    test('parses markdown into structured releases', () {
      const sample = '''
# Change Log

## 23 August 2026

- **Clean-Slate Rebuild**: Complete ground-up rebuild using Flutter.
- **Venue LAN Sync Priority (`roboref.local`)**: Default connection.
- Simple bullet without bold title.

## 20 August 2026

- **Initial Commit**: Project initialized.
''';

      final releases = parseChangeLogReleases(sample);
      expect(releases.length, 2);
      expect(releases[0].title, '23 August 2026');
      expect(releases[0].itemCount, 3);
      expect(releases[0].markdownContent.contains('Clean-Slate Rebuild'), isTrue);
      expect(releases[0].markdownContent.contains('roboref.local'), isTrue);

      expect(releases[1].title, '20 August 2026');
      expect(releases[1].itemCount, 1);
      expect(releases[1].markdownContent.contains('Initial Commit'), isTrue);
    });

    test('parses actual changeLog.md file from disk assets', () async {
      final raw = await loadChangeLogMarkdown();
      final releases = parseChangeLogReleases(raw);

      expect(releases.isNotEmpty, isTrue);
      expect(releases.first.title, '23 August 2026');
      expect(releases.first.itemCount, greaterThanOrEqualTo(7));
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

      // Check markdown content is present
      expect(find.textContaining('Clean-Slate Rebuild', findRichText: true), findsWidgets);
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

      expect(find.textContaining('Clean-Slate Rebuild', findRichText: true), findsWidgets);
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
