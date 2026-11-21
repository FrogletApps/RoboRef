import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:roboref/core/l10n/l10n.dart';
import 'package:roboref/core/routing/app_router.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_selection/screens/event_selection_screen.dart';
import 'package:roboref/features/event_workspace/screens/event_workspace_screen.dart';
import 'package:roboref/features/home/screens/changelog_screen.dart';
import 'package:roboref/features/home/screens/home_screen.dart';
import 'package:roboref/features/home/screens/share_screen.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/rules/screens/rules_screen.dart';
import 'package:roboref/features/settings/screens/privacy_policy_screen.dart';
import 'package:roboref/features/settings/screens/settings_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppRoutes & AppRouter.parseRoute', () {
    test('parses root and top-level static routes cleanly', () {
      expect(AppRouter.parseRoute('/').kind, AppRouteKind.home);
      expect(AppRouter.parseRoute('/').canonicalPath, '/');
      expect(AppRouter.parseRoute('').kind, AppRouteKind.home);
      expect(AppRouter.parseRoute(null).kind, AppRouteKind.home);

      expect(AppRouter.parseRoute('/events').kind, AppRouteKind.events);
      expect(AppRouter.parseRoute('/events/').canonicalPath, '/events');

      expect(AppRouter.parseRoute('/share').kind, AppRouteKind.share);
      expect(AppRouter.parseRoute('/SHARE').canonicalPath, '/share');

      expect(AppRouter.parseRoute('/settings').kind, AppRouteKind.settings);
      expect(AppRouter.parseRoute('/changelog').kind, AppRouteKind.changelog);
      expect(AppRouter.parseRoute('/ChangeLog/').canonicalPath, '/changelog');

      expect(AppRouter.parseRoute('/privacy').kind, AppRouteKind.privacy);
      expect(AppRouter.parseRoute('/rules').kind, AppRouteKind.rules);
    });

    test('parses event workspace routes with SKU, tab, and joinShare query', () {
      final base = AppRouter.parseRoute('/event/re-v5rc-26-0042');
      expect(base.kind, AppRouteKind.eventWorkspace);
      expect(base.sku, 'RE-V5RC-26-0042');
      expect(base.tabIndex, 0);
      expect(base.canonicalPath, '/event/RE-V5RC-26-0042');

      final teams = AppRouter.parseRoute('/event/re-v5rc-26-0042/teams');
      expect(teams.kind, AppRouteKind.eventWorkspace);
      expect(teams.sku, 'RE-V5RC-26-0042');
      expect(teams.tabIndex, 1);
      expect(teams.canonicalPath, '/event/RE-V5RC-26-0042/teams');

      final notes = AppRouter.parseRoute('/event/RE-V5RC-26-0042/notes');
      expect(notes.tabIndex, 2);
      expect(notes.canonicalPath, '/event/RE-V5RC-26-0042/notes');

      final rules = AppRouter.parseRoute('/event/RE-V5RC-26-0042/rules');
      expect(rules.tabIndex, 3);
      expect(rules.canonicalPath, '/event/RE-V5RC-26-0042/rules');

      final manage = AppRouter.parseRoute('/event/RE-V5RC-26-0042/manage?joinShare=abc123');
      expect(manage.tabIndex, 4);
      expect(manage.joinShare, 'ABC123');
      expect(manage.canonicalPath, '/event/RE-V5RC-26-0042/manage');

      // Unknown tab defaults to matches (index 0)
      final unknownTab = AppRouter.parseRoute('/event/RE-V5RC-26-0042/unknown');
      expect(unknownTab.tabIndex, 0);
      expect(unknownTab.canonicalPath, '/event/RE-V5RC-26-0042');
    });

    test('falls back to home for unknown paths or missing event SKU', () {
      expect(AppRouter.parseRoute('/does-not-exist').kind, AppRouteKind.home);
      expect(AppRouter.parseRoute('/event').kind, AppRouteKind.home);
      expect(AppRouter.parseRoute('/event/').kind, AppRouteKind.home);
    });

    test('AppRoutes.eventPath builds canonical event paths', () {
      expect(AppRoutes.eventPath('re-v5rc-26-0042'), '/event/RE-V5RC-26-0042');
      expect(AppRoutes.eventPath('re-v5rc-26-0042', tabIndex: 0), '/event/RE-V5RC-26-0042');
      expect(AppRoutes.eventPath('re-v5rc-26-0042', tabIndex: 1), '/event/RE-V5RC-26-0042/teams');
      expect(AppRoutes.eventPath('re-v5rc-26-0042', tabIndex: 2), '/event/RE-V5RC-26-0042/notes');
      expect(AppRoutes.eventPath('re-v5rc-26-0042', tabIndex: 3), '/event/RE-V5RC-26-0042/rules');
      expect(AppRoutes.eventPath('re-v5rc-26-0042', tabIndex: 4), '/event/RE-V5RC-26-0042/manage');
      expect(AppRoutes.eventPath(''), '/');
    });

    test('onGenerateInitialRoutes returns single Home route for / and stacked routes for deep paths', () {
      final rootRoutes = AppRouter.onGenerateInitialRoutes('/');
      expect(rootRoutes.length, 1);
      expect(rootRoutes.first.settings.name, '/');

      final changelogRoutes = AppRouter.onGenerateInitialRoutes('/changelog');
      expect(changelogRoutes.length, 2);
      expect(changelogRoutes[0].settings.name, '/');
      expect(changelogRoutes[1].settings.name, '/changelog');

      final eventRoutes = AppRouter.onGenerateInitialRoutes('/event/RE-V5RC-26-0042/teams');
      expect(eventRoutes.length, 2);
      expect(eventRoutes[0].settings.name, '/');
      expect(eventRoutes[1].settings.name, '/event/RE-V5RC-26-0042/teams');
    });
  });

  group('AppRouter Widget Navigation', () {
    late SharedPreferences prefs;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      HomeScreen.resetDeepLinkCheckForTesting();
    });

    tearDown(() async {
      await db.close();
    });

    Widget buildRoutedApp(String initialRoute) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: initialRoute,
          onGenerateRoute: AppRouter.onGenerateRoute,
          onGenerateInitialRoutes: AppRouter.onGenerateInitialRoutes,
        ),
      );
    }

    testWidgets('opens /changelog directly with Back button to Home', (tester) async {
      await tester.pumpWidget(buildRoutedApp('/changelog'));
      await tester.pump();
      expect(find.byType(ChangeLogScreen), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
    });

    testWidgets('opens /privacy directly', (tester) async {
      await tester.pumpWidget(buildRoutedApp('/privacy'));
      await tester.pump();
      expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    });

    testWidgets('opens /share directly', (tester) async {
      await tester.pumpWidget(buildRoutedApp('/share'));
      await tester.pump();
      expect(find.byType(ShareScreen), findsOneWidget);
    });

    testWidgets('opens /settings directly', (tester) async {
      await tester.pumpWidget(buildRoutedApp('/settings'));
      await tester.pump();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('opens /events directly', (tester) async {
      await tester.pumpWidget(buildRoutedApp('/events'));
      await tester.pump();
      expect(find.byType(EventSelectionScreen), findsOneWidget);
    });

    testWidgets('opens /rules directly', (tester) async {
      await tester.pumpWidget(buildRoutedApp('/rules'));
      await tester.pump();
      expect(find.byType(RulesScreen), findsOneWidget);
    });

    testWidgets('opens /event/<SKU>/teams directly on Teams tab', (tester) async {
      await tester.pumpWidget(buildRoutedApp('/event/RE-V5RC-26-0042/teams'));
      await tester.pump();
      final workspace = tester.widget<EventWorkspaceScreen>(
        find.byType(EventWorkspaceScreen),
      );
      expect(workspace.initialSku, 'RE-V5RC-26-0042');
      expect(workspace.initialTabIndex, 1);
    });
  });
}
