import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../controllers/meals/meal_controller.dart';
import 'package:nhamhealth_flutter/app/translations/meal_localization_helpers.dart';

class MealCategory extends GetView<MealController> {
  const MealCategory({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppSpacing.tabletBreakpoint;
    final barHeight = isTablet ? 46.0 : 42.0;

    return SizedBox(
      height: barHeight,
      child: Obx(
        () => ListView.separated(
          key: const ValueKey('meal-category-top-bar'),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: controller.categories.length,
          separatorBuilder: (_, _) => SizedBox(width: isTablet ? 10 : 8),
          itemBuilder: (context, index) {
            final selected = controller.selectedCategory.value == index;
            final category = controller.categories[index];

            return Semantics(
              button: true,
              selected: selected,
              label: 'meals.show_category_meals'.trParams({
                'category': localizeCategory(category.name),
              }),
              child: InkWell(
                key: ValueKey<int>(category.id),
                onTap: () => controller.selectCategory(index),
                borderRadius: BorderRadius.circular(barHeight / 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: barHeight,
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? context.appColorScheme.primary
                            : context.appElevatedSurface,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color:
                          selected
                              ? context.appColorScheme.primary
                              : context.appBorder,
                    ),
                    boxShadow: selected ? context.appTileShadow : null,
                  ),
                  child: Text(
                    localizeCategory(category.name),
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color:
                          selected
                              ? context.appColorScheme.onPrimary
                              : context.appText,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
