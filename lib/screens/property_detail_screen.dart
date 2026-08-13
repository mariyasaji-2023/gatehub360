import 'package:flutter/material.dart';
import '../models/property_listing.dart';
import '../models/rent_payment.dart';
import '../services/auth_service.dart' show ApiException;
import '../services/property_api.dart';
import '../services/rent_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import '../widgets/property_photo_gallery.dart';
import '../widgets/property_video_player.dart';
import '../widgets/razorpay_payment_sheet.dart';

Color _modeColor(String mode) => switch (mode) {
      'Rent' => AppColors.amber,
      'Commercial' => AppColors.brandLight,
      _ => AppColors.brand,
    };

class PropertyDetailScreen extends StatefulWidget {
  final MyPropertyListing property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _checkingRental = true;
  MyRental? _rental;
  DueMonth? _paying;
  bool _payingAll = false;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _checkRental();
  }

  // Whether the signed-in user already has this property linked as a
  // tenant — if their account isn't a tenant at all, or the lookup fails,
  // this just quietly falls back to the browse/join view rather than
  // erroring. Drives which of the two page layouts below renders.
  Future<void> _checkRental() async {
    try {
      final rentals = await RentApi.fetchMyRentals();
      final match = rentals.where((r) => r.propertyId == widget.property.id).toList();
      if (!mounted) return;
      setState(() {
        _rental = match.isEmpty ? null : match.first;
        _checkingRental = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _checkingRental = false);
    }
  }

  Future<void> _joinWithCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Join Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the code your property owner shared with you to link this property to your account.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Join code'),
              onSubmitted: (v) => Navigator.of(context).pop(v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Join')),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;

    setState(() => _joining = true);
    try {
      await RentApi.joinWithCode(code.trim(), propertyId: widget.property.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined — here\'s your rent')));
      await _checkRental();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not join: $e')));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _pay(DueMonth due) async {
    final rental = _rental;
    if (rental == null) return;
    setState(() => _paying = due);
    final result = await showRazorpayCheckout(
      context: context,
      description: '${rental.propertyTitle} rent — ${due.label}',
      amountLabel: due.amount.toString(),
    );
    if (!mounted) return;

    if (result.outcome != PaymentOutcome.success) {
      setState(() => _paying = null);
      if (result.outcome == PaymentOutcome.failed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed. Please try again.')));
      }
      return;
    }

    try {
      await RentApi.payRent(rental.tenantId, month: due.month, year: due.year, paymentId: result.paymentId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${due.label} paid')));
      await _checkRental();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment succeeded but could not be recorded: $e')));
    } finally {
      if (mounted) setState(() => _paying = null);
    }
  }

  // One Razorpay checkout for the combined total, then a payRent call per
  // due month against that same paymentId — RentPayment's uniqueness is on
  // (tenant, month, year), not the paymentId, so reusing one payment across
  // several months' records is fine.
  Future<void> _payAll() async {
    final rental = _rental;
    if (rental == null || rental.due.isEmpty) return;
    final total = rental.due.fold<num>(0, (sum, d) => sum + d.amount);

    setState(() => _payingAll = true);
    final result = await showRazorpayCheckout(
      context: context,
      description: '${rental.propertyTitle} rent — ${rental.due.length} month${rental.due.length > 1 ? 's' : ''}',
      amountLabel: total.toString(),
    );
    if (!mounted) return;

    if (result.outcome != PaymentOutcome.success) {
      setState(() => _payingAll = false);
      if (result.outcome == PaymentOutcome.failed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed. Please try again.')));
      }
      return;
    }

    try {
      for (final due in rental.due) {
        await RentApi.payRent(rental.tenantId, month: due.month, year: due.year, paymentId: result.paymentId!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All dues paid')));
      await _checkRental();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment succeeded but could not be fully recorded: $e')));
      await _checkRental();
    } finally {
      if (mounted) setState(() => _payingAll = false);
    }
  }

  Future<void> _openEnquiryForm(BuildContext context) async {
    final phone = await showDialog<String>(
      context: context,
      builder: (_) => const _EnquiryDialog(),
    );
    if (phone == null || !context.mounted) return;

    try {
      await PropertyApi.sendEnquiry(widget.property.id, phone);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The owner has been notified and will contact you soon.')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.property;

    return Scaffold(
      appBar: AppBar(title: Text(d.title, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: _checkingRental
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: _rental != null ? _buildRentalView(d, _rental!) : _buildBrowseView(d),
              ),
      ),
    );
  }

  // --- Not linked yet: the marketplace-style listing a prospective renter
  // would see, plus a box to link up if they already have a join code. ---
  List<Widget> _buildBrowseView(MyPropertyListing d) {
    return [
      if (d.images.isNotEmpty) ...[
        PropertyPhotoGallery(images: d.images),
        const SizedBox(height: 20),
      ],
      if (d.videoUrl != null) ...[
        PropertyVideoPlayer(videoUrl: d.videoUrl!),
        const SizedBox(height: 20),
      ],
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.brand.withValues(alpha: 0.15), AppColors.brand.withValues(alpha: 0.03)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillBadge(label: d.mode, color: _modeColor(d.mode)),
                PillBadge(label: d.type, color: AppColors.brandLight),
              ],
            ),
            const SizedBox(height: 12),
            Text(d.title, style: AppFonts.heading(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              d.bhk == 'N/A' ? '📍 ${d.location} · ${d.sqft} sqft' : '📍 ${d.location} · ${d.bhk} · ${d.sqft} sqft',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Text('₹${d.price}', style: AppFonts.heading(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.brand)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openEnquiryForm(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                child: const Text('Contact Owner'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About This Property', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(d.about, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      DarkCard(
        borderColor: AppColors.brand.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key_outlined, color: AppColors.brand, size: 20),
                const SizedBox(width: 8),
                Text('Renting This Property?', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "If your owner already added you as a tenant here, enter the join code they shared to see and pay your rent.",
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _joining ? null : _joinWithCode,
                icon: _joining
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.key_outlined),
                label: const Text('Enter Join Code'),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // --- Already linked: this is now "your place," not a listing — lead
  // with the actual rent you pay and drop the marketplace framing
  // (asking price, big Contact Owner CTA) that doesn't apply anymore. ---
  List<Widget> _buildRentalView(MyPropertyListing d, MyRental rental) {
    return [
      if (d.images.isNotEmpty) ...[
        PropertyPhotoGallery(images: d.images),
        const SizedBox(height: 20),
      ],
      if (d.videoUrl != null) ...[
        PropertyVideoPlayer(videoUrl: d.videoUrl!),
        const SizedBox(height: 20),
      ],
      DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(d.title, style: AppFonts.heading(fontSize: 19, fontWeight: FontWeight.w800))),
                const PillBadge(label: 'You Rent This', color: AppColors.success),
              ],
            ),
            const SizedBox(height: 10),
            _detailRow(Icons.location_on_outlined, d.location),
            if ((rental.roomNumber ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              _detailRow(Icons.door_front_door_outlined, 'Room ${rental.roomNumber}'),
            ],
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),
            Text('₹${rental.monthlyRent}/month', style: AppFonts.heading(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.brand)),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (rental.due.isEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("Nothing pending — you're fully paid up.", style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
            ),
          ],
        )
      else ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text('Due', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700))),
            Text(
              'Total ₹${rental.due.fold<num>(0, (sum, d) => sum + d.amount)}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (rental.due.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _payingAll
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ElevatedButton.icon(
                    onPressed: _payAll,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Pay All Dues', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
        const SizedBox(height: 10),
        for (final due in rental.due)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DarkCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(due.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('₹${due.amount}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    width: 110,
                    child: _paying == due
                        ? const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: CircularProgressIndicator(strokeWidth: 2))
                        : ElevatedButton(
                            onPressed: () => _pay(due),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                            child: const Text('Pay Now', style: TextStyle(fontSize: 12.5)),
                          ),
                  ),
                ],
              ),
            ),
          ),
      ],
      if (rental.payments.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text('History', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final payment in rental.payments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DarkCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(payment.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('₹${payment.amount}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  PillBadge(label: payment.methodLabel, color: payment.method == 'online' ? AppColors.brand : AppColors.success),
                ],
              ),
            ),
          ),
      ],
      const SizedBox(height: 20),
      DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About This Property', style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(d.about, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6)),
          ],
        ),
      ),
    ];
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
      ],
    );
  }
}

class _EnquiryDialog extends StatefulWidget {
  const _EnquiryDialog();

  @override
  State<_EnquiryDialog> createState() => _EnquiryDialogState();
}

class _EnquiryDialogState extends State<_EnquiryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact Owner'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your phone number and we'll notify the owner so they can reach out to you.",
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Your phone number'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 10 ? 'Enter a valid phone number' : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Notify Owner')),
      ],
    );
  }
}
