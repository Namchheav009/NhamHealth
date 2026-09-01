import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/meals/meal_controller.dart';

class MealFilterButton extends GetView<MealController> {
  const MealFilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => IconButton(
        key: const ValueKey<String>('meal-filter-button'),
        tooltip: 'Filter meals'.tr,
        onPressed: () => _showFilters(context),
        icon: Badge(
          isLabelVisible: controller.activeFilterCount > 0,
          label: Text('${controller.activeFilterCount}'),
          child: Icon(
            Icons.tune_rounded,
            color:
                controller.activeFilterCount > 0
                    ? context.appColorScheme.primary
                    : context.appMutedText,
            size: 23,
          ),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    Get.bottomSheet<void>(
      const _MealFilterSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _MealFilterSheet extends GetView<MealController> {
  const _MealFilterSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Meal filters'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.clearMealFilters,
                    child: Text('Clear all'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FilterLabel(text: 'Category'.tr),
              const SizedBox(height: 8),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (
                      var index = 0;
                      index < controller.categories.length;
                      index++
                    )
                      ChoiceChip(
                        label: Text(controller.categories[index].name.tr),
                        selected: controller.selectedCategory.value == index,
                        onSelected: (_) => controller.selectCategory(index),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _FilterLabel(text: 'Calories'.tr),
              const SizedBox(height: 8),
              Obx(
                () => _ChoiceRow<int?>(
                  value: controller.maxCalories.value,
                  values: const [null, 400, 600],
                  label: (value) => value == null ? 'Any'.tr : '≤ $value kcal',
                  onSelected: controller.setMaxCalories,
                ),
              ),
              const SizedBox(height: 20),
              _FilterLabel(text: 'Cooking time'.tr),
              const SizedBox(height: 8),
              Obx(
                () => _ChoiceRow<int?>(
                  value: controller.maxCookingMinutes.value,
                  values: const [null, 20, 30],
                  label: (value) => value == null ? 'Any'.tr : '≤ $value min',
                  onSelected: controller.setMaxCookingMinutes,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.appColorScheme.primary.withValues(
                      alpha: 0.22,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI personalized ideas'.tr,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Uses saved height, weight and BMI when available, plus activity and daily nutrition goals for general wellness.'
                                .tr,
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 10.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Obx(
                      () => IconButton(
                        tooltip: 'Refresh AI ideas'.tr,
                        onPressed:
                            controller.isIdeasLoading.value
                                ? null
                                : () => controller.loadPersonalizedIdeas(
                                  refresh: true,
                                ),
                        icon:
                            controller.isIdeasLoading.value
                                ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.refresh_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Get.back<void>(),
                  child: Text('Done'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.value,
    required this.values,
    required this.label,
    required this.onSelected,
  });

  final T value;
  final List<T> values;
  final String Function(T value) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in values)
          ChoiceChip(
            label: Text(label(option)),
            selected: value == option,
            onSelected: (_) => onSelected(option),
          ),
      ],
    );
  }
}
