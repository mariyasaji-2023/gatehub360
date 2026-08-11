import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // True black everywhere (OLED-friendly) — page, cards, tiles, and input
  // fields all share the same pure black. With no color/brightness
  // difference left to separate a box from the page behind it, definition
  // comes entirely from `border` — keep that one clearly visible.
  static const bg = Color(0xFF000000);
  static const card = Color(0xFF000000);
  static const surfaceAlt = Color(0xFF000000);
  static const border = Color(0xFF33415F);
  static const muted = Color(0xFF8892AD);
  static const text = Color(0xFFEEF2FC);

  // Brand blue (matches the logo's accent color) — the single accent used everywhere:
  // prices, CTAs, checkmarks, section identity, and all "Explore" links.
  // Brightened slightly from the light-theme value so it still pops on a dark page.
  static const brand = Color(0xFF4C9CFF);
  static const brandLight = Color(0xFF8CC4FF);
  static const brandDeep = Color(0xFF0F2E7A);
  // Text/icon color placed on top of the brand-blue surface (buttons, gradient
  // banners) — stays white regardless of the app's own light/dark background.
  static const brandOnDark = Color(0xFFFFFFFF);

  // Semantic status colors — not tied to brand identity.
  static const amber = Color(0xFFF5A623);
  static const danger = Color(0xFFFF6B6B);
  static const success = Color(0xFF3DD68C);

  // Elevation shadow for cards resting on the dark background — a plain black
  // falloff instead of the light theme's navy-tinted one, since a colored
  // shadow barely reads against a background this dark.
  static const shadow = Color(0x59000000);
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
        // Light status-bar icons (clock, battery, wifi) so they stay legible
        // against the dark app bar/background.
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
