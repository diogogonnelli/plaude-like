import 'package:flutter/material.dart';

import '../tokens/plaude_colors.dart';
import 'plaude_badge.dart';

enum PlaudeStatusTone { info, success, warning, danger, neutral }

class PlaudeStatusChip extends StatelessWidget {
  const PlaudeStatusChip({
    super.key,
    required this.label,
    this.tone = PlaudeStatusTone.neutral,
  });

  final String label;
  final PlaudeStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = switch (tone) {
      PlaudeStatusTone.info => (PlaudeColors.olive, const Color(0xFFE8EDE3)),
      PlaudeStatusTone.success => (PlaudeColors.success, const Color(0xFFE5F5EA)),
      PlaudeStatusTone.warning => (PlaudeColors.warning, const Color(0xFFFFF0CC)),
      PlaudeStatusTone.danger => (PlaudeColors.danger, const Color(0xFFFEE4E2)),
      PlaudeStatusTone.neutral => (PlaudeColors.smoke, const Color(0xFFF2ECE4)),
    };

    return PlaudeBadge(
      label: label,
      backgroundColor: palette.$2,
      foregroundColor: palette.$1,
      leading: Icon(
        Icons.brightness_1,
        size: 8,
        color: palette.$1,
      ),
    );
  }
}
