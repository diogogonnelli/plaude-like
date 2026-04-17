import 'package:flutter/material.dart';

import '../design/brand_design_system.dart';

ThemeData buildGravacaoTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: BrandColors.accent,
        brightness: Brightness.light,
        surface: BrandColors.surface,
      ).copyWith(
        primary: BrandColors.accent,
        secondary: BrandColors.shell,
        onPrimary: Colors.white,
        surface: BrandColors.surface,
        onSurface: BrandColors.text,
        outline: BrandColors.strokeStrong,
        error: BrandColors.accent,
      );

  final textTheme = BrandTypography.textTheme(ThemeData.light().textTheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BrandColors.canvas,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      color: BrandColors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BrandRadius.lg),
        side: const BorderSide(color: BrandColors.stroke),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BrandColors.surfaceMuted,
      side: const BorderSide(color: BrandColors.stroke),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BrandRadius.pill),
      ),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.surface,
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandRadius.md),
        borderSide: const BorderSide(color: BrandColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandRadius.md),
        borderSide: const BorderSide(color: BrandColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BrandRadius.md),
        borderSide: const BorderSide(color: BrandColors.accent, width: 1.5),
      ),
    ),
    dividerColor: BrandColors.stroke,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BrandColors.surface.withValues(alpha: 0.96),
      indicatorColor: BrandColors.accent.withValues(alpha: 0.1),
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: BrandColors.accent.withValues(alpha: 0.1),
      selectedIconTheme: const IconThemeData(color: BrandColors.accent),
      unselectedIconTheme: const IconThemeData(color: BrandColors.textMuted),
      selectedLabelTextStyle: textTheme.labelMedium,
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: BrandColors.textMuted,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.accent,
      foregroundColor: Colors.white,
    ),
  );
}
