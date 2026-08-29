import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class CaloriesAiInsightCard extends StatelessWidget {
  const CaloriesAiInsightCard({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(-10, 0),
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Image.asset(
                    'assets/images/wellness/ai_search.png',
                    fit: BoxFit.cover,
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
                            '⚖️ Needs Balance'.tr,
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
                      'Most of your calories came from food and sweet drinks. Stay balanced by choosing a lighter next meal.'
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

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                context,
                '🍎 Add fruit',
                const Color(0xFFE9F7EB),
                const Color(0xFF00A651),
              ),
              _chip(
                context,
                '🥗 Choose lighter dinner',
                const Color(0xFFFFEEE7),
                const Color(0xFFFF641E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String text,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            context.appIsDark
                ? Color.alphaBlend(
                  foreground.withValues(alpha: 0.13),
                  context.appSurfaceLow,
                )
                : background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Text(text.tr, style: TextStyle(fontSize: 9, color: foreground)),
    );
  }
}
