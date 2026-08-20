import 'package:flutter/material.dart';

import '../../controllers/meal_controller.dart';

class MealCard extends StatelessWidget {
  final MealModel meal;
  final VoidCallback onFavorite;

  const MealCard({super.key, required this.meal, required this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                meal.image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(7, 8, 5, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: Color(0xFF424242),
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${meal.calories} kcal',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),

                    Tooltip(
                      message:
                          meal.isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                      child: InkResponse(
                        onTap: onFavorite,
                        radius: 18,
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(
                            meal.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 22,
                            color:
                                meal.isFavorite
                                    ? Colors.red
                                    : const Color(0xFF969696),
                          ),
                        ),
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
