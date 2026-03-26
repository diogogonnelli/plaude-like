import 'package:flutter/material.dart';

class PlaudeColors {
  const PlaudeColors._();

  static const ink = Color(0xFF1D1B1A);
  static const paper = Color(0xFFFFFBF6);
  static const canvas = Color(0xFFF4EFE7);
  static const clay = Color(0xFFDA6B2D);
  static const clayDark = Color(0xFFB24F1D);
  static const olive = Color(0xFF53624B);
  static const moss = Color(0xFF7C8A73);
  static const sand = Color(0xFFE2D7C8);
  static const smoke = Color(0xFF6F6A66);
  static const success = Color(0xFF2F7D53);
  static const warning = Color(0xFFC88A1A);
  static const danger = Color(0xFFB42318);

  static const warmGradient = LinearGradient(
    colors: [
      Color(0xFF231B18),
      Color(0xFF5A443B),
      Color(0xFFB45E2B),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const haloGradient = LinearGradient(
    colors: [
      Color(0x33DA6B2D),
      Color(0x00DA6B2D),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: clay,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFCE6D9),
      onPrimaryContainer: Color(0xFF4F220E),
      secondary: olive,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE6ECE0),
      onSecondaryContainer: Color(0xFF1F281B),
      tertiary: moss,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE8EDE3),
      onTertiaryContainer: Color(0xFF243023),
      error: danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE4E2),
      onErrorContainer: Color(0xFF5D0B08),
      surface: paper,
      onSurface: ink,
      surfaceContainerHighest: Color(0xFFF4EBDF),
      onSurfaceVariant: smoke,
      outline: sand,
      outlineVariant: Color(0xFFE9DED1),
      shadow: Color(0x33000000),
      scrim: Color(0x66000000),
      inverseSurface: ink,
      onInverseSurface: paper,
      inversePrimary: Color(0xFFF0B48C),
    );
  }
}
