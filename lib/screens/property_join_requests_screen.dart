import 'package:flutter/material.dart';

import '../models/property_join_request.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import 'tenant_invite_screen.dart';

/// Opened from the "Invite Tenant" screen — pending self-submitted requests
/// for this property (see backend/public/invite.html), with Approve/Reject.
/// Approving creates a real Tenant record and immediately offers to share
/// its join code, same as the manual Add Tenant flow does.
class PropertyJoinRequestsScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const PropertyJoinRequestsScreen({super.key, required this.propertyId, required this.propertyTitle});

  @override
  State<PropertyJoinRequestsScreen> createState() => _PropertyJoinRequestsScreenState();
}

class _PropertyJoinRequestsScreenState extends State<PropertyJoinRequestsScreen> {
  List<PropertyJoinRequest> _requests = [];
  bool _loading = true;
  String? _error;
  String? _respondingId;

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
      final requests = await PropertyApi.fetchJoinRequests(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _reject(PropertyJoinRequest request) async {
    setState(() => _respondingId = request.id);
    try {
      await PropertyApi.respondToJoinRequest(widget.propertyId, request.id, approve: false);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _respondingId = null);
    }
  }

  Future<void> _approve(PropertyJoinRequest request) async {
    num? rent = request.monthlyRent;
    if (rent == null || rent <= 0) {
      rent = await _askForRent(request);
      if (rent == null) return; // cancelled
    }

    setState(() => _respondingId = request.id);
    try {
      final tenant = await PropertyApi.respondToJoinRequest(widget.propertyId, request.id, approve: true, monthlyRent: rent);
      await _load();
      if (!mounted || tenant == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TenantInviteScreen(tenant: tenant, propertyTitle: widget.propertyTitle)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _respondingId = null);
    }
  }

  Future<num?> _askForRent(PropertyJoinRequest request) async {
    final controller = TextEditingController();
    return showDialog<num>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Monthly rent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${request.name} didn't set a rent amount — enter one to approve.", style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            const SizedBox(height: 14),
            TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '₹ per month')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = num.tryParse(controller.text.trim());
              Navigator.of(context).pop((amount != null && amount > 0) ? amount : null);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
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
                        if (_requests.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('No pending requests.', style: TextStyle(fontSize: 13.5, color: AppColors.muted))),
                          ),
                        for (final r in _requests)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DarkCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(r.phone, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                                  if ((r.roomNumber ?? '').isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text('Room: ${r.roomNumber}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                  ],
                                  if (r.monthlyRent != null) ...[
                                    const SizedBox(height: 2),
                                    Text('Rent: ₹${r.monthlyRent}/mo', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                  ],
                                  if (r.moveInDate != null) ...[
                                    const SizedBox(height: 2),
                                    Text('Wants to move in: ${_formatDate(r.moveInDate!)}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                  ],
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                  _respondingId == r.id
                                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: CircularProgressIndicator(strokeWidth: 2)))
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _reject(r),
                                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), foregroundColor: AppColors.danger),
                                                child: const Text('Reject'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(onPressed: () => _approve(r), child: const Text('Approve')),
                                            ),
                                          ],
                                        ),
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
