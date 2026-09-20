import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../controllers/meals/meal_controller.dart';
import 'package:nhamhealth_flutter/app/translations/meal_localization_helpers.dart';

class MealFilterButton extends GetView<MealController> {
  const MealFilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => IconButton(
        key: const ValueKey<String>('meal-filter-button'),
        tooltip: 'meals.filter'.tr,
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
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppSpacing.tabletBreakpoint;
    if (isTablet) {
      Get.dialog<void>(
        const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(24),
          child: _MealFilterSheet(isDialog: true),
        ),
      );
    } else {
      Get.bottomSheet<void>(
        const _MealFilterSheet(isDialog: false),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }
}

class _MealFilterSheet extends GetView<MealController> {
  const _MealFilterSheet({this.isDialog = false});

  final bool isDialog;

  @override
  Widget build(BuildContext context) {
    final sheet = Container(
      constraints: BoxConstraints(
        maxWidth: isDialog ? 540 : double.infinity,
        maxHeight: MediaQuery.sizeOf(context).height * (isDialog ? 0.86 : 0.82),
      ),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius:
            isDialog
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(24)),
        border:
            isDialog
                ? Border.all(color: context.appBorder.withValues(alpha: 0.6))
                : null,
        boxShadow: isDialog ? context.appCardShadow : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, isDialog ? 20 : 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isDialog) ...[
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
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'meals.filters'.tr,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: isDialog ? 20 : 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.clearMealFilters,
                  child: Text('common.clear_all'.tr),
                ),
                if (isDialog) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'common.close'.tr,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back<void>(),
                  ),
                ],
              ],
            ),
              const SizedBox(height: 14),
              _FilterLabel(text: 'meals.category'.tr),
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
                        label: Text(
                          localizeCategory(controller.categories[index].name),
                        ),
                        selected: controller.selectedCategory.value == index,
                        onSelected: (_) => controller.selectCategory(index),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _FilterLabel(text: 'common.calories'.tr),
              const SizedBox(height: 8),
              Obx(
                () => _ChoiceRow<int?>(
                  value: controller.maxCalories.value,
                  values: const [null, 400, 600],
                  label:
                      (value) =>
                          value == null
                              ? 'common.any'.tr
                              : '≤ ${localizeCalories(value)}',
                  onSelected: controller.setMaxCalories,
                ),
              ),
              const SizedBox(height: 20),
              _FilterLabel(text: 'common.cooking_time'.tr),
              const SizedBox(height: 8),
              Obx(
                () => _ChoiceRow<int?>(
                  value: controller.maxCookingMinutes.value,
                  values: const [null, 20, 30],
                  label:
                      (value) =>
                          value == null
                              ? 'common.any'.tr
                              : '≤ ${localizeCookingTime(value)}',
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
                            'meals.ai_personalized_ideas'.tr,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'meals.personalization_data_description'.tr,
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
                        tooltip: 'meals.refresh_ai_ideas'.tr,
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
                  child: Text('common.done'.tr),
                ),
              ),
            ],
          ),
        ),
      );
    if (isDialog) {
      return Center(child: sheet);
    }
    return SafeArea(top: false, child: sheet);
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
