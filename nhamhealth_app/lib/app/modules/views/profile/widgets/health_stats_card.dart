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
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
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
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.person_outline_rounded,
                title: 'Age',
                value:
                    controller.age.value > 0
                        ? '${controller.age.value}'
                        : '--',
                unit: 'Years',
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _Stat(
                icon: Icons.height_rounded,
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
              child: _Stat(
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
              child: _Stat(
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
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    this.unitColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color? unitColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF6FBEF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE3EFD9)),
          ),
          child: Icon(icon, color: HealthStatsCard.green, size: 17),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  color: Color(0xFF65766C),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  color: Color(0xFF26322B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: unitColor ?? const Color(0xFF65766C),
                  fontSize: 8,
                  fontWeight:
                      unitColor == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
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
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    color: const Color(0xFFE4EAE6),
  );
}
