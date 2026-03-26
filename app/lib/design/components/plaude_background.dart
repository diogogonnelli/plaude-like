import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/plaude_colors.dart';
import '../tokens/plaude_radius.dart';

class PlaudeBackground extends StatelessWidget {
  const PlaudeBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  final Widget child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF4EFE7),
            Color(0xFFF9F6F1),
            Color(0xFFE9E1D3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          if (showOrbs) ...[
            const Positioned(
              top: -80,
              left: -60,
              child: _Orb(size: 240, color: Color(0x33DA6B2D)),
            ),
            const Positioned(
              bottom: -100,
              right: -40,
              child: _Orb(size: 260, color: Color(0x3353624B)),
            ),
          ],
          Positioned.fill(
            child: CustomPaint(
              painter: _MeshPainter(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PlaudeColors.sand.withValues(alpha: 0.26)
      ..strokeWidth = 1;

    const spacing = 64.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PlaudeArcBackdrop extends StatelessWidget {
  const PlaudeArcBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(PlaudeRadius.xl),
        border: Border.all(color: PlaudeColors.sand),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PlaudeRadius.xl),
        child: Stack(
          children: [
            Positioned(
              right: -90,
              top: -90,
              child: Transform.rotate(
                angle: math.pi / 5,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: PlaudeColors.haloGradient,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
