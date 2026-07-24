import 'package:flutter/material.dart';

import '../models/society_bill.dart';
import '../services/auth_service.dart';
import '../services/society_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import '../widgets/razorpay_payment_sheet.dart';

class SocietyBillingScreen extends StatefulWidget {
  const SocietyBillingScreen({super.key});

  @override
  State<SocietyBillingScreen> createState() => _SocietyBillingScreenState();
}

class _SocietyBillingScreenState extends State<SocietyBillingScreen> {
  List<SocietyBill> _bills = [];
  bool _isAssociation = false;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.syncCurrentUser();
      final bills = await SocietyApi.fetchBills();
      if (!mounted) return;
      setState(() {
        _isAssociation = user.role == UserRole.apartmentAssociation;
        _bills = bills;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openGenerateDialog() async {
    final now = DateTime.now();
    final amountController = TextEditingController();
    final result = await showDialog<num>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Generate this month\'s bills'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_monthName(now.month)} ${now.year}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount per flat (₹)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final amount = num.tryParse(amountController.text.trim());
              Navigator.of(context).pop(amount);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (result == null || result <= 0) return;

    try {
      final created = await SocietyApi.generateBills(month: now.month, year: now.year, amount: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $created bill(s)')));
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _toggleAssociationPaidStatus(SocietyBill bill) async {
    try {
      await SocietyApi.setBillStatus(bill.id, !bill.paid);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _payBill(SocietyBill bill) async {
    setState(() => _paying = true);
    final result = await showRazorpayCheckout(
      context: context,
      description: 'Maintenance — ${bill.periodLabel}',
      amountLabel: bill.amount.toString(),
    );
    if (!mounted) return;
    setState(() => _paying = false);

    if (result.outcome != PaymentOutcome.success) {
      if (result.outcome == PaymentOutcome.failed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment failed. Please try again.')));
      }
      return;
    }

    try {
      await SocietyApi.markBillPaid(bill.id, paymentId: result.paymentId);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  String _monthName(int m) => _monthNames[m - 1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing')),
      floatingActionButton: _isAssociation
          ? FloatingActionButton.extended(
              onPressed: _openGenerateDialog,
              icon: const Icon(Icons.receipt_long),
              label: const Text('Generate Bills'),
              backgroundColor: AppColors.brand,
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        if (_bills.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No bills yet.', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
                            ),
                          ),
                        ..._bills.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DarkCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(b.periodLabel, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              '₹${b.amount}',
                                              if (_isAssociation && b.flatNumber?.isNotEmpty == true) 'Flat ${b.flatNumber}',
                                            ].join(' · '),
                                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isAssociation)
                                      GestureDetector(
                                        onTap: () => _toggleAssociationPaidStatus(b),
                                        child: PillBadge(label: b.paid ? 'Paid' : 'Unpaid', color: b.paid ? AppColors.brand : AppColors.amber),
                                      )
                                    else if (b.paid)
                                      const PillBadge(label: 'Paid', color: AppColors.brand)
                                    else
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: _paying ? null : () => _payBill(b),
                                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                                          child: const Text('Pay Now', style: TextStyle(fontSize: 12.5)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
        ),
      ),
    );
  }
}
