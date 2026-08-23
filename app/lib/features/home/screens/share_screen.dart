import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  final String shareUrl = 'https://roboref.fyi';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share RoboRef'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo & Title
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icons/roboref-512x512.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: const [
                      TextSpan(text: 'RoboRef'),
                      TextSpan(
                        text: '.fyi',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Scan the QR code below or share the link with head referees, alliance referees, and scorekeepers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13.5),
                ),
                const SizedBox(height: 28),

                // QR Code Display Card
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Custom styled QR-like visual code representation
                        CustomPaint(
                          size: const Size(200, 200),
                          painter: _QrCodePainter(),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'https://roboref.fyi',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Share Link Actions
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'https://roboref.fyi',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('RoboRef link copied to clipboard!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Link'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cell = size.width / 21;

    // Corner 1 (Top-Left)
    _drawFinderPattern(canvas, paint, 0, 0, cell);
    // Corner 2 (Top-Right)
    _drawFinderPattern(canvas, paint, 14 * cell, 0, cell);
    // Corner 3 (Bottom-Left)
    _drawFinderPattern(canvas, paint, 0, 14 * cell, cell);

    // Decorative data grid dots for QR representation
    final sampleDots = [
      const Point(8, 2), const Point(9, 2), const Point(11, 2), const Point(12, 2),
      const Point(8, 4), const Point(10, 4), const Point(12, 4),
      const Point(2, 8), const Point(4, 8), const Point(6, 8), const Point(8, 8),
      const Point(10, 8), const Point(14, 8), const Point(16, 8), const Point(18, 8),
      const Point(3, 10), const Point(7, 10), const Point(10, 10), const Point(13, 10),
      const Point(17, 10), const Point(5, 12), const Point(8, 12), const Point(11, 12),
      const Point(15, 12), const Point(18, 12), const Point(8, 14), const Point(10, 14),
      const Point(12, 14), const Point(16, 14), const Point(9, 16), const Point(11, 16),
      const Point(13, 16), const Point(17, 16), const Point(8, 18), const Point(12, 18),
      const Point(15, 18), const Point(18, 18),
    ];

    for (final pt in sampleDots) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pt.x * cell, pt.y * cell, cell * 0.9, cell * 0.9),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }
  }

  void _drawFinderPattern(Canvas canvas, Paint paint, double x, double y, double cell) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, 7 * cell, 7 * cell), paint);
    // Inner white square
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + cell, y + cell, 5 * cell, 5 * cell), whitePaint);
    // Center square
    canvas.drawRect(Rect.fromLTWH(x + 2 * cell, y + 2 * cell, 3 * cell, 3 * cell), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);
}
