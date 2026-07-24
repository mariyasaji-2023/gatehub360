import 'package:flutter/material.dart';
import '../data/booking_store.dart';
import '../data/listings_data.dart';
import '../models/service_offering.dart';
import '../services/auth_service.dart';
import '../services/services_api.dart';
import '../theme/app_theme.dart';
import '../widgets/razorpay_payment_sheet.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String slug;
  const ServiceDetailScreen({super.key, required this.slug});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _pkg = 0;
  int _provider = 0;
  int? _faq;

  List<MyServiceListing> _providers = [];
  bool _loadingProviders = true;
  String? _providersError;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
      _providersError = null;
    });
    try {
      final providers = await ServicesApi.fetchForCategory(widget.slug);
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _provider = 0;
        _loadingProviders = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _providersError = e.message;
        _loadingProviders = false;
      });
    }
  }

  Future<void> _handleBook(ServiceDetail d, ServicePackage pkg, MyServiceListing provider) async {
    if (pkg.price.toLowerCase().contains('quote')) {
      BookingStore.add(Booking(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        serviceName: d.name,
        packageName: pkg.name,
        providerName: provider.providerName ?? 'Provider',
        amountLabel: pkg.price,
        status: BookingStatus.pending,
        bookedAt: DateTime.now(),
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("We'll contact you with a free quote shortly.")),
      );
      return;
    }
    final result = await showRazorpayCheckout(
      context: context,
      description: '${d.name} — ${pkg.name}',
      amountLabel: pkg.price,
    );
    if (!mounted || result.outcome == PaymentOutcome.cancelled) return;

    BookingStore.add(Booking(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      serviceName: d.name,
      packageName: pkg.name,
      providerName: provider.providerName ?? 'Provider',
      amountLabel: pkg.price,
      status: result.outcome == PaymentOutcome.success ? BookingStatus.paid : BookingStatus.failed,
      paymentId: result.paymentId,
      bookedAt: DateTime.now(),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.outcome == PaymentOutcome.success
              ? '${pkg.name} booked with ${provider.providerName} for ${d.name}!'
              : 'Payment failed. Check My Bookings to retry.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = serviceDetailFor(widget.slug);
    final selectedPkg = d.packages[_pkg.clamp(0, d.packages.length - 1)];
    final selectedProvider = _providers.isEmpty ? null : _providers[_provider.clamp(0, _providers.length - 1)];

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: d.color.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 14),
                  Text(d.name, style: AppFonts.heading(fontSize: 22, fontWeight: FontWeight.w800, color: d.color)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('⭐ ${d.rating}', style: const TextStyle(fontSize: 13.5, color: AppColors.amber)),
                      Text('${d.jobs} jobs completed', style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: d.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text('Starts ${d.price}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: d.color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(d.desc, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Providers Offering This', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              "Pick a provider — they'll confirm and reach out once you book.",
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 14),
            if (_loadingProviders)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_providersError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Text(_providersError!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                      const SizedBox(height: 10),
                      OutlinedButton(onPressed: _loadProviders, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else if (_providers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No providers have listed this service yet.',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
              )
            else
              ...List.generate(_providers.length, (i) {
                final p = _providers[i];
                final selected = i == _provider;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: selected ? d.color.withValues(alpha: 0.08) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _provider = i),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? d.color : AppColors.border, width: selected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: d.color.withValues(alpha: 0.15),
                              child: Icon(Icons.person_outline, color: d.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.providerName ?? 'Provider', style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(p.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(p.price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: d.color)),
                                const SizedBox(height: 6),
                                Icon(
                                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: selected ? d.color : AppColors.muted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 10),
            Text('Choose a Package', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...List.generate(d.packages.length, (i) {
              final p = d.packages[i];
              final selected = i == _pkg;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: selected ? d.color.withValues(alpha: 0.08) : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _pkg = i),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? d.color : AppColors.border, width: selected ? 2 : 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(p.price, style: AppFonts.heading(fontSize: 19, fontWeight: FontWeight.w700, color: d.color)),
                          const SizedBox(height: 12),
                          ...p.includes.map((inc) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('✓', style: TextStyle(fontSize: 12.5, color: d.color)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(inc, style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedProvider == null ? null : () => _handleBook(d, selectedPkg, selectedProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: d.color,
                  foregroundColor: d.color == AppColors.brand ? AppColors.brandOnDark : Colors.white,
                ),
                child: Text(
                  selectedProvider == null ? 'No providers available' : 'Book ${selectedPkg.name} — ${selectedPkg.price}',
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Frequently Asked Questions', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...List.generate(d.faqs.length, (i) {
              final f = d.faqs[i];
              final open = _faq == i;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _faq = open ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(f.question, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500))),
                            Icon(open ? Icons.close : Icons.add, size: 18, color: AppColors.muted),
                          ],
                        ),
                      ),
                    ),
                    if (open)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(f.answer, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6)),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
