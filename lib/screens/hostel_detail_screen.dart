import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

enum _Tab { overview, rooms, amenities, location, rules }

class HostelDetailScreen extends StatefulWidget {
  final int id;
  const HostelDetailScreen({super.key, required this.id});

  @override
  State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  _Tab _tab = _Tab.overview;

  @override
  Widget build(BuildContext context) {
    final d = hostelDetailFor(widget.id);

    return Scaffold(
      appBar: AppBar(title: Text(d.title, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.brand.withValues(alpha: 0.15), AppColors.brand.withValues(alpha: 0.03)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PillBadge(label: '✓ ${d.badge}', color: AppColors.brand),
                      PillBadge(label: d.type, color: AppColors.brandLight),
                      PillBadge(label: d.gender, color: AppColors.brandLight),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(d.title, style: AppFonts.heading(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('📍 ${d.location}', style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('⭐ ${d.rating} (${d.reviews} reviews)', style: const TextStyle(fontSize: 13.5, color: AppColors.amber)),
                      const SizedBox(width: 14),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(text: '₹${d.price}', style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.brand)),
                          const TextSpan(text: '/month', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                          child: const Text('Book Now'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(onPressed: () {}, child: const Text('📞 Call Owner')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _Tab.values.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                    selected: _tab == t,
                    onSelected: (_) => setState(() => _tab = t),
                    selectedColor: AppColors.brand.withValues(alpha: 0.18),
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(color: _tab == t ? AppColors.brandLight : AppColors.muted, fontSize: 13),
                    side: BorderSide(color: _tab == t ? AppColors.brand.withValues(alpha: 0.4) : AppColors.border),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 18),
            switch (_tab) {
              _Tab.overview => Column(
                  children: [
                    DarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About This Property', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Text(d.about, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Owner Details', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                child: const Text('👤', style: TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d.owner, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                                  Text(d.phone, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              _Tab.rooms => Column(
                  children: d.rooms
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DarkCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.name, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(text: '₹${r.price}', style: AppFonts.heading(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.brand)),
                                      const TextSpan(text: '/month', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                                    ]),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('${r.available} beds available', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                                      child: const Text('Book This Room'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              _Tab.amenities => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: d.amenities
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.brand.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Text('✓', style: TextStyle(color: AppColors.brand, fontSize: 15)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(a, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              _Tab.location => DarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nearby Landmarks', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...d.nearby.map((n) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                const Text('📍'),
                                const SizedBox(width: 10),
                                Expanded(child: Text(n, style: const TextStyle(fontSize: 13.5, color: AppColors.muted))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              _Tab.rules => DarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('House Rules', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...d.rules.map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Text('•', style: TextStyle(color: AppColors.danger, fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(r, style: const TextStyle(fontSize: 13.5, color: AppColors.muted))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }
}
