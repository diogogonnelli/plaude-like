import 'package:flutter/material.dart';

import '../tokens/plaude_colors.dart';
import '../tokens/plaude_radius.dart';
import '../tokens/plaude_spacing.dart';

class PlaudeTranscriptBlock extends StatelessWidget {
  const PlaudeTranscriptBlock({
    super.key,
    required this.speaker,
    required this.timestamp,
    required this.text,
    this.highlight = false,
  });

  final String speaker;
  final String timestamp;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: PlaudeSpacing.cardInsetCompact,
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFF8EBDD) : const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(PlaudeRadius.lg),
        border: Border.all(
          color: highlight ? PlaudeColors.clay.withValues(alpha: 0.34) : PlaudeColors.sand,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(speaker, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 8),
              Text(
                timestamp,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
