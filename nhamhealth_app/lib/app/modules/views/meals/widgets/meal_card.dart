import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/meal_localization_helpers.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_nutrient_theme.dart';
import '../../../models/meals/meal_model.dart';

class MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
        boxShadow: context.appTileShadow,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _MealImage(path: meal.image),
                    Positioned(
                      left: 7,
                      top: 7,
                      child: _MealBadge(label: localizeCategory(meal.category)),
                    ),
                    Positioned(
                      right: 7,
                      top: 7,
                      child: _FavoriteButton(
                        isFavorite: meal.isFavorite,
                        onTap: onFavorite,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizeDishName(meal.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: context.appText,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 7,
                        runSpacing: 3,
                        children: [
                          _MealMetric(
                            icon: AppNutrientTheme.caloriesIcon,
                            color: AppNutrientTheme.caloriesColor,
                            label: localizeCalories(meal.calories),
                          ),
                          if (meal.proteinGrams case final protein?)
                            if (protein > 0)
                              _MealMetric(
                                icon: AppNutrientTheme.proteinIcon,
                                color: AppNutrientTheme.proteinColor,
                                label: '${_number(protein)} g',
                              ),
                          if (meal.cookingTimeMinutes case final minutes?) ...[
                            _MealMetric(
                              icon: Icons.schedule_rounded,
                              color: context.appMutedText,
                              label: localizeCookingTime(minutes),
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

class _MealBadge extends StatelessWidget {
  const _MealBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 92),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.wb_sunny_rounded,
          color: AppColors.accentOrange,
          size: 9,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
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
  );
}

class _MealMetric extends StatelessWidget {
  const _MealMetric({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 10),
      const SizedBox(width: 2),
      Text(
        label,
        style: TextStyle(
          color: context.appMutedText,
          fontSize: 7.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message:
        isFavorite
            ? 'common.remove_from_favorites'.tr
            : 'common.add_to_favorites'.tr,
    child: Material(
      color: Colors.white.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 16,
            color: isFavorite ? AppColors.favoriteRed : const Color(0xFF8A8D8B),
          ),
        ),
      ),
    ),
  );
}

String _number(num value) =>
    value.toDouble() == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

class _MealImage extends StatelessWidget {
  const _MealImage({required this.path});

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
