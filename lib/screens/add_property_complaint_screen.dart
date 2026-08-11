import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/property_complaint.dart';
import '../models/tenant.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';

/// Opened from the property dashboard's "Add Complaint" quick action.
/// Fields backed by real data (description, location, urgent, issue type,
/// which tenant it's reported by) are fully functional; "Handled by" (no
/// staff/team concept in this app yet), photo/file upload, and scheduling
/// availability are shown but marked "Coming soon".
class AddPropertyComplaintScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const AddPropertyComplaintScreen({super.key, required this.propertyId, required this.propertyTitle});

  @override
  State<AddPropertyComplaintScreen> createState() => _AddPropertyComplaintScreenState();
}

class _AddPropertyComplaintScreenState extends State<AddPropertyComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ComplaintLocation? _location;
  ComplaintCategory? _category;
  bool _urgent = false;
  Tenant? _reportedBy;
  AuthUser? _owner;

  List<Tenant> _tenants = [];
  bool _loadingTenants = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final owner = await AuthService.syncCurrentUser();
      final tenants = await PropertyApi.fetchTenants(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _owner = owner;
        _tenants = tenants.where((t) => t.status == 'active').toList();
        _loadingTenants = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTenants = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _comingSoon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));

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

  Future<void> _pickReportedBy() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TenantPickerSheet(tenants: _tenants),
    );
    if (picked == null) return;
    setState(() => _reportedBy = picked.isEmpty ? null : _tenants.firstWhere((t) => t.id == picked));
  }

  Future<void> _call(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

  Future<void> _whatsApp(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final number = digits.length == 10 ? '91$digits' : digits;
    return launchUrl(Uri.parse('https://wa.me/$number'), mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an issue type')));
      return;
    }
    setState(() => _saving = true);
    try {
      await PropertyApi.createComplaint(
        widget.propertyId,
        description: _descriptionController.text.trim(),
        category: _category!,
        location: _location,
        urgent: _urgent,
        tenantId: _reportedBy?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket submitted')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit ticket: $e')));
    }
  }

  Widget _row({required String label, required Widget value, VoidCallback? onTap, Widget? trailing}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          Expanded(child: value),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ],
        ),
      );

  Widget _pickerValue(String text, {bool placeholder = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: placeholder ? AppColors.muted : AppColors.text),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.muted),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Raise Maintenance Ticket'),
            Text(widget.propertyTitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Complaint Details', style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _group([
              _row(
                label: 'Property',
                value: Text(widget.propertyTitle, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description', hintText: "Please explain the issue you're facing…"),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Describe the issue' : null,
            ),
            const SizedBox(height: 14),
            _group([
              _row(label: 'Found at', value: _pickerValue(_location?.label ?? 'Select issue location', placeholder: _location == null), onTap: _pickLocation),
              _row(
                label: 'Is this urgent?',
                value: const SizedBox.shrink(),
                trailing: Switch(value: _urgent, activeColor: AppColors.danger, onChanged: (v) => setState(() => _urgent = v)),
              ),
              _row(
                label: 'Current status',
                value: Text(ComplaintStatus.received.label, textAlign: TextAlign.right, style: AppFonts.heading(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              _row(label: 'Issue Type', value: _pickerValue(_category?.label ?? 'Select issue type', placeholder: _category == null), onTap: _pickCategory),
              _row(label: 'Add Photos or Files', value: _pickerValue('Coming soon', placeholder: true), onTap: _comingSoon),
            ]),
            const SizedBox(height: 20),
            Text('Handled & Reported by', style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _group([
              _row(label: 'Handled by', value: _pickerValue('Coming soon', placeholder: true), onTap: _comingSoon),
              _row(
                label: 'Reported by',
                value: _loadingTenants
                    ? const Align(alignment: Alignment.centerRight, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : _pickerValue(_reportedBy?.name ?? 'You (Owner)'),
                onTap: _tenants.isEmpty ? null : _pickReportedBy,
              ),
            ]),
            const SizedBox(height: 10),
            _buildReportedByCard(),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _comingSoon,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Availability'),
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
                    : const Text('Submit Ticket', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportedByCard() {
    final name = _reportedBy?.name ?? (_owner?.name ?? 'Owner');
    final phone = _reportedBy?.phone ?? _owner?.phoneNumber;
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundColor: AppColors.surfaceAlt, child: Icon(Icons.person_outline, color: AppColors.muted, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (phone != null) Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty) ...[
            IconButton(onPressed: () => _call(phone), icon: const Icon(Icons.call_outlined, color: AppColors.amber), tooltip: 'Call'),
            IconButton(onPressed: () => _whatsApp(phone), icon: const Icon(Icons.chat_outlined, color: AppColors.success), tooltip: 'WhatsApp'),
          ],
        ],
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

/// Picks which active tenant this ticket is reported by, or clears back to
/// "You (Owner)".
class _TenantPickerSheet extends StatelessWidget {
  final List<Tenant> tenants;
  const _TenantPickerSheet({required this.tenants});

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
            Text('Reported by', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(contentPadding: EdgeInsets.zero, title: const Text('You (Owner)'), onTap: () => Navigator.of(context).pop('')),
                  const Divider(height: 1),
                  for (final t in tenants)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(t.phone, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      onTap: () => Navigator.of(context).pop(t.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
