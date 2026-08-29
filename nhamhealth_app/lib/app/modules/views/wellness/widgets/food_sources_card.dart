import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/calories_controller.dart';
import '../../../../theme/app_colors.dart';
import 'add_food_source_sheet.dart';
import 'food_source_tile.dart';

class FoodSourcesCard extends GetView<CaloriesController> {
  const FoodSourcesCard({super.key});

  void _showAddFood() {
    Get.bottomSheet(
      const AddFoodSourceSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Today\'s food sources'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF00A651),
                      size: 15,
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: _showAddFood,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A651),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Add more'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Obx(
            () => Column(
              children:
                  controller.foodSources.map((source) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: FoodSourceTile(
                        source: source,
                        onTap: () {
                          controller.openFoodSourceDetail(source);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
