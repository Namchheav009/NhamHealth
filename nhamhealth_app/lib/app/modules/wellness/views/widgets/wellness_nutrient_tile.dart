import 'package:flutter/material.dart';

import '../../models/wellness_summary_model.dart';

class WellnessNutrientTile extends StatelessWidget {
  const WellnessNutrientTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final WellnessSummaryModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFECECEC),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              // Name + value
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 10,
                        ),
                        children: [
                          TextSpan(
                            text: item.current,
                            style: TextStyle(
                              color: item.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: '/${item.target} ${item.unit}',
                            style: const TextStyle(
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE8E8E8),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.color,
                    ),
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

              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD0D0D0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}