import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roboref/features/incidents/screens/incident_logger_screen.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/incidents/state/incident_controller.dart';

void main() {
  testWidgets('IncidentLoggerScreen delete IconButton has tooltip "Delete Note"', (WidgetTester tester) async {
    final note = IncidentNote(
      id: 'note-1',
      sku: 'RE-VRC-24-0001',
      teamNumber: '1234A',
      matchId: 'Q1',
      ruleCodesJson: '["G1"]',
      severity: 'minor',
      notes: 'Minor rule warning',
      refereeName: 'Ref 1',
      deviceId: 'dev1',
      isDeleted: false,
      isSynced: true,
      version: 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTournamentNotesProvider.overrideWithValue(AsyncValue.data([note])),
        ],
        child: const MaterialApp(
          home: IncidentLoggerScreen(showAppBar: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final deleteButtonFinder = find.byTooltip('Delete Note');
    expect(deleteButtonFinder, findsOneWidget);

    final iconButtonFinder = find.ancestor(
      of: find.byIcon(Icons.delete_outline),
      matching: find.byType(IconButton),
    );
    expect(iconButtonFinder, findsOneWidget);

    final iconButton = tester.widget<IconButton>(iconButtonFinder);
    expect(iconButton.tooltip, equals('Delete Note'));
  });
}
