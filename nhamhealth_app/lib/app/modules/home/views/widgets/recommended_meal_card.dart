import 'package:flutter/material.dart';

import '../../models/recommended_meal_model.dart';

class RecommendedMealCard
    extends StatelessWidget {
  final RecommendedMealModel meal;

  const RecommendedMealCard({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Image.asset(
              meal.image,
              width: double.infinity,
              height: 115,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  '${meal.calories} kcal • ${meal.cookingTime}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color:
                          Color(0xFFFFB800),
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      meal.rating.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}