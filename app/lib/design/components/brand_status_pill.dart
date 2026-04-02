import 'package:flutter/material.dart';

import 'brand_badge.dart';
import '../tokens/brand_colors.dart';

enum BrandStatusTone { neutral, accent, success, warning, info }

class BrandStatusPill extends StatelessWidget {
  const BrandStatusPill({
    super.key,
    required this.label,
    this.tone = BrandStatusTone.neutral,
  });

  final String label;
  final BrandStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor, borderColor) = switch (tone) {
      BrandStatusTone.accent => (
        BrandColors.accent.withValues(alpha: 0.1),
        BrandColors.accent,
        BrandColors.accent.withValues(alpha: 0.16),
      ),
      BrandStatusTone.success => (
        BrandColors.positive.withValues(alpha: 0.1),
        const Color(0xFF087A45),
        BrandColors.positive.withValues(alpha: 0.16),
      ),
      BrandStatusTone.warning => (
        BrandColors.warning.withValues(alpha: 0.12),
        const Color(0xFFAA4300),
        BrandColors.warning.withValues(alpha: 0.16),
      ),
      BrandStatusTone.info => (
        BrandColors.info.withValues(alpha: 0.1),
        BrandColors.info,
        BrandColors.info.withValues(alpha: 0.16),
      ),
      BrandStatusTone.neutral => (
        BrandColors.surfaceMuted,
        BrandColors.shell,
        BrandColors.stroke,
      ),
    };

    return BrandBadge(
      label: label,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      borderColor: borderColor,
    );
  }
}
