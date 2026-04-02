import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'plaude_colors.dart';

class PlaudeTypography {
  const PlaudeTypography._();

  static TextTheme textTheme() {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 56,
        height: 0.95,
        fontWeight: FontWeight.w800,
        color: PlaudeColors.ink,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 44,
        height: 1,
        fontWeight: FontWeight.w800,
        color: PlaudeColors.ink,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        height: 1.05,
        fontWeight: FontWeight.w800,
        color: PlaudeColors.ink,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: PlaudeColors.ink,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: PlaudeColors.ink,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: PlaudeColors.ink,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 1.45,
        color: PlaudeColors.ink,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 1.45,
        color: PlaudeColors.ink,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: PlaudeColors.ink,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: PlaudeColors.smoke,
      ),
    );
  }
}
