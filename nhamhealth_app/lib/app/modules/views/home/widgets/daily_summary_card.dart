import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_nutrient_theme.dart';
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
          AppNutrientTheme.caloriesIcon,
          AppNutrientTheme.caloriesColor,
        ),
        (
          summary.protein,
          AppNutrientTheme.proteinIcon,
          AppNutrientTheme.proteinColor,
        ),
        (
          summary.water,
          AppNutrientTheme.waterIcon,
          AppNutrientTheme.waterColor,
        ),
      ];

      return Container(
        constraints: const BoxConstraints(minHeight: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              context.appSoftPink,
              context.appElevatedSurface,
              context.appSoftGreen,
            ],
          ),
          border:
              context.appIsDark ? Border.all(color: context.appBorder) : null,
          boxShadow: context.appHomeCardShadow,
        ),
        child: InnerShadow(
          borderRadius: BorderRadius.circular(15),
          shadows: context.appIsDark ? context.appInnerShadow : const [],
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
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
                        'home.your_daily_wellness'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
                              'common.view_details'.tr,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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
                                        : context.appMutedSurface.withValues(
                                          alpha: 0.82,
                                        ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    names[day.weekday - 1].trOrSelf,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color:
                                          selected
                                              ? Colors.white70
                                              : context.appText,
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
                                              : context.appText,
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
                const SizedBox(height: 16),
                SizedBox(
                  key: const ValueKey<String>('home-wellness-cards'),
                  height: 96,
                  child: Row(
                    children: [
                      for (
                        var index = 0;
                        index < nutrients.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(width: 8),
                        Expanded(
                          child: NutritionProgressCard(
                            key: ValueKey<String>(
                              'home-wellness-${nutrients[index].$1.title.split('.').last.toLowerCase()}',
                            ),
                            data: nutrients[index].$1,
                            icon: nutrients[index].$2,
                            iconColor: nutrients[index].$3,
                            onTap:
                                index == 2
                                    ? controller.openWaterDetails
                                    : controller.openWellnessDetails,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
