import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stand-in for a feature that's temporarily on hold — keeps its tab/entry
/// point visible in the nav, but swaps the real screen for this notice
/// instead of removing access outright.
class ComingSoonPlaceholder extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;

  const ComingSoonPlaceholder({
    super.key,
    this.emoji = '🚧',
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
