import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.homeBackground,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background/bg.png',
            fit: BoxFit.cover,
            alignment: alignment,
          ),
        ),
        child,
      ],
    ),
  );
}
