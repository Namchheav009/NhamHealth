import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/food_source_detail_controller.dart';
import '../../../../theme/app_colors.dart';

class FoodDetailSummaryCard extends GetView<FoodSourceDetailController> {
  const FoodDetailSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3ED),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    controller.source.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.source.mealType.tr,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? context.appMutedText : Colors.black38,
                        ),
                      ),
                      Text(
                        controller.source.foodName.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? context.appText : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${controller.currentCalories.value}',
                              style: const TextStyle(
                                color: Color(0xFFFF641E),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            TextSpan(
                              text: ' kcal',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? context.appMutedText
                                        : Colors.black38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '☕ Medium cup   ⏰ Added 10:30 AM'.tr,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? context.appMutedText : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sweet drink, enjoy in balance.'.tr,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? context.appMutedText : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${controller.percentOfTodayCalories}%',
                      style: const TextStyle(
                        color: Color(0xFFFF641E),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "of today's\ncalories".tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? context.appMutedText : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: controller.progress,
                minHeight: 7,
                backgroundColor:
                    isDark
                        ? context.appColorScheme.surfaceContainerHighest
                        : const Color(0xFFE3E3E3),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF641E)),
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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
    );
  }
}
