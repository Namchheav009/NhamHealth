import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/food_source_detail_controller.dart';
import '../../../../theme/app_colors.dart';

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
                  'Nutrition estimate'.tr,
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
                  icon: Icons.local_fire_department_rounded,
                  title: 'Calories',
                  value: '+${controller.currentCalories.value}',
                  unit: 'kcal',
                  color: const Color(0xFFFF641E),
                  bg: const Color(0xFFFFF1E8),
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: Icons.bolt_rounded,
                  title: 'Protein',
                  value: '+${controller.estimatedProtein}',
                  unit: 'g',
                  color: const Color(0xFF00A651),
                  bg: const Color(0xFFEAF7EC),
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: Icons.air_rounded,
                  title: 'Fiber',
                  value: '+${controller.estimatedFiber}',
                  unit: 'g',
                  color: const Color(0xFF9747FF),
                  bg: const Color(0xFFF2EAFE),
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: Icons.hexagon_rounded,
                  title: 'Sugar',
                  value: '+${controller.estimatedSugar}',
                  unit: 'g',
                  color: const Color(0xFFFF5CB8),
                  bg: const Color(0xFFFFEDF7),
                ),
                const SizedBox(width: 8),
                _nutritionBox(
                  context: context,
                  icon: Icons.water_drop_rounded,
                  title: 'Hydration tip',
                  value: controller.hydrationTip,
                  unit: '',
                  color: const Color(0xFF48BFF2),
                  bg: const Color(0xFFE8F7FF),
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
              title.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color:
                    context.appIsDark ? context.appMutedText : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: small ? 9 : 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit.tr,
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
