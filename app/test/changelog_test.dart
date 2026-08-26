import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:roboref/features/home/screens/changelog_screen.dart';

String getPubspecVersion() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw StateError('pubspec.yaml not found at ${Directory.current.path}');
  }
  final content = pubspecFile.readAsStringSync();
  final match = RegExp(r'^version:\s*([^\s]+)', multiLine: true).firstMatch(content);
  if (match == null) {
    throw StateError('Could not find version in pubspec.yaml');
  }
  return match.group(1)!.trim();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final currentVersion = getPubspecVersion();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'RoboRef',
      packageName: 'app.roboref',
      version: currentVersion.split('+').first,
      buildNumber: currentVersion.contains('+') ? currentVersion.split('+').last : '',
      buildSignature: '',
    );
  });

  group('ChangeLog Parsing & Version Alignment', () {
    test('parses markdown into structured releases', () {
      const sample = '''
# Change Log

## 2026.8.23+1

- **Clean-Slate Rebuild**: Complete ground-up rebuild using Flutter.
- **Venue LAN Sync Priority (`roboref.local`)**: Default connection.
- Simple bullet without bold title.

## 2026.8.20+1

- **Initial Commit**: Project initialized.
''';

      final releases = parseChangeLogReleases(sample);
      expect(releases.length, 2);
      expect(releases[0].title, '2026.8.23+1');
      expect(releases[0].itemCount, 3);
      expect(releases[0].markdownContent.contains('Clean-Slate Rebuild'), isTrue);
      expect(releases[0].markdownContent.contains('roboref.local'), isTrue);

      expect(releases[1].title, '2026.8.20+1');
      expect(releases[1].itemCount, 1);
      expect(releases[1].markdownContent.contains('Initial Commit'), isTrue);
    });

    test('top changelog release title matches current version in pubspec.yaml', () async {
      final raw = await loadChangeLogMarkdown();
      final releases = parseChangeLogReleases(raw);

      expect(releases.isNotEmpty, isTrue, reason: 'Changelog must contain at least one release');
      expect(
        releases.first.title,
        equals(currentVersion),
        reason:
            'The most recent changelog heading at the top of changeLog.md ("${releases.first.title}") '
            'must match the current pubspec.yaml version ("$currentVersion"). '
            'Please update changeLog.md to include "## $currentVersion" as the top section heading.',
      );
    });

    test('root documents/changeLog.md matches app/assets/changeLog.md and current version', () {
      final docFile = File('../documents/changeLog.md');
      if (docFile.existsSync()) {
        final docContent = docFile.readAsStringSync();
        final docReleases = parseChangeLogReleases(docContent);
        expect(
          docReleases.first.title,
          equals(currentVersion),
          reason: 'The top release title in documents/changeLog.md must match pubspec.yaml version ($currentVersion)',
        );
      }
    });
  });

  group('ChangeLogScreen Widget Tests', () {
    testWidgets('renders current version in version card and as top item in release history', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangeLogScreen(),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // 1. Check AppBar
      expect(find.text('Change Log'), findsOneWidget);

      // 2. Check Version Card displays current version
      expect(find.text('Current Version'), findsOneWidget);
      expect(find.text('v$currentVersion'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // 3. Check Release History header and verify current version is the top release title
      expect(find.text('Release History'), findsOneWidget);
      expect(find.text(currentVersion), findsOneWidget);

      // 4. Check markdown content is present
      expect(find.textContaining('Theme Improvements', findRichText: true), findsWidgets);
      expect(find.textContaining('Event Filters', findRichText: true), findsWidgets);
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
      await tester.enterText(find.byType(TextField), 'Theme Improvements');
      await tester.pumpAndSettle();

      expect(find.textContaining('Theme Improvements', findRichText: true), findsWidgets);

      // Search for something non-existent
      await tester.enterText(find.byType(TextField), 'xyznonexistent123');
      await tester.pumpAndSettle();

      expect(find.textContaining('No changelog entries found'), findsOneWidget);
      expect(find.text('Clear search'), findsOneWidget);

      // Clear search
      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Theme Improvements', findRichText: true), findsWidgets);
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

    testWidgets('renders custom overrideVersion when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChangeLogScreen(
            overrideVersion: '2026.8.23+99',
          ),
        ),
      );

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('v2026.8.23+99'), findsOneWidget);
    });
  });
}
