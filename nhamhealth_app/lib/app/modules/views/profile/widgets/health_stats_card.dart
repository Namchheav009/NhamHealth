import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile/profile_controller.dart';
import '../../../../theme/app_colors.dart';

class HealthStatsCard extends GetView<ProfileController> {
  const HealthStatsCard({super.key});

  static const green = Color(0xFF00A24A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.person_outline_rounded,
                title: 'Age',
                value:
                    controller.age.value > 0 ? '${controller.age.value}' : '--',
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
                alignment: MainAxisAlignment.center,
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
    this.alignment = MainAxisAlignment.center,
  });

  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color? unitColor;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          Container(
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              shape: BoxShape.circle,
              border: Border.all(color: context.appBorder),
            ),
            child: Icon(icon, color: HealthStatsCard.green, size: 15),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  unit.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: unitColor ?? context.appMutedText,
                    fontSize: 7,
                    fontWeight:
                        unitColor == null ? FontWeight.w400 : FontWeight.w600,
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

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    color: context.appBorder,
  );
}
