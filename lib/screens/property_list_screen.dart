import 'dart:convert';

import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../models/property_listing.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/emoji_tile.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/hero_search_bar.dart';
import '../widgets/pill_badge.dart';
import '../widgets/section_hero.dart';
import 'property_detail_screen.dart';

Color _modeColor(String mode) => switch (mode) {
      'Rent' => AppColors.amber,
      'Commercial' => AppColors.brandLight,
      _ => AppColors.brand,
    };

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _searchController = TextEditingController();
  String _type = 'All';
  String _bhk = 'All';
  List<MyPropertyListing> _listings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listings = await PropertyApi.fetchAll(type: _type);
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

  void _selectType(String type) {
    setState(() => _type = type);
    _load();
  }

  List<MyPropertyListing> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _listings.where((p) {
      final matchBhk = _bhk == 'All' || p.bhk == _bhk || (_bhk == '4+ BHK' && p.bhk == '4 BHK');
      final matchSearch = q.isEmpty || p.title.toLowerCase().contains(q) || p.location.toLowerCase().contains(q);
      return matchBhk && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SectionHero(
              titleStart: "Search India's Best",
              titleHighlight: 'Real Estate & Properties',
              accentColor: AppColors.brand,
              child: HeroSearchBar(
                controller: _searchController,
                hint: 'Search city, locality, project name...',
                accentColor: AppColors.brand,
                onSearch: () => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterChipRow<String>(
                    leadingLabel: 'Type:',
                    items: propertyTypes,
                    labelBuilder: (t) => t,
                    selected: _type,
                    accentColor: AppColors.brand,
                    onSelect: _selectType,
                  ),
                  const SizedBox(height: 10),
                  FilterChipRow<String>(
                    leadingLabel: 'BHK:',
                    items: propertyBhks,
                    labelBuilder: (b) => b,
                    selected: _bhk,
                    accentColor: AppColors.brand,
                    onSelect: (b) => setState(() => _bhk = b),
                  ),
                  const SizedBox(height: 20),
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
                    Text('${filtered.length} Properties Found', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No properties listed yet.',
                            style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.66,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _PropertyCard(property: filtered[i]),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final MyPropertyListing property;
  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p))),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (p.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.memory(
                        base64Decode(p.images.first),
                        height: 96,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    EmojiTile(
                      emoji: p.emoji,
                      color: AppColors.brand,
                      height: 96,
                      fontSize: 34,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: PillBadge(label: p.mode, color: _modeColor(p.mode)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('📍 ${p.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Text('₹${p.price}', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brand)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (p.bhk != 'N/A')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(5)),
                            child: Text(p.bhk, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(5)),
                          child: Text('${p.sqft} sqft', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
