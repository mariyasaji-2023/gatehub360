import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickAction({required this.icon, required this.label, this.onTap});
}

/// "Quick Actions" style section — a title row with a "View All" link, above
/// a fixed 4-column grid of circular icon shortcuts (wraps to as many rows
/// as needed, no horizontal scrolling). Tapping an action with no `onTap`
/// wired yet just says so, instead of doing nothing.
class QuickActionsSection extends StatelessWidget {
  final String title;
  final List<QuickAction> actions;
  final VoidCallback? onViewAll;

  const QuickActionsSection({super.key, this.title = 'Quick Actions', required this.actions, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Expanded(child: Text(title, style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700))),
              InkWell(
                onTap: onViewAll ??
                    () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon')),
                        ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View All', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 16, color: AppColors.muted),
                  ],
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return Column(
              children: [
                Material(
                  color: AppColors.brand.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: action.onTap ??
                        () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${action.label} — coming soon')),
                            ),
                    child: Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      child: Icon(action.icon, color: AppColors.brand, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.15),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
