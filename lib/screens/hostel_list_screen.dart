import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../models/hostel_listing.dart';
import '../services/auth_service.dart';
import '../services/hostel_api.dart';
import '../theme/app_theme.dart';
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
  List<MyHostelListing> _listings = [];
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
      final type = ['PG', 'Hostel', 'Service Apt', 'Flat'].contains(_filter) ? _filter : null;
      final gender = _filter == 'For Men' ? 'Men' : (_filter == 'For Women' ? 'Women' : null);
      final listings = await HostelApi.fetchAll(type: type, gender: gender);
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

  void _selectFilter(String filter) {
    setState(() => _filter = filter);
    _load();
  }

  List<MyHostelListing> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return _listings;
    return _listings.where((l) => l.title.toLowerCase().contains(q) || l.location.toLowerCase().contains(q)).toList();
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
              titleStart: 'Find Your Perfect',
              titleHighlight: 'PG, Hostel or Flat',
              accentColor: AppColors.brand,
              child: HeroSearchBar(
                controller: _searchController,
                hint: 'Search by location, area, name...',
                accentColor: AppColors.brand,
                onSearch: () => setState(() {}),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilterChipRow<String>(
                    items: hostelFilters,
                    labelBuilder: (f) => f,
                    selected: _filter,
                    accentColor: AppColors.brand,
                    onSelect: _selectFilter,
                  ),
                  const SizedBox(height: 18),
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
                    Text('${filtered.length} PGs & Hostels Found', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text('No listings found.', style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
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
                          childAspectRatio: 0.68,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _HostelCard(listing: filtered[i]),
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

class _HostelCard extends StatelessWidget {
  final MyHostelListing listing;
  const _HostelCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HostelDetailScreen(listing: listing)),
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
                    PillBadge(label: listing.gender, color: AppColors.brand),
                    const SizedBox(height: 8),
                    Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text('📍 ${listing.location}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                    const SizedBox(height: 3),
                    Text(listing.type, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '₹${listing.startingPrice}', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.brand)),
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
