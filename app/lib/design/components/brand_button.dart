import 'package:flutter/material.dart';

import '../tokens/brand_colors.dart';
import '../tokens/brand_motion.dart';
import '../tokens/brand_radius.dart';

enum BrandButtonVariant { primary, secondary, ghost }

class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = BrandButtonVariant.primary,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BrandButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final button = switch (variant) {
      BrandButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: BrandColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BrandRadius.pill),
          ),
        ),
        child: child,
      ),
      BrandButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.shellDark,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: BrandColors.stroke),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BrandRadius.pill),
          ),
        ),
        child: child,
      ),
      BrandButtonVariant.ghost => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.shell,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BrandRadius.pill),
          ),
        ),
        child: child,
      ),
    };

    return AnimatedContainer(
      duration: BrandMotion.fast,
      curve: BrandMotion.standardCurve,
      width: expanded ? double.infinity : null,
      child: button,
    );
  }
}
