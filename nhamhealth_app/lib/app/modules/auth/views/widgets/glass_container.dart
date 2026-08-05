import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.blur = 20,
    this.opacity = 0.15,
    this.borderRadius = 24,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color.fromARGB(197, 208, 208, 208).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}