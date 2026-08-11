import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rent_payment.dart';
import '../models/tenant.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

/// One tenant's full rent picture, opened from Collect Payment — due months
/// with a "Mark Collected" action (owner recorded cash/UPI/bank transfer
/// themselves), plus paid history including anything the tenant paid online.
class TenantRentDetailScreen extends StatefulWidget {
  final String propertyId;
  final Tenant tenant;

  const TenantRentDetailScreen({super.key, required this.propertyId, required this.tenant});

  @override
  State<TenantRentDetailScreen> createState() => _TenantRentDetailScreenState();
}

class _TenantRentDetailScreenState extends State<TenantRentDetailScreen> {
  TenantRentDetail? _detail;
  bool _loading = true;
  String? _error;
  DueMonth? _collecting;

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
      final detail = await PropertyApi.fetchTenantRent(widget.propertyId, widget.tenant.id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load rent details. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _collect(DueMonth due) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _MethodPickerSheet(due: due),
    );
    if (method == null) return;

    setState(() => _collecting = due);
    try {
      await PropertyApi.collectRentManually(widget.propertyId, widget.tenant.id, month: due.month, year: due.year, method: method);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${due.label} marked collected')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not record payment: $e')));
    } finally {
      if (mounted) setState(() => _collecting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tenant.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(onRefresh: _load, child: _buildBody(_detail!)),
    );
  }

  Widget _buildError() {
    return Center(
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
    );
  }

  Widget _buildBody(TenantRentDetail detail) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('₹${detail.tenant.monthlyRent}/month', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  PillBadge(
                    label: detail.tenant.status == 'active' ? 'Active' : detail.tenant.status[0].toUpperCase() + detail.tenant.status.substring(1),
                    color: detail.tenant.status == 'active' ? AppColors.success : AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if ((detail.tenant.roomNumber ?? '').isEmpty)
                _detailRow(Icons.call_outlined, detail.tenant.phone)
              else ...[
                _detailRow(Icons.door_front_door_outlined, 'Room ${detail.tenant.roomNumber}'),
                const SizedBox(height: 6),
                _detailRow(Icons.call_outlined, detail.tenant.phone),
              ],
              if ((detail.tenant.email ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.mail_outline, detail.tenant.email!),
              ],
              const SizedBox(height: 6),
              _detailRow(Icons.event_outlined, 'Joined ${_formatDate(detail.tenant.moveInDate)}'),
              if (detail.tenant.moveOutDate != null) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.event_busy_outlined, 'Moved out ${_formatDate(detail.tenant.moveOutDate!)}'),
              ],
            ],
          ),
        ),
        if (detail.tenant.isLinked == false) ...[
          const SizedBox(height: 14),
          DarkCard(
            borderColor: AppColors.amber,
            child: Row(
              children: [
                const Icon(Icons.key_outlined, color: AppColors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Hasn't joined yet — share this code", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 3),
                      Text(
                        detail.tenant.joinCode ?? '——————',
                        style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800).copyWith(letterSpacing: 3),
                      ),
                    ],
                  ),
                ),
                if (detail.tenant.joinCode != null)
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: detail.tenant.joinCode!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                    },
                    icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.muted),
                    tooltip: 'Copy code',
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Due', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (detail.due.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing pending — fully paid up.', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
          )
        else
          for (final due in detail.due)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DarkCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(due.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('₹${due.amount}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      width: 128,
                      child: _collecting == due
                          ? const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: CircularProgressIndicator(strokeWidth: 2))
                          : ElevatedButton(
                              onPressed: () => _collect(due),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
                              child: const Text('Mark Collected', style: TextStyle(fontSize: 12.5)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 24),
        Text('History', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (detail.payments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No payments recorded yet.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          )
        else
          for (final payment in detail.payments)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DarkCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payment.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('₹${payment.amount} · ${_formatDate(payment.paidAt)}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    PillBadge(label: payment.methodLabel, color: payment.method == 'online' ? AppColors.brand : AppColors.success),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _MethodPickerSheet extends StatelessWidget {
  final DueMonth due;
  const _MethodPickerSheet({required this.due});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('How was ${due.label} collected?', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
          ),
          for (final entry in const [('cash', 'Cash'), ('upi', 'UPI'), ('bank_transfer', 'Bank Transfer')])
            ListTile(
              title: Text(entry.$2),
              onTap: () => Navigator.of(context).pop(entry.$1),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
