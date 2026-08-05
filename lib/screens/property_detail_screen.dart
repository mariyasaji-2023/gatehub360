import 'package:flutter/material.dart';
import '../models/property_listing.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

Color _modeColor(String mode) => switch (mode) {
      'Rent' => AppColors.amber,
      'Commercial' => AppColors.brandLight,
      _ => AppColors.brand,
    };

class PropertyDetailScreen extends StatelessWidget {
  final MyPropertyListing property;
  const PropertyDetailScreen({super.key, required this.property});

  Future<void> _openEnquiryForm(BuildContext context) async {
    final phone = await showDialog<String>(
      context: context,
      builder: (_) => const _EnquiryDialog(),
    );
    if (phone == null || !context.mounted) return;

    try {
      await PropertyApi.sendEnquiry(property.id, phone);
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
    final d = property;

    return Scaffold(
      appBar: AppBar(title: Text(d.title, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
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
            const SizedBox(height: 22),
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
          ],
        ),
      ),
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
