import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';
import 'nutrition_progress_card.dart';

class DailySummaryCard extends GetView<HomeController> {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.dashboard.value?.dailySummary;
      if (summary == null) return const SizedBox.shrink();
      final nutrients = [
        (
          summary.calories,
          Icons.local_fire_department_rounded,
          const Color(0xFFFF6A24),
        ),
        (
          summary.protein,
          Icons.energy_savings_leaf_rounded,
          const Color(0xFF00B85C),
        ),
        (summary.sugar, Icons.hexagon_rounded, const Color(0xFFFF5CB8)),
      ];

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
                    Expanded(
                      child: Text(
                        'Your Daily Wellness'.tr,
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              'View Details'.tr,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
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
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: Row(
                    children: List.generate(controller.recentDays.length, (
                      index,
                    ) {
                      final day = controller.recentDays[index];
                      final selected =
                          day.year == controller.selectedDay.value.year &&
                          day.month == controller.selectedDay.value.month &&
                          day.day == controller.selectedDay.value.day;
                      const names = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right:
                                index == controller.recentDays.length - 1
                                    ? 0
                                    : 4,
                          ),
                          child: InkWell(
                            onTap: () => controller.selectDay(day),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? AppColors.primaryGreen
                                        : Colors.white.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    names[day.weekday - 1].tr,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          selected
                                              ? Colors.white70
                                              : AppColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          selected
                                              ? Colors.white
                                              : AppColors.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    const columns = 3;
                    final cardWidth =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children:
                          nutrients.map((nutrient) {
                            return SizedBox(
                              key: ValueKey<String>(
                                'home-wellness-${nutrient.$1.title.toLowerCase()}',
                              ),
                              width: cardWidth,
                              height: 112,
                              child: NutritionProgressCard(
                                data: nutrient.$1,
                                icon: nutrient.$2,
                                iconColor: nutrient.$3,
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
