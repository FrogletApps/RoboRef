import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roboref/core/theme/app_theme.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_data/screens/event_import_sheet.dart';
import 'package:roboref/features/event_data/services/vex_events_client.dart';
import 'package:roboref/features/event_selection/screens/event_selection_screen.dart';
import 'package:roboref/features/event_selection/services/event_cache_service.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/features/home/screens/changelog_screen.dart';
import 'package:roboref/features/home/screens/home_screen.dart';
import 'package:roboref/features/home/screens/share_screen.dart';
import 'package:roboref/features/incidents/screens/incident_logger_screen.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/incidents/widgets/rule_selection_sheet.dart';
import 'package:roboref/features/matches/screens/match_schedule_screen.dart';
import 'package:roboref/features/rules/data/default_rules.dart';
import 'package:roboref/features/rules/screens/rules_screen.dart';
import 'package:roboref/features/settings/screens/privacy_policy_screen.dart';
import 'package:roboref/features/settings/screens/settings_screen.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:roboref/features/sharing/models/share_models.dart';
import 'package:roboref/features/sharing/state/share_controller.dart';
import 'package:roboref/features/sharing/widgets/event_share_sheet.dart';
import 'package:roboref/features/teams/screens/team_list_screen.dart';

/// Runs all four built-in Flutter accessibility guidelines against the current widget tree:
/// - Android tap target size (>= 48x48 dp)
/// - iOS tap target size (>= 44x44 dp)
/// - Labeled tap targets (non-empty semantic label on every interactive control)
/// - WCAG 2.1 AA text contrast ratio
Future<void> expectMeetsAllAccessibilityGuidelines(WidgetTester tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  } finally {
    handle.dispose();
  }
}

class _FakeShareController extends ShareController {
  final EventShareState initialState;
  _FakeShareController(this.initialState);

  @override
  EventShareState build() => initialState;

  @override
  Future<void> loadEventShareState(String sku) async {}

  @override
  Future<void> refreshShareStatus(String sku) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase testDb;
  late SharedPreferences prefs;
  late MockClient mockHttpClient;

  final int nowMs = DateTime(2026, 10, 24, 10, 30).millisecondsSinceEpoch;

  setUp(() async {
    HomeScreen.resetDeepLinkCheckForTesting();
    SharedPreferences.setMockInitialValues({
      'current_sku': 'RE-V5RC-26-4487',
      'referee_name': 'Head Referee Jane',
      'device_id': 'test-device-uuid',
      'server_url': 'https://test.roboref.app',
    });
    prefs = await SharedPreferences.getInstance();
    testDb = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory()),
    );

    // Seed events covering multiple programs (V5RC, VIQRC, VEX AI) and sharing states
    await testDb.upsertEvent(
      EventsCompanion.insert(
        sku: 'RE-V5RC-26-4487',
        name: '2026 Signature V5RC Regional',
        program: 'V5RC',
        season: '2026-2027',
        startDate: '2026-10-24T08:00:00Z',
        endDate: '2026-10-25T17:00:00Z',
        venue: const Value('Convention Center'),
        city: const Value('Austin'),
        region: const Value('Texas'),
        isShared: const Value(true),
        shareRole: const Value('admin'),
        adminRefereeName: const Value('Head Referee Jane'),
        updatedAt: nowMs,
      ),
    );
    await testDb.upsertEvent(
      EventsCompanion.insert(
        sku: 'RE-VIQRC-26-1002',
        name: '2026 State VIQRC Championship',
        program: 'VIQRC',
        season: '2026-2027',
        startDate: '2026-11-01T08:00:00Z',
        endDate: '2026-11-01T17:00:00Z',
        venue: const Value('High School Gym'),
        city: const Value('Dallas'),
        region: const Value('Texas'),
        isShared: const Value(false),
        updatedAt: nowMs - 1000,
      ),
    );

    // Seed teams (ranked, multi-digit ranked, unranked)
    await testDb.into(testDb.teams).insert(
      const TeamsCompanion(
        sku: Value('RE-V5RC-26-4487'),
        teamNumber: Value('1114A'),
        teamName: Value('Simbotics'),
        rank: Value(1),
      ),
    );
    await testDb.into(testDb.teams).insert(
      const TeamsCompanion(
        sku: Value('RE-V5RC-26-4487'),
        teamNumber: Value('2056A'),
        teamName: Value('OP Robotics'),
        rank: Value(14),
      ),
    );
    await testDb.into(testDb.teams).insert(
      const TeamsCompanion(
        sku: Value('RE-V5RC-26-4487'),
        teamNumber: Value('217A'),
        teamName: Value('ThunderChickens'),
        rank: Value(null),
      ),
    );

    // Seed matches (Red vs Blue and single-alliance)
    await testDb.into(testDb.matches).insert(
      MatchesCompanion(
        matchId: const Value('m1'),
        divisionId: const Value(1),
        sku: const Value('RE-V5RC-26-4487'),
        name: const Value('Qualifier #12'),
        field: const Value('Field 1'),
        scheduledTime: const Value('2026-10-24T09:30:00Z'),
        redTeamsJson: Value(jsonEncode(['1114A', '2056A'])),
        blueTeamsJson: Value(jsonEncode(['217A', '148A'])),
      ),
    );

    // Seed incident notes across all 5 severity types
    final severities = ['general', 'minor', 'major', 'inspection', 'disabled'];
    for (int i = 0; i < severities.length; i++) {
      await testDb.into(testDb.incidentNotes).insert(
        IncidentNotesCompanion(
          id: Value('note-$i'),
          sku: const Value('RE-V5RC-26-4487'),
          teamNumber: Value(i.isEven ? '1114A' : '2056A'),
          matchId: const Value('Q12'),
          severity: Value(severities[i]),
          notes: Value('Test ${severities[i]} incident note description'),
          refereeName: const Value('Head Referee Jane'),
          deviceId: const Value('test-device-uuid'),
          ruleCodesJson: Value(jsonEncode(['<SG1>', '<GG2>'])),
          createdAt: Value(nowMs),
          updatedAt: Value(nowMs),
        ),
      );
    }

    mockHttpClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 1,
              'sku': 'RE-V5RC-26-4487',
              'name': '2026 Signature V5RC Regional',
              'program': {'code': 'V5RC'},
              'start': '2026-10-24T00:00:00Z',
              'end': '2026-10-25T00:00:00Z',
              'location': {'venue': 'Convention Center', 'city': 'Austin', 'region': 'Texas', 'country': 'United States'},
            },
            {
              'id': 2,
              'sku': 'RE-VIQRC-26-1002',
              'name': '2026 State VIQRC Championship',
              'program': {'code': 'VIQRC'},
              'start': '2026-11-01T00:00:00Z',
              'end': '2026-11-01T00:00:00Z',
              'location': {'venue': 'High School Gym', 'city': 'Dallas', 'region': 'Texas', 'country': 'United States'},
            },
          ],
        }),
        200,
      );
    });
  });

  tearDown(() async {
    await testDb.close();
  });

  Widget buildTestableScreen({
    required Widget child,
    required ThemeData theme,
    List<Override> extraOverrides = const [],
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(testDb),
        syncSettingsHttpClientProvider.overrideWithValue(mockHttpClient),
        vexEventsClientProvider.overrideWithValue(
          VexEventsClient(
            client: mockHttpClient,
            serverUrl: 'https://test.roboref.app',
          ),
        ),
        eventCacheServiceProvider.overrideWithValue(
          EventCacheService(prefs),
        ),
        ...extraOverrides,
      ],
      child: MaterialApp(
        theme: theme,
        builder: (context, widget) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: widget!,
          );
        },
        home: child,
      ),
    );
  }

  // ===========================================================================
  // 1. FLUTTER ACCESSIBILITY GUIDELINES (TAP TARGETS, LABELS, CONTRAST)
  // ===========================================================================
  for (final themeEntry in {
    'Light Theme': AppTheme.lightTheme,
    'Dark Theme': AppTheme.darkTheme,
  }.entries) {
    final themeName = themeEntry.key;
    final themeData = themeEntry.value;

    group('WCAG & Material Accessibility Guidelines ($themeName)', () {
      testWidgets('HomeScreen (with recent & shared events) meets all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const HomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Recent Tournaments'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      });

      testWidgets('EventSelectionScreen (with active filters & events) meets all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const EventSelectionScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Activate a filter so the "Reset Filters" button is also rendered and audited
        await tester.tap(find.widgetWithText(FilterChip, 'V5RC'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Filters'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('MatchScheduleScreen and Match Details Sheet meet all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const MatchScheduleScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await expectMeetsAllAccessibilityGuidelines(tester);

        // Open Match Details Modal Sheet
        await tester.tap(find.text('Q 12'));
        await tester.pumpAndSettle();

        expect(find.text('Qualification 12'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('TeamListScreen and Team History Sheet meet all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const TeamListScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await expectMeetsAllAccessibilityGuidelines(tester);

        // Open Team History Modal Sheet
        await tester.tap(find.text('1114A'));
        await tester.pumpAndSettle();

        expect(find.text('Team 1114A History'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('IncidentLoggerScreen, AddIncidentSheet, and RuleSelectionSheet meet all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const IncidentLoggerScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await expectMeetsAllAccessibilityGuidelines(tester);

        // Open AddIncidentSheet
        await tester.tap(find.text('Add Note'));
        await tester.pumpAndSettle();

        expect(find.text('New Note'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);

        // Open RuleSelectionSheet
        final showMoreRules = find.widgetWithText(OutlinedButton, 'Show More Rules');
        await tester.ensureVisible(showMoreRules);
        await tester.tap(showMoreRules);
        await tester.pumpAndSettle();

        expect(find.text('Select Rule Violations'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('RulesScreen (with disclaimer banner and Rule Details sheet) meets all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const RulesScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('DISCLAIMER:'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);

        // Open Rule Details Modal Sheet
        await tester.tap(find.text('<SG1>'));
        await tester.pumpAndSettle();

        expect(find.text('Search Q&A'), findsOneWidget);
        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('SettingsScreen (Event Manage Mode with sharing enabled) meets all guidelines', (tester) async {
        final sharedState = EventShareState(
          sku: 'RE-V5RC-26-4487',
          isShared: true,
          shareId: 'ABC123',
          role: ShareRole.admin,
          adminRefereeName: 'Head Referee Jane',
          participants: [
            ShareParticipantModel(
              deviceId: 'test-device-uuid',
              refereeName: 'Head Referee Jane',
              role: ShareRole.admin,
              joinedAt: 1000,
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            extraOverrides: [
              shareControllerProvider.overrideWith(() => _FakeShareController(sharedState)),
            ],
            child: const SettingsScreen(
              showAppBar: true,
              isEventManagePage: true,
              eventSku: 'RE-V5RC-26-4487',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('ShareScreen meets all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const ShareScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('EventShareSheet (Local Only, Conflict, and Shared Admin states) meets all guidelines', (tester) async {
        // 1. Local Only state
        const localState = EventShareState(
          sku: 'RE-V5RC-26-4487',
          isShared: false,
        );

        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            extraOverrides: [
              shareControllerProvider.overrideWith(() => _FakeShareController(localState)),
            ],
            child: const Scaffold(
              body: EventShareSheet(sku: 'RE-V5RC-26-4487'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectMeetsAllAccessibilityGuidelines(tester);

        // 2. Conflict state
        final conflictState = EventShareState(
          sku: 'RE-V5RC-26-4487',
          isShared: false,
          isConflict: true,
          existingShares: [
            ActiveShareSummary(
              id: 'XYZ789',
              sku: 'RE-V5RC-26-4487',
              adminRefereeName: 'Other Head Ref',
              participantCount: 2,
              createdAt: 1000,
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            extraOverrides: [
              shareControllerProvider.overrideWith(() => _FakeShareController(conflictState)),
            ],
            child: const Scaffold(
              body: EventShareSheet(sku: 'RE-V5RC-26-4487'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectMeetsAllAccessibilityGuidelines(tester);

        // 3. Shared Online Admin state
        final sharedAdminState = EventShareState(
          sku: 'RE-V5RC-26-4487',
          isShared: true,
          shareId: 'ABC123',
          role: ShareRole.admin,
          adminRefereeName: 'Head Referee Jane',
          participants: [
            ShareParticipantModel(
              deviceId: 'test-device-uuid',
              refereeName: 'Head Referee Jane',
              role: ShareRole.admin,
              joinedAt: 1000,
            ),
            ShareParticipantModel(
              deviceId: 'peer-device-uuid',
              refereeName: 'Scorekeeper Bob',
              role: ShareRole.member,
              joinedAt: 1100,
            ),
          ],
        );

        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            extraOverrides: [
              shareControllerProvider.overrideWith(() => _FakeShareController(sharedAdminState)),
            ],
            child: const Scaffold(
              body: EventShareSheet(sku: 'RE-V5RC-26-4487'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectMeetsAllAccessibilityGuidelines(tester);
      });

      testWidgets('EventImportSheet, ChangeLogScreen, and PrivacyPolicyScreen meet all guidelines', (tester) async {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const Scaffold(body: EventImportSheet()),
          ),
        );
        await tester.pumpAndSettle();
        await expectMeetsAllAccessibilityGuidelines(tester);

        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const ChangeLogScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await expectMeetsAllAccessibilityGuidelines(tester);

        await tester.pumpWidget(
          buildTestableScreen(
            theme: themeData,
            child: const PrivacyPolicyScreen(),
          ),
        );
        await tester.pumpAndSettle();
        await expectMeetsAllAccessibilityGuidelines(tester);
      });
    });
  }

  // ===========================================================================
  // 2. LARGE TEXT SCALING (200% FONT SIZE / WCAG 1.4.4 RESIZE TEXT)
  // ===========================================================================
  group('200% Text Scaling & Reflow (WCAG 1.4.4 & 1.4.10)', () {
    const mobileSize = Size(390, 844);
    const scale200 = TextScaler.linear(2.0);

    void configureMobileViewport(WidgetTester tester) {
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('HomeScreen scales all text (including RoboRef.app brand title) at 200% without overflow', (tester) async {
      configureMobileViewport(tester);

      // Measure title height at 100% scale
      await tester.pumpWidget(
        buildTestableScreen(
          theme: AppTheme.lightTheme,
          textScaler: TextScaler.noScaling,
          child: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final unscaledTitleHeight = tester.getSize(find.textContaining('RoboRef', findRichText: true).first).height;

      // Pump at 200% scale
      await tester.pumpWidget(
        buildTestableScreen(
          theme: AppTheme.lightTheme,
          textScaler: scale200,
          child: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final scaledTitleHeight = tester.getSize(find.textContaining('RoboRef', findRichText: true).first).height;
      expect(
        scaledTitleHeight,
        greaterThan(unscaledTitleHeight * 1.4),
        reason: 'RoboRef.app brand title must respect MediaQuery textScaler (use Text.rich instead of raw RichText)',
      );
    });

    testWidgets('EventSelectionScreen Reset Filters button does not collide with Region/Division chips at 200% scale', (tester) async {
      configureMobileViewport(tester);

      await tester.pumpWidget(
        buildTestableScreen(
          theme: AppTheme.lightTheme,
          textScaler: scale200,
          child: const EventSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select a program so "Reset Filters" appears
      await tester.tap(find.widgetWithText(FilterChip, 'V5RC'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final regionChipRect = tester.getRect(find.widgetWithText(FilterChip, 'All Regions'));
      final resetBtnRect = tester.getRect(find.text('Reset Filters'));

      expect(
        regionChipRect.overlaps(resetBtnRect),
        isFalse,
        reason: 'Reset Filters button must not overlap the Region FilterChip on narrow/scaled screens',
      );
    });

    testWidgets('All workspace tabs and modal sheets render at 200% text scale without layout overflow', (tester) async {
      configureMobileViewport(tester);

      final screens = <Widget>[
        const MatchScheduleScreen(),
        const TeamListScreen(),
        const IncidentLoggerScreen(),
        const RulesScreen(),
        const SettingsScreen(isEventManagePage: true, eventSku: 'RE-V5RC-26-4487'),
        const ShareScreen(),
        const Scaffold(body: AddIncidentSheet(initialMatch: 'Q12', initialTeam: '1114A')),
      ];

      for (final screen in screens) {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: AppTheme.lightTheme,
            textScaler: scale200,
            child: screen,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${screen.runtimeType} overflowed at 200% text scale');
      }
    });
  });

  // ===========================================================================
  // 3. SCREEN READER SEMANTICS & NON-COLOR REDUNDANCY
  // ===========================================================================
  group('Screen Reader Semantics & Assistive Tech Announcements', () {
    testWidgets('Match Details Sheet exposes Red/Blue alliance information in text or semantics (WCAG 1.4.1 Use of Color)', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: AppTheme.lightTheme,
            child: const MatchScheduleScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Q 12'));
        await tester.pumpAndSettle();

        final redTeamCard = find.byKey(const ValueKey('match_team_1114A'));
        final blueTeamCard = find.byKey(const ValueKey('match_team_217A'));
        expect(redTeamCard, findsOneWidget);
        expect(blueTeamCard, findsOneWidget);

        // Check that Red and Blue alliance membership is communicated via text or semantics inside the card
        final redCardSemantics = tester.getSemantics(redTeamCard);
        final blueCardSemantics = tester.getSemantics(blueTeamCard);

        final hasRedTextOrSemantics =
            find.descendant(of: redTeamCard, matching: find.textContaining(RegExp(r'RED', caseSensitive: false))).evaluate().isNotEmpty ||
            redCardSemantics.label.toUpperCase().contains('RED');
        final hasBlueTextOrSemantics =
            find.descendant(of: blueTeamCard, matching: find.textContaining(RegExp(r'BLUE', caseSensitive: false))).evaluate().isNotEmpty ||
            blueCardSemantics.label.toUpperCase().contains('BLUE');

        expect(
          hasRedTextOrSemantics,
          isTrue,
          reason: 'Team card 1114A in Match Details Sheet must indicate Red Alliance via text or semantic label, not color alone',
        );
        expect(
          hasBlueTextOrSemantics,
          isTrue,
          reason: 'Team card 217A in Match Details Sheet must indicate Blue Alliance via text or semantic label, not color alone',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('TeamListScreen rank avatars expose clear semantic labels (e.g. "Rank 1st", "Unranked")', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: AppTheme.lightTheme,
            child: const TeamListScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(RegExp(r'Rank 1st', caseSensitive: false)),
          findsOneWidget,
          reason: 'Ranked team avatar should expose a unified "Rank 1st" semantic label',
        );
        expect(
          find.bySemanticsLabel(RegExp(r'Unranked', caseSensitive: false)),
          findsOneWidget,
          reason: 'Unranked team avatar ("-") should expose "Unranked" semantic label instead of reading "hyphen/dash"',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('QR codes in ShareScreen and EventShareSheet expose descriptive image semantics', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: AppTheme.lightTheme,
            child: const ShareScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final qrFinder = find.byType(QrImageView);
        expect(qrFinder, findsOneWidget);

        final qrSemantics = tester.getSemantics(qrFinder);
        expect(
          qrSemantics.label.toLowerCase().contains('qr code'),
          isTrue,
          reason: 'QrImageView must be wrapped in Semantics with a descriptive "QR code..." label',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('RuleSelectionSheet merges checkbox and row semantics so each rule is a single focusable toggle', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        final ruleset = getGameRuleset('V5RC', '2026-2027');
        await tester.pumpWidget(
          buildTestableScreen(
            theme: AppTheme.lightTheme,
            child: Scaffold(
              body: RuleSelectionSheet(
                ruleset: ruleset,
                initialSelectedRules: const {'<SG1>'},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Filter to a single rule (SG1)
        await tester.enterText(
          find.widgetWithText(TextField, 'Search by rule code (SG1, GG2...) or summary...'),
          'SG1',
        );
        await tester.pumpAndSettle();

        final sg1Card = find.ancestor(of: find.text('<SG1>'), matching: find.byType(Card));
        expect(sg1Card, findsOneWidget);

        // Collect all interactive semantic nodes inside the SG1 card
        final cardElement = tester.element(sg1Card);
        final interactiveNodes = <SemanticsNode>[];
        void visit(SemanticsNode node) {
          final data = node.getSemanticsData();
          if (data.hasAction(SemanticsAction.tap)) {
            interactiveNodes.add(node);
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        final rootSemantics = cardElement.renderObject?.debugSemantics;
        if (rootSemantics != null) {
          visit(rootSemantics);
        }

        expect(
          interactiveNodes.length,
          equals(1),
          reason: 'Each rule card in RuleSelectionSheet should expose exactly 1 tappable semantics node (use MergeSemantics or IgnorePointer on Checkbox)',
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Dynamic status regions expose liveRegion semantics (WCAG 4.1.3 Status Messages)', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          buildTestableScreen(
            theme: AppTheme.lightTheme,
            child: const EventSelectionScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final summaryFinder = find.textContaining('Found ');
        expect(summaryFinder, findsOneWidget);

        final summarySemantics = tester.getSemantics(summaryFinder);
        expect(
          summarySemantics.getSemanticsData().hasFlag(SemanticsFlag.isLiveRegion),
          isTrue,
          reason: 'EventSelectionScreen search summary should be wrapped in Semantics(liveRegion: true)',
        );
      } finally {
        handle.dispose();
      }
    });
  });

  // ===========================================================================
  // 4. WEB / PWA (app/web/index.html) ACCESSIBILITY AUDIT
  // ===========================================================================
  group('Web HTML & Viewport Accessibility (web/index.html)', () {
    late String indexHtml;

    setUpAll(() {
      final file = File('web/index.html');
      indexHtml = file.existsSync()
          ? file.readAsStringSync()
          : File('app/web/index.html').readAsStringSync();
    });

    test('<html> element declares lang="en" attribute (WCAG 3.1.1)', () {
      expect(
        RegExp(r'<html[^>]*\blang\s*=\s*["\x27]en["\x27]', caseSensitive: false).hasMatch(indexHtml),
        isTrue,
        reason: 'web/index.html <html> tag must include lang="en"',
      );
    });

    test('viewport meta tag allows pinch-to-zoom and does not lock maximum-scale=1.0 (WCAG 1.4.4)', () {
      final viewportMatch = RegExp(
        r'<meta[^>]*name\s*=\s*["\x27]viewport["\x27][^>]*>',
        caseSensitive: false,
      ).firstMatch(indexHtml);
      expect(viewportMatch, isNotNull);

      final viewportTag = viewportMatch!.group(0)!.toLowerCase();
      expect(
        viewportTag.contains('user-scalable=no'),
        isFalse,
        reason: 'Viewport meta tag must not disable pinch-to-zoom (user-scalable=no)',
      );
      expect(
        viewportTag.contains('maximum-scale=1.0') || viewportTag.contains('maximum-scale=1'),
        isFalse,
        reason: 'Viewport meta tag must not restrict maximum-scale to 1.0',
      );
    });

    test('splash status element includes aria-live="polite" and CSS respects prefers-reduced-motion', () {
      expect(
        indexHtml.contains('aria-live="polite"'),
        isTrue,
        reason: '#splash-status should include aria-live="polite" so screen readers announce loading updates',
      );
      expect(
        indexHtml.contains('prefers-reduced-motion'),
        isTrue,
        reason: 'web/index.html CSS should include @media (prefers-reduced-motion: reduce)',
      );
    });
  });
}
