import 'dart:math';

import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

enum _Tab { overview, amenities, price, emi }

double _parsePriceToRupees(String price) {
  final isCrore = price.contains('Cr');
  final numPart = double.tryParse(price.replaceAll(RegExp(r'[A-Za-z/,₹]'), '')) ?? 0;
  return isCrore ? numPart * 10000000 : numPart * 100000;
}

double _monthlyEmi(String priceStr, int years) {
  final principal = _parsePriceToRupees(priceStr) * 0.8;
  const r = 0.085 / 12;
  final n = years * 12;
  return principal * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
}

class PropertyDetailScreen extends StatefulWidget {
  final int id;
  const PropertyDetailScreen({super.key, required this.id});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  _Tab _tab = _Tab.overview;
  int _years = 20;

  @override
  Widget build(BuildContext context) {
    final d = propertyDetailFor(widget.id);

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
                  Text(d.emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      PillBadge(label: '✓ ${d.badge}', color: AppColors.brand),
                      PillBadge(label: d.status, color: AppColors.brandLight),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(d.title, style: AppFonts.heading(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('📍 ${d.location} · ${d.bhk} · ${d.sqft} sqft · Floor ${d.floor}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  Text('₹${d.price}', style: AppFonts.heading(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.brand)),
                  const SizedBox(height: 6),
                  Text('Builder: ${d.builder} · Facing: ${d.facing} · ${d.age}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                          child: const Text('Contact Builder'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(onPressed: () {}, child: const Text('Schedule Visit')),
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
                children: [
                  _tabChip(_Tab.overview, 'Overview'),
                  _tabChip(_Tab.amenities, 'Amenities'),
                  _tabChip(_Tab.price, 'Price'),
                  _tabChip(_Tab.emi, 'EMI Calculator'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            switch (_tab) {
              _Tab.overview => DarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About This Property', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(d.about, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6)),
                    ],
                  ),
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
                                const Text('✓', style: TextStyle(color: AppColors.brandLight, fontSize: 15)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(a, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              _Tab.price => DarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price Breakdown', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...d.priceBreakdown.entries.map((e) {
                        final isTotal = e.key == 'Total Cost';
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: isTotal ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                              Text(e.value, style: TextStyle(fontSize: 13.5, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400, color: isTotal ? AppColors.brand : AppColors.text)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              _Tab.emi => DarkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EMI Calculator', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 18),
                      Text('Loan Tenure: $_years years', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                      Slider(
                        value: _years.toDouble(),
                        min: 5,
                        max: 30,
                        divisions: 25,
                        label: '$_years years',
                        activeColor: AppColors.brand,
                        onChanged: (v) => setState(() => _years = v.round()),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            const Text('Estimated Monthly EMI (8.5% interest)', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
                            const SizedBox(height: 8),
                            Text(
                              '${formatInr(_monthlyEmi(d.price, _years))}/mo',
                              style: AppFonts.heading(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.brand),
                            ),
                            const SizedBox(height: 8),
                            Text('For 80% loan amount at 8.5% p.a. over $_years years', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }

  Widget _tabChip(_Tab t, String label) {
    final selected = _tab == t;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _tab = t),
        selectedColor: AppColors.brand.withValues(alpha: 0.18),
        backgroundColor: AppColors.card,
        labelStyle: TextStyle(color: selected ? AppColors.brandLight : AppColors.muted, fontSize: 13),
        side: BorderSide(color: selected ? AppColors.brand.withValues(alpha: 0.4) : AppColors.border),
      ),
    );
  }
}
