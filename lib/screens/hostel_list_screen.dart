import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../models/hostel_listing.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/emoji_tile.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/hero_search_bar.dart';
import '../widgets/pill_badge.dart';
import '../widgets/section_hero.dart';
import 'hostel_detail_screen.dart';

class HostelListScreen extends StatefulWidget {
  const HostelListScreen({super.key});

  @override
  State<HostelListScreen> createState() => _HostelListScreenState();
}

class _HostelListScreenState extends State<HostelListScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All';
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HostelListing> get _filtered {
    return hostelListings.where((l) {
      final matchFilter = _filter == 'All' ||
          l.type == _filter ||
          (_filter == 'For Men' && l.gender == 'Men') ||
          (_filter == 'For Women' && l.gender == 'Women');
      final q = _search.toLowerCase();
      final matchSearch = l.title.toLowerCase().contains(q) || l.location.toLowerCase().contains(q);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHero(
            titleStart: 'Find Your Perfect',
            titleHighlight: 'PG, Hostel or Flat',
            accentColor: AppColors.brand,
            child: HeroSearchBar(
              controller: _searchController,
              hint: 'Search by location, area, name...',
              accentColor: AppColors.brand,
              onSearch: () => setState(() => _search = _searchController.text),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Owner Features', style: AppFonts.heading(fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ...hostelOwnerFeatures.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DarkCard(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.icon, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.title, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(f.desc, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${filtered.length} PGs & Hostels Found', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                FilterChipRow<String>(
                  items: hostelFilters,
                  labelBuilder: (f) => f,
                  selected: _filter,
                  accentColor: AppColors.brand,
                  onSelect: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _HostelCard(listing: filtered[i]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HostelCard extends StatelessWidget {
  final HostelListing listing;
  const _HostelCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HostelDetailScreen(id: listing.id)),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiTile(
                emoji: listing.emoji,
                color: AppColors.brand,
                height: 90,
                fontSize: 34,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PillBadge(label: '✓ ${listing.badge}', color: AppColors.brand),
                    const SizedBox(height: 8),
                    Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('📍 ${listing.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    const SizedBox(height: 3),
                    Text('⭐ ${listing.rating} (${listing.reviews})', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '₹${listing.price}', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brand)),
                          const TextSpan(text: '/mo', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        ],
                      ),
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
