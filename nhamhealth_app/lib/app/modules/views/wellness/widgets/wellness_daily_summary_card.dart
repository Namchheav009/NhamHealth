import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/wellness_controller.dart';
import '../../../../theme/app_colors.dart';
import 'wellness_nutrient_tile.dart';

class WellnessDailySummaryCard extends GetView<WellnessController> {
  const WellnessDailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.appSoftGreen,
                child: Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF43C756),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Your Daily Summary'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(
            () => Column(
              children: List.generate(controller.nutrients.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: WellnessNutrientTile(
                    item: controller.nutrients[index],
                    // onTap:
                    //     () => controller.openNutrientDetails(
                    //       controller.nutrients[index].name,
                    //     ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
