import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile/profile_controller.dart';
import '../../../../theme/app_colors.dart';

class ProgressCard extends GetView<ProfileController> {
  const ProgressCard({super.key});

  static const green = Color(0xFF00A24A);

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color:
            isDark
                ? context.appSurfaceLow.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Progress".tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),

              GestureDetector(
                onTap: controller.openProgressDetails,
                child: Row(
                  children: [
                    Text(
                      'View Details'.tr,
                      style: TextStyle(
                        color: isDark ? context.appColorScheme.primary : green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? context.appColorScheme.primary : green,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _progressItem(
                    context: context,
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.deepOrange,
                    title: 'Calories',
                    current: '${controller.calories.value}',
                    target: '${controller.caloriesGoal.value}',
                    unit: 'kcal',
                    progress: controller.caloriesProgress,
                  ),
                ),

                _divider(context),

                Expanded(
                  child: _progressItem(
                    context: context,
                    icon: Icons.energy_savings_leaf_outlined,
                    iconColor: isDark ? context.appColorScheme.primary : green,
                    title: 'Protein',
                    current: '${controller.protein.value}',
                    target: '${controller.proteinGoal.value}',
                    unit: 'g',
                    progress: controller.proteinProgress,
                  ),
                ),

                _divider(context),

                Expanded(
                  child: _progressItem(
                    context: context,
                    icon: Icons.water_drop_rounded,
                    iconColor: const Color(0xFF72A9FF),
                    title: 'Water',
                    current: '${controller.water.value}',
                    target: '${controller.waterGoal.value}',
                    unit: 'glasses',
                    progress: controller.waterProgress,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      height: 70,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: context.appIsDark ? context.appBorder : Colors.grey.shade300,
    );
  }

  Widget _progressItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String current,
    required String target,
    required String unit,
    required double progress,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 21),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title.tr,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      context.appIsDark
                          ? context.appMutedText
                          : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: current,
                style: TextStyle(
                  color:
                      context.appIsDark
                          ? context.appText
                          : const Color(0xFF444444),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: ' / $target',
                style: TextStyle(
                  color:
                      context.appIsDark
                          ? context.appMutedText
                          : Colors.grey.shade400,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),

        Text(
          unit.tr,
          style: TextStyle(
            color:
                context.appIsDark ? context.appMutedText : Colors.grey.shade500,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress.clamp(0.0, 1.0),
            backgroundColor:
                context.appIsDark
                    ? context.appColorScheme.surfaceContainerHighest
                    : Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              context.appIsDark ? context.appColorScheme.primary : green,
            ),
          ),
        ),
      ],
    );
  }
}
