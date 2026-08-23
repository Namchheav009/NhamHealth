import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../controllers/home/home_controller.dart';
import 'nutrition_progress_card.dart';

class DailySummaryCard extends GetView<HomeController> {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.dashboard.value?.dailySummary;
      if (summary == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3ECE6)),
          boxShadow: AppShadows.surface,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primaryGreen,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Daily Wellness',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Track your nutrition at a glance',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: controller.openWellnessDetails,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkGreen,
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 1),
                      Icon(Icons.chevron_right_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: controller.recentDays.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (_, index) {
                  final day = controller.recentDays[index];
                  final selected = day.year == controller.selectedDay.value.year &&
                      day.month == controller.selectedDay.value.month &&
                      day.day == controller.selectedDay.value.day;
                  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return InkWell(
                    onTap: () => controller.selectDay(day),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 43,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryGreen
                            : const Color(0xFFF6F9F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryGreen
                              : const Color(0xFFE4EAE6),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            names[day.weekday - 1],
                            style: TextStyle(
                              fontSize: 9,
                              color: selected ? Colors.white70 : AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: Color(0xFFE7ECE9)),
            ),
            Row(
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
      );
    });
  }
}

class _WellnessDivider extends StatelessWidget {
  const _WellnessDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 62,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: const Color(0xFFE1E7E3),
  );
}
