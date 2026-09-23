import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../config/api_config.dart';
import '../../../../theme/app_colors.dart';
import '../../../services/wellness/ingredient_visual_service.dart';

class IngredientAvatar extends StatelessWidget {
  const IngredientAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.componentType,
    this.size = 56,
    this.borderRadius = 16,
  });

  final String name;
  final String? imageUrl;
  final String? componentType;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final visual = IngredientVisualService.resolve(
      name,
      componentType: componentType,
      customImageUrl: imageUrl,
    );

    final rawUrl = visual.imageUrl;
    final resolvedUrl =
        rawUrl != null && rawUrl.startsWith('/')
            ? '${ApiConfig.baseUrl}$rawUrl'
            : rawUrl;
    final isDark = context.appIsDark;

    Widget fallbackWidget() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? context.appSurfaceLow : visual.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color:
              isDark
                  ? context.appBorder
                  : visual.iconColor.withValues(alpha: 0.12),
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

    return Semantics(
      image: true,
      label: name,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark ? context.appBorder : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - 1.5),
          child: CachedNetworkImage(
            imageUrl: resolvedUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 220),
            memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
            placeholder:
                (context, url) => Stack(
                  fit: StackFit.expand,
                  children: [
                    fallbackWidget(),
                    Center(
                      child: SizedBox.square(
                        dimension: size * 0.28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: visual.iconColor.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
            errorWidget: (context, url, error) => fallbackWidget(),
          ),
        ),
      ),
    );
  }
}
