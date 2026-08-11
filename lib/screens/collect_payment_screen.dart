import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import 'tenant_rent_detail_screen.dart';

/// Opened from the property dashboard's "Collect Payment" quick action —
/// every active tenant with an at-a-glance paid/pending badge. Tap a tenant
/// to see which months are due and record a collection.
class CollectPaymentScreen extends StatefulWidget {
  final String propertyId;

  const CollectPaymentScreen({super.key, required this.propertyId});

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
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
      final tenants = await PropertyApi.fetchTenants(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _tenants = tenants.where((t) => t.status == 'active').toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load tenants. Pull to retry.';
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
      appBar: AppBar(title: const Text('Collect Payment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : (_tenants?.isEmpty ?? true)
                  ? _buildEmpty()
                  : RefreshIndicator(onRefresh: _load, child: _buildList(_tenants!)),
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

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No tenants yet. Add one from the dashboard first.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
      ),
    );
  }

  Widget _buildList(List<Tenant> tenants) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (final tenant in tenants)
          Padding(
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
                          '₹${tenant.monthlyRent}/mo · ${tenant.phone}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  tenant.isFullyPaid
                      ? const PillBadge(label: 'Up to date', color: AppColors.success)
                      : PillBadge(label: '${tenant.pendingMonths} month${tenant.pendingMonths! > 1 ? 's' : ''} due', color: AppColors.amber),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
