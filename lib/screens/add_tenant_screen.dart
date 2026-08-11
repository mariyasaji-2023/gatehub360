import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tenant.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';

/// Opened from the property dashboard's "Add Tenant" quick action. Captures
/// core tenant details only — KYC photo and rental agreement upload are a
/// follow-up once file storage is wired up.
class AddTenantScreen extends StatefulWidget {
  final String propertyId;

  const AddTenantScreen({super.key, required this.propertyId});

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _roomController = TextEditingController();
  final _rentController = TextEditingController();
  DateTime _moveInDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _roomController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _pickMoveInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _moveInDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final tenant = await PropertyApi.addTenant(
        widget.propertyId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        roomNumber: _roomController.text.trim(),
        monthlyRent: num.parse(_rentController.text.trim()),
        moveInDate: _moveInDate,
      );
      if (!mounted) return;
      await _showJoinCode(tenant);
      if (!mounted) return;
      Navigator.of(context).pop<Tenant>(tenant);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add tenant: $e')));
    }
  }

  Future<void> _showJoinCode(Tenant tenant) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('${tenant.name} added'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Share this code with them — they'll enter it in the app to link their account and start seeing/paying their rent.",
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            DarkCard(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  tenant.joinCode ?? '——————',
                  style: AppFonts.heading(fontSize: 28, fontWeight: FontWeight.w800).copyWith(letterSpacing: 4),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (tenant.joinCode != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: tenant.joinCode!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
              },
              child: const Text('Copy Code'),
            ),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tenant')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Tenant name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the tenant\'s name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 10 ? 'Enter a valid phone number' : null;
              },
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 4),
              child: Text(
                "Just for your records — after adding them, you'll get a join code to share so they can link their own account.",
                style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Room number (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly rent (₹)'),
              validator: (v) {
                final amount = num.tryParse((v ?? '').trim());
                return (amount == null || amount <= 0) ? 'Enter a valid amount' : null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickMoveInDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Move-in date'),
                child: Row(
                  children: [
                    Expanded(child: Text(_formatDate(_moveInDate))),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.brandOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Tenant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
