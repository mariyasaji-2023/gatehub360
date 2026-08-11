import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatOverviewItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const StatOverviewItem({required this.icon, required this.value, required this.label, required this.color, this.onTap});
}

/// Horizontally scrollable strip of at-a-glance stat cards — e.g. dues,
/// vacant/occupied beds, active complaints — shown near the top of a
/// management dashboard.
class StatOverviewBar extends StatelessWidget {
  final List<StatOverviewItem> items;

  const StatOverviewBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final card = Container(
            width: 132,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(item.icon, size: 15, color: item.color),
                ),
                const Spacer(),
                Text(item.value, style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ],
            ),
          );
          if (item.onTap == null) return card;
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(borderRadius: BorderRadius.circular(16), onTap: item.onTap, child: card),
          );
        },
      ),
    );
  }
}
