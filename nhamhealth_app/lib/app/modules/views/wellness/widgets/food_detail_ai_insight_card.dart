import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class FoodDetailAiInsightCard extends StatelessWidget {
  const FoodDetailAiInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.all(15),
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
        children: [
          Row(
            children: [
              Transform.translate(
                offset: const Offset(-10, 0),
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Image.asset(
                    'assets/images/wellness/ai_search.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AI Insight'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? context.appText : null,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Color.alphaBlend(
                                      const Color(
                                        0xFFFF641E,
                                      ).withValues(alpha: 0.12),
                                      context.appSurfaceLow,
                                    )
                                    : const Color(0xFFFFEEE6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '⚖️ Watch sugar'.tr,
                            style: const TextStyle(
                              color: Color(0xFFFF641E),
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Milk tea is okay sometimes, but sugar is a bit high for one drink. Balance it with water and a lighter next choice.'
                          .tr,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: isDark ? context.appMutedText : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
