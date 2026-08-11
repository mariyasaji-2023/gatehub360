import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A titled card for a section that has nothing in it yet — a centered
/// outline icon, a short explanation, and a button to fill it in. Used for
/// "Occupancy", and reusable as-is for "Financials" / "Journey" style
/// sections later since they follow the same empty-state layout.
class EmptyStateSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final String buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyStateSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    required this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
              child: Icon(icon, size: 28, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onButtonTap ??
                  () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$buttonLabel — coming soon')),
                      ),
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                foregroundColor: AppColors.text,
              ),
              child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
