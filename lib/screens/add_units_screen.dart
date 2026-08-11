import 'package:flutter/material.dart';
import '../models/property_unit.dart';
import '../theme/app_theme.dart';

class _UnitRow {
  final String label;
  final int bedsPerUnit;
  const _UnitRow(this.label, this.bedsPerUnit);
}

class _UnitSection {
  final String title;
  final List<_UnitRow> rows;
  const _UnitSection(this.title, this.rows);
}

const _sections = [
  _UnitSection('Room', [
    _UnitRow('Single Sharing', 1),
    _UnitRow('Double Sharing', 2),
    _UnitRow('3 Sharing', 3),
    _UnitRow('4 Sharing', 4),
    _UnitRow('5 Sharing', 5),
    _UnitRow('6 Sharing', 6),
  ]),
  _UnitSection('RK', [
    _UnitRow('1 RK', 1),
    _UnitRow('2 RK', 1),
  ]),
  _UnitSection('BHK', [
    _UnitRow('1 BHK', 1),
    _UnitRow('2 BHK', 1),
    _UnitRow('3 BHK', 1),
    _UnitRow('4 BHK', 1),
    _UnitRow('5 BHK', 1),
  ]),
  _UnitSection('Studio Apartment', [
    _UnitRow('Total Studio', 1),
  ]),
];

typedef UnitTotals = ({int units, int beds});

/// What [AddUnitsScreen] pops with - the aggregate totals for the calling
/// screen's own display, plus the per-row breakdown the backend needs to
/// create individual trackable units.
class UnitSubmission {
  final int units;
  final int beds;
  final List<UnitRowInput> rows;

  const UnitSubmission({required this.units, required this.beds, required this.rows});
}

/// Opened from a floor card's "Add Units" button — a stepper per unit type,
/// grouped into collapsible Room / RK / BHK / Studio Apartment sections.
/// Pops with the {units, beds} totals once at least one is added.
class AddUnitsScreen extends StatefulWidget {
  final String floor;

  const AddUnitsScreen({super.key, required this.floor});

  @override
  State<AddUnitsScreen> createState() => _AddUnitsScreenState();
}

class _AddUnitsScreenState extends State<AddUnitsScreen> {
  final Map<String, int> _counts = {};
  final Set<String> _expanded = {'Room'};

  int _sectionUnits(_UnitSection s) => s.rows.fold(0, (sum, r) => sum + (_counts[r.label] ?? 0));
  int _sectionBeds(_UnitSection s) => s.rows.fold(0, (sum, r) => sum + (_counts[r.label] ?? 0) * r.bedsPerUnit);

  int get _totalUnits => _sections.fold(0, (sum, s) => sum + _sectionUnits(s));
  int get _totalBeds => _sections.fold(0, (sum, s) => sum + _sectionBeds(s));

  void _change(String label, int delta) {
    setState(() {
      final next = (_counts[label] ?? 0) + delta;
      if (next < 0) return;
      _counts[label] = next;
    });
  }

  void _submit() {
    if (_totalUnits == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one unit first')));
      return;
    }
    final rows = <UnitRowInput>[
      for (final section in _sections)
        for (final row in section.rows)
          if ((_counts[row.label] ?? 0) > 0)
            UnitRowInput(type: section.title, label: row.label, beds: row.bedsPerUnit, count: _counts[row.label]!),
    ];
    Navigator.of(context).pop<UnitSubmission>(UnitSubmission(units: _totalUnits, beds: _totalBeds, rows: rows));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add units to ${widget.floor}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          for (final section in _sections) ...[
            _buildSection(section),
            const SizedBox(height: 14),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.brandOnDark,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add Units', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(_UnitSection section) {
    final expanded = _expanded.contains(section.title);
    final units = _sectionUnits(section);
    final beds = _sectionBeds(section);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (!_expanded.remove(section.title)) _expanded.add(section.title);
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppColors.brand.withValues(alpha: 0.06),
              child: Row(
                children: [
                  Text(section.title, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      '$units Unit/ $beds Bed',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.brand, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.brand),
                ],
              ),
            ),
          ),
          if (expanded)
            for (final row in section.rows)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Row(
                  children: [
                    Expanded(child: Text(row.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                    _StepperButton(icon: Icons.remove_circle_outline, onTap: () => _change(row.label, -1)),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${_counts[row.label] ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _StepperButton(icon: Icons.add_circle_outline, onTap: () => _change(row.label, 1)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: AppColors.brand, size: 22),
      ),
    );
  }
}
