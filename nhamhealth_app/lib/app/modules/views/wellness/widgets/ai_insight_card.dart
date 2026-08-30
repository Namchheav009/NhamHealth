import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
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

              // const SizedBox(width: 10),
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
                            color: context.appText,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEE6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFC7AA)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.balance_rounded,
                                color: Color(0xFFFF6A32),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Needs Balance'.tr,
                                style: const TextStyle(
                                  color: Color(0xFFFF6A32),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Sugar is a bit high and fiber is still low. Drink 1 more glass of water and choose a light next meal.'
                          .tr,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: context.appMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 6,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              _chip(
                context,
                emoji: '🍎',
                text: 'Add fruit',
                background: const Color(0xFFE8F7EB),
                foreground: const Color(0xFF24A852),
              ),
              _chip(
                context,
                emoji: '💧',
                text: 'Drink more water',
                background: const Color(0xFFE7F7FF),
                foreground: const Color(0xFF42B8EC),
              ),
              _chip(
                context,
                emoji: '🥗',
                text: 'Choose lighter dinner',
                background: const Color(0xFFFFEEE8),
                foreground: const Color(0xFFFF7138),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String emoji,
    required String text,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color:
            context.appIsDark
                ? Color.alphaBlend(
                  foreground.withValues(alpha: 0.14),
                  context.appSurface,
                )
                : background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 3),
          Text(text.tr, style: TextStyle(color: foreground, fontSize: 9)),
        ],
      ),
    );
  }
}
