import 'package:flutter/material.dart';

import '../tokens/brand_colors.dart';
import '../tokens/brand_motion.dart';
import '../tokens/brand_radius.dart';
import '../tokens/brand_spacing.dart';

class BrandPanel extends StatelessWidget {
  const BrandPanel({
    super.key,
    required this.child,
    this.padding = BrandSpacing.panelInset,
    this.highlight = false,
    this.backgroundColor = BrandColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: BrandMotion.medium,
      curve: BrandMotion.standardCurve,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(BrandRadius.lg),
        border: Border.all(
          color: highlight
              ? BrandColors.accent.withValues(alpha: 0.26)
              : BrandColors.stroke,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.shellDark.withValues(
              alpha: highlight ? 0.12 : 0.06,
            ),
            blurRadius: highlight ? 34 : 22,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}
