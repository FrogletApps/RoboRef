import 'package:flutter/material.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (severity.toLowerCase()) {
      case 'd_q':
      case 'dq':
        bg = Colors.red.shade700;
        fg = Colors.white;
        label = 'DISQUALIFIED';
        break;
      case 'major':
        bg = Colors.deepOrange.shade600;
        fg = Colors.white;
        label = 'MAJOR VIOLATION';
        break;
      case 'warning':
        bg = Colors.amber.shade700;
        fg = Colors.black;
        label = 'WARNING';
        break;
      case 'minor':
      default:
        bg = Colors.blueGrey.shade100;
        fg = Colors.blueGrey.shade900;
        label = 'MINOR';
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
