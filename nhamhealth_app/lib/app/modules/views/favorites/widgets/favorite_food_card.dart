import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/favorites/favorite_food.dart';

class FavoriteFoodCard extends StatelessWidget {
  const FavoriteFoodCard({
    super.key,
    required this.food,
    required this.onRemove,
  });
  final FavoriteFood food;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.appBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              food.image.startsWith('http')
                  ? CachedNetworkImage(
                    imageUrl: food.image,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const _FoodFallback(),
                  )
                  : food.image.isEmpty
                  ? const _FoodFallback()
                  : Image.asset(
                    food.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _FoodFallback(),
                  ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: context.appSurface,
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primaryPink,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 27,
                child: Text(
                  food.name.tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${food.calories} kcal',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.appMutedText,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFBE0B),
                    size: 14,
                  ),
                  Text(
                    food.rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 9, color: context.appText),
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

class _FoodFallback extends StatelessWidget {
  const _FoodFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFFEAF4EE),
    child: Center(
      child: Icon(Icons.restaurant_rounded, color: Color(0xFF0AA653)),
    ),
  );
}
