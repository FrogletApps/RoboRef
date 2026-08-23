import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:roboref/features/home/screens/share_screen.dart';

void main() {
  testWidgets('ShareScreen renders actual QrImageView linking to https://roboref.fyi', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ShareScreen(),
      ),
    );

    // Verify Title and Text
    expect(find.text('Share RoboRef'), findsOneWidget);
    expect(find.text('https://roboref.fyi'), findsNWidgets(2)); // Card and copy bar
    expect(find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains('RoboRef.fyi')), findsOneWidget);

    // Verify QrImageView is present
    final qrFinder = find.byType(QrImageView);
    expect(qrFinder, findsOneWidget);

    final shareScreen = tester.widget<ShareScreen>(find.byType(ShareScreen));
    expect(shareScreen.shareUrl, equals('https://roboref.fyi'));

    // Verify Copy Link button
    expect(find.text('Copy Link'), findsOneWidget);
  });
}
