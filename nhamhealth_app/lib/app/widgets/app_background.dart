import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.lightDecoration,
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final Decoration? lightDecoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    if (!isDark) {
      if (lightDecoration case final decoration?) {
        return DecoratedBox(decoration: decoration, child: child);
      }
      return ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.asset(
                  'assets/images/background/bg.png',
                  fit: BoxFit.cover,
                  alignment: alignment,
                ),
              ),
            ),
            child,
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFF08100B),
            Color(0xFF101C14),
            Color(0xFF111713),
          ],
          stops: const [0, 0.58, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -150,
            right: -135,
            child: _AmbientGlow(
              color: colors.primary.withValues(alpha: 0.11),
              size: 340,
            ),
          ),
          Positioned(
            bottom: -170,
            left: -150,
            child: _AmbientGlow(
              color: colors.secondary.withValues(alpha: 0.08),
              size: 380,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0, 1],
            ),
          ),
        ),
      ),
    );
  }
}
