import 'package:flutter/material.dart';

import 'forest_glow_background.dart';

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
    return ForestGlowBackground(force: true, child: child);
  }
}
