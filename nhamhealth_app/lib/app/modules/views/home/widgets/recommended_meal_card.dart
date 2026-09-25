import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/meal_localization_helpers.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_nutrient_theme.dart';
import '../../../models/home/recommended_meal_model.dart';

class RecommendedMealCard extends StatelessWidget {
  const RecommendedMealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    this.width,
  });

  final RecommendedMealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? 156.0;
    final isWide = effectiveWidth >= 180.0;
    final imageHeight = isWide ? 118.0 : 108.0;
    const radius = 14.0;

    return Container(
      width: effectiveWidth,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
        boxShadow: context.appTileShadow,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(radius - 1),
                    ),
                    child: _MealImage(path: meal.image, height: imageHeight),
                  ),
                  Positioned(
                    left: 7,
                    top: 7,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 92),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.accentOrange,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              'common.recommended'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: isWide ? 9 : 7,
                    top: isWide ? 9 : 7,
                    child: InkWell(
                      onTap: onFavorite,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: isWide ? 32 : 30,
                        height: isWide ? 32 : 30,
                        decoration: BoxDecoration(
                          color: context.appElevatedSurface.withValues(
                            alpha: 0.94,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: context.appBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey<bool>(isFavorite),
                            size: isWide ? 20 : 18,
                            color:
                                isFavorite
                                    ? AppColors.favoriteRed
                                    : const Color(0xFF8A8D8B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 10 : 8,
                    isWide ? 8 : 7,
                    isWide ? 10 : 8,
                    isWide ? 8 : 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizeDishName(meal.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: isWide ? 12.5 : 11.5,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: AppNutrientTheme.caloriesColor,
                            size: isWide ? 14 : 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            localizeCalories(meal.calories),
                            maxLines: 1,
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: isWide ? 10 : 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (meal.cookingTime.isNotEmpty) ...[
                            SizedBox(width: isWide ? 8 : 4),
                            Icon(
                              Icons.schedule_rounded,
                              color: context.appMutedText,
                              size: isWide ? 14 : 13,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                meal.cookingTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.appMutedText,
                                  fontSize: isWide ? 10 : 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (meal.proteinGrams case final protein?)
                            if (protein > 0) ...[
                              const Spacer(),
                              Tooltip(
                                message: 'common.protein'.tr,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fitness_center_rounded,
                                      color: AppNutrientTheme.proteinColor,
                                      size: isWide ? 14 : 13,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${_formatNutrition(protein)}g',
                                      style: TextStyle(
                                        color: context.appMutedText,
                                        fontSize: isWide ? 10 : 9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNutrition(num value) =>
    value.toDouble() == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

class _MealImage extends StatelessWidget {
  const _MealImage({required this.path, this.height = 96});

  final String path;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!path.startsWith('http://') && !path.startsWith('https://')) {
      return Image.asset(
        path.isEmpty ? 'assets/images/meals/healthy_salad.jpg' : path,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: path,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder:
          (_, _) => const ColoredBox(
            color: Color(0xFFEAF4EE),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      errorWidget:
          (_, _, _) => Image.asset(
            'assets/images/meals/healthy_salad.jpg',
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
          ),
    );
  }
}
