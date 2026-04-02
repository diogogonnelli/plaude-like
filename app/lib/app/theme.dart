import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildPlaudeTheme() {
  const background = Color(0xFFF7F0E5);
  const surface = Color(0xFFFFFBF6);
  const ink = Color(0xFF221B16);
  const accent = Color(0xFFD97706);
  const secondary = Color(0xFF6B7280);

  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.light,
    surface: surface,
  ).copyWith(
    primary: accent,
    secondary: secondary,
    onPrimary: Colors.white,
    surface: surface,
    onSurface: ink,
    outline: const Color(0xFFD8CFC2),
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme().copyWith(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 52,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyLarge: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      color: ink,
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      color: ink,
      height: 1.45,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFE2D7C8)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFD8CFC2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFD8CFC2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFD8CFC2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
    ),
  );
}
