import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/wellness_controller.dart';

/// Water shortcut shown on the Daily Wellness dashboard.
class AiMealCard extends GetView<WellnessController> {
  const AiMealCard({super.key});

  static const double _waterImageWidth = 104;
  static const double _waterImageHeight = 112;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            key: const ValueKey('daily-wellness-water-image'),
            width: _waterImageWidth,
            height: _waterImageHeight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/wellness/AI-water.png',
                width: _waterImageWidth,
                height: _waterImageHeight,
                // This source is landscape-oriented, so `contain` makes the
                // character look much smaller than the AI Insight robot even
                // though both image slots have identical dimensions.
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'wellness.log_water'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'wellness.log_water_description'.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: FilledButton.icon(
                    onPressed: () => controller.openNutrientDetails('Water'),
                    icon: const Icon(Icons.water_drop_rounded, size: 16),
                    label: Text(
                      'wellness.open_water_tracker'.tr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF25A9E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
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
