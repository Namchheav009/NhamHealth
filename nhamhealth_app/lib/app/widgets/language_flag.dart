import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class LanguageFlag extends StatelessWidget {
  const LanguageFlag({super.key, required this.languageCode, this.size = 34});

  final String languageCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath =
        languageCode == 'km'
            ? 'assets/icons/lang/world.png'
            : 'assets/icons/lang/circle.png';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        shape: BoxShape.circle,
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
