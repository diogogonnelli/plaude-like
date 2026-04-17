import 'package:flutter/material.dart';

import '../tokens/brand_colors.dart';
import '../tokens/brand_typography.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.compact = false,
    this.showSpot = true,
    this.showSpotText = true,
    this.leadingSeal = false,
    this.showSubtitle = false,
    this.textColor = BrandColors.text,
    this.subtitleColor = BrandColors.textMuted,
  });

  final bool compact;
  final bool showSpot;
  final bool showSpotText;
  final bool leadingSeal;
  final bool showSubtitle;
  final Color textColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 24.0 : 30.0;
    final sealSize = compact ? 18.0 : 20.0;
    final sealWidth = (sealSize * 4) + 6;
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: subtitleColor);

    final title = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Grav',
            style: BrandTypography.wordmark(size: titleSize, color: textColor),
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
    );

    final mark = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        if (showSubtitle)
          Text('Inteligência de captura e execução', style: subtitleStyle),
      ],
    );

    final lockup = leadingSeal
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SpotSeal(size: sealSize),
                  const SizedBox(width: 10),
                  Flexible(child: title),
                ],
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(left: sealWidth + 10),
                  child: Text(
                    'Inteligência de captura e execução',
                    style: subtitleStyle,
                  ),
                ),
              ],
            ],
          )
        : mark;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        lockup,
        if (showSpot) SpotEndorsement(showText: showSpotText),
      ],
    );
  }
}

class SpotEndorsement extends StatelessWidget {
  const SpotEndorsement({super.key, this.showText = true});

  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SpotSeal(size: 16),
        if (showText) ...[
          const SizedBox(width: 8),
          Text('SPOT', style: BrandTypography.institutionalLabel),
        ],
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
