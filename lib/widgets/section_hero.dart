import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHero extends StatelessWidget {
  final String titleStart;
  final String titleHighlight;
  final Color accentColor;
  final Widget? child;

  const SectionHero({
    super.key,
    required this.titleStart,
    required this.titleHighlight,
    required this.accentColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$titleStart ', style: AppFonts.heading(fontSize: 22, height: 1.2)),
                TextSpan(text: titleHighlight, style: AppFonts.heading(fontSize: 22, height: 1.2, color: accentColor)),
              ],
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 16),
            child!,
          ],
        ],
      ),
    );
  }
}
