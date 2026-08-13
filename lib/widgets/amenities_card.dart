import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';

/// The amenities a property owner selected, shown as checkmarked chips.
/// Used on both the buyer/tenant-facing property detail page and the
/// owner's own property dashboard.
class AmenitiesCard extends StatelessWidget {
  final List<String> amenities;
  const AmenitiesCard({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amenities', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final amenity in amenities)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: AppColors.brand),
                      const SizedBox(width: 8),
                      Text(amenity, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
