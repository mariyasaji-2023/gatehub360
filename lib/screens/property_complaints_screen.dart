import 'package:flutter/material.dart';

import '../models/property_complaint.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
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

/// Every maintenance ticket raised for this property — opened by tapping
/// the dashboard's "Active Complaints" stat tile. Owner can move a ticket
/// through received -> in progress -> resolved.
class PropertyComplaintsScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const PropertyComplaintsScreen({super.key, required this.propertyId, required this.propertyTitle});

  @override
  State<PropertyComplaintsScreen> createState() => _PropertyComplaintsScreenState();
}

class _PropertyComplaintsScreenState extends State<PropertyComplaintsScreen> {
  List<PropertyComplaint> _complaints = [];
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
      final complaints = await PropertyApi.fetchComplaints(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _complaints = complaints;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  Future<void> _changeStatus(PropertyComplaint complaint, ComplaintStatus status) async {
    setState(() => _updatingId = complaint.id);
    try {
      await PropertyApi.updateComplaintStatus(widget.propertyId, complaint.id, status);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Color _statusColor(ComplaintStatus status) => switch (status) {
        ComplaintStatus.received => AppColors.danger,
        ComplaintStatus.inProgress => AppColors.amber,
        ComplaintStatus.resolved => AppColors.success,
      };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Complaints'),
            Text(widget.propertyTitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        if (_complaints.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('No complaints yet.', style: TextStyle(fontSize: 13.5, color: AppColors.muted))),
                          ),
                        for (final c in _complaints)
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
                                        child: Text(c.description, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
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
                                      if (c.tenantName != null) PillBadge(label: c.tenantName!, color: AppColors.muted),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_formatDate(c.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                  if (c.status != ComplaintStatus.resolved) ...[
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                    _updatingId == c.id
                                        ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: CircularProgressIndicator(strokeWidth: 2)))
                                        : Row(
                                            children: [
                                              if (c.status == ComplaintStatus.received)
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () => _changeStatus(c, ComplaintStatus.inProgress),
                                                    child: const Text('Mark In Progress'),
                                                  ),
                                                ),
                                              if (c.status == ComplaintStatus.received) const SizedBox(width: 10),
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
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}
