import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/property_listing.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/property_edit_sheet.dart';
import 'property_dashboard_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  List<MyPropertyListing> _listings = [];
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
      final listings = await PropertyApi.fetchMine();
      if (!mounted) return;
      setState(() {
        _listings = listings;
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

  Future<void> _openProperty(MyPropertyListing listing) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PropertyDashboardScreen(listing: listing),
    ));
  }

  Future<void> _openForm({MyPropertyListing? existing}) async {
    final saved = await openPropertyEditForm(context, existing: existing);
    if (saved) await _load();
  }

  Future<void> _confirmDelete(MyPropertyListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove property?'),
        content: Text('"${listing.title}" will no longer be visible to buyers/tenants.'),
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
      await PropertyApi.delete(listing.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('My Properties')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Property'),
          backgroundColor: AppColors.brand,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else ...[
                Text('Your Listings (${_listings.length})', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                if (_listings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "You haven't added any properties yet.\nTap \"Add Property\" to get started.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6),
                      ),
                    ),
                  ),
                ..._listings.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DarkCard(
                        onTap: () => _openProperty(l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _PropertyThumb(listing: l),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l.title, style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 3),
                                      Text('📍 ${l.location}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                      const SizedBox(height: 3),
                                      Text('₹${l.price} · ${l.type} · ${l.mode}', style: const TextStyle(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _openForm(existing: l);
                                    if (v == 'delete') _confirmDelete(l);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(l.about, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (l.bhk != 'N/A')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                                    child: Text(l.bhk, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                                  child: Text('${l.sqft} sqft', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (l.active ? AppColors.brand : AppColors.muted).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l.active ? 'Visible to buyers/tenants' : 'Hidden',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: l.active ? AppColors.brand : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small preview tile used on the "My Properties" list — the first added
/// photo if there is one, otherwise the type emoji as before.
class _PropertyThumb extends StatelessWidget {
  final MyPropertyListing listing;
  const _PropertyThumb({required this.listing});

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    if (listing.images.isEmpty) {
      return Text(listing.emoji, style: const TextStyle(fontSize: 30));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        base64Decode(listing.images.first),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
