import 'package:flutter/material.dart';

import '../../models/meal_model.dart';

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
              child: _MealImage(path: meal.image),
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

class _MealImage extends StatelessWidget {
  const _MealImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    const fallback = 'assets/images/meals/healthy_salad.jpg';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(fallback, fit: BoxFit.cover),
      );
    }
    return Image.asset(
      path.isEmpty ? fallback : path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(fallback, fit: BoxFit.cover),
    );
  }
}
