import 'package:flutter/material.dart';

import '../../models/nutrition_progress_model.dart';
import 'inner_shadow.dart';

class NutritionProgressCard extends StatelessWidget {
  const NutritionProgressCard({
    super.key,
    required this.data,
    required this.icon,
    required this.iconColor,
  });

  final NutritionProgressModel data;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF858585),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '${data.value} / ${data.target}',
            maxLines: 1,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF929292)),
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE3DF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: InnerShadow(
                borderRadius: BorderRadius.circular(10),
                shadows: const [
                  BoxShadow(
                    color: Color(0x24004A2A),
                    blurRadius: 3,
                    offset: Offset(-1, -1),
                  ),
                ],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: data.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF009B49),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
