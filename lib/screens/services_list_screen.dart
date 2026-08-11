import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/section_hero.dart';
import 'profile_screen.dart';
import 'service_detail_screen.dart';

const _serviceIcons = {
  'plumbing': Icons.plumbing_outlined,
  'electrician': Icons.electrical_services_outlined,
  'ac-service': Icons.ac_unit_outlined,
  'painting': Icons.format_paint_outlined,
  'cleaning': Icons.cleaning_services_outlined,
  'carpentry': Icons.carpenter_outlined,
  'upvc-windows': Icons.window_outlined,
  'cctv': Icons.videocam_outlined,
  'locksmith': Icons.lock_outline,
  'bathroom': Icons.bathtub_outlined,
};

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AuthService.syncCurrentUser();
      if (!mounted) return;
      setState(() => _user = user);
    } catch (_) {
      // Greeting just falls back to a nameless "Hello," — not worth an error state.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.toLowerCase();
    final filtered = serviceOfferings.where((s) => s.name.toLowerCase().contains(q)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          HomeGreetingHeader(
            name: _user?.name,
            photoUrl: _user?.photoURL,
            onBellTap: null,
            onAvatarTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          const SectionHero(
            titleStart: 'Home',
            titleHighlight: 'Services',
            accentColor: AppColors.brand,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _search = v),
                            style: const TextStyle(color: AppColors.text, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Filters & Search',
                              hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                              filled: false,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Icon(Icons.search, size: 20, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters coming soon')),
                  ),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.tune, size: 20, color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
              children: filtered.map((s) {
                final isQuote = s.price.toLowerCase().contains('quote');
                return DarkCard(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(slug: s.slug))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_serviceIcons[s.slug] ?? Icons.build_outlined, size: 26, color: AppColors.brand),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.heading(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.desc,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.price,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isQuote ? AppColors.muted : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
