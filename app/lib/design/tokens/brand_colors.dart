import 'package:flutter/material.dart';

class BrandColors {
  const BrandColors._();

  static const canvas = Color(0xFFF7F8FA);
  static const canvasAlt = Color(0xFFF0F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8F9FB);
  static const stroke = Color(0xFFD8DADF);
  static const strokeStrong = Color(0xFFB6BBC4);
  static const shell = Color(0xFF666362);
  static const shellDark = Color(0xFF3F3D3C);
  static const text = Color(0xFF1F252C);
  static const textMuted = Color(0xFF6E7680);
  static const accent = Color(0xFFDE0C2F);
  static const accentSoft = Color(0xFFF05A6C);
  static const positive = Color(0xFF02B663);
  static const warning = Color(0xFFFF6D37);
  static const info = Color(0xFF2934F1);

  static const heroGradient = LinearGradient(
    colors: [shellDark, shell, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const canvasGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), canvas, canvasAlt],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
