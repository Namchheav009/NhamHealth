import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

enum FoodPortionPreset {
  small(
    0.5,
    'wellness.portion_small',
    'wellness.portion_small_desc',
    Icons.rice_bowl_outlined,
  ),
  regular(
    1.0,
    'wellness.portion_regular',
    'wellness.portion_regular_desc',
    Icons.dinner_dining_outlined,
  ),
  large(
    1.5,
    'wellness.portion_large',
    'wellness.portion_large_desc',
    Icons.ramen_dining_outlined,
  ),
  xlarge(
    2.0,
    'wellness.portion_xlarge',
    'wellness.portion_xlarge_desc',
    Icons.set_meal_outlined,
  );

  const FoodPortionPreset(
    this.multiplier,
    this.titleKey,
    this.descKey,
    this.icon,
  );
  final double multiplier;
  final String titleKey;
  final String descKey;
  final IconData icon;

  static FoodPortionPreset fromMultiplier(double m) {
    if (m <= 0.65) return FoodPortionPreset.small;
    if (m <= 1.2) return FoodPortionPreset.regular;
    if (m <= 1.75) return FoodPortionPreset.large;
    return FoodPortionPreset.xlarge;
  }
}

enum DrinkCupPreset {
  small(250.0, 'wellness.cup_small', Icons.coffee_outlined),
  regular(500.0, 'wellness.cup_regular', Icons.local_cafe_outlined),
  large(700.0, 'wellness.cup_large', Icons.emoji_food_beverage_outlined);

  const DrinkCupPreset(this.ml, this.titleKey, this.icon);
  final double ml;
  final String titleKey;
  final IconData icon;

  static DrinkCupPreset fromMl(double ml) {
    if (ml <= 320) return DrinkCupPreset.small;
    if (ml <= 600) return DrinkCupPreset.regular;
    return DrinkCupPreset.large;
  }
}

/// Visual Portion Size Selector for Food or Drinks.
class VisualPortionSelector extends StatelessWidget {
  const VisualPortionSelector({
    super.key,
    required this.isDrink,
    required this.selectedAmount,
    required this.onFoodAmountChanged,
    required this.onDrinkCupChanged,
    this.drinkSugarPercentage = 100,
    this.onDrinkSugarChanged,
    this.baseCalories = 400.0,
  });

  final bool isDrink;
  final double selectedAmount;
  final ValueChanged<double> onFoodAmountChanged;
  final ValueChanged<double> onDrinkCupChanged;
  final int drinkSugarPercentage;
  final ValueChanged<int>? onDrinkSugarChanged;
  final double baseCalories;

  static const green = Color(0xFF00A651);
  static const greenDark = Color(0xFF087A48);

  @override
  Widget build(BuildContext context) {
    return isDrink ? _buildDrinkSelector(context) : _buildFoodSelector(context);
  }

  Widget _buildFoodSelector(BuildContext context) {
    final currentPreset = FoodPortionPreset.fromMultiplier(selectedAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 18, color: green),
            const SizedBox(width: 8),
            Text(
              'wellness.choose_plate_size'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Visual grid of 4 portion cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children:
              FoodPortionPreset.values.map((preset) {
                final isSelected = (currentPreset == preset);
                final calories = (baseCalories * preset.multiplier).round();

                return InkWell(
                  onTap: () => onFoodAmountChanged(preset.multiplier),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? (context.appIsDark
                                  ? green.withValues(alpha: .22)
                                  : const Color(0xFFE8F8F0))
                              : context.appSurfaceLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected
                                ? green
                                : context.appBorder.withValues(alpha: .5),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: green.withValues(alpha: .18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                              : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? green
                                        : context.appBorder.withValues(
                                          alpha: .3,
                                        ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                preset.icon,
                                size: 18,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : context.appMutedText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? green.withValues(alpha: .15)
                                        : context.appBorder.withValues(
                                          alpha: .2,
                                        ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${preset.multiplier}x',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isSelected
                                          ? greenDark
                                          : context.appMutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.titleKey.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                color:
                                    isSelected
                                        ? (context.appIsDark
                                            ? const Color(0xFF5EE09A)
                                            : greenDark)
                                        : context.appText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$calories kcal',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? greenDark
                                        : context.appMutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDrinkSelector(BuildContext context) {
    final currentCup = DrinkCupPreset.fromMl(selectedAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_drink_outlined, size: 18, color: green),
            const SizedBox(width: 8),
            Text(
              'wellness.choose_drink_size'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 3 Horizontal Cup Size Cards
        Row(
          children:
              DrinkCupPreset.values.map((cup) {
                final isSelected = (currentCup == cup);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => onDrinkCupChanged(cup.ml),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? (context.appIsDark
                                      ? green.withValues(alpha: .22)
                                      : const Color(0xFFE8F8F0))
                                  : context.appSurfaceLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? green
                                    : context.appBorder.withValues(alpha: .5),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              cup.icon,
                              size:
                                  cup == DrinkCupPreset.large
                                      ? 28
                                      : (cup == DrinkCupPreset.regular
                                          ? 24
                                          : 20),
                              color: isSelected ? green : context.appMutedText,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${cup.ml.toInt()} ml',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:
                                    isSelected
                                        ? (context.appIsDark
                                            ? const Color(0xFF5EE09A)
                                            : greenDark)
                                        : context.appText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cup.titleKey.tr.split('(').first.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isSelected
                                        ? greenDark
                                        : context.appMutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
        // Visual Sugar Level with Cubes
        _buildSugarLevelSection(context),
      ],
    );
  }

  Widget _buildSugarLevelSection(BuildContext context) {
    if (onDrinkSugarChanged == null) return const SizedBox.shrink();

    final sugarLevels = const [0, 25, 50, 100, 120];
    final cubes = _sugarCubesFor(drinkSugarPercentage);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🧊', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'wellness.sugar_level'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      drinkSugarPercentage > 100
                          ? Colors.orange.withValues(alpha: .2)
                          : green.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$drinkSugarPercentage% ($cubes ${cubes == 1 ? 'cube' : 'cubes'})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        drinkSugarPercentage > 100
                            ? Colors.orange.shade800
                            : greenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sugar level pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                sugarLevels.map((lvl) {
                  final isSel = (drinkSugarPercentage == lvl);
                  return InkWell(
                    onTap: () => onDrinkSugarChanged!(lvl),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSel
                                ? (lvl > 100 ? Colors.orange : green)
                                : context.appSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSel
                                  ? (lvl > 100 ? Colors.orange : green)
                                  : context.appBorder.withValues(alpha: .5),
                        ),
                      ),
                      child: Text(
                        '$lvl%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white : context.appText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  int _sugarCubesFor(int percentage) {
    if (percentage == 0) return 0;
    if (percentage <= 25) return 2;
    if (percentage <= 50) return 4;
    if (percentage <= 100) return 7;
    return 10;
  }
}
