import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  final VoidCallback? onSearch;

  const HeroSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.accentColor,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: onSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: accentColor == AppColors.brand ? AppColors.brandOnDark : Colors.white,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: const Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
