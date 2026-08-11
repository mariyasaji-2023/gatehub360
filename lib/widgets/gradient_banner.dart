import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A blue gradient card for the one or two things on a screen that deserve
/// top billing — identity (which society you're in) or a trust signal
/// (payments) — everything else stays a plain white DarkCard so the gradient
/// keeps its weight instead of competing with itself.
class GradientBanner extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GradientBanner({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final banner = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDeep],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.brand.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );

    if (onTap == null) return banner;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: banner,
      ),
    );
  }
}
