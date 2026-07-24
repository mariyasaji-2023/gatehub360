import 'package:flutter/material.dart';

import '../models/society_complaint.dart';
import '../services/auth_service.dart';
import '../services/society_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

class SocietyComplaintsScreen extends StatefulWidget {
  const SocietyComplaintsScreen({super.key});

  @override
  State<SocietyComplaintsScreen> createState() => _SocietyComplaintsScreenState();
}

class _SocietyComplaintsScreenState extends State<SocietyComplaintsScreen> {
  List<SocietyComplaint> _complaints = [];
  bool _isAssociation = false;
  bool _loading = true;
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
      final complaints = await SocietyApi.fetchComplaints();
      if (!mounted) return;
      setState(() {
        _isAssociation = user.role == UserRole.apartmentAssociation;
        _complaints = complaints;
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

  Future<void> _openForm() async {
    final result = await showModalBottomSheet<({String title, String description, ComplaintCategory category, ComplaintPriority priority})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ComplaintFormSheet(),
    );
    if (result == null) return;

    try {
      await SocietyApi.createComplaint(
        title: result.title,
        description: result.description,
        category: result.category,
        priority: result.priority,
      );
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _changeStatus(SocietyComplaint complaint, ComplaintStatus status) async {
    try {
      await SocietyApi.updateComplaintStatus(complaint.id, status);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Color _statusColor(ComplaintStatus status) => switch (status) {
        ComplaintStatus.open => AppColors.danger,
        ComplaintStatus.inProgress => AppColors.amber,
        ComplaintStatus.resolved => AppColors.brand,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Raise Complaint'),
        backgroundColor: AppColors.brand,
      ),
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
                        if (_complaints.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No complaints yet.', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
                            ),
                          ),
                        ..._complaints.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: DarkCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(c.title, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                                        ),
                                        if (c.priority == ComplaintPriority.urgent) ...[
                                          const PillBadge(label: 'Urgent', color: AppColors.danger),
                                          const SizedBox(width: 6),
                                        ],
                                        PillBadge(label: c.status.label, color: _statusColor(c.status)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(c.description, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5)),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        PillBadge(label: c.category.label, color: AppColors.brandLight),
                                        if (c.flatNumber?.isNotEmpty == true) PillBadge(label: 'Flat ${c.flatNumber}', color: AppColors.muted),
                                      ],
                                    ),
                                    if (_isAssociation && c.status != ComplaintStatus.resolved) ...[
                                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                      Row(
                                        children: [
                                          if (c.status == ComplaintStatus.open)
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _changeStatus(c, ComplaintStatus.inProgress),
                                                child: const Text('Mark In Progress'),
                                              ),
                                            ),
                                          if (c.status == ComplaintStatus.open) const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _changeStatus(c, ComplaintStatus.resolved),
                                              child: const Text('Mark Resolved'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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

class _ComplaintFormSheet extends StatefulWidget {
  const _ComplaintFormSheet();

  @override
  State<_ComplaintFormSheet> createState() => _ComplaintFormSheetState();
}

class _ComplaintFormSheetState extends State<_ComplaintFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  ComplaintCategory _category = ComplaintCategory.plumbing;
  ComplaintPriority _priority = ComplaintPriority.normal;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _category,
      priority: _priority,
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
                Text('Raise Complaint', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ComplaintCategory.values.map((cat) {
                    final selected = cat == _category;
                    return ChoiceChip(
                      label: Text(cat.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = cat),
                      selectedColor: AppColors.brand,
                      backgroundColor: AppColors.surfaceAlt,
                      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.text, fontSize: 12.5),
                      side: BorderSide(color: selected ? AppColors.brand : AppColors.border),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Describe the issue'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _priority == ComplaintPriority.urgent,
                  onChanged: (v) => setState(() => _priority = v ? ComplaintPriority.urgent : ComplaintPriority.normal),
                  activeColor: AppColors.danger,
                  title: const Text('Urgent', style: TextStyle(fontSize: 13.5)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _save, child: const Text('Submit Complaint')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
