import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../models/favorite_food.dart';

class FavoriteFoodCard extends StatelessWidget {
  const FavoriteFoodCard({super.key, required this.food, required this.onRemove});
  final FavoriteFood food;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE3E8E5))),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Stack(fit: StackFit.expand, children: [
        Image.asset(
          food.image,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFEAF4EE),
            child: Icon(Icons.restaurant_rounded, color: Color(0xFF0AA653)),
          ),
        ),
        Positioned(top: 6, right: 6, child: Material(color: Colors.white, shape: const CircleBorder(), elevation: 1, child: InkWell(
          onTap: onRemove,
          customBorder: const CircleBorder(),
          child: const Padding(padding: EdgeInsets.all(5), child: Icon(Icons.favorite_rounded, color: AppColors.primaryPink, size: 18)),
        ))),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(7, 7, 7, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 27, child: Text(food.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, height: 1.15, fontWeight: FontWeight.w600))),
        const SizedBox(height: 5),
        Row(children: [Expanded(child: Text('${food.calories} kcal', style: const TextStyle(fontSize: 9, color: AppColors.secondaryText))), const Icon(Icons.star_rounded, color: Color(0xFFFFBE0B), size: 14), Text(food.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 9))]),
      ])),
    ]),
  );
}
