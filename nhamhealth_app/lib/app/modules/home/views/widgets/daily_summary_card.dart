import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import 'nutrition_progress_card.dart';

class DailySummaryCard
    extends GetView<HomeController> {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary =
          controller.dashboard.value?.dailySummary;

      if (summary == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF4F6),
              Colors.white,
              Color(0xFFF0FFF2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.eco_outlined,
                  color: Color(0xFF00A651),
                  size: 20,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Your Daily Wellness',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const Spacer(),

                GestureDetector(
                  onTap: () {
                    // Navigate detail
                  },
                  child: const Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              Color(0xFF00A651),
                        ),
                      ),
                      Icon(
                        Icons
                            .chevron_right_rounded,
                        size: 17,
                        color:
                            Color(0xFF00A651),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                NutritionProgressCard(
                  data: summary.calories,
                  icon:
                      Icons.local_fire_department,
                  iconColor:
                      const Color(0xFFFF7629),
                ),

                _divider(),

                NutritionProgressCard(
                  data: summary.protein,
                  icon: Icons.energy_savings_leaf,
                  iconColor:
                      const Color(0xFF00B85C),
                ),

                _divider(),

                NutritionProgressCard(
                  data: summary.water,
                  icon: Icons.water_drop,
                  iconColor:
                      const Color(0xFF69AFFF),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 55,
      margin:
          const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE9E9E9),
    );
  }
}