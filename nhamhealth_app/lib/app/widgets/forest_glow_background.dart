import 'package:flutter/material.dart';

/// Shared dark-mode background: a calm, layered green glow on near-black.
///
/// Usage:
/// ```dart
/// ForestGlowBackground(
///   child: Scaffold(
///     backgroundColor: Colors.transparent,
///     body: ...
///   ),
/// )
/// ```
class ForestGlowBackground extends StatelessWidget {
  const ForestGlowBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.force = false,
  });

  final Widget child;

  /// Toggle the faint floating particles. Everything else (glows, mist,
  /// vignette) is cheap enough to always keep on.
  final bool showParticles;

  /// Paint a route-local background even when the app-level background is
  /// already present. This keeps an incoming page visually complete while it
  /// animates over the previous route.
  final bool force;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alreadyWrapped =
        context.getInheritedWidgetOfExactType<_ForestGlowScope>() != null;

    if (!isDark || (alreadyWrapped && !force)) return child;

    return _ForestGlowScope(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF040A07)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _BaseGradient(),
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _ForestGlowPainter(showParticles: showParticles),
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

class _ForestGlowScope extends InheritedWidget {
  const _ForestGlowScope({required super.child});

  @override
  bool updateShouldNotify(_ForestGlowScope oldWidget) => false;
}

/// A single soft diagonal gradient — replaces the old 5-stop gradient with
/// something calmer and cheaper to render.
class _BaseGradient extends StatelessWidget {
  const _BaseGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF030806), Color(0xFF081A11), Color(0xFF030806)],
        ),
      ),
    );
  }
}

/// Three simple layers: two soft glows, an optional sprinkle of particles,
/// and a vignette to focus the eye toward the center. No trees, no waves,
/// no branch — just quiet depth.
class _ForestGlowPainter extends CustomPainter {
  const _ForestGlowPainter({required this.showParticles});

  final bool showParticles;

  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color softGreen = Color(0xFF86EFAC);

  static const List<Offset> _particlePositions = [
    Offset(0.10, 0.16),
    Offset(0.24, 0.34),
    Offset(0.46, 0.14),
    Offset(0.72, 0.22),
    Offset(0.88, 0.38),
    Offset(0.60, 0.68),
    Offset(0.30, 0.78),
    Offset(0.82, 0.82),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
      canvas,
      center: Offset(size.width * 0.75, size.height * 0.15),
      radius: size.shortestSide * 0.75,
      color: primaryGreen,
      peakAlpha: 0.14,
    );

    _paintGlow(
      canvas,
      center: Offset(size.width * 0.15, size.height * 0.80),
      radius: size.shortestSide * 0.85,
      color: primaryGreen,
      peakAlpha: 0.09,
    );

    if (showParticles) {
      _paintParticles(canvas, size);
    }

    _paintVignette(canvas, size);
  }

  void _paintGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double peakAlpha,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint =
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: peakAlpha),
              color.withValues(alpha: peakAlpha * 0.3),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  void _paintParticles(Canvas canvas, Size size) {
    for (var i = 0; i < _particlePositions.length; i++) {
      final point = Offset(
        _particlePositions[i].dx * size.width,
        _particlePositions[i].dy * size.height,
      );
      final radius = i.isEven ? 1.3 : 0.9;

      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = primaryGreen.withValues(alpha: 0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        point,
        radius,
        Paint()..color = softGreen.withValues(alpha: 0.45),
      );
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint =
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.transparent,
              const Color(0xFF020604).withValues(alpha: 0.42),
            ],
            stops: const [0.55, 1],
          ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ForestGlowPainter oldDelegate) =>
      oldDelegate.showParticles != showParticles;
}
