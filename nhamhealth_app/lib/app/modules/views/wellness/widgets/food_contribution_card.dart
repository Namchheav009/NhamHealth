import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class FoodContributionCard extends StatelessWidget {
  const FoodContributionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? context.appSurfaceLow : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: context.appBorder) : null,
        boxShadow:
            isDark
                ? context.appCardShadow
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Contribution today'.tr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? context.appText : null,
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
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.track_changes_rounded,
                color: Color(0xFFFF641E),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This drink added a lot of sugar with little fiber or protein.\n• Main source of sugar today\n• Pairs better with water or fruit'
                      .tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? context.appMutedText : Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
