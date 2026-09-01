import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/meals/meal_controller.dart';

class MealCategory extends GetView<MealController> {
  const MealCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Obx(
        () => ListView.separated(
          key: const ValueKey('meal-category-top-bar'),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: controller.categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final selected = controller.selectedCategory.value == index;
            final category = controller.categories[index];

            return Semantics(
              button: true,
              selected: selected,
              label: 'Show @category meals'.trParams({
                'category': category.name.tr,
              }),
              child: InkWell(
                key: ValueKey<int>(category.id),
                onTap: () => controller.selectCategory(index),
                borderRadius: BorderRadius.circular(21),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 42,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    category.name.tr,
                    style: TextStyle(
                      fontSize: 12,
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
