import 'package:flutter/material.dart';

import '../../../../theme/app_shadows.dart';

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
    final rect = Offset.zero & size;
    final innerRRect = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(innerRRect);

    for (final shadow in shadows) {
      final strokeWidth =
          (shadow.blurRadius * 1.7) + (shadow.spreadRadius * 2) + 1;
      final shadowRect = rect.inflate(shadow.spreadRadius).shift(shadow.offset);

      canvas.drawRRect(
        borderRadius.toRRect(shadowRect),
        Paint()
          ..color = shadow.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            shadow.blurSigma * 0.65,
          ),
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
