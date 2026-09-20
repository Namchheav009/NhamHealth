import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import '../../../models/wellness/plate_item_model.dart';

/// Card showing intelligent AI observations and health tips
/// derived from the specific ingredients detected on the plate.
class PlateAiInsightsCard extends StatelessWidget {
  const PlateAiInsightsCard({super.key, required this.controller});

  final AiFoodController controller;

  static const Color green = Color(0xFF00A651);
  static const Color greenDark = Color(0xFF087A48);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.plateItems.where((i) => i.isSelected).toList();
      if (items.isEmpty) return const SizedBox.shrink();

      final insights = _generateInsights(items);
      if (insights.isEmpty) return const SizedBox.shrink();

      final isDark = context.appIsDark;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? context.appSurface : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? context.appBorder.withValues(alpha: 0.6)
                    : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Sparkle Icon + Title
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF143021)
                            : const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.tips_and_updates_rounded,
                      color: green,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wellness.ingredient_insights'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'wellness.ingredient_insights_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: context.appBorder.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),

            // Insights list
            ...insights.map((insight) => _buildInsightTile(context, insight)),
          ],
        ),
      );
    });
  }

  Widget _buildInsightTile(BuildContext context, _PlateInsight insight) {
    final isDark = context.appIsDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: insight.color.withValues(alpha: isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(insight.icon, size: 14, color: insight.color),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appMutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_PlateInsight> _generateInsights(List<PlateItemState> items) {
    final list = <_PlateInsight>[];

    // 1. Cooking Oil / Fat Check
    final oilItem = items.firstWhereOrNull(
      (i) =>
          i.role.toLowerCase().contains('cooking fat') ||
          i.name.toLowerCase().contains('oil') ||
          i.name.toLowerCase().contains('butter'),
    );
    if (oilItem != null && oilItem.calories >= 60) {
      list.add(
        _PlateInsight(
          title: 'wellness.insight_cooking_oil_title'.tr,
          description: 'wellness.insight_cooking_oil_desc'.trParams({
            'cals': '${oilItem.calories.round()}',
          }),
          icon: Icons.opacity_rounded,
          color: const Color(0xFFF59E0B),
        ),
      );
    }

    // 2. Carb Base Check
    final carbItem = items.firstWhereOrNull(
      (i) =>
          i.role.toLowerCase().contains('carb base') ||
          i.role.toLowerCase().contains('noodle base') ||
          i.role.toLowerCase().contains('baked carb'),
    );
    if (carbItem != null && carbItem.carbs >= 30) {
      list.add(
        _PlateInsight(
          title: 'wellness.insight_carb_title'.trParams({
            'name': carbItem.name,
          }),
          description: 'wellness.insight_carb_desc'.trParams({
            'carbs': '${carbItem.carbs.round()}',
          }),
          icon: Icons.grain_rounded,
          color: const Color(0xFF3B82F6),
        ),
      );
    }

    // 3. Protein Source Check
    final proteinItem = items.firstWhereOrNull(
      (i) =>
          i.role.toLowerCase().contains('protein') ||
          i.name.toLowerCase().contains('egg') ||
          i.name.toLowerCase().contains('chicken') ||
          i.name.toLowerCase().contains('beef') ||
          i.name.toLowerCase().contains('pork') ||
          i.name.toLowerCase().contains('fish') ||
          i.name.toLowerCase().contains('tofu'),
    );
    if (proteinItem != null && proteinItem.protein >= 5) {
      list.add(
        _PlateInsight(
          title: 'wellness.insight_protein_title'.trParams({
            'name': proteinItem.name,
          }),
          description: 'wellness.insight_protein_desc'.trParams({
            'protein': '${proteinItem.protein.round()}',
          }),
          icon: Icons.fitness_center_rounded,
          color: const Color(0xFF10B981),
        ),
      );
    }

    // 4. Veggie Boost Tip
    final veggieItem = items.firstWhereOrNull(
      (i) =>
          i.role.toLowerCase().contains('green') ||
          i.name.toLowerCase().contains('vegetable') ||
          i.name.toLowerCase().contains('salad'),
    );
    if (veggieItem == null || veggieItem.baseServingSize < 60) {
      list.add(
        _PlateInsight(
          title: 'wellness.insight_veggie_boost_title'.tr,
          description: 'wellness.insight_veggie_boost_desc'.tr,
          icon: Icons.eco_rounded,
          color: const Color(0xFF059669),
        ),
      );
    }

    return list;
  }
}

class _PlateInsight {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _PlateInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
