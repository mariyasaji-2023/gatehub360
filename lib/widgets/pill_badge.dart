import 'package:flutter/material.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const PillBadge({super.key, required this.label, required this.color, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
