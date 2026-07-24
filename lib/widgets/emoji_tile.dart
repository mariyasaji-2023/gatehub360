import 'package:flutter/material.dart';

class EmojiTile extends StatelessWidget {
  final String emoji;
  final Color color;
  final double height;
  final double fontSize;
  final BorderRadius? borderRadius;

  const EmojiTile({
    super.key,
    required this.emoji,
    required this.color,
    this.height = 150,
    this.fontSize = 52,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(emoji, style: TextStyle(fontSize: fontSize)),
    );
  }
}
