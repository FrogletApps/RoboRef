import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull;
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
      expect(find.byIcon(Icons.admin_panel_settings), findsNothing);

      // Switch to EVENT-SHARED
      container.read(syncSettingsProvider.notifier).setSku('EVENT-SHARED');
      await tester.pumpAndSettle();

      // Expect admin shield icon (Icons.admin_panel_settings) immediately without tapping
      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
      await tester.pump(Duration.zero);
    });
  });
}
