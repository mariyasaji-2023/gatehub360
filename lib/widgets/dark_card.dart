import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        // On the dark background a shadow alone barely reads as "elevated" —
        // unlike the old light page, so every card gets a subtle border by
        // default. A borderColor still overrides it (e.g. a danger outline
        // on a warning card).
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
