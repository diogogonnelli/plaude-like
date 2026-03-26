import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'plaude_colors.dart';

class PlaudeTypography {
  const PlaudeTypography._();

  static TextTheme textTheme() {
    final base = GoogleFonts.spaceGroteskTextTheme();
    return GoogleFonts.dmSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 56,
        height: 0.95,
        fontWeight: FontWeight.w700,
        color: PlaudeColors.ink,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 44,
        height: 1,
        fontWeight: FontWeight.w700,
        color: PlaudeColors.ink,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        height: 1.05,
        fontWeight: FontWeight.w700,
        color: PlaudeColors.ink,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        height: 1.1,
        fontWeight: FontWeight.w700,
        color: PlaudeColors.ink,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: PlaudeColors.ink,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: PlaudeColors.ink,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        height: 1.45,
        color: PlaudeColors.ink,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        height: 1.45,
        color: PlaudeColors.ink,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: PlaudeColors.ink,
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: PlaudeColors.smoke,
      ),
    );
  }
}
