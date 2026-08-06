import 'package:flutter/material.dart';

import '../../models/nutrition_progress_model.dart';

class NutritionProgressCard
    extends StatelessWidget {
  final NutritionProgressModel data;
  final IconData icon;
  final Color iconColor;

  const NutritionProgressCard({
    super.key,
    required this.data,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  data.title,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            '${data.value} / ${data.target}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            data.unit,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: data.progress,
              backgroundColor:
                  const Color(0xFFE7E7E7),
              valueColor:
                  const AlwaysStoppedAnimation(
                Color(0xFF00A651),
              ),
            ),
          ),
        ],
      ),
    );
  }
}