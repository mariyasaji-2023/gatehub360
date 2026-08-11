import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The personalized "Hello, {name} / Welcome Back!" strip shown at the top
/// of whichever tab is a role's landing screen — notification shortcut
/// (nullable; screens without an inbox-like feed fall back to a snackbar)
/// and a tappable profile avatar. Shared so every role's first screen greets
/// the same way instead of each screen reinventing it.
class HomeGreetingHeader extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final VoidCallback? onBellTap;
  final VoidCallback onAvatarTap;

  const HomeGreetingHeader({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.onBellTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = (name ?? '').trim().split(RegExp(r'\s+')).first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
    final photo = photoUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty ? 'Hello,' : 'Hello, $firstName',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('Welcome Back!', style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: onBellTap ??
                () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications yet.')),
                    ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.brand,
              backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
              child: (photo == null || photo.isEmpty)
                  ? Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
          child: Icon(icon, size: 20, color: AppColors.text),
        ),
      ),
    );
  }
}
