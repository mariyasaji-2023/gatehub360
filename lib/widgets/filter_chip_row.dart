import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterChipRow<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) labelBuilder;
  final T selected;
  final ValueChanged<T> onSelect;
  final Color accentColor;
  final String? leadingLabel;

  const FilterChipRow({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.selected,
    required this.onSelect,
    this.accentColor = AppColors.brand,
    this.leadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (leadingLabel != null)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Text(leadingLabel!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ),
        for (final item in items)
          _Chip(
            label: labelBuilder(item),
            selected: item == selected,
            accentColor: accentColor,
            onTap: () => onSelect(item),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accentColor.withValues(alpha: 0.18) : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? accentColor.withValues(alpha: 0.5) : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? accentColor : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
