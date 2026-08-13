import 'package:flutter/material.dart';

import '../models/property_complaint.dart';
import '../services/rent_api.dart';
import '../theme/app_theme.dart';

/// Lets a tenant raise a maintenance complaint against a property they rent
/// - opened from a "Report an Issue" button on their rental card in My Rent.
class RaiseComplaintScreen extends StatefulWidget {
  final String tenantId;
  final String propertyTitle;

  const RaiseComplaintScreen({super.key, required this.tenantId, required this.propertyTitle});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ComplaintLocation? _location;
  ComplaintCategory? _category;
  bool _urgent = false;
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<ComplaintCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionSheet<ComplaintCategory>(
        title: 'Issue Type',
        options: ComplaintCategory.values.map((c) => (c, c.label)).toList(),
        selected: _category,
      ),
    );
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickLocation() async {
    final picked = await showModalBottomSheet<ComplaintLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionSheet<ComplaintLocation>(
        title: 'Found at',
        options: ComplaintLocation.values.map((l) => (l, l.label)).toList(),
        selected: _location,
      ),
    );
    if (picked != null) setState(() => _location = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an issue type')));
      return;
    }
    setState(() => _saving = true);
    try {
      await RentApi.raiseComplaint(
        widget.tenantId,
        description: _descriptionController.text.trim(),
        category: _category!,
        location: _location,
        urgent: _urgent,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted — the owner has been notified.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit complaint: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Raise a Complaint'),
            Text(widget.propertyTitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Description', hintText: "Please explain the issue you're facing…"),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe the issue' : null,
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _row(label: 'Issue Type', value: _category?.label ?? 'Select issue type', placeholder: _category == null, onTap: _pickCategory),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _row(label: 'Found at', value: _location?.label ?? 'Select location', placeholder: _location == null, onTap: _pickLocation),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Urgent?', style: TextStyle(fontSize: 13, color: AppColors.muted))),
                        Switch(value: _urgent, activeColor: AppColors.danger, onChanged: (v) => setState(() => _urgent = v)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Complaint', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({required String label, required String value, required bool placeholder, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: placeholder ? AppColors.muted : AppColors.text)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _OptionSheet<T> extends StatelessWidget {
  final String title;
  final List<(T, String)> options;
  final T? selected;

  const _OptionSheet({required this.title, required this.options, this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final (value, label) = options[i];
                  final isSelected = value == selected;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.brand : AppColors.text)),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.brand, size: 18) : null,
                    onTap: () => Navigator.of(context).pop(value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
