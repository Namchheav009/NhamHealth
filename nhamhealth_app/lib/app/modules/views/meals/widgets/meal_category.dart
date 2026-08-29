import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/meals/meal_controller.dart';

class MealCategory extends GetView<MealController> {
  const MealCategory({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Obx(
        () => ListView.separated(
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
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  height: 36,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? context.appColorScheme.primary
                            : context.appElevatedSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected
                              ? context.appColorScheme.primary
                              : context.appBorder,
                    ),
                  ),
                  child: Text(
                    category.name.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
