import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';

/// Paints soft inset shadows inside a rounded surface.
///
/// A rounded hole is cut from a larger shadow layer and its edge is blurred.
/// Clipping the result keeps the blur entirely inside the card.
class InnerShadow extends StatelessWidget {
  const InnerShadow({
    super.key,
    required this.borderRadius,
    required this.child,
    this.shadows = AppShadows.innerSurface,
  });

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        foregroundPainter: _InnerShadowPainter(
          borderRadius: borderRadius,
          shadows: shadows,
        ),
        child: child,
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({
    required this.borderRadius,
    required this.shadows,
  });

  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || shadows.isEmpty) return;

    final rect = Offset.zero & size;
    final surface = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(surface, doAntiAlias: true);

    for (final shadow in shadows) {
      final spread = math.max(0.0, shadow.spreadRadius);
      final holeRect = rect.deflate(spread).shift(shadow.offset);
      if (holeRect.isEmpty) continue;

      final extra =
          shadow.blurRadius +
          spread +
          math.max(shadow.offset.dx.abs(), shadow.offset.dy.abs()) +
          2;
      final shadowPath =
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(rect.inflate(extra))
            ..addRRect(borderRadius.toRRect(holeRect));

      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InnerShadowPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.shadows != shadows;
  }
}
