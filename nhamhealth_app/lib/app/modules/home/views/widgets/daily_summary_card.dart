import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../controllers/home_controller.dart';
import 'inner_shadow.dart';
import 'nutrition_progress_card.dart';

class DailySummaryCard extends GetView<HomeController> {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.dashboard.value?.dailySummary;
      if (summary == null) {
        return const SizedBox.shrink();
      }

      return Container(
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.softPink,
              AppColors.cardSurface,
              AppColors.softGreen,
            ],
          ),
          boxShadow: AppShadows.surface,
        ),
        child: InnerShadow(
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 17),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Your Daily Wellness',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: controller.openWellnessDetails,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 17,
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    NutritionProgressCard(
                      data: summary.calories,
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF6A24),
                    ),
                    const _WellnessDivider(),
                    NutritionProgressCard(
                      data: summary.protein,
                      icon: Icons.energy_savings_leaf_rounded,
                      iconColor: const Color(0xFF00B85C),
                    ),
                    const _WellnessDivider(),
                    NutritionProgressCard(
                      data: summary.water,
                      icon: Icons.water_drop_rounded,
                      iconColor: const Color(0xFF69AFFF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _WellnessDivider extends StatelessWidget {
  const _WellnessDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFFB9BDBB),
    );
  }
}
