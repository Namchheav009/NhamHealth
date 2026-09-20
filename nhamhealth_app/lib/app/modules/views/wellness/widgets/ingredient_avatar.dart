import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../services/wellness/ingredient_visual_service.dart';

class IngredientAvatar extends StatelessWidget {
  const IngredientAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.componentType,
    this.size = 50,
  });

  final String name;
  final String? imageUrl;
  final String? componentType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visual = IngredientVisualService.resolve(
      name,
      componentType: componentType,
      customImageUrl: imageUrl,
    );

    final resolvedUrl = visual.imageUrl;
    final isDark = context.appIsDark;

    Widget fallbackWidget() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? context.appSurfaceLow : visual.backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? context.appBorder : const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          visual.fallbackIcon,
          color: visual.iconColor,
          size: size * 0.48,
        ),
      ),
    );

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return fallbackWidget();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? context.appBorder : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: resolvedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => fallbackWidget(),
          errorWidget: (context, url, error) => fallbackWidget(),
        ),
      ),
    );
  }
}
