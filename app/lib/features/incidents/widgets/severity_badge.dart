import 'package:flutter/material.dart';
import '../../../core/l10n/l10n.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    final String label = localizeSeverity(context, severity, uppercaseBadge: true);

    switch (severity.toLowerCase()) {
      case 'disabled':
        bg = Colors.purple.shade700;
        fg = Colors.white;
        break;
      case 'major':
        bg = Colors.red.shade900;
        fg = Colors.white;
        break;
      case 'inspection':
        bg = Colors.teal.shade700;
        fg = Colors.white;
        break;
      case 'minor':
        bg = Colors.yellow.shade600;
        fg = Colors.black87;
        break;
      case 'general':
      default:
        bg = Colors.blueGrey.shade100;
        fg = Colors.blueGrey.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
