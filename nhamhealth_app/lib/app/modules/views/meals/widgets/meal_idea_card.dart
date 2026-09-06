import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/meals/meal_model.dart';

class MealIdeaCard extends StatelessWidget {
  const MealIdeaCard({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onFavorite,
  });

  final MealModel meal;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Expanded(flex: 5, child: _MealIdeaImage(path: meal.image)),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              meal.name.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 14,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          InkResponse(
                            onTap: onFavorite,
                            radius: 20,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                meal.isFavorite
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: AppColors.primaryGreen,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meal.recommendationReason.isNotEmpty
                            ? meal.recommendationReason
                            : [
                              if (meal.difficulty.isNotEmpty)
                                meal.difficulty.tr,
                              meal.category.tr,
                              'Healthy'.tr,
                            ].join('  •  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _Metric(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.accentOrange,
                            label: '${meal.calories} kcal',
                          ),
                          if (meal.proteinGrams case final protein?)
                            if (protein > 0)
                              _Metric(
                                icon: Icons.fitness_center_rounded,
                                iconColor: AppColors.primaryGreen,
                                label:
                                    '${'Protein'.tr} ${_formatNutrition(protein)}g',
                              ),
                          if (meal.cookingTimeMinutes case final minutes?)
                            _Metric(
                              icon: Icons.schedule_rounded,
                              iconColor: context.appMutedText,
                              label: '$minutes min',
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
    );
  }
}

String _formatNutrition(num value) =>
    value.toDouble() == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 17),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(color: context.appMutedText, fontSize: 10.5),
        ),
      ],
    );
  }
}

class _MealIdeaImage extends StatelessWidget {
  const _MealIdeaImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    const fallback = 'assets/images/meals/healthy_salad.jpg';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }
    return Image.asset(
      path.isEmpty ? fallback : path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(fallback, fit: BoxFit.cover),
    );
  }
}
