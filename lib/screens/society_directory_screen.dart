import 'package:flutter/material.dart';

import '../models/society_resident.dart';
import '../services/auth_service.dart';
import '../services/society_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

class SocietyDirectoryScreen extends StatefulWidget {
  const SocietyDirectoryScreen({super.key});

  @override
  State<SocietyDirectoryScreen> createState() => _SocietyDirectoryScreenState();
}

class _SocietyDirectoryScreenState extends State<SocietyDirectoryScreen> {
  List<SocietyResident> _residents = [];
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
      final residents = await SocietyApi.fetchResidents();
      if (!mounted) return;
      setState(() {
        _residents = residents;
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

  String _roleLabel(String? role) => switch (role) {
        'apartment_association' => 'Association',
        'pg_owner' => 'PG Owner',
        'property_owner' => 'Property Owner',
        'tenant' => 'Tenant',
        _ => 'Resident',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resident Directory')),
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
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        if (_residents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No residents have joined yet.', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
                            ),
                          ),
                        ..._residents.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DarkCard(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.surfaceAlt,
                                      child: Text(
                                        (r.name?.isNotEmpty == true ? r.name![0] : '?').toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r.name?.isNotEmpty == true ? r.name! : 'Unnamed',
                                              style: AppFonts.heading(fontSize: 14, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 3),
                                          Text(
                                            [
                                              if (r.flatNumber?.isNotEmpty == true) 'Flat ${r.flatNumber}',
                                              if (r.phoneNumber?.isNotEmpty == true) r.phoneNumber!,
                                            ].join(' · '),
                                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PillBadge(label: _roleLabel(r.role), color: AppColors.brand),
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
