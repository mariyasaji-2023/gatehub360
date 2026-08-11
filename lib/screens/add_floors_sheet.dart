import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

String _ordinalFloor(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th Floor';
  switch (n % 10) {
    case 1:
      return '${n}st Floor';
    case 2:
      return '${n}nd Floor';
    case 3:
      return '${n}rd Floor';
    default:
      return '${n}th Floor';
  }
}

final List<String> floorOptions = [
  'Basement',
  'Ground Floor',
  for (var i = 1; i <= 20; i++) _ordinalFloor(i),
];

/// Bottom sheet opened from "Add Your First Floor" — lets an owner pick one
/// or more floors at once. Pops with the selected floor names, or null if
/// dismissed without picking any.
class AddFloorsSheet extends StatefulWidget {
  const AddFloorsSheet({super.key});

  @override
  State<AddFloorsSheet> createState() => _AddFloorsSheetState();
}

class _AddFloorsSheetState extends State<AddFloorsSheet> {
  final Set<String> _selected = {};

  void _toggle(String floor) {
    setState(() {
      if (!_selected.remove(floor)) _selected.add(floor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 16, 12, 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text('Select floors to add', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700)),
                Positioned(
                  right: 0,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: AppColors.text),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: floorOptions.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                final floor = floorOptions[index];
                final selected = _selected.contains(floor);
                return InkWell(
                  onTap: () => _toggle(floor),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        _CircleCheckbox(selected: selected),
                        const SizedBox(width: 16),
                        Text(floor, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                  child: Text(
                    _selected.isEmpty
                        ? 'Select floors'
                        : 'Add ${_selected.length} Floor${_selected.length > 1 ? 's' : ''}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleCheckbox extends StatelessWidget {
  final bool selected;
  const _CircleCheckbox({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.brand : Colors.transparent,
        border: Border.all(color: selected ? AppColors.brand : AppColors.border, width: 2),
      ),
      child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}
