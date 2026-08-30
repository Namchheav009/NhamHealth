import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/calories_controller.dart';
import '../../../../theme/app_colors.dart';

class CalorieProgressCard extends GetView<CaloriesController> {
  const CalorieProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFF641E),
                    size: 30,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calories'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: '/${controller.targetCalories.value} kcal',
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        '✨ You\'re on track today'.tr,
                        style: TextStyle(
                          fontSize: 9,
                          color: context.appMutedText,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  '${controller.percentage}%',
                  style: const TextStyle(
                    color: Color(0xFFFF641E),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: controller.progress,
                minHeight: 7,
                backgroundColor: context.appColorScheme.outlineVariant,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF641E)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appCardShadow,
    );
  }
}
