import 'package:flutter/material.dart';

import '../tokens/plaude_colors.dart';
import '../tokens/plaude_radius.dart';
import '../tokens/plaude_spacing.dart';

class PlaudeStatTile extends StatelessWidget {
  const PlaudeStatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PlaudeSpacing.cardInsetCompact,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(PlaudeRadius.lg),
        border: Border.all(color: PlaudeColors.sand),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF6E8DD),
                borderRadius: BorderRadius.circular(PlaudeRadius.md),
              ),
              child: Icon(icon, color: PlaudeColors.clay),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                if (caption != null) ...[
                  const SizedBox(height: 4),
                  Text(caption!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
