import 'package:flutter/material.dart';
import '../models/rent_payment.dart';
import '../services/rent_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import '../widgets/razorpay_payment_sheet.dart';

/// Tenant-facing rent screen — shows every property this signed-in user has
/// linked to their account by entering an owner-shared join code, what's
/// due on each, and lets them pay via Razorpay.
class MyRentScreen extends StatefulWidget {
  const MyRentScreen({super.key});

  @override
  State<MyRentScreen> createState() => _MyRentScreenState();
}

class _MyRentScreenState extends State<MyRentScreen> {
  List<MyRental>? _rentals;
  bool _loading = true;
  String? _error;
  DueMonth? _paying;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _showJoinDialog() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join with code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the code your property owner shared with you.',
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
      final propertyTitle = await RentApi.joinWithCode(code.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(propertyTitle != null ? 'Joined $propertyTitle' : 'Joined')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not join: $e')));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rentals = await RentApi.fetchMyRentals();
      if (!mounted) return;
      setState(() {
        _rentals = rentals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your rent details. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _pay(MyRental rental, DueMonth due) async {
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
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment succeeded but could not be recorded: $e')));
    } finally {
      if (mounted) setState(() => _paying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rent'),
        actions: [
          IconButton(
            onPressed: _joining ? null : _showJoinDialog,
            icon: _joining
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.key_outlined),
            tooltip: 'Join with code',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : (_rentals?.isEmpty ?? true)
                  ? _buildEmpty()
                  : RefreshIndicator(onRefresh: _load, child: _buildList(_rentals!)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "No rentals linked yet. Get the join code from your property owner and enter it here to see and pay your rent.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _joining ? null : _showJoinDialog,
              icon: const Icon(Icons.key_outlined),
              label: const Text('Join with Code'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<MyRental> rentals) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (final rental in rentals) ...[
          DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rental.propertyTitle, style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(rental.propertyLocation, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                const SizedBox(height: 8),
                Text('₹${rental.monthlyRent}/month', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Due', style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (rental.due.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nothing pending — you\'re fully paid up.', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
            )
          else
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
                                onPressed: () => _pay(rental, due),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                                child: const Text('Pay Now', style: TextStyle(fontSize: 12.5)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          if (rental.payments.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('History', style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
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
                      PillBadge(label: payment.methodLabel, color: AppColors.success),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
