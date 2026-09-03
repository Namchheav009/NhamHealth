import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../models/home/recommended_meal_model.dart';

class RecommendedMealCard extends StatelessWidget {
  const RecommendedMealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  final RecommendedMealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              context.appIsDark
                  ? const Color(0xFF4ADE80).withValues(alpha: 0.23)
                  : context.appBorder.withValues(alpha: 0.7),
        ),
        boxShadow: context.appHomeTileShadow,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(16),
        shadows: context.appIsDark ? context.appInnerShadow : const [],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: _MealImage(path: meal.image),
                    ),
                    Positioned(
                      right: 7,
                      top: 7,
                      child: InkWell(
                        onTap: onFavorite,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 28,
                          height: 28,
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
                              size: 17,
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
                    padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            meal.name.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 11,
                              height: 1.18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.accentOrange,
                              size: 13,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${meal.calories} kcal',
                              maxLines: 1,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                              size: 13,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              meal.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ),
    );
  }
}

class _MealImage extends StatelessWidget {
  const _MealImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (!path.startsWith('http://') && !path.startsWith('https://')) {
      return Image.asset(
        path.isEmpty ? 'assets/images/meals/healthy_salad.jpg' : path,
        width: double.infinity,
        height: 96,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: path,
      width: double.infinity,
      height: 96,
      fit: BoxFit.cover,
      memCacheWidth: 300,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder:
          (_, _) => const ColoredBox(
            color: Color(0xFFEAF4EE),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      errorWidget:
          (_, _, _) => Image.asset(
            'assets/images/meals/healthy_salad.jpg',
            fit: BoxFit.cover,
          ),
    );
  }
}
