import 'package:flutter/material.dart';

import '../tokens/plaude_colors.dart';
import '../tokens/plaude_radius.dart';
import '../tokens/plaude_spacing.dart';

class PlaudeCard extends StatelessWidget {
  const PlaudeCard({
    super.key,
    required this.child,
    this.padding = PlaudeSpacing.cardInset,
    this.backgroundColor = PlaudeColors.paper,
    this.elevation = 0,
    this.outlined = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double elevation;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(PlaudeRadius.xl),
        border: outlined ? Border.all(color: PlaudeColors.sand) : null,
        boxShadow: elevation <= 0
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
