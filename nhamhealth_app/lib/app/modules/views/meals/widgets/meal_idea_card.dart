import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/meal_localization_helpers.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_nutrient_theme.dart';
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
      height: 126,
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
              Expanded(flex: 4, child: _MealIdeaImage(path: meal.image)),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              localizeDishName(meal.name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 12,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Tooltip(
                            message:
                                meal.isFavorite
                                    ? 'common.remove_from_favorites'.tr
                                    : 'common.add_to_favorites'.tr,
                            child: InkResponse(
                              onTap: onFavorite,
                              radius: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  meal.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color:
                                      meal.isFavorite
                                          ? AppColors.favoriteRed
                                          : const Color(0xFF8A8D8B),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accentOrange),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          localizeCategory(meal.category),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accentOrange,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 9,
                        runSpacing: 4,
                        children: [
                          _Metric(
                            icon: AppNutrientTheme.caloriesIcon,
                            iconColor: AppNutrientTheme.caloriesColor,
                            label: localizeCalories(meal.calories),
                          ),
                          if (meal.proteinGrams case final protein?)
                            if (protein > 0)
                              _Metric(
                                icon: AppNutrientTheme.proteinIcon,
                                iconColor: AppNutrientTheme.proteinColor,
                                label: 'meals.protein_grams'.trParams({
                                  'value': _formatNutrition(protein),
                                }),
                              ),
                          if (meal.cookingTimeMinutes case final minutes?)
                            _Metric(
                              icon: Icons.schedule_rounded,
                              iconColor: context.appMutedText,
                              label: localizeCookingTime(minutes),
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
        Icon(icon, color: iconColor, size: 12),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: context.appMutedText, fontSize: 9)),
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
