import 'package:flutter/material.dart';

import '../tokens/plaude_colors.dart';
import '../tokens/plaude_motion.dart';
import '../tokens/plaude_radius.dart';

enum PlaudeButtonVariant { primary, secondary, ghost }

class PlaudeButton extends StatelessWidget {
  const PlaudeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PlaudeButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PlaudeButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      PlaudeButtonVariant.primary => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: PlaudeColors.clay,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlaudeRadius.pill),
            ),
          ),
          child: _Content(label: label, icon: icon),
        ),
      PlaudeButtonVariant.secondary => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: PlaudeColors.ink,
            side: const BorderSide(color: PlaudeColors.sand),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(PlaudeRadius.pill),
            ),
          ),
          child: _Content(label: label, icon: icon),
        ),
      PlaudeButtonVariant.ghost => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: PlaudeColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          child: _Content(label: label, icon: icon),
        ),
    };

    return AnimatedContainer(
      duration: PlaudeMotion.fast,
      curve: PlaudeMotion.curve,
      width: fullWidth ? double.infinity : null,
      child: button,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );
  }
}
