import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/food_source_detail_controller.dart';

class FoodDetailSummaryCard extends GetView<FoodSourceDetailController> {
  const FoodDetailSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
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
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black38,
                        ),
                      ),
                      Text(
                        controller.source.foodName.tr,
                        style: const TextStyle(
                          fontSize: 18,
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
                                fontSize: 14,
                              ),
                            ),
                            const TextSpan(
                              text: ' kcal',
                              style: TextStyle(
                                color: Colors.black38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '☕ Medium cup   ⏰ Added 10:30 AM'.tr,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Sweet drink, enjoy in balance.'.tr,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.black38,
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
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black38,
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
                backgroundColor: const Color(0xFFE3E3E3),
                valueColor: const AlwaysStoppedAnimation(Color(0xFFFF641E)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
