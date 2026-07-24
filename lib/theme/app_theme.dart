import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF000000);
  static const card = Color(0xFF141414);
  static const surfaceAlt = Color(0xFF1F1F1F);
  static const border = Color(0xFF2B2B2B);
  static const muted = Color(0xFF9CA3AF);
  static const text = Color(0xFFFFFFFF);

  // Brand blue (matches the logo's accent color) — the single accent used everywhere:
  // prices, CTAs, checkmarks, section identity, and all "Explore" links.
  static const brand = Color(0xFF1D82EA);
  static const brandLight = Color(0xFF6FB2F5);
  static const brandOnDark = Color(0xFFFFFFFF);

  // Semantic status colors — not tied to brand identity.
  static const amber = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
}

class AppFonts {
  static TextStyle heading({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w800,
    Color color = AppColors.text,
    double? height,
  }) {
    return TextStyle(fontFamily: 'Poppins', fontSize: fontSize, fontWeight: fontWeight, color: color, height: height);
  }
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true, fontFamily: 'DM Sans');
    final textTheme = base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.brand,
        secondary: AppColors.brand,
        surface: AppColors.card,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.brandOnDark,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11.5),
      ),
    );
  }
}
