import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile/profile_controller.dart';

class HealthStatsCard extends GetView<ProfileController> {
  const HealthStatsCard({super.key});

  static const green = Color(0xFF00A24A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _stat(
              icon: Icons.person_outline,
              title: 'Age',
              value: controller.age.value > 0 ? '${controller.age.value}' : '--',
              unit: 'Years',
            ),
            ),
            const _StatDivider(),
            Expanded(
              child: _stat(
              icon: Icons.straighten,
              title: 'Height',
              value:
                  controller.height.value > 0
                      ? '${controller.height.value}'
                      : '--',
              unit: 'cm',
            ),
            ),
            const _StatDivider(),
            Expanded(
              child: _stat(
              icon: Icons.monitor_weight_outlined,
              title: 'Weight',
              value:
                  controller.weight.value > 0
                      ? '${controller.weight.value}'
                      : '--',
              unit: 'kg',
            ),
            ),
            const _StatDivider(),
            Expanded(
              child: _stat(
              icon: Icons.monitor_heart_outlined,
              title: 'BMI',
              value:
                  controller.bmi > 0
                      ? controller.bmi.toStringAsFixed(1)
                      : '--',
              unit: controller.bmiStatus,
              unitColor: green,
            ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBEF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: green, size: 20),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFF65766C),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF26322B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 14,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              unit,
              maxLines: 1,
              style: TextStyle(
                color: unitColor ?? const Color(0xFF65766C),
                fontSize: 10,
                fontWeight: unitColor == null
                    ? FontWeight.w400
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 72,
    margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
    color: const Color(0xFFE4EAE6),
  );
}
