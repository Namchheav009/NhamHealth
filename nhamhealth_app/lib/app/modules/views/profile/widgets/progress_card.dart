import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile/profile_controller.dart';

class ProgressCard extends GetView<ProfileController> {
  const ProgressCard({super.key});

  static const green = Color(0xFF00A24A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
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
              const Expanded(
                child: Text(
                  "Today's Progress",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),

              GestureDetector(
                onTap: controller.openProgressDetails,
                child: const Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.chevron_right_rounded, color: green, size: 22),
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
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.deepOrange,
                    title: 'Calories',
                    current: '${controller.calories.value}',
                    target: '${controller.caloriesGoal.value}',
                    unit: 'kcal',
                    progress: controller.caloriesProgress,
                  ),
                ),

                _divider(),

                Expanded(
                  child: _progressItem(
                    icon: Icons.energy_savings_leaf_outlined,
                    iconColor: green,
                    title: 'Protein',
                    current: '${controller.protein.value}',
                    target: '${controller.proteinGoal.value}',
                    unit: 'g',
                    progress: controller.proteinProgress,
                  ),
                ),

                _divider(),

                Expanded(
                  child: _progressItem(
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

  Widget _divider() {
    return Container(
      height: 70,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.grey.shade300,
    );
  }

  Widget _progressItem({
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
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
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
                style: const TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: ' / $target',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),

        Text(unit, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(green),
          ),
        ),
      ],
    );
  }
}
