import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile/profile_controller.dart';

class HealthStatsCard extends GetView<ProfileController> {
  const HealthStatsCard({super.key});

  static const green = Color(0xFF00A24A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(
              icon: Icons.person_outline,
              title: 'Age',
              value: '${controller.age.value}',
              unit: 'Years',
            ),
            _stat(
              icon: Icons.straighten,
              title: 'Height',
              value: '${controller.height.value}',
              unit: 'cm',
            ),
            _stat(
              icon: Icons.monitor_weight_outlined,
              title: 'Weight',
              value: '${controller.weight.value}',
              unit: 'kg',
            ),
            _stat(
              icon: Icons.monitor_heart_outlined,
              title: 'BMI',
              value: controller.bmi.toStringAsFixed(1),
              unit: controller.bmiStatus,
              unitColor: green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    Color? unitColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBEF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: green, size: 20),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF52617B),
                    fontSize: 11,
                  ),
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                Text(
                  unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unitColor ?? const Color(0xFF52617B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
