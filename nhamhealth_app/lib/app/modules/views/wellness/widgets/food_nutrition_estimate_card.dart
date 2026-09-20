import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_nutrient_theme.dart';
import '../../../controllers/wellness/food_source_detail_controller.dart';

class FoodNutritionEstimateCard extends GetView<FoodSourceDetailController> {
  const FoodNutritionEstimateCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'wellness.nutrition_estimate'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? context.appText : null,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF00A651),
                  size: 15,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _nutritionBox(
                  context: context,
                  icon: AppNutrientTheme.caloriesIcon,
                  title: 'common.calories',
                  value: '+${controller.currentCalories.value}',
                  unit: 'kcal',
                  color: AppNutrientTheme.caloriesColor,
                  bg: AppNutrientTheme.caloriesBg,
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: AppNutrientTheme.proteinIcon,
                  title: 'common.protein',
                  value: '+${controller.estimatedProtein}',
                  unit: 'g',
                  color: AppNutrientTheme.proteinColor,
                  bg: AppNutrientTheme.proteinBg,
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: AppNutrientTheme.fiberIcon,
                  title: 'common.fiber',
                  value: '+${controller.estimatedFiber}',
                  unit: 'g',
                  color: AppNutrientTheme.fiberColor,
                  bg: AppNutrientTheme.fiberBg,
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: AppNutrientTheme.sugarIcon,
                  title: 'common.sugar',
                  value: '+${controller.estimatedSugar}',
                  unit: 'g',
                  color: AppNutrientTheme.sugarColor,
                  bg: AppNutrientTheme.sugarBg,
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: AppNutrientTheme.waterIcon,
                  title: 'wellness.hydration_tip',
                  value: controller.hydrationTip,
                  unit: '',
                  color: AppNutrientTheme.waterColor,
                  bg: AppNutrientTheme.waterBg,
                  small: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionBox({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
    required Color bg,
    bool small = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color:
              context.appIsDark
                  ? Color.alphaBlend(
                    color.withValues(alpha: 0.12),
                    context.appSurfaceLow,
                  )
                  : bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              title.trOrSelf,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color:
                    context.appIsDark ? context.appMutedText : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.trOrSelf,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: small ? 9 : 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit.trOrSelf,
                style: TextStyle(
                  fontSize: 9,
                  color:
                      context.appIsDark ? context.appMutedText : Colors.black45,
                ),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = context.appIsDark;
    return BoxDecoration(
      color: isDark ? context.appSurfaceLow : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: isDark ? Border.all(color: context.appBorder) : null,
      boxShadow:
          isDark
              ? context.appCardShadow
              : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
    );
  }
}
