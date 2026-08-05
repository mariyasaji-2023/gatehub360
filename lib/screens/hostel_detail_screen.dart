import 'package:flutter/material.dart';
import '../models/hostel_listing.dart';
import '../services/auth_service.dart';
import '../services/hostel_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

enum _Tab { overview, rooms, amenities }

class HostelDetailScreen extends StatefulWidget {
  final MyHostelListing listing;
  const HostelDetailScreen({super.key, required this.listing});

  @override
  State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  _Tab _tab = _Tab.overview;

  Future<void> _openEnquiryForm() async {
    final phone = await showDialog<String>(
      context: context,
      builder: (_) => const _EnquiryDialog(),
    );
    if (phone == null || !mounted) return;

    try {
      await HostelApi.sendEnquiry(widget.listing.id, phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The owner has been notified and will contact you soon.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.listing;

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
                  Text(d.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PillBadge(label: d.type, color: AppColors.brand),
                      PillBadge(label: d.gender, color: AppColors.brandLight),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(d.title, style: AppFonts.heading(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('📍 ${d.location}', style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: '₹${d.startingPrice}', style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.brand)),
                      const TextSpan(text: '/month onwards', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openEnquiryForm,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                      child: const Text('Contact Owner'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _tabChip(_Tab.overview, 'Overview'),
                const SizedBox(width: 8),
                _tabChip(_Tab.rooms, 'Rooms'),
                const SizedBox(width: 8),
                _tabChip(_Tab.amenities, 'Amenities'),
              ],
            ),
            const SizedBox(height: 18),
            switch (_tab) {
              _Tab.overview => DarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About This Place', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(d.about, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6)),
                    ],
                  ),
                ),
              _Tab.rooms => Column(
                  children: d.rooms
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DarkCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.name, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 6),
                                        Text('${r.available} beds available', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(text: '₹${r.price}', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brand)),
                                      const TextSpan(text: '/mo', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                                    ]),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              _Tab.amenities => d.amenities.isEmpty
                  ? const DarkCard(
                      child: Text('No amenities listed.', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
                    )
                  : GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: d.amenities
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Text('✓', style: TextStyle(color: AppColors.brand, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(a, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
            },
          ],
        ),
      ),
    );
  }

  Widget _tabChip(_Tab t, String label) {
    final selected = _tab == t;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _tab = t),
      selectedColor: AppColors.brand.withValues(alpha: 0.18),
      backgroundColor: AppColors.card,
      labelStyle: TextStyle(color: selected ? AppColors.brandLight : AppColors.muted, fontSize: 13),
      side: BorderSide(color: selected ? AppColors.brand.withValues(alpha: 0.4) : AppColors.border),
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
