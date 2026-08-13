import 'package:flutter/material.dart';

import '../models/property_complaint.dart';
import '../services/rent_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

const _categoryIcons = {
  ComplaintCategory.plumbing: Icons.plumbing_outlined,
  ComplaintCategory.electrical: Icons.electrical_services_outlined,
  ComplaintCategory.cleaning: Icons.cleaning_services_outlined,
  ComplaintCategory.structural: Icons.foundation_outlined,
  ComplaintCategory.appliance: Icons.kitchen_outlined,
  ComplaintCategory.pestControl: Icons.pest_control_outlined,
  ComplaintCategory.other: Icons.report_problem_outlined,
};

/// Tenant-facing "track status" view — every complaint they've raised,
/// across every property they've linked. Read-only; only the owner can
/// change status.
class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  List<PropertyComplaint>? _complaints;
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
      final complaints = await RentApi.fetchMyComplaints();
      if (!mounted) return;
      setState(() {
        _complaints = complaints;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load complaints. Pull to retry.';
        _loading = false;
      });
    }
  }

  Color _statusColor(ComplaintStatus status) => switch (status) {
        ComplaintStatus.received => AppColors.danger,
        ComplaintStatus.inProgress => AppColors.amber,
        ComplaintStatus.resolved => AppColors.success,
        ComplaintStatus.closed => AppColors.muted,
      };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
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
                : RefreshIndicator(
                    onRefresh: _load,
                    child: (_complaints?.isEmpty ?? true)
                        ? ListView(
                            children: const [
                              SizedBox(height: 60),
                              Center(child: Text('No complaints raised yet.', style: TextStyle(color: AppColors.muted))),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            children: [
                              for (final c in _complaints!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: DarkCard(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(9),
                                              decoration: BoxDecoration(color: _statusColor(c.status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                              child: Icon(_categoryIcons[c.category] ?? Icons.report_problem_outlined, size: 18, color: _statusColor(c.status)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (c.propertyTitle != null)
                                                    Text(c.propertyTitle!, style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                                                  Text(c.description, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            if (c.urgent) const PillBadge(label: 'Urgent', color: AppColors.danger),
                                            PillBadge(label: c.status.label, color: _statusColor(c.status)),
                                            PillBadge(label: c.category.label, color: AppColors.brandLight),
                                            if (c.location != null) PillBadge(label: c.location!.label, color: AppColors.muted),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(_formatDate(c.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
      ),
    );
  }
}
