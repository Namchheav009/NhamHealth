import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/wellness_controller.dart';
import 'wellness_nutrient_tile.dart';

class WellnessDailySummaryCard extends GetView<WellnessController> {
  const WellnessDailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFFF8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF43C756),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Your Daily Summary'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
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
