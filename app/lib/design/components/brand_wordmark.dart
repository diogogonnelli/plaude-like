import 'package:flutter/material.dart';

import '../tokens/brand_colors.dart';
import '../tokens/brand_typography.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.compact = false,
    this.showSpot = true,
    this.textColor = BrandColors.text,
    this.subtitleColor = BrandColors.textMuted,
  });

  final bool compact;
  final bool showSpot;
  final Color textColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 24.0 : 30.0;
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: subtitleColor);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Grav',
                    style: BrandTypography.wordmark(
                      size: titleSize,
                      color: textColor,
                    ),
                  ),
                  TextSpan(
                    text: 'Ação',
                    style: BrandTypography.wordmark(
                      size: titleSize,
                      color: BrandColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            Text('Inteligência de captura e execução', style: subtitleStyle),
          ],
        ),
        if (showSpot) const SpotEndorsement(),
      ],
    );
  }
}

class SpotEndorsement extends StatelessWidget {
  const SpotEndorsement({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpotSeal(size: 16),
        const SizedBox(width: 8),
        Text('SPOT', style: BrandTypography.institutionalLabel),
      ],
    );
  }
}

class SpotSeal extends StatelessWidget {
  const SpotSeal({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SpotBubble(letter: 'S', size: size),
        const SizedBox(width: 2),
        _SpotBubble(letter: 'P', size: size),
        const SizedBox(width: 2),
        _SpotBubble(size: size, filled: true),
        const SizedBox(width: 2),
        _SpotBubble(letter: 'T', size: size),
      ],
    );
  }
}

class _SpotBubble extends StatelessWidget {
  const _SpotBubble({required this.size, this.letter, this.filled = false});

  final double size;
  final String? letter;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? BrandColors.accent : BrandColors.shell,
      ),
      child: letter == null
          ? null
          : Text(
              letter!,
              style: BrandTypography.institutionalLabel.copyWith(
                color: Colors.white,
                fontSize: size * 0.48,
                letterSpacing: 0,
              ),
            ),
    );
  }
}
