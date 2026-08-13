import 'package:flutter/material.dart';

import '../models/visitor.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

/// Visitor Entry/Exit/History for one property — opened from the dashboard's
/// "Visitors" quick action. A visitor with no exit time yet shows as
/// "Inside" with a Mark Exit action; everyone else is just history.
class PropertyVisitorsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyVisitorsScreen({super.key, required this.propertyId});

  @override
  State<PropertyVisitorsScreen> createState() => _PropertyVisitorsScreenState();
}

class _PropertyVisitorsScreenState extends State<PropertyVisitorsScreen> {
  List<Visitor>? _visitors;
  bool _loading = true;
  String? _error;
  String? _updatingId;

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
      final visitors = await PropertyApi.fetchVisitors(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _visitors = visitors;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load visitors. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _logEntry() async {
    final result = await showModalBottomSheet<_VisitorEntryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LogVisitorSheet(),
    );
    if (result == null) return;

    try {
      await PropertyApi.logVisitorEntry(
        widget.propertyId,
        name: result.name,
        phone: result.phone,
        purpose: result.purpose,
        meetingName: result.meetingName,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not log visitor: $e')));
    }
  }

  Future<void> _markExit(Visitor visitor) async {
    setState(() => _updatingId = visitor.id);
    try {
      await PropertyApi.markVisitorExit(widget.propertyId, visitor.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not mark exit: $e')));
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day}/${local.month} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final visitors = _visitors ?? const [];
    final inside = visitors.where((v) => v.isInside).toList();
    final history = visitors.where((v) => !v.isInside).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Visitors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logEntry,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Log Entry'),
        backgroundColor: AppColors.brand,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
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
                  )
                : visitors.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No visitors logged yet.', style: TextStyle(color: AppColors.muted)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                          children: [
                            if (inside.isNotEmpty) ...[
                              Text('Currently Inside (${inside.length})', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              for (final v in inside) _buildVisitorCard(v, inside: true),
                              const SizedBox(height: 20),
                            ],
                            Text('History', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            if (history.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('No past visitors yet.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                              )
                            else
                              for (final v in history) _buildVisitorCard(v, inside: false),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildVisitorCard(Visitor v, {required bool inside}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DarkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.name, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      if ((v.purpose ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(v.purpose!, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ],
                      if ((v.meetingName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Visiting: ${v.meetingName}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                      ],
                    ],
                  ),
                ),
                PillBadge(label: inside ? 'Inside' : 'Exited', color: inside ? AppColors.success : AppColors.muted),
              ],
            ),
            const SizedBox(height: 10),
            Text('In: ${_formatTime(v.entryTime)}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            if (v.exitTime != null) ...[
              const SizedBox(height: 2),
              Text('Out: ${_formatTime(v.exitTime!)}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            ],
            if (inside) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _updatingId == v.id ? null : () => _markExit(v),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                  child: _updatingId == v.id
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Mark Exit', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VisitorEntryResult {
  final String name;
  final String? phone;
  final String? purpose;
  final String? meetingName;

  const _VisitorEntryResult({required this.name, this.phone, this.purpose, this.meetingName});
}

class _LogVisitorSheet extends StatefulWidget {
  const _LogVisitorSheet();

  @override
  State<_LogVisitorSheet> createState() => _LogVisitorSheetState();
}

class _LogVisitorSheetState extends State<_LogVisitorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _meetingController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _meetingController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_VisitorEntryResult(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      purpose: _purposeController.text.trim(),
      meetingName: _meetingController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log Visitor Entry', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Visitor name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _purposeController,
                  decoration: const InputDecoration(labelText: 'Purpose of visit (optional)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _meetingController,
                  decoration: const InputDecoration(labelText: 'Visiting whom (optional)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                    child: const Text('Log Entry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
