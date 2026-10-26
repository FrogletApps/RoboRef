import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/core/utils/sku_utils.dart';
import 'package:roboref/features/event_selection/state/event_controller.dart';
import 'package:roboref/features/event_workspace/screens/event_workspace_screen.dart';
import 'package:roboref/features/sharing/services/share_client.dart';
import 'package:roboref/features/sharing/widgets/event_share_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareClient Network Tests', () {
    test('getServerTypeDisplayName categorizes cloud and other servers properly', () {
      expect(getServerTypeDisplayName('https://roboref.app'), equals('RoboRef Cloud Server'));
      expect(getServerTypeDisplayName('https://test.roboref.app'), equals('RoboRef Cloud Server'));
      expect(getServerTypeDisplayName('https://my-worker.workers.dev'), equals('RoboRef Cloud Server'));
      expect(getServerTypeDisplayName('http://localhost:8080'), equals('Other Server'));
      expect(getServerTypeDisplayName('http://roboref.local:8080'), equals('Other Server'));
      expect(getServerTypeDisplayName('http://192.168.1.50:8080'), equals('Other Server'));
    });

    test('buildJoinUrl constructs correct URLs for test, prod, and custom servers', () {
      // 1. Test server URL -> targets test.roboref.app
      expect(
        buildJoinUrl(
          shareId: 'ABC123',
          sku: 'RE-VRC-24-1234',
          serverUrl: 'https://test.roboref.app',
        ),
        equals('https://test.roboref.app?joinShare=ABC123&sku=RE-VRC-24-1234'),
      );

      // 2. Test environment with cloud server -> targets test.roboref.app
      expect(
        buildJoinUrl(
          shareId: 'XYZ789',
          sku: 'RE-VRC-24-9999',
          serverUrl: 'https://roboref.app',
          environment: AppEnvironment.test,
        ),
        equals('https://test.roboref.app?joinShare=XYZ789&sku=RE-VRC-24-9999'),
      );

      // 3. Web origin with test domain -> targets test.roboref.app
      expect(
        buildJoinUrl(
          shareId: 'TEST01',
          sku: 'RE-VRC-24-5555',
          serverUrl: 'https://roboref.app',
          webOrigin: 'https://test.roboref.app',
          isWeb: true,
        ),
        equals('https://test.roboref.app?joinShare=TEST01&sku=RE-VRC-24-5555'),
      );

      // 4. Production cloud server -> targets roboref.app
      expect(
        buildJoinUrl(
          shareId: 'ABC123',
          sku: 'RE-VRC-24-1234',
          serverUrl: 'https://roboref.app',
          environment: AppEnvironment.production,
        ),
        equals('https://roboref.app?joinShare=ABC123&sku=RE-VRC-24-1234'),
      );

      // 5. Local LAN server -> preserves LAN address without trailing slash
      expect(
        buildJoinUrl(
          shareId: 'LAN123',
          sku: 'RE-VRC-24-1234',
          serverUrl: 'http://192.168.1.100:8080/',
        ),
        equals('http://192.168.1.100:8080?joinShare=LAN123&sku=RE-VRC-24-1234'),
      );

      expect(
        buildJoinUrl(
          shareId: 'LAN456',
          sku: 'RE-VRC-24-1234',
          serverUrl: 'http://roboref.local:8080',
        ),
        equals('http://roboref.local:8080?joinShare=LAN456&sku=RE-VRC-24-1234'),
      );
    });

    test('checkActiveShares parses response list correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/share/check' && request.url.queryParameters['sku'] == 'RE-VRC-24-1234') {
          return http.Response(
            jsonEncode({
              'sku': 'RE-VRC-24-1234',
              'activeShares': [
                {
                  'id': 'ABC123',
                  'sku': 'RE-VRC-24-1234',
                  'adminRefereeName': 'Alice Ref',
                  'participantCount': 2,
                  'createdAt': 1000,
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = ShareClient(baseUrl: 'http://test.local', httpClient: mockClient);
      final list = await client.checkActiveShares('RE-VRC-24-1234');

      expect(list.length, equals(1));
      expect(list[0].id, equals('ABC123'));
      expect(list[0].adminRefereeName, equals('Alice Ref'));
      expect(list[0].participantCount, equals(2));
    });

    test('createShareSession handles success and 409 conflict responses', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        if (body['sku'] == 'CONFLICT-SKU' && body['force'] != true) {
          return http.Response(
            jsonEncode({
              'error': 'SHARE_ALREADY_EXISTS',
              'message': 'A share session already exists hosted by Bob Ref',
              'existingShares': [
                {
                  'id': 'XYZ789',
                  'sku': 'CONFLICT-SKU',
                  'adminRefereeName': 'Bob Ref',
                  'participantCount': 1,
                  'createdAt': 2000,
                }
              ]
            }),
            409,
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'session': {
              'id': 'NEW123',
              'sku': body['sku'],
              'adminDeviceId': body['adminDeviceId'],
              'adminRefereeName': body['adminRefereeName'],
              'createdAt': 3000,
              'updatedAt': 3000,
              'participants': [
                {
                  'deviceId': body['adminDeviceId'],
                  'refereeName': body['adminRefereeName'],
                  'role': 'admin',
                  'joinedAt': 3000,
                }
              ]
            }
          }),
          200,
        );
      });

      final client = ShareClient(baseUrl: 'http://test.local', httpClient: mockClient);

      // 1. Success creation
      final res1 = await client.createShareSession(
        sku: 'NORMAL-SKU',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );
      expect(res1.success, isTrue);
      expect(res1.session?.id, equals('NEW123'));
      expect(res1.session?.participants.length, equals(1));

      // 2. Conflict response
      final res2 = await client.createShareSession(
        sku: 'CONFLICT-SKU',
        adminDeviceId: 'dev-2',
        adminRefereeName: 'Charlie',
      );
      expect(res2.success, isFalse);
      expect(res2.isConflict, isTrue);
      expect(res2.conflictMessage, contains('Bob Ref'));
      expect(res2.existingShares.length, equals(1));
    });

    test('createShareSession handles exceptions and general HTTP errors', () async {
      final mockThrowClient = MockClient((request) async {
        throw Exception('Network connection failed');
      });

      final clientWithException = ShareClient(baseUrl: 'http://test.local', httpClient: mockThrowClient);
      final exceptionResult = await clientWithException.createShareSession(
        sku: 'SKU1',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );

      expect(exceptionResult.success, isFalse);
      expect(exceptionResult.errorMessage, equals('Exception: Network connection failed'));

      final mockErrorClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'INTERNAL_SERVER_ERROR',
          }),
          500,
        );
      });

      final clientWithError = ShareClient(baseUrl: 'http://test.local', httpClient: mockErrorClient);
      final errorResult = await clientWithError.createShareSession(
        sku: 'SKU1',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );

      expect(errorResult.success, isFalse);
      expect(errorResult.errorMessage, equals('INTERNAL_SERVER_ERROR'));
    });

    test('leaveShareSession handles admin block and normal leave', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body);
        if (body['deviceId'] == 'admin-blocked') {
          return http.Response(
            jsonEncode({
              'error': 'ADMIN_CANNOT_LEAVE_WITH_ACTIVE_PARTICIPANTS',
              'message': 'The admin cannot leave while other referees are in the session.',
            }),
            400,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'deleted': true,
            'remainingCount': 0,
          }),
          200,
        );
      });

      final client = ShareClient(baseUrl: 'http://test.local', httpClient: mockClient);

      final blocked = await client.leaveShareSession(shareId: 'S1', deviceId: 'admin-blocked');
      expect(blocked.success, isFalse);
      expect(blocked.isAdminBlocked, isTrue);

      final ok = await client.leaveShareSession(shareId: 'S1', deviceId: 'member-1');
      expect(ok.success, isTrue);
      expect(ok.deleted, isTrue);
    });

    test('leaveShareSession handles exceptions and general HTTP errors', () async {
      final mockThrowClient = MockClient((request) async {
        throw Exception('Network connection failed');
      });

      final clientWithException = ShareClient(baseUrl: 'http://test.local', httpClient: mockThrowClient);
      final exceptionResult = await clientWithException.leaveShareSession(shareId: 'S1', deviceId: 'dev-1');

      expect(exceptionResult.success, isFalse);
      expect(exceptionResult.errorMessage, equals('Exception: Network connection failed'));

      final mockErrorClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'INTERNAL_SERVER_ERROR',
          }),
          500,
        );
      });

      final clientWithError = ShareClient(baseUrl: 'http://test.local', httpClient: mockErrorClient);
      final errorResult = await clientWithError.leaveShareSession(shareId: 'S1', deviceId: 'dev-1');

      expect(errorResult.success, isFalse);
      expect(errorResult.errorMessage, equals('INTERNAL_SERVER_ERROR'));
    });

    test('updateRefereeName sends correct request and parses session with previousNames', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/share/update-name'));
        final body = jsonDecode(request.body);
        expect(body['deviceId'], equals('dev-1'));
        expect(body['refereeName'], equals('New Ref Name'));
        expect(body['shareId'], equals('ABC123'));

        return http.Response(
          jsonEncode({
            'success': true,
            'session': {
              'id': 'ABC123',
              'sku': 'SKU1',
              'adminDeviceId': 'dev-1',
              'adminRefereeName': 'New Ref Name',
              'createdAt': 100,
              'updatedAt': 200,
              'participants': [
                {
                  'deviceId': 'dev-1',
                  'refereeName': 'New Ref Name',
                  'role': 'admin',
                  'joinedAt': 100,
                  'previousNames': ['Old Ref Name'],
                }
              ],
            },
          }),
          200,
        );
      });

      final client = ShareClient(baseUrl: 'http://test.local', httpClient: mockClient);
      final session = await client.updateRefereeName(
        deviceId: 'dev-1',
        refereeName: 'New Ref Name',
        shareId: 'ABC123',
      );

      expect(session, isNotNull);
      expect(session!.adminRefereeName, equals('New Ref Name'));
      expect(session.participants.first.previousNames, equals(['Old Ref Name']));
    });

    test('ShareClient normalizes trailing slashes and missing scheme in baseUrl', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode({
            'success': true,
            'session': {
              'id': 'NORM12',
              'sku': 'RE-VRC-26-1234',
              'adminDeviceId': 'dev-1',
              'adminRefereeName': 'Alice',
              'createdAt': 100,
              'updatedAt': 100,
              'participants': [],
            },
          }),
          200,
        );
      });

      final trailingSlashClient = ShareClient(
        baseUrl: 'https://test.roboref.app/',
        httpClient: mockClient,
      );
      final res1 = await trailingSlashClient.createShareSession(
        sku: 'RE-VRC-26-1234',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );
      expect(res1.success, isTrue);
      expect(capturedUri?.toString(), equals('https://test.roboref.app/api/share/create'));

      final schemeLessClient = ShareClient(
        baseUrl: 'roboref.local:8080/',
        httpClient: mockClient,
      );
      final res2 = await schemeLessClient.createShareSession(
        sku: 'RE-VRC-26-1234',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );
      expect(res2.success, isTrue);
      expect(capturedUri?.toString(), equals('http://roboref.local:8080/api/share/create'));
    });

    test('createShareSession safely handles null, HTML, or missing session payloads without null check errors', () async {
      // 1. JSON "null" body
      final nullBodyClient = ShareClient(
        baseUrl: 'https://test.roboref.app',
        httpClient: MockClient((_) async => http.Response('null', 200)),
      );
      final nullRes = await nullBodyClient.createShareSession(
        sku: 'SKU1',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );
      expect(nullRes.success, isFalse);
      expect(nullRes.errorMessage, isNot(contains('Null check operator')));

      // 2. 200 response with session: null
      final nullSessionClient = ShareClient(
        baseUrl: 'https://test.roboref.app',
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode({'success': true, 'session': null}), 200),
        ),
      );
      final nullSessionRes = await nullSessionClient.createShareSession(
        sku: 'SKU1',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );
      expect(nullSessionRes.success, isFalse);
      expect(nullSessionRes.errorMessage, isNot(contains('Null check operator')));

      // 3. HTML response (e.g. SPA fallback or proxy error)
      final htmlClient = ShareClient(
        baseUrl: 'https://test.roboref.app',
        httpClient: MockClient(
          (_) async => http.Response('<!DOCTYPE html><html><body>Error</body></html>', 502),
        ),
      );
      final htmlRes = await htmlClient.createShareSession(
        sku: 'SKU1',
        adminDeviceId: 'dev-1',
        adminRefereeName: 'Alice',
      );
      expect(htmlRes.success, isFalse);
      expect(htmlRes.errorMessage, contains('502'));
    });
  });

  group('EventShareSheet Widget Tests', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-VRC-24-9999',
        'referee_name': 'Test Head Ref',
        'device_id': 'device-test-123',
        'server_url': 'http://localhost:8080',
      });
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // Seed test event
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'RE-VRC-24-9999',
          name: '2024 VEX National Championship',
          program: 'VRC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Renders Local-Only view with Share Event button by default', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: EventShareSheet(sku: 'RE-VRC-24-9999'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Event Sharing & Sync'), findsOneWidget);
      expect(find.text('RE-VRC-24-9999'), findsWidgets);
      expect(find.text('LOCAL ONLY'), findsOneWidget);
      expect(find.text('Notes are stored entirely locally on this device.'), findsOneWidget);
      expect(find.text('Share Event Online'), findsOneWidget);
      expect(find.text('Enter 6-Digit Share Code'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      await tester.pump(Duration.zero);
    });

    testWidgets('Renders Shared Online Host / Admin view when event is shared', (tester) async {
      // Mark event as shared in DB
      await db.updateEventShareState(
        'RE-VRC-24-9999',
        isShared: true,
        shareId: 'CODE88',
        shareRole: 'admin',
        adminRefereeName: 'Test Head Ref',
        adminDeviceId: 'device-test-123',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: EventShareSheet(sku: 'RE-VRC-24-9999'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sharing: Other Server (Host / Admin)'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('CODE88'), findsOneWidget);
      expect(find.text('Copy Join Link'), findsOneWidget);
      expect(find.text('Close & Delete Share Session'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      await tester.pump(Duration.zero);
    });

    testWidgets('EventShareSheet displays (i) button and opens name history popup', (tester) async {
      await db.updateEventShareState(
        'RE-VRC-24-9999',
        isShared: true,
        shareId: 'CODE88',
        shareRole: 'admin',
        adminRefereeName: 'Head Ref Current',
        adminDeviceId: 'device-test-123',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/share/status') {
          return http.Response(
            jsonEncode({
              'success': true,
              'session': {
                'id': 'CODE88',
                'sku': 'RE-VRC-24-9999',
                'adminDeviceId': 'device-test-123',
                'adminRefereeName': 'Head Ref Current',
                'createdAt': 1000,
                'updatedAt': 2000,
                'participants': [
                  {
                    'deviceId': 'device-test-123',
                    'refereeName': 'Head Ref Current',
                    'role': 'admin',
                    'joinedAt': 1000,
                    'previousNames': ['Initial Ref', 'Ref Level 1'],
                  },
                  {
                    'deviceId': 'device-member-456',
                    'refereeName': 'Field Ref Bob',
                    'role': 'member',
                    'joinedAt': 1100,
                    'previousNames': <String>[],
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: EventShareSheet(sku: 'RE-VRC-24-9999'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Connected Referees section header has info icon
      final headerInfoBtn = find.byTooltip('Referee name history');
      expect(headerInfoBtn, findsOneWidget);

      // Tap the header info icon
      await tester.tap(headerInfoBtn);
      await tester.pumpAndSettle();

      // Popup dialog appears
      expect(find.text('Referee Name History'), findsOneWidget);
      expect(find.text('Head Ref Current'), findsWidgets);
      expect(find.text('Initial Ref'), findsOneWidget);
      expect(find.text('Ref Level 1'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close the popup
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Referee Name History'), findsNothing);

      // Verify individual referee item has info icon
      final refereeInfoBtn = find.byTooltip('Previous names for Head Ref Current');
      expect(refereeInfoBtn, findsOneWidget);

      // Tap referee info button
      await tester.tap(refereeInfoBtn);
      await tester.pumpAndSettle();

      // Individual Name History dialog appears
      expect(find.text('Name History'), findsOneWidget);
      expect(find.text('Current Name: Head Ref Current'), findsOneWidget);
      expect(find.text('Previous names at this event:'), findsOneWidget);
      expect(find.text('Initial Ref'), findsOneWidget);
      expect(find.text('Ref Level 1'), findsOneWidget);

      // Close individual dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Name History'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      await tester.pump(Duration.zero);
    });



    testWidgets('Incident notes stay strictly local when event is not shared', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
      );

      final incidentController = container.read(incidentControllerProvider.notifier);

      // Add a note while event is local only
      await incidentController.addNote(
        teamNumber: '9999A',
        ruleCodes: ['G1'],
        severity: 'minor',
        notes: 'Local incident note',
      );

      // Verify note is saved in SQLite database
      final notes = await db.getUnsyncedNotes();
      expect(notes.length, equals(1));
      expect(notes[0].teamNumber, equals('9999A'));
      expect(notes[0].isSynced, isFalse);

      // Trigger sync manually while unshared - should NOT sync / remains local
      await incidentController.triggerSync();

      final unsyncedAfter = await db.getUnsyncedNotes();
      expect(unsyncedAfter.length, equals(1)); // Still marked unsynced because it was not pushed

      container.dispose();
    });

    testWidgets('EventWorkspaceScreen updates share icon reactively when switching between shared and unshared events', (tester) async {
      // Event 1 is unshared
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'EVENT-LOCAL',
          name: 'Local Tournament',
          program: 'VRC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          isShared: const Value(false),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      // Event 2 is shared with admin role
      await db.upsertEvent(
        EventsCompanion.insert(
          sku: 'EVENT-SHARED',
          name: 'Shared Tournament',
          program: 'VRC',
          season: '2024-2025',
          startDate: '2024-11-10',
          endDate: '2024-11-12',
          isShared: const Value(true),
          shareId: const Value('SHAR12'),
          shareRole: const Value('admin'),
          adminRefereeName: const Value('Head Referee'),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
        ],
      );

      // Set to EVENT-LOCAL
      container.read(syncSettingsProvider.notifier).setSku('EVENT-LOCAL');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EventWorkspaceScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect share_outlined icon for local event
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byIcon(Icons.share), findsNothing);

      // Switch to EVENT-SHARED
      container.read(syncSettingsProvider.notifier).setSku('EVENT-SHARED');
      await tester.pumpAndSettle();

      // Expect active share icon (Icons.share) immediately without tapping
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      await tester.pump(Duration.zero);
    });

    testWidgets('Tapping Share Event Online creates share and persists state even if SKU row was not pre-inserted', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/share/create') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'session': {
                'id': 'NEW777',
                'sku': body['sku'],
                'adminDeviceId': body['adminDeviceId'],
                'adminRefereeName': body['adminRefereeName'],
                'createdAt': 1000,
                'updatedAt': 1000,
                'participants': [
                  {
                    'deviceId': body['adminDeviceId'],
                    'refereeName': body['adminRefereeName'],
                    'role': 'admin',
                    'joinedAt': 1000,
                  }
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          activeEventProvider.overrideWith((ref) => Stream.value(null)),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: EventShareSheet(sku: 'DEMO-UNSEEDED-2026'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Null check operator used on a null value'), findsNothing);
      expect(find.text('Share Event Online'), findsOneWidget);

      await tester.tap(find.text('Share Event Online'));
      await tester.pumpAndSettle();

      expect(find.text('Null check operator used on a null value'), findsNothing);
      expect(find.text('NEW777'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);

      final savedEvent = await db.getEventBySku('DEMO-UNSEEDED-2026');
      expect(savedEvent, isNotNull);
      expect(savedEvent!.isShared, isTrue);
      expect(savedEvent.shareId, equals('NEW777'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      await tester.pump(Duration.zero);
    });
  });

  group('Legacy Database Schema Migration Regression Tests', () {
    testWidgets('Upgrades legacy v2 database missing share columns and shares event without null check error', (tester) async {
      SharedPreferences.setMockInitialValues({
        'current_sku': 'RE-VRC-26-1001',
        'referee_name': 'Head Ref Jane',
        'device_id': 'device-legacy-1',
        'server_url': 'https://test.roboref.app',
      });
      final prefs = await SharedPreferences.getInstance();

      // Simulate a local database originally created before share columns were added,
      // then upgraded to schemaVersion 2 (which previously only added teams.rank).
      final legacyDb = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('''
              CREATE TABLE events (
                sku TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                program TEXT NOT NULL,
                season TEXT NOT NULL,
                start_date TEXT NOT NULL,
                end_date TEXT NOT NULL,
                venue TEXT,
                city TEXT,
                region TEXT,
                is_hidden INTEGER NOT NULL DEFAULT 0,
                updated_at INTEGER NOT NULL
              );
              CREATE TABLE teams (
                team_number TEXT NOT NULL,
                team_name TEXT NOT NULL,
                sku TEXT NOT NULL,
                organization TEXT,
                city TEXT,
                region TEXT,
                country TEXT,
                rank INTEGER,
                PRIMARY KEY (team_number, sku)
              );
              CREATE TABLE matches (
                match_id TEXT NOT NULL,
                sku TEXT NOT NULL,
                division_id INTEGER NOT NULL,
                name TEXT NOT NULL,
                field TEXT,
                scheduled_time TEXT,
                red_teams_json TEXT NOT NULL,
                blue_teams_json TEXT NOT NULL,
                red_score INTEGER,
                blue_score INTEGER,
                PRIMARY KEY (match_id, sku)
              );
              CREATE TABLE incident_notes (
                id TEXT NOT NULL PRIMARY KEY,
                sku TEXT NOT NULL,
                team_number TEXT NOT NULL,
                match_id TEXT,
                rule_codes_json TEXT NOT NULL,
                severity TEXT NOT NULL,
                notes TEXT NOT NULL,
                referee_name TEXT NOT NULL,
                device_id TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                is_deleted INTEGER NOT NULL DEFAULT 0,
                version INTEGER NOT NULL DEFAULT 0,
                is_synced INTEGER NOT NULL DEFAULT 0
              );
              INSERT INTO events (sku, name, program, season, start_date, end_date, updated_at)
              VALUES ('RE-VRC-26-1001', 'Legacy Regional Qualifier', 'V5RC', '2026-2027', '2026-10-25', '2026-10-26', 1000);
              PRAGMA user_version = 2;
            ''');
          },
        ),
      );
      addTearDown(() async => legacyDb.close());

      final migratedEvent = await legacyDb.getEventBySku('RE-VRC-26-1001');
      expect(migratedEvent, isNotNull);
      expect(migratedEvent!.name, equals('Legacy Regional Qualifier'));
      expect(migratedEvent.isShared, isFalse);
      expect(migratedEvent.isHidden, isFalse);

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/share/create') {
          return http.Response(
            jsonEncode({
              'success': true,
              'session': {
                'id': 'MIGR88',
                'sku': 'RE-VRC-26-1001',
                'adminDeviceId': 'device-legacy-1',
                'adminRefereeName': 'Head Ref Jane',
                'createdAt': 2000,
                'updatedAt': 2000,
                'participants': [
                  {
                    'deviceId': 'device-legacy-1',
                    'refereeName': 'Head Ref Jane',
                    'role': 'admin',
                    'joinedAt': 2000,
                  }
                ],
              },
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(legacyDb),
          syncSettingsHttpClientProvider.overrideWithValue(mockClient),
        ],
      );

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: EventShareSheet(sku: 'RE-VRC-26-1001'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Null check operator'), findsNothing);
      expect(find.text('Share Event Online'), findsOneWidget);

      await tester.tap(find.text('Share Event Online'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Null check operator'), findsNothing);
      expect(find.text('Sharing: RoboRef Cloud Server (Host / Admin)'), findsOneWidget);
      expect(find.text('MIGR88'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      await tester.pump(Duration.zero);
    });

    test('Upgrades earliest v1 database (7-column events) and full v2 database idempotently', () async {
      // 1. Earliest v1 schema (missing venue, city, region, is_hidden, share columns, and teams.rank)
      final v1Db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('''
              CREATE TABLE events (
                sku TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                program TEXT NOT NULL,
                season TEXT NOT NULL,
                start_date TEXT NOT NULL,
                end_date TEXT NOT NULL,
                updated_at INTEGER NOT NULL
              );
              CREATE TABLE teams (
                team_number TEXT NOT NULL,
                team_name TEXT NOT NULL,
                sku TEXT NOT NULL,
                organization TEXT,
                city TEXT,
                region TEXT,
                country TEXT,
                PRIMARY KEY (team_number, sku)
              );
              INSERT INTO events (sku, name, program, season, start_date, end_date, updated_at)
              VALUES ('RE-VRC-26-0001', 'Earliest V1 Event', 'V5RC', '2026-2027', '2026-08-23', '2026-08-23', 500);
              PRAGMA user_version = 1;
            ''');
          },
        ),
      );
      addTearDown(() async => v1Db.close());

      final v1Event = await v1Db.getEventBySku('RE-VRC-26-0001');
      expect(v1Event, isNotNull);
      expect(v1Event!.isHidden, isFalse);
      expect(v1Event.isShared, isFalse);

      // 2. Full v2 schema (all 16 event columns + teams.rank already present)
      final fullV2Db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('''
              CREATE TABLE events (
                sku TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                program TEXT NOT NULL,
                season TEXT NOT NULL,
                start_date TEXT NOT NULL,
                end_date TEXT NOT NULL,
                venue TEXT,
                city TEXT,
                region TEXT,
                is_hidden INTEGER NOT NULL DEFAULT 0,
                is_shared INTEGER NOT NULL DEFAULT 0,
                share_id TEXT,
                share_role TEXT,
                admin_referee_name TEXT,
                admin_device_id TEXT,
                updated_at INTEGER NOT NULL
              );
              CREATE TABLE teams (
                team_number TEXT NOT NULL,
                team_name TEXT NOT NULL,
                sku TEXT NOT NULL,
                organization TEXT,
                city TEXT,
                region TEXT,
                country TEXT,
                rank INTEGER,
                PRIMARY KEY (team_number, sku)
              );
              INSERT INTO events (sku, name, program, season, start_date, end_date, is_shared, share_id, share_role, updated_at)
              VALUES ('RE-VRC-26-0002', 'Already Shared V2 Event', 'V5RC', '2026-2027', '2026-10-01', '2026-10-01', 1, 'KEEP12', 'admin', 900);
              PRAGMA user_version = 2;
            ''');
          },
        ),
      );
      addTearDown(() async => fullV2Db.close());

      final v2Event = await fullV2Db.getEventBySku('RE-VRC-26-0002');
      expect(v2Event, isNotNull);
      expect(v2Event!.isShared, isTrue);
      expect(v2Event.shareId, equals('KEEP12'));
      expect(v2Event.shareRole, equals('admin'));
    });
  });
}


