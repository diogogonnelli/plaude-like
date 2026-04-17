import 'package:flutter/material.dart';

import '../tokens/brand_colors.dart';
import '../tokens/brand_radius.dart';
import '../tokens/brand_spacing.dart';
import '../tokens/brand_typography.dart';

class BrandBadge extends StatelessWidget {
  const BrandBadge({
    super.key,
    required this.label,
    this.leading,
    this.backgroundColor = BrandColors.surface,
    this.foregroundColor = BrandColors.text,
    this.borderColor = BrandColors.stroke,
  });

  final String label;
  final Widget? leading;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: BrandSpacing.chipPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(BrandRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: BrandSpacing.xs),
          ],
          Text(
            label,
            style: BrandTypography.institutionalLabel.copyWith(
              color: foregroundColor,
              fontSize: 10.6,
            ),
          ),
        ],
      ),
    );
  }
}
