import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/event_selection/screens/event_selection_screen.dart';
import '../../features/event_workspace/screens/event_workspace_screen.dart';
import '../../features/home/screens/changelog_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/share_screen.dart';
import '../../features/rules/screens/rules_screen.dart';
import '../../features/settings/screens/privacy_policy_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

/// Canonical web and in-app path routes for RoboRef.
abstract final class AppRoutes {
  static const String home = '/';
  static const String events = '/events';
  static const String share = '/share';
  static const String settings = '/settings';
  static const String changelog = '/changelog';
  static const String privacy = '/privacy';
  static const String rules = '/rules';
  static const String eventPrefix = '/event';

  static const List<String> eventTabs = [
    'matches',
    'teams',
    'notes',
    'rules',
    'manage',
  ];

  static String tabNameForIndex(int index) {
    if (index < 0 || index >= eventTabs.length) {
      return eventTabs.first;
    }
    return eventTabs[index];
  }

  static int tabIndexForName(String? name) {
    if (name == null || name.isEmpty) return 0;
    final idx = eventTabs.indexOf(name.trim().toLowerCase());
    return idx >= 0 ? idx : 0;
  }

  /// Builds a canonical path for an event workspace, e.g. `/event/RE-V5RC-26-0042`
  /// or `/event/RE-V5RC-26-0042/teams`.
  static String eventPath(String sku, {int? tabIndex}) {
    final cleanSku = sku.trim().toUpperCase();
    if (cleanSku.isEmpty) return home;
    final encodedSku = Uri.encodeComponent(cleanSku);
    if (tabIndex == null || tabIndex <= 0 || tabIndex >= eventTabs.length) {
      return '$eventPrefix/$encodedSku';
    }
    return '$eventPrefix/$encodedSku/${eventTabs[tabIndex]}';
  }
}

enum AppRouteKind {
  home,
  events,
  share,
  settings,
  changelog,
  privacy,
  rules,
  eventWorkspace,
}

class ParsedAppRoute {
  final AppRouteKind kind;
  final String canonicalPath;
  final String? sku;
  final int tabIndex;
  final String? joinShare;

  const ParsedAppRoute({
    required this.kind,
    required this.canonicalPath,
    this.sku,
    this.tabIndex = 0,
    this.joinShare,
  });
}

/// Centralized path-based router for RoboRef across Web, Android, iOS, and Desktop.
abstract final class AppRouter {
  /// Parses a raw route string (e.g. `/changelog`, `/event/RE-V5RC-26-0042/teams`)
  /// into a normalized [ParsedAppRoute]. Unknown paths fall back to [AppRoutes.home].
  static ParsedAppRoute parseRoute(String? rawRouteName) {
    final raw = (rawRouteName == null || rawRouteName.trim().isEmpty)
        ? AppRoutes.home
        : rawRouteName.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      return const ParsedAppRoute(
        kind: AppRouteKind.home,
        canonicalPath: AppRoutes.home,
      );
    }

    final segments = uri.pathSegments
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return const ParsedAppRoute(
        kind: AppRouteKind.home,
        canonicalPath: AppRoutes.home,
      );
    }

    final first = segments.first.toLowerCase();
    switch (first) {
      case 'events':
        return const ParsedAppRoute(
          kind: AppRouteKind.events,
          canonicalPath: AppRoutes.events,
        );
      case 'share':
        return const ParsedAppRoute(
          kind: AppRouteKind.share,
          canonicalPath: AppRoutes.share,
        );
      case 'settings':
        return const ParsedAppRoute(
          kind: AppRouteKind.settings,
          canonicalPath: AppRoutes.settings,
        );
      case 'changelog':
        return const ParsedAppRoute(
          kind: AppRouteKind.changelog,
          canonicalPath: AppRoutes.changelog,
        );
      case 'privacy':
        return const ParsedAppRoute(
          kind: AppRouteKind.privacy,
          canonicalPath: AppRoutes.privacy,
        );
      case 'rules':
        return const ParsedAppRoute(
          kind: AppRouteKind.rules,
          canonicalPath: AppRoutes.rules,
        );
      case 'event':
        if (segments.length >= 2) {
          final sku = Uri.decodeComponent(segments[1]).trim().toUpperCase();
          if (sku.isNotEmpty) {
            final tabIndex = segments.length >= 3
                ? AppRoutes.tabIndexForName(segments[2])
                : 0;
            final joinShare = uri.queryParameters['joinShare'] ??
                uri.queryParameters['join'] ??
                uri.queryParameters['shareId'];
            final cleanJoinShare =
                (joinShare != null && joinShare.trim().isNotEmpty)
                    ? joinShare.trim().toUpperCase()
                    : null;
            return ParsedAppRoute(
              kind: AppRouteKind.eventWorkspace,
              canonicalPath: AppRoutes.eventPath(sku, tabIndex: tabIndex),
              sku: sku,
              tabIndex: tabIndex,
              joinShare: cleanJoinShare,
            );
          }
        }
        return const ParsedAppRoute(
          kind: AppRouteKind.home,
          canonicalPath: AppRoutes.home,
        );
      default:
        return const ParsedAppRoute(
          kind: AppRouteKind.home,
          canonicalPath: AppRoutes.home,
        );
    }
  }

  static Widget _buildScreen(ParsedAppRoute parsed) {
    switch (parsed.kind) {
      case AppRouteKind.home:
        return const HomeScreen();
      case AppRouteKind.events:
        return const EventSelectionScreen();
      case AppRouteKind.share:
        return const ShareScreen();
      case AppRouteKind.settings:
        return const SettingsScreen();
      case AppRouteKind.changelog:
        return const ChangeLogScreen();
      case AppRouteKind.privacy:
        return const PrivacyPolicyScreen();
      case AppRouteKind.rules:
        return const RulesScreen();
      case AppRouteKind.eventWorkspace:
        return EventWorkspaceScreen(
          initialSku: parsed.sku,
          initialTabIndex: parsed.tabIndex,
          initialJoinShare: parsed.joinShare,
        );
    }
  }

  /// Builds a [MaterialPageRoute] for a path string, preserving [RouteSettings.name]
  /// so Flutter Web updates the browser address bar automatically.
  static Route<dynamic> routeForPath(String path) {
    final parsed = parseRoute(path);
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: parsed.canonicalPath),
      builder: (_) => _buildScreen(parsed),
    );
  }

  /// Passed to [MaterialApp.onGenerateRoute].
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return routeForPath(settings.name ?? AppRoutes.home);
  }

  /// Passed to [MaterialApp.onGenerateInitialRoutes].
  /// Deep links (e.g. `/changelog`, `/event/RE-V5RC-26-0042/teams`) are stacked on top
  /// of [AppRoutes.home] so the AppBar back button returns cleanly to Home.
  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRouteName) {
    final parsed = parseRoute(initialRouteName);
    final homeRoute = routeForPath(AppRoutes.home);
    if (parsed.kind == AppRouteKind.home) {
      return [homeRoute];
    }
    return [homeRoute, routeForPath(initialRouteName)];
  }

  /// Pushes a canonical path route onto the nearest [Navigator].
  /// Works in both the full app (updating browser URLs on Web) and isolated widget tests.
  static Future<T?> push<T>(BuildContext context, String path) {
    final parsed = parseRoute(path);
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        settings: RouteSettings(name: parsed.canonicalPath),
        builder: (_) => _buildScreen(parsed),
      ),
    );
  }

  /// Replaces the current route with a canonical path route on the nearest [Navigator].
  static Future<T?> pushReplacement<T, TO>(BuildContext context, String path) {
    final parsed = parseRoute(path);
    return Navigator.of(context).pushReplacement<T, TO>(
      MaterialPageRoute<T>(
        settings: RouteSettings(name: parsed.canonicalPath),
        builder: (_) => _buildScreen(parsed),
      ),
    );
  }

  /// Replaces the current browser URL on Flutter Web (e.g. when switching tabs inside
  /// [EventWorkspaceScreen]) without pushing an extra browser history entry.
  static void updateBrowserUrl(String path) {
    if (!kIsWeb) return;
    final parsed = parseRoute(path);
    try {
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse(parsed.canonicalPath),
        replace: true,
      );
    } catch (_) {}
  }
}
