import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/wellness/wellness_controller.dart';
import '../../../../theme/app_colors.dart';

class AiMealCard extends GetView<WellnessController> {
  const AiMealCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? context.appSurfaceLow : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: context.appBorder) : null,
        boxShadow:
            isDark
                ? context.appCardShadow
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            height: 116,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/wellness/ai_search.png',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                semanticLabel: 'AI food search assistant',
              ),
            ),
          ),

          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log food with AI'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? context.appText : const Color(0xFF555555),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Tell AI what you ate and choose the amount for a better estimate.'
                      .tr,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? context.appMutedText : Colors.black54,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    // CLICK -> AI PAGE
                    onPressed: controller.openMealAutoFill,

                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),

                    label: Text(
                      'Open AI Meal Auto-Fill'.tr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: context.appColorScheme.primary,
                      foregroundColor: context.appColorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
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
