import 'package:flutter/material.dart';

import '../tokens/plaude_colors.dart';
import '../tokens/plaude_radius.dart';
import '../tokens/plaude_spacing.dart';

class PlaudeBadge extends StatelessWidget {
  const PlaudeBadge({
    super.key,
    required this.label,
    this.leading,
    this.backgroundColor = PlaudeColors.paper,
    this.foregroundColor = PlaudeColors.ink,
  });

  final String label;
  final Widget? leading;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(PlaudeRadius.pill),
        border: Border.all(color: PlaudeColors.sand),
      ),
      child: Padding(
        padding: PlaudeSpacing.chipPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(size: 14, color: foregroundColor),
                child: leading!,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
