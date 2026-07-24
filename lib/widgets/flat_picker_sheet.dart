import 'package:flutter/material.dart';

import '../models/society_flat.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';
import 'pill_badge.dart';

/// A bottom sheet listing a society's flats, letting the caller pick a vacant
/// one (occupied flats are shown but disabled). Used both when a resident
/// joins by invite code, and when an association assigns a flat while
/// approving a join request.
class FlatPickerSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SocietyFlat> flats;
  final String emptyMessage;

  const FlatPickerSheet({
    super.key,
    required this.title,
    this.subtitle = "Pick a flat. Occupied flats are shown but can't be selected.",
    required this.flats,
    this.emptyMessage = 'No flats have been added yet.',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 16),
              if (flats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(emptyMessage, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                )
              else
                ...flats.map((f) {
                  final vacant = f.status == FlatStatus.vacant;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DarkCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: vacant ? () => Navigator.of(context).pop(f) : null,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Flat ${f.flatNumber}',
                              style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700, color: vacant ? AppColors.text : AppColors.muted),
                            ),
                          ),
                          PillBadge(label: f.status.label, color: vacant ? AppColors.success : AppColors.muted),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
