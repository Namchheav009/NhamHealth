import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/wellness/wellness_summary_model.dart';
import '../../../../theme/app_colors.dart';

class WellnessNutrientTile extends StatelessWidget {
  const WellnessNutrientTile({super.key, required this.item});

  final WellnessSummaryModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 10),
                    children: [
                      TextSpan(
                        text: item.current,
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '/${item.target} ${item.unit.tr}',
                        style: TextStyle(color: context.appMutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 5,
                backgroundColor: context.appColorScheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(item.color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${item.percentage}%',
            style: TextStyle(
              color: item.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
