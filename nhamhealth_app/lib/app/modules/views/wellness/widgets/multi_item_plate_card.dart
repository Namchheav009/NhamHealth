import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import '../../../models/wellness/plate_item_model.dart';
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

      final selectedCount = items.where((i) => i.isSelected).length;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                context.appIsDark
                    ? context.appBorder.withValues(alpha: .5)
                    : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.appIsDark ? .2 : .04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.restaurant_outlined,
                    color: greenDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wellness.plate_items'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'wellness.detected_items_count'.trParams({
                          'count': '${items.length}',
                        }),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active count pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selectedCount > 0
                            ? green.withValues(alpha: .15)
                            : Colors.grey.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'wellness.items_selected'.trParams({
                      'count': '$selectedCount',
                    }),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color:
                          selectedCount > 0 ? greenDark : context.appMutedText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildPlateItemTile(context, item, index);
              },
            ),

            const SizedBox(height: 14),

            // Add missing item button
            OutlinedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text('wellness.add_plate_item'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: greenDark,
                side: BorderSide(color: green.withValues(alpha: .4)),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPlateItemTile(
    BuildContext context,
    PlateItemState item,
    int index,
  ) {
    final isSelected = item.isSelected;
    final itemIcon = _iconFor(item);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isSelected
                ? (context.appIsDark
                    ? green.withValues(alpha: .12)
                    : const Color(0xFFF0FDF4))
                : context.appSurfaceLow.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSelected
                  ? green.withValues(alpha: .6)
                  : context.appBorder.withValues(alpha: .4),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Checkbox, Food Icon, Item Name, and Remove Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox toggle
              InkWell(
                onTap: () => controller.togglePlateItem(index),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    isSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: isSelected ? green : context.appMutedText,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Food Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? green.withValues(alpha: .18)
                          : context.appBorder.withValues(alpha: .3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  itemIcon,
                  size: 18,
                  color: isSelected ? greenDark : context.appMutedText,
                ),
              ),
              const SizedBox(width: 10),

              // Item Name
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? context.appText : context.appMutedText,
                    decoration: isSelected ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Remove item button
              IconButton(
                onPressed: () => controller.removePlateItem(index),
                icon: const Icon(Icons.close_rounded, size: 18),
                color: context.appMutedText,
                tooltip: 'Remove',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Row 2: Calories & Macros (Left) + Portion Selector Pill Button (Right)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Calories & Macros
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${item.calories.round()} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? greenDark : context.appMutedText,
                          ),
                        ),
                        if (item.protein > 0 || item.carbs > 0 || item.fat > 0)
                          TextSpan(
                            text:
                                ' • P:${item.protein.toStringAsFixed(0)}g C:${item.carbs.toStringAsFixed(0)}g F:${item.fat.toStringAsFixed(0)}g',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.appMutedText,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Portion Selector Pill Button
                InkWell(
                  onTap:
                      isSelected
                          ? () => _showPortionSheet(context, item, index)
                          : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (context.appIsDark
                                  ? green.withValues(alpha: .25)
                                  : const Color(0xFFDCFCE7))
                              : context.appBorder.withValues(alpha: .2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? green : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.portionLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isSelected ? greenDark : context.appMutedText,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: isSelected ? greenDark : context.appMutedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              Text(
                '${'wellness.select_portion'.tr}: ${item.name}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.appText,
                ),
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

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: dialogContext.appSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'wellness.add_plate_item'.tr,
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
                    hintText: 'e.g. Rice, Grilled Fish',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'wellness.plate_item_calories'.tr,
                    hintText: '150',
                  ),
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
                  if (name.isNotEmpty) {
                    controller.addPlateItem(
                      name: name,
                      calories: cals,
                      protein: cals * 0.05,
                      carbs: cals * 0.15,
                      fat: cals * 0.03,
                    );
                  }
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(backgroundColor: green),
                child: Text('wellness.add_plate_item'.tr),
              ),
            ],
          ),
    );
  }

  IconData _iconFor(PlateItemState item) {
    if (item.componentType == 'drink') return Icons.local_drink_outlined;
    final lower = item.name.toLowerCase();
    if (lower.contains('rice') ||
        lower.contains('បាយ') ||
        lower.contains('noodle')) {
      return Icons.rice_bowl_outlined;
    }
    if (lower.contains('soup') ||
        lower.contains('សម្ល') ||
        lower.contains('curry')) {
      return Icons.soup_kitchen_outlined;
    }
    if (lower.contains('fish') ||
        lower.contains('meat') ||
        lower.contains('pork') ||
        lower.contains('chicken') ||
        lower.contains('សាច់') ||
        lower.contains('ត្រី')) {
      return Icons.set_meal_outlined;
    }
    if (lower.contains('vegetable') ||
        lower.contains('salad') ||
        lower.contains('បន្លែ')) {
      return Icons.eco_outlined;
    }
    return Icons.lunch_dining_outlined;
  }
}
