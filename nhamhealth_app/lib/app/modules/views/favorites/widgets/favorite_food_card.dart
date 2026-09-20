import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../models/favorites/favorite_food.dart';

class FavoriteFoodCard extends StatelessWidget {
  const FavoriteFoodCard({
    super.key,
    required this.food,
    required this.onOpen,
    required this.onRemove,
  });
  final FavoriteFood food;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isTablet =
        AppSpacing.isTabletFor(context) ||
        MediaQuery.sizeOf(context).shortestSide >= AppSpacing.tabletBreakpoint;

    return Material(
      color: context.appElevatedSurface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
            border: Border.all(color: context.appBorder),
          ),
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
                      top: isTablet ? 8 : 6,
                      right: isTablet ? 8 : 6,
                      child: Material(
                        color: context.appSurface,
                        shape: const CircleBorder(),
                        elevation: 1,
                        child: InkWell(
                          onTap: onRemove,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: EdgeInsets.all(isTablet ? 7 : 5),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: AppColors.primaryPink,
                              size: isTablet ? 20 : 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 10 : 7,
                  isTablet ? 8 : 7,
                  isTablet ? 10 : 7,
                  isTablet ? 10 : 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: isTablet ? 36 : 27,
                      child: Text(
                        food.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 10.5,
                          height: 1.18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${food.calories} kcal',
                            style: TextStyle(
                              fontSize: isTablet ? 11.5 : 9,
                              color: context.appMutedText,
                              fontWeight:
                                  isTablet ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            food.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isTablet ? 11.5 : 9,
                              color: context.appMutedText,
                              fontWeight:
                                  isTablet ? FontWeight.w500 : FontWeight.w400,
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
        ),
      ),
    );
  }
}

class _FoodFallback extends StatelessWidget {
  const _FoodFallback();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.appSoftGreen,
    child: const Center(
      child: Icon(Icons.restaurant_rounded, color: AppColors.primaryGreen),
    ),
  );
}
