import 'package:flutter/material.dart';
import '../data/booking_store.dart';
import '../models/service_offering.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  (String, Color) _statusMeta(BookingStatus status) => switch (status) {
        BookingStatus.paid => ('Paid', AppColors.brand),
        BookingStatus.pending => ('Pending', AppColors.amber),
        BookingStatus.failed => ('Failed', Colors.redAccent),
      };

  @override
  Widget build(BuildContext context) {
    final bookings = BookingStore.bookings;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: SafeArea(
        child: bookings.isEmpty
            ? Center(
                child: Text(
                  "You haven't booked any services yet.",
                  style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: bookings.length,
                itemBuilder: (context, i) {
                  final b = bookings[i];
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
                          Text('${b.packageName} · with ${b.providerName}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(b.amountLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brand)),
                              Text(_formatDate(b.bookedAt), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                            ],
                          ),
                          if (b.paymentId != null) ...[
                            const SizedBox(height: 6),
                            Text('Payment ID: ${b.paymentId}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
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
