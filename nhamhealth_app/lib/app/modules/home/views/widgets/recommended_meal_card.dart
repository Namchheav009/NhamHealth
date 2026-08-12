import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../models/recommended_meal_model.dart';
import 'inner_shadow.dart';

class RecommendedMealCard extends StatelessWidget {
  const RecommendedMealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.onFavorite,
  });

  final RecommendedMealModel meal;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE3E8E5)),
        boxShadow: AppShadows.tile,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(13),
        shadows: AppShadows.innerSurface,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.asset(
                        meal.image,
                        width: double.infinity,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 5,
                      child: InkWell(
                        onTap: onFavorite,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFD5DAD7)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            size: 16,
                            color: Color(0xFF8A8D8B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            meal.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 9,
                              height: 1.12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${meal.calories} kcal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFAAA9A9),
                                  fontSize: 8,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                              size: 13,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              meal.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFF737373),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
