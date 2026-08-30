import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/wellness/food_source_model.dart';
import '../../../../theme/app_colors.dart';

class FoodSourceTile extends StatelessWidget {
  const FoodSourceTile({super.key, required this.source, required this.onTap});

  final FoodSourceModel source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Material(
      color: isDark ? context.appSurfaceLow : const Color(0xFFFCFCFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? context.appBorder : const Color(0xFFECECEC),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Color.alphaBlend(
                            const Color(0xFFFF641E).withValues(alpha: 0.12),
                            context.appSurfaceLow,
                          )
                          : const Color(0xFFFFF3ED),
                  shape: BoxShape.circle,
                ),
                child: Text(source.emoji, style: const TextStyle(fontSize: 20)),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.mealType.tr,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? context.appMutedText : Colors.black38,
                      ),
                    ),
                    Text(
                      source.foodName.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? context.appText : null,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${source.calories}',
                style: const TextStyle(
                  color: Color(0xFFFF641E),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 4),

              Text(
                'kcal'.tr,
                style: TextStyle(
                  color: isDark ? context.appMutedText : Colors.black38,
                  fontSize: 9,
                ),
              ),

              const SizedBox(width: 5),

              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? context.appColorScheme.outline : Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
