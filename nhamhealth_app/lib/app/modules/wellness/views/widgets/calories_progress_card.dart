import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/calories_controller.dart';

class CalorieProgressCard
    extends GetView<CaloriesController> {
  const CalorieProgressCard({super.key});

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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calories',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${controller.currentCalories.value}',
                              style: const TextStyle(
                                color:
                                    Color(0xFFFF641E),
                                fontWeight:
                                    FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '/${controller.targetCalories.value} kcal',
                              style: const TextStyle(
                                color: Colors.black38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        '✨ You\'re on track today',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black38,
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
              borderRadius:
                  BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: controller.progress,
                minHeight: 7,
                backgroundColor:
                    const Color(0xFFE3E3E3),
                valueColor:
                    const AlwaysStoppedAnimation(
                  Color(0xFFFF641E),
                ),
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
          color:
              Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}