import 'package:flutter/material.dart';

import '../tokens/brand_colors.dart';

class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: BrandColors.canvasGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              Positioned(
                top: -width * 0.14,
                right: -width * 0.04,
                child: _OutlineOrb(
                  size: width.clamp(180.0, 340.0) * 0.72,
                  color: BrandColors.accent.withValues(alpha: 0.14),
                ),
              ),
              Positioned(
                top: width < 700 ? 118 : 146,
                left: -22,
                child: _StripedOrb(
                  size: width.clamp(140.0, 260.0) * 0.6,
                  color: BrandColors.shell.withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                bottom: -44,
                left: width < 860 ? -18 : width * 0.18,
                child: _FilledOrb(
                  size: width.clamp(180.0, 320.0) * 0.54,
                  color: BrandColors.accent.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                bottom: width < 820 ? 54 : 68,
                right: width < 820 ? -10 : 12,
                child: _DottedOrb(
                  size: width.clamp(160.0, 240.0) * 0.58,
                  color: BrandColors.shell.withValues(alpha: 0.18),
                ),
              ),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _FilledOrb extends StatelessWidget {
  const _FilledOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _OutlineOrb extends StatelessWidget {
  const _OutlineOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

class _StripedOrb extends StatelessWidget {
  const _StripedOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StripedCirclePainter(color),
    );
  }
}

class _DottedOrb extends StatelessWidget {
  const _DottedOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _DottedCirclePainter(color),
    );
  }
}

class _StripedCirclePainter extends CustomPainter {
  _StripedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final clip = Path()..addOval(rect);
    canvas.save();
    canvas.clipPath(clip);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (double y = 8; y < size.height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StripedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DottedCirclePainter extends CustomPainter {
  _DottedCirclePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final paint = Paint()..color = color;
    for (double y = 6; y < size.height; y += 12) {
      for (double x = 6; x < size.width; x += 12) {
        final offset = Offset(x, y);
        if ((offset - center).distance <= radius) {
          canvas.drawCircle(offset, 1.8, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
