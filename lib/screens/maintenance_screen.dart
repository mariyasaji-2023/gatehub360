import 'package:flutter/material.dart';
import '../models/rent_payment.dart';
import '../models/tenant.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import '../widgets/stat_overview_bar.dart';
import 'tenant_rent_detail_screen.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Opened from the property dashboard's "Maintenance" quick action —
/// "Maintenance Reports" up top (mirrors the rent summary strip), then
/// every tenant with a monthly maintenance charge set and their
/// paid/pending status. Tap a tenant to see due months / record a
/// collection, on the same screen used for rent.
class MaintenanceScreen extends StatefulWidget {
  final String propertyId;

  const MaintenanceScreen({super.key, required this.propertyId});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  RentSummary? _summary;
  List<Tenant>? _tenants;
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
      final results = await Future.wait([
        PropertyApi.fetchMaintenanceSummary(widget.propertyId),
        PropertyApi.fetchTenants(widget.propertyId),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as RentSummary;
        _tenants = (results[1] as List<Tenant>).where((t) => t.status == 'active').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load maintenance details. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _openTenant(Tenant tenant) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TenantRentDetailScreen(propertyId: widget.propertyId, tenant: tenant)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(onRefresh: _load, child: _buildBody()),
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

  Widget _buildBody() {
    final month = _monthNames[DateTime.now().month - 1];
    final tenantsWithCharge = (_tenants ?? []).where((t) => t.maintenanceAmount > 0).toList();
    final tenantsWithoutCharge = (_tenants ?? []).where((t) => t.maintenanceAmount <= 0).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const SizedBox(height: 16),
        StatOverviewBar(items: [
          StatOverviewItem(icon: Icons.payments_outlined, value: '₹${_summary?.todayCollection ?? 0}', label: "Today's Collection", color: AppColors.success),
          StatOverviewItem(icon: Icons.account_balance_wallet_outlined, value: '₹${_summary?.thisMonthCollection ?? 0}', label: '$month Collection', color: AppColors.success),
          StatOverviewItem(icon: Icons.receipt_long_outlined, value: '₹${_summary?.thisMonthDues ?? 0}', label: '$month Dues', color: AppColors.amber),
          StatOverviewItem(icon: Icons.pending_actions_outlined, value: '₹${_summary?.allTimeDues ?? 0}', label: 'All Time Dues', color: AppColors.amber),
        ]),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Tenants', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        if (tenantsWithCharge.isEmpty && tenantsWithoutCharge.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Text('No tenants yet. Add one from the dashboard first.', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final tenant in tenantsWithCharge) _tenantRow(tenant),
              for (final tenant in tenantsWithoutCharge) _tenantRow(tenant),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tenantRow(Tenant tenant) {
    final hasCharge = tenant.maintenanceAmount > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DarkCard(
        onTap: () => _openTenant(tenant),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (tenant.roomNumber ?? '').isEmpty ? tenant.name : '${tenant.name} · Room ${tenant.roomNumber}',
                    style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasCharge ? '₹${tenant.maintenanceAmount}/mo maintenance' : 'No maintenance amount set',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (hasCharge)
              tenant.isMaintenanceFullyPaid
                  ? const PillBadge(label: 'Up to date', color: AppColors.success)
                  : PillBadge(
                      label: '${tenant.pendingMaintenanceMonths} month${(tenant.pendingMaintenanceMonths ?? 0) > 1 ? 's' : ''} due',
                      color: AppColors.amber,
                    )
            else
              const PillBadge(label: 'Not set', color: AppColors.muted),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
