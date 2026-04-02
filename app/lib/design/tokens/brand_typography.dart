import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand_colors.dart';

class BrandTypography {
  const BrandTypography._();

  static TextTheme textTheme(TextTheme base) {
    final roboto = GoogleFonts.robotoTextTheme(base);
    return roboto.copyWith(
      displayLarge: GoogleFonts.roboto(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        color: BrandColors.text,
        height: 0.92,
      ),
      headlineLarge: GoogleFonts.roboto(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        color: BrandColors.text,
        height: 1.0,
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: BrandColors.text,
      ),
      titleLarge: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: BrandColors.text,
      ),
      titleMedium: GoogleFonts.roboto(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: BrandColors.text,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: BrandColors.text,
        height: 1.46,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BrandColors.textMuted,
        height: 1.5,
      ),
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: BrandColors.text,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: BrandColors.textMuted,
        letterSpacing: 0.3,
      ),
    );
  }

  static TextStyle get institutionalLabel => GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: BrandColors.shell,
    letterSpacing: 1.4,
  );

  static TextStyle wordmark({
    double size = 26,
    Color color = BrandColors.text,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -1.0,
    );
  }
}
