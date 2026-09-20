import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import '../../../models/wellness/plate_item_model.dart';
import '../../../services/wellness/ingredient_visual_service.dart';
import 'ingredient_avatar.dart';
import 'visual_portion_selector.dart';

class MultiItemPlateCard extends StatelessWidget {
  const MultiItemPlateCard({super.key, required this.controller});

  final AiFoodController controller;

  static const green = Color(0xFF00A651);
  static const greenDark = Color(0xFF087A48);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.plateItems;
      if (items.isEmpty) return const SizedBox.shrink();

      final isDark = context.appIsDark;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
            // Header Row: Sparkle Icon + Title & Subtitle + Count Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: Icon(Icons.auto_awesome, color: green, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wellness.detected_ingredients'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'wellness.ingredients_likely_inside'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appMutedText,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? green.withValues(alpha: 0.18)
                            : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'wellness.ingredients_found'.trParams({
                      'count': '${items.length}',
                    }),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF4ADE80) : greenDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: context.appBorder.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),

            // Ingredients List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder:
                  (_, _) => Divider(
                    height: 20,
                    thickness: 0.8,
                    color: context.appBorder.withValues(alpha: 0.35),
                  ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildIngredientRow(context, item, index);
              },
            ),

            const SizedBox(height: 16),

            // Info note row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? context.appSurfaceLow : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.appBorder.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? green.withValues(alpha: 0.2)
                              : const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: greenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'wellness.review_and_adjust_ingredients'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appMutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Add Ingredient Button
            OutlinedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                'wellness.add_ingredient'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFF4ADE80) : greenDark,
                side: BorderSide(
                  color: green.withValues(alpha: isDark ? 0.6 : 0.4),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildIngredientRow(
    BuildContext context,
    PlateItemState item,
    int index,
  ) {
    final visual = IngredientVisualService.resolve(
      item.name,
      componentType: item.componentType,
      customRole: item.role,
      customImageUrl: item.imageUrl,
    );

    final displayRole = item.role.isNotEmpty ? item.role : visual.defaultRole;

    return InkWell(
      onTap: () => _showPortionSheet(context, item, index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar / Thumbnail
            IngredientAvatar(
              name: item.name,
              imageUrl: item.imageUrl ?? visual.imageUrl,
              componentType: item.componentType,
              size: 52,
            ),
            const SizedBox(width: 12),

            // Name, Role & Confidence Pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color:
                          item.isSelected
                              ? context.appText
                              : context.appMutedText,
                      decoration:
                          item.isSelected ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appMutedText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Confidence & Macro Badges
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildConfidenceBadge(context, item),
                      if (item.calories > 0) ...[
                        const SizedBox(width: 6),
                        _buildMacroContributionPill(context, item),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Subtle Vertical Divider
            Container(
              width: 1,
              height: 42,
              color: context.appBorder.withValues(alpha: 0.5),
            ),

            const SizedBox(width: 12),

            // Amount Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'wellness.amount_label'.tr,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.appMutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.servingSize.round()} ${item.unit}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, PlateItemState item) {
    final isDark = context.appIsDark;
    final isHigh = item.isHighConfidence;
    final isMed = item.isMediumConfidence;

    final Color bgColor =
        isHigh
            ? (isDark ? const Color(0xFF143021) : const Color(0xFFECFDF5))
            : isMed
            ? (isDark ? const Color(0xFF332005) : const Color(0xFFFFFBEB))
            : (isDark ? context.appSurfaceLow : const Color(0xFFF1F5F9));

    final Color textColor =
        isHigh
            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669))
            : isMed
            ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
            : context.appMutedText;

    final IconData icon =
        isHigh
            ? Icons.signal_cellular_alt_rounded
            : isMed
            ? Icons.signal_cellular_alt_2_bar_rounded
            : Icons.signal_cellular_alt_1_bar_rounded;

    final String label =
        isHigh
            ? 'wellness.high_confidence'.tr
            : isMed
            ? 'wellness.medium_confidence'.tr
            : 'wellness.low_confidence'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: textColor),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroContributionPill(
    BuildContext context,
    PlateItemState item,
  ) {
    final isDark = context.appIsDark;
    final cals = item.calories.round();
    String macroText = '';
    if (item.carbs >= item.protein &&
        item.carbs >= item.fat &&
        item.carbs >= 3) {
      macroText = ' • ${item.carbs.round()}g C';
    } else if (item.protein >= item.carbs &&
        item.protein >= item.fat &&
        item.protein >= 2) {
      macroText = ' • ${item.protein.round()}g P';
    } else if (item.fat >= 2) {
      macroText = ' • ${item.fat.round()}g F';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$cals kcal$macroText',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  void _showPortionSheet(BuildContext context, PlateItemState item, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${'wellness.select_portion'.tr}: ${item.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.removePlateItem(index);
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Remove',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              VisualPortionSelector(
                isDrink: item.componentType == 'drink',
                selectedAmount: item.portionMultiplier,
                baseCalories: item.baseCalories,
                onFoodAmountChanged: (multiplier) {
                  controller.updatePlateItemPortion(index, multiplier);
                  Navigator.pop(sheetContext);
                },
                onDrinkCupChanged: (ml) {
                  final multiplier = ml / 350.0;
                  controller.updatePlateItemPortion(index, multiplier);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController(text: '150');
    final amountController = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: dialogContext.appSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'wellness.add_ingredient'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dialogContext.appText,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'wellness.plate_item_name'.tr,
                    hintText: 'e.g. Matcha powder, Sweetener',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'wellness.amount_label'.tr,
                          hintText: '50',
                          suffixText: 'g',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'wellness.plate_item_calories'.tr,
                          hintText: '150',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('common.cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final cals =
                      double.tryParse(caloriesController.text.trim()) ?? 150.0;
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 50.0;
                  if (name.isNotEmpty) {
                    controller.addPlateItem(
                      name: name,
                      calories: cals,
                      protein: cals * 0.05,
                      carbs: cals * 0.15,
                      fat: cals * 0.03,
                      amount: amount,
                      unit: 'g',
                    );
                  }
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('wellness.add_ingredient'.tr),
              ),
            ],
          ),
    );
  }
}
