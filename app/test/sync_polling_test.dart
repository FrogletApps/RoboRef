import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_workspace/screens/event_workspace_screen.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'current_sku': 'RE-V5RC-24-9999',
      'referee_name': 'Head Ref Bob',
      'device_id': 'test-device-uuid',
      'server_url': 'http://localhost:8080',
    });
    prefs = await SharedPreferences.getInstance();

    db = AppDatabase.forTesting(
      drift.DatabaseConnection(NativeDatabase.memory()),
    );

    // Insert dummy event
    await db.upsertEvent(
      EventsCompanion(
        sku: const drift.Value('RE-V5RC-24-9999'),
        name: const drift.Value('National Championship'),
        program: const drift.Value('V5RC'),
        season: const drift.Value('2024-2025'),
        startDate: const drift.Value('2025-03-01'),
        endDate: const drift.Value('2025-03-02'),
        updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        isShared: const drift.Value(true),
        shareId: const drift.Value('SHARE1'),
        shareRole: const drift.Value('admin'),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Sync Polling & Delta Version Tests', () {
    test('AppDatabase.getLatestNoteVersion returns 0 when no notes exist', () async {
      final ver = await db.getLatestNoteVersion('RE-V5RC-24-9999');
      expect(ver, 0);
    });

    test('AppDatabase.getLatestNoteVersion returns the highest version for the SKU', () async {
      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const drift.Value('note-1'),
          sku: const drift.Value('RE-V5RC-24-9999'),
          teamNumber: const drift.Value('1111A'),
          ruleCodesJson: drift.Value(jsonEncode(['G1'])),
          severity: const drift.Value('minor'),
          notes: const drift.Value('Note 1'),
          refereeName: const drift.Value('Bob'),
          deviceId: const drift.Value('dev-1'),
          createdAt: const drift.Value(1000),
          updatedAt: const drift.Value(1000),
          isDeleted: const drift.Value(false),
          version: const drift.Value(3),
          isSynced: const drift.Value(true),
        ),
      );

      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const drift.Value('note-2'),
          sku: const drift.Value('RE-V5RC-24-9999'),
          teamNumber: const drift.Value('2222B'),
          ruleCodesJson: drift.Value(jsonEncode(['G2'])),
          severity: const drift.Value('warning'),
          notes: const drift.Value('Note 2'),
          refereeName: const drift.Value('Bob'),
          deviceId: const drift.Value('dev-1'),
          createdAt: const drift.Value(2000),
          updatedAt: const drift.Value(2000),
          isDeleted: const drift.Value(false),
          version: const drift.Value(7),
          isSynced: const drift.Value(true),
        ),
      );

      // Note for another SKU shouldn't count
      await db.into(db.incidentNotes).insert(
        IncidentNotesCompanion(
          id: const drift.Value('note-3'),
          sku: const drift.Value('OTHER-SKU'),
          teamNumber: const drift.Value('3333C'),
          ruleCodesJson: drift.Value(jsonEncode(['G3'])),
          severity: const drift.Value('major'),
          notes: const drift.Value('Note 3'),
          refereeName: const drift.Value('Bob'),
          deviceId: const drift.Value('dev-1'),
          createdAt: const drift.Value(3000),
          updatedAt: const drift.Value(3000),
          isDeleted: const drift.Value(false),
          version: const drift.Value(20),
          isSynced: const drift.Value(true),
        ),
      );

      final ver = await db.getLatestNoteVersion('RE-V5RC-24-9999');
      expect(ver, 7);
    });

    testWidgets('EventWorkspaceScreen starts periodic polling and handles tab changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            databaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: EventWorkspaceScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial workspace loaded
      expect(find.byType(EventWorkspaceScreen), findsOneWidget);

      // Verify switching to Teams tab (index 1) triggers quiet sync check without error
      await tester.tap(find.text('Teams'));
      await tester.pumpAndSettle();

      // Verify switching to Incidents tab (index 2) triggers quiet sync check without error
      await tester.tap(find.text('Incidents'));
      await tester.pumpAndSettle();

      // Fast-forward 60 seconds to simulate a periodic background polling tick
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();

      // Clean up and unmount to trigger dispose()
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
