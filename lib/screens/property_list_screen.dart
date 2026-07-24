import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../models/property_listing.dart';
import '../theme/app_theme.dart';
import '../widgets/emoji_tile.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/hero_search_bar.dart';
import '../widgets/pill_badge.dart';
import '../widgets/section_hero.dart';
import 'property_detail_screen.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _searchController = TextEditingController();
  String _mode = 'Buy';
  String _type = 'All';
  String _bhk = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PropertyListing> get _filtered {
    return propertyListings.where((p) {
      final matchType = _type == 'All' || p.type == _type;
      final matchBhk = _bhk == 'All' || p.bhk == _bhk || (_bhk == '4+ BHK' && p.bhk == '4 BHK');
      return matchType && matchBhk;
    }).toList();
  }

  Color _statusColor(String status) {
    if (status == 'Ready to Move') return AppColors.brand;
    if (status == 'New Launch') return AppColors.amber;
    return AppColors.brandLight;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHero(
            titleStart: "Search India's Best",
            titleHighlight: 'Real Estate & Properties',
            accentColor: AppColors.brand,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: propertyModes
                        .map((m) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(9),
                                  onTap: () => setState(() => _mode = m),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: _mode == m ? AppColors.brand : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(m, style: TextStyle(fontSize: 13, color: _mode == m ? Colors.white : AppColors.muted, fontWeight: _mode == m ? FontWeight.w600 : FontWeight.w400)),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                HeroSearchBar(
                  controller: _searchController,
                  hint: 'Search city, locality, project name...',
                  accentColor: AppColors.brand,
                  onSearch: () => setState(() {}),
                ),
              ],
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
                  onSelect: (t) => setState(() => _type = t),
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
                Text('${filtered.length} Properties Found', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
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
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    return Material(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(id: p.id))),
                        child: Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
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
                                    child: PillBadge(label: p.status, color: _statusColor(p.status), fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PillBadge(label: '✓ ${p.badge}', color: AppColors.brandLight),
                                    const SizedBox(height: 8),
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
                                          child: Text(p.type == 'Plot' ? p.sqft : '${p.sqft} sqft', style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
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
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
