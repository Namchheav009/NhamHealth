import 'package:flutter/material.dart';

class FoodDetailAiInsightCard extends StatelessWidget {
  const FoodDetailAiInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
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
                        const Text(
                          'AI Insight',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
                          ),
                          child: const Text(
                            '⚖️ Watch sugar',
                            style: TextStyle(
                              color: Color(0xFFFF641E),
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Milk tea is okay sometimes, but sugar is a bit high for one drink. '
                      'Balance it with water and a lighter next choice.',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.5,
                        color: Colors.black54,
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