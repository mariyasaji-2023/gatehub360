import 'package:flutter/material.dart';
import '../data/booking_store.dart';
import '../models/service_offering.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/section_hero.dart';

class ProviderBookingsScreen extends StatelessWidget {
  const ProviderBookingsScreen({super.key});

  (String, Color) _statusMeta(BookingStatus status) => switch (status) {
        BookingStatus.paid => ('Paid', AppColors.brand),
        BookingStatus.pending => ('Pending', AppColors.amber),
        BookingStatus.failed => ('Failed', Colors.redAccent),
      };

  @override
  Widget build(BuildContext context) {
    final bookings = BookingStore.bookings;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHero(
            titleStart: 'Bookings',
            titleHighlight: 'Received',
            accentColor: AppColors.brand,
            child: Text(
              'Demo view — shows every booking made in the app, not just yours, until providers are linked to real accounts.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: bookings.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No bookings yet.',
                        style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bookings.map((b) {
                      final (statusLabel, statusColor) = _statusMeta(b.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DarkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(b.serviceName, style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(statusLabel, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(b.packageName, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(b.amountLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brand)),
                                  Text(_formatDate(b.bookedAt), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day}/${d.month}/${d.year} · $h:$m $ampm';
  }
}
