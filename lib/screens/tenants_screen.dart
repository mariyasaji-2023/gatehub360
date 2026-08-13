import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/tenant.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import 'tenant_rent_detail_screen.dart';

/// Opened from the property dashboard's "Tenants" quick action — every
/// tenant ever added to this property, active or not, so an owner can
/// confirm who's on record without going through the payment flow.
class TenantsScreen extends StatefulWidget {
  final String propertyId;

  const TenantsScreen({super.key, required this.propertyId});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
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
        _tenants = tenants;
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

  Future<void> _confirmRemove(Tenant tenant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove tenant?'),
        content: Text('"${tenant.name}" and their rent history will be permanently removed from this property.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await PropertyApi.deleteTenant(widget.propertyId, tenant.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not remove tenant: $e')));
    }
  }

  Future<void> _showJoinCode(Tenant tenant) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${tenant.name}\'s join code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "They haven't linked their account yet — share this code so they can.",
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
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tenants')),
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
                  if (tenant.isLinked == false)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: IconButton(
                        onPressed: () => _showJoinCode(tenant),
                        icon: const Icon(Icons.key_outlined, color: AppColors.amber, size: 20),
                        tooltip: 'View join code',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  tenant.status == 'active'
                      ? const PillBadge(label: 'Active', color: AppColors.success)
                      : PillBadge(label: tenant.status[0].toUpperCase() + tenant.status.substring(1), color: AppColors.muted),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'remove') _confirmRemove(tenant);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'remove', child: Text('Remove Tenant')),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
