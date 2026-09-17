import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../models/planner/meal_plan.dart';
import 'planner_shared.dart';

String _plannerLabel(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}

class MealPlannerView extends GetView<MealPlannerController> {
  const MealPlannerView({super.key});

  static const _days = [
    'planner.mon',
    'planner.tue',
    'planner.wed',
    'planner.thu',
    'planner.fri',
    'planner.sat',
    'planner.sun',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    body: AppBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontalFor(context),
                12,
                AppSpacing.pageHorizontalFor(context),
                0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxContentWidth,
                ),
                child: _header(context),
              ),
            ),
            Expanded(
              child: Obx(
                () => RefreshIndicator(
                  onRefresh: controller.refreshPlanner,
                  color: AppColors.primaryGreen,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalFor(context),
                      14,
                      AppSpacing.pageHorizontalFor(context),
                      100,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSpacing.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _dateCard(context),
                              if (controller.isLoading.value)
                                const Padding(
                                  padding: EdgeInsets.only(top: 14),
                                  child: LinearProgressIndicator(
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              if (controller.errorMessage.value.isNotEmpty ||
                                  controller
                                      .recommendationsError
                                      .value
                                      .isNotEmpty)
                                _error(context),
                              const SizedBox(height: 16),
                              _dailyOverview(context),
                              const SizedBox(height: 20),
                              _sectionHeading(context),
                              const SizedBox(height: 12),
                              ...MealPlanSlot.values.map(
                                (slot) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _slotCard(context, slot),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalFor(context),
        8,
        AppSpacing.pageHorizontalFor(context),
        16,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxContentWidth,
          ),
          child: PlannerPrimaryButton(
            label: 'planner.generate_grocery_list'.tr,
            icon: Icons.shopping_bag_outlined,
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () => _generate(context),
          ),
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) {
    return PlannerPageHeader(
      title: 'planner.title'.tr,
      showBack: Navigator.of(context).canPop(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'planner.weekly_view'.tr,
            onPressed: () => Get.toNamed(AppRoutes.mealPlannerWeek),
            icon: const Icon(Icons.calendar_month_outlined),
            color: AppColors.primaryGreen,
            iconSize: 24,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'planner.grocery_list'.tr,
            onPressed: () => Get.toNamed(AppRoutes.mealPlannerGrocery),
            icon: const Icon(Icons.shopping_basket_outlined),
            color: AppColors.primaryGreen,
            iconSize: 24,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _dateCard(BuildContext context) {
    final start = controller.weekStart;
    final end = controller.weekDays.last;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _weekArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => controller.changeWeek(-1),
                context: context,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'planner.this_week'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              _weekArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => controller.changeWeek(1),
                context: context,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Divider(height: 1, color: context.appBorder.withValues(alpha: 0.65)),
          const SizedBox(height: 11),
          SizedBox(
            height: 64,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(7, (index) {
                  final date = controller.weekDays[index];
                  final isSelected = index == controller.selectedDayIndex.value;
                  final hasMeals = controller.mealsFor(date).isNotEmpty;
                  return SizedBox(
                    width: 62,
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 6 ? 0 : 7),
                      child: _dayPill(
                        context: context,
                        index: index,
                        date: date,
                        dayName: _days[index].tr,
                        isSelected: isSelected,
                        hasMeals: hasMeals,
                        onTap: () => controller.selectDay(index),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekArrowButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.appBackground,
        shape: BoxShape.circle,
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
      ),
      child: Center(child: Icon(icon, size: 20, color: context.appText)),
    ),
  );

  Widget _dayPill({
    required BuildContext context,
    required int index,
    required DateTime date,
    required String dayName,
    required bool isSelected,
    required bool hasMeals,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: ValueKey('planner-day-$index'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : context.appBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primaryGreen
                    : context.appBorder.withValues(alpha: 0.65),
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : context.appMutedText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : context.appText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white
                        : (hasMeals
                            ? AppColors.primaryGreen
                            : Colors.transparent),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyOverview(BuildContext context) {
    final progress = controller.adherenceProgress.clamp(0.0, 1.0);
    final hasMeals = controller.selectedMeals.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.daily_overview'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasMeals
                          ? controller.dailyGoalComplete
                              ? 'planner.all_meals_eaten'.tr
                              : 'planner.mark_meals_eaten'.tr
                          : _plannerLabel(
                            'planner.start_planning_day',
                            'Start planning your day',
                          ),
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: context.appBorder.withValues(alpha: 0.6),
                      color: AppColors.primaryGreen,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _plannerLabel('planner.adherence', 'adherence'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _macroCard(
                context,
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: '${controller.selectedCalories}',
                label: 'planner.kcal'.tr,
              ),
              _macroDivider(context),
              _macroCard(
                context,
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF3B82F6),
                value: '${controller.selectedProtein.toStringAsFixed(0)}g',
                label: 'planner.protein'.tr,
              ),
              _macroDivider(context),
              _macroCard(
                context,
                icon: Icons.blur_on_rounded,
                iconColor: const Color(0xFF10B981),
                value: '${controller.selectedCarbs.toStringAsFixed(0)}g',
                label: 'planner.carbs'.tr,
              ),
              _macroDivider(context),
              _macroCard(
                context,
                icon: Icons.opacity_rounded,
                iconColor: const Color(0xFFF43F5E),
                value: '${controller.selectedFat.toStringAsFixed(0)}g',
                label: 'planner.fat'.tr,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.appBorder.withValues(alpha: 0.6),
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.eatenMeals}/${controller.dailyMealGoal} ${'planner.meals_eaten_short'.tr}'
            '${controller.skippedMeals == 0 ? '' : '  •  ${controller.skippedMeals} ${'planner.skipped'.tr}'}',
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroDivider(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: context.appBorder.withValues(alpha: 0.7),
  );

  Widget _macroCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: context.appText,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeading(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'planner.meals_for_date'.trParams({
              'date': DateFormat('EEE, d MMM').format(controller.selectedDate),
            }),
            style: TextStyle(
              color: context.appText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _showEditDaySheet(context),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: Text('planner.edit_day'.tr),
        ),
      ],
    );
  }

  Future<void> _showEditDaySheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: context.appSurfaceLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder:
            (sheet) => Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.appBorder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'planner.meals_for_date'.trParams({
                      'date': DateFormat(
                        'EEE, d MMM',
                      ).format(controller.selectedDate),
                    }),
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.appBorder),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          MealPlanSlot.values.indexed.map((entry) {
                            final index = entry.$1;
                            final slot = entry.$2;
                            final meal = controller.mealFor(slot);
                            final slotTheme = PlannerSlotTheme.of(slot);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 3,
                                  ),
                                  leading:
                                      meal == null
                                          ? CircleAvatar(
                                            backgroundColor: slotTheme.soft,
                                            child: Icon(
                                              slotTheme.icon,
                                              color: slotTheme.accent,
                                              size: 21,
                                            ),
                                          )
                                          : PlannerMealImage(
                                            meal: meal,
                                            width: 44,
                                            height: 44,
                                            radius: 11,
                                          ),
                                  title: Text(
                                    slot.labelKey.tr,
                                    style: TextStyle(
                                      color: context.appText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    meal == null
                                        ? '+ ${'planner.add_meal'.tr}'
                                        : plannerMealName(meal),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          meal == null
                                              ? AppColors.primaryGreen
                                              : context.appMutedText,
                                    ),
                                  ),
                                  trailing: Icon(
                                    meal == null
                                        ? Icons.add_circle_rounded
                                        : Icons.edit_outlined,
                                    color: AppColors.primaryGreen,
                                  ),
                                  onTap: () {
                                    Navigator.pop(sheet);
                                    if (meal == null) {
                                      _openSlot(slot);
                                    } else {
                                      _showMealOptionsSheet(context, meal);
                                    }
                                  },
                                ),
                                if (index < MealPlanSlot.values.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 60,
                                    color: context.appBorder,
                                  ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
      );

  Widget _slotCard(BuildContext context, MealPlanSlot slot) {
    final meal = controller.mealFor(slot);
    final theme = PlannerSlotTheme.of(slot);

    return Material(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: ValueKey('planner-slot-${slot.name}'),
        borderRadius: BorderRadius.circular(20),
        onTap:
            meal == null
                ? () => _openSlot(slot)
                : () => _showMealOptionsSheet(context, meal),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (meal == null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        context.appIsDark
                            ? theme.soft.withValues(alpha: 0.15)
                            : theme.soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(theme.icon, color: theme.accent, size: 22),
                )
              else
                PlannerMealImage(meal: meal, width: 60, height: 60, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meal == null) ...[
                      Text(
                        slot.labelKey.tr,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '+ ${'planner.add_meal'.tr}',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ] else ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: theme.soft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              theme.icon,
                              size: 12,
                              color: theme.accent,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            slot.labelKey.tr,
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        plannerMealName(meal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(meal.calories * meal.servings).round()} ${'planner.kcal'.tr}  •  ${(meal.proteinGrams * meal.servings).toStringAsFixed(0)}g ${'planner.protein'.tr}',
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _mealStatusBadge(context, meal.status),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (meal == null)
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showMealOptionsSheet(context, meal),
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: context.appMutedText,
                      iconSize: 22,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.appMutedText,
                      size: 20,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _error(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.appDangerSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            controller.recommendationsError.value.isNotEmpty
                ? controller.recommendationsError.value
                : controller.errorMessage.value,
            style: TextStyle(color: context.appOnDangerSurface, fontSize: 11),
          ),
        ),
        TextButton(
          onPressed: controller.refreshPlanner,
          child: Text('planner.retry'.tr),
        ),
      ],
    ),
  );

  Future<void> _openSlot(MealPlanSlot slot) async {
    if (controller.isLoadingRecommendations.value) {
      return;
    }
    if (controller.recommendationsError.value.isNotEmpty) {
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: controller.recommendationsError.value,
      );
      return;
    }
    Get.toNamed(AppRoutes.mealPlannerCategories, arguments: {'slot': slot});
  }

  Future<void> _showMealOptionsSheet(BuildContext context, PlannedMeal meal) =>
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        backgroundColor: context.appSurfaceLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        builder:
            (sheet) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheet).height * 0.85,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.appBorder,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        PlannerMealImage(
                          meal: meal,
                          width: 44,
                          height: 44,
                          radius: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            plannerMealName(meal),
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    if (meal.status != MealPlanStatus.eaten)
                      _sheetAction(
                        Icons.check_circle_outline_rounded,
                        'planner.mark_as_eaten'.tr,
                        () {
                          Get.back<void>();
                          controller.changeStatus(meal, MealPlanStatus.eaten);
                        },
                        context: context,
                      ),
                    if (meal.status != MealPlanStatus.skipped)
                      _sheetAction(
                        Icons.skip_next_outlined,
                        'planner.mark_as_skipped'.tr,
                        () {
                          Get.back<void>();
                          controller.changeStatus(meal, MealPlanStatus.skipped);
                        },
                        context: context,
                      ),
                    if (meal.status != MealPlanStatus.planned)
                      _sheetAction(
                        Icons.undo_rounded,
                        'planner.reset_to_planned'.tr,
                        () {
                          Get.back<void>();
                          controller.changeStatus(meal, MealPlanStatus.planned);
                        },
                        context: context,
                      ),
                    _sheetAction(
                      Icons.visibility_outlined,
                      'planner.view_details'.tr,
                      () {
                        Get.back<void>();
                        Get.toNamed(
                          AppRoutes.mealPlannerDetail,
                          arguments: {'meal': meal},
                        );
                      },
                      context: context,
                    ),
                    _sheetAction(
                      Icons.sync_rounded,
                      'planner.replace_meal'.tr,
                      () {
                        Get.back<void>();
                        Get.toNamed(
                          AppRoutes.mealPlannerMeals,
                          arguments: {'slot': meal.slot, 'replace': meal},
                        );
                      },
                      context: context,
                    ),
                    _sheetAction(
                      Icons.calendar_month_outlined,
                      'planner.move_meal'.tr,
                      () {
                        Get.back<void>();
                        _move(context, meal);
                      },
                      context: context,
                    ),
                    _sheetAction(
                      Icons.restaurant_menu_rounded,
                      'planner.change_serving'.tr,
                      () {
                        Get.back<void>();
                        _serving(context, meal);
                      },
                      context: context,
                    ),
                    _sheetAction(
                      Icons.delete_outline_rounded,
                      'planner.remove_meal'.tr,
                      () {
                        Get.back<void>();
                        _remove(context, meal);
                      },
                      danger: true,
                      context: context,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: Get.back<void>,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'planner.cancel'.tr,
                          style: TextStyle(
                            color: context.appText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

  Widget _mealStatusBadge(BuildContext context, MealPlanStatus status) {
    final (label, icon, color) = switch (status) {
      MealPlanStatus.eaten => (
        'planner.eaten'.tr,
        Icons.check_circle_rounded,
        AppColors.primaryGreen,
      ),
      MealPlanStatus.skipped => (
        'planner.skipped'.tr,
        Icons.skip_next_rounded,
        context.appMutedText,
      ),
      MealPlanStatus.planned => (
        'planner.planned'.tr,
        Icons.schedule_rounded,
        const Color(0xFFF59E0B),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetAction(
    IconData icon,
    String label,
    VoidCallback tap, {
    bool danger = false,
    required BuildContext context,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(
      icon,
      color: danger ? const Color(0xFFEF4444) : AppColors.primaryGreen,
      size: 22,
    ),
    title: Text(
      label,
      style: TextStyle(
        color: danger ? const Color(0xFFEF4444) : context.appText,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
    onTap: tap,
  );

  Future<void> _move(
    BuildContext context,
    PlannedMeal meal,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: context.appSurfaceLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder:
        (sheet) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'planner.move_title'.trParams({'meal': plannerMealName(meal)}),
                style: TextStyle(
                  color: context.appText,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.appBorder),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      controller.weekDays.indexed.map((entry) {
                        final index = entry.$1;
                        final day = entry.$2;
                        final occupied = controller
                            .mealsFor(day)
                            .any((m) => m.slot == meal.slot);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              leading: const Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.primaryGreen,
                                size: 21,
                              ),
                              title: Text(
                                DateFormat('EEEE, d MMM').format(day),
                                style: TextStyle(
                                  color: context.appText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing:
                                  occupied
                                      ? const Icon(
                                        Icons.swap_horiz_rounded,
                                        color: Colors.orange,
                                      )
                                      : Icon(
                                        Icons.chevron_right_rounded,
                                        color: context.appMutedText,
                                      ),
                              onTap: () async {
                                Navigator.pop(sheet);
                                final ok = await controller.moveMeal(meal, day);
                                if (!ok) {
                                  await AppAlert.actionError(
                                    title: 'planner.error'.tr,
                                    message: 'planner.save_error'.tr,
                                  );
                                }
                              },
                            ),
                            if (index < controller.weekDays.length - 1)
                              Divider(
                                height: 1,
                                indent: 58,
                                color: context.appBorder,
                              ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        ),
  );

  Future<void> _serving(BuildContext context, PlannedMeal meal) async {
    double value = meal.servings;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.appSurfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (sheet) => StatefulBuilder(
            builder:
                (_, setState) => Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: context.appBorder,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'planner.change_serving'.tr,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.appBorder),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed:
                                  value > .25
                                      ? () => setState(() => value -= .25)
                                      : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: context.appText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              value.toStringAsFixed(
                                value == value.roundToDouble() ? 0 : 2,
                              ),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: context.appText,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() => value += .25),
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(sheet),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                side: BorderSide(color: context.appBorder),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: Text('planner.cancel'.tr),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                controller.changeServing(meal, value);
                                Navigator.pop(sheet);
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppColors.primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: Text('planner.save'.tr),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Future<void> _remove(BuildContext context, PlannedMeal meal) async {
    final remove =
        await showGeneralDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'common.alert_dialog'.tr,
          barrierColor: Colors.black.withValues(alpha: 0.48),
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder:
              (dialog, animation, secondaryAnimation) => Material(
                type: MaterialType.transparency,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: const SizedBox.expand(),
                    ),
                    SafeArea(
                      minimum: const EdgeInsets.all(22),
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                29,
                                28,
                                28,
                              ),
                              decoration: BoxDecoration(
                                color: dialog.appElevatedSurface,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: dialog.appElevatedSurface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.16,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.errorCoral,
                                      size: 34,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'planner.remove_question'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: dialog.appText,
                                      fontSize: 20,
                                      height: 1.2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'planner.remove_help'.tr,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: dialog.appMutedText,
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 52,
                                          child: OutlinedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  dialog,
                                                  false,
                                                ),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color: dialog.appBorder,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(21),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            child: Text('planner.cancel'.tr),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 52,
                                          child: FilledButton(
                                            onPressed:
                                                () =>
                                                    Navigator.pop(dialog, true),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.errorCoral,
                                              foregroundColor: Colors.white,
                                              elevation: 5,
                                              shadowColor: AppColors.errorCoral
                                                  .withValues(alpha: 0.38),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(21),
                                              ),
                                              textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            child: Text('planner.remove'.tr),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        ) ??
        false;
    if (remove) await controller.removeMeal(meal.slot);
  }

  Future<void> _generate(BuildContext context) async {
    if (controller.groceryItems.isEmpty) {
      await AppAlert.actionError(
        title: 'planner.grocery_list'.tr,
        message: 'planner.empty_grocery_list'.tr,
      );
      return;
    }

    final start = controller.weekStart;
    final end = controller.weekDays.last;
    final range =
        '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';

    await showDialog<void>(
      context: context,
      builder:
          (dialog) => Dialog(
            backgroundColor: context.appElevatedSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: context.appMutedText,
                      onPressed: () => Navigator.pop(dialog),
                      style: IconButton.styleFrom(
                        backgroundColor: context.appBackground,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.appSoftGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_basket_rounded,
                          color: AppColors.primaryGreen,
                          size: 40,
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'planner.grocery_ready'.tr,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'planner.grocery_ready_help'.trParams({'range': range}),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        Get.toNamed(AppRoutes.mealPlannerGrocery);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      child: Text('planner.view_grocery_list'.tr),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      style: TextButton.styleFrom(
                        backgroundColor: context.appSoftGreen,
                        foregroundColor: AppColors.primaryGreen,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      child: Text('planner.keep_planning'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
