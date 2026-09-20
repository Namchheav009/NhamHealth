import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_nutrient_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../models/planner/meal_plan.dart';
import 'planner_shared.dart';

String _plannerLabel(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}

class MealPlannerView extends StatefulWidget {
  const MealPlannerView({super.key});

  @override
  State<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<MealPlannerView>
    with WidgetsBindingObserver {
  MealPlannerController get controller => Get.find<MealPlannerController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !controller.hasLoadedOnce.value) {
        controller.syncToToday();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      controller.syncToToday(forceRefresh: true);
    }
  }

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
                  onRefresh: () => controller.refreshPlanner(force: true),
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
                          child: LoadingContentTransition(
                            isLoading:
                                !controller.hasLoadedOnce.value ||
                                controller.isLoading.value,
                            loading: const PageSkeleton.mealPlanner(),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _dateCard(context),
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
                                LoadingContentTransition(
                                  isLoading: controller.isLoadingDay.value,
                                  loading: const PageSkeleton.plannerSlots(),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children:
                                        MealPlanSlot.values
                                            .map(
                                              (slot) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: _slotCard(context, slot),
                                              ),
                                            )
                                            .toList(),
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
            tooltip: 'planner.auto_fill'.tr,
            onPressed: () => _confirmAutoFill(context),
            icon: const Icon(Icons.auto_awesome_rounded),
            color: AppColors.primaryGreen,
            iconSize: 22,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 2),
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

  Future<void> _confirmAutoFill(BuildContext context) =>
      showAutoFillConfirmDialog(context, controller);

  Widget _dateCard(BuildContext context) {
    final start = controller.weekStart;
    final end = controller.weekDays.last;

    return Container(
      padding: const EdgeInsets.all(16),
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
                child: InkWell(
                  key: const ValueKey('planner-week-picker-button'),
                  onTap: () => _pickWeekDate(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'planner.selected_week'.tr,
                                style: TextStyle(
                                  color: context.appMutedText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 13,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => controller.goToToday(),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'planner.today'.tr,
                                    style: const TextStyle(
                                      color: AppColors.primaryGreen,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.appText,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 20,
                                color: context.appMutedText,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _weekArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => controller.changeWeek(1),
                context: context,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: context.appMutedText,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'planner.duration'.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          [3, 4, 5, 6, 7].map((days) {
                            final isSelected =
                                controller.planDaysCount.value == days;
                            return Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: InkWell(
                                key: ValueKey('planner-duration-$days'),
                                onTap: () => controller.setPlanDaysCount(days),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  constraints: const BoxConstraints(
                                    minWidth: 34,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4.5,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.primaryGreen
                                            : context.appBackground,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColors.primaryGreen
                                              : context.appBorder.withValues(
                                                alpha: 0.65,
                                              ),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    '$days${'planner.days_short'.tr}',
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : context.appText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 74,
            child:
                controller.planDays.length <= 5
                    ? Row(
                      children: List.generate(controller.planDays.length, (
                        index,
                      ) {
                        final date = controller.planDays[index];
                        final isSelected =
                            index == controller.selectedDayIndex.value;
                        final hasMeals = controller.mealsFor(date).isNotEmpty;
                        final gap =
                            controller.planDays.length <= 3 ? 12.0 : 8.0;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right:
                                  index == controller.planDays.length - 1
                                      ? 0
                                      : gap,
                            ),
                            child: _dayPill(
                              context: context,
                              index: index,
                              date: date,
                              dayName: _days[date.weekday - 1].tr,
                              isSelected: isSelected,
                              hasMeals: hasMeals,
                              onTap: () => controller.selectDay(index),
                            ),
                          ),
                        );
                      }),
                    )
                    : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(controller.planDays.length, (
                          index,
                        ) {
                          final date = controller.planDays[index];
                          final isSelected =
                              index == controller.selectedDayIndex.value;
                          final hasMeals = controller.mealsFor(date).isNotEmpty;
                          return SizedBox(
                            width: 66,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right:
                                    index == controller.planDays.length - 1
                                        ? 0
                                        : 8,
                              ),
                              child: _dayPill(
                                context: context,
                                index: index,
                                date: date,
                                dayName: _days[date.weekday - 1].tr,
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

  Future<void> _pickWeekDate(BuildContext context) async {
    DateTime selectedStart = controller.planStartDate;
    int selectedDays = controller.planDaysCount.value;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.appSurfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              final previewEnd = selectedStart.add(
                Duration(days: selectedDays - 1),
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.appBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'planner.custom_plan'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'planner.choose_duration'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'planner.duration'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          [3, 4, 5, 6, 7].map((days) {
                            final isSel = selectedDays == days;
                            return InkWell(
                              key: ValueKey('modal-duration-$days'),
                              onTap:
                                  () =>
                                      setSheetState(() => selectedDays = days),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSel
                                          ? AppColors.primaryGreen
                                          : context.appElevatedSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSel
                                            ? AppColors.primaryGreen
                                            : context.appBorder.withValues(
                                              alpha: 0.8,
                                            ),
                                  ),
                                ),
                                child: Text(
                                  '$days${'planner.days_short'.tr}',
                                  style: TextStyle(
                                    color:
                                        isSel ? Colors.white : context.appText,
                                    fontSize: 13,
                                    fontWeight:
                                        isSel
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'planner.start_date'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: selectedStart,
                          firstDate: DateTime(now.year - 2),
                          lastDate: DateTime(now.year + 2, 12, 31),
                          helpText: 'planner.select_date'.tr,
                          cancelText: 'planner.cancel'.tr,
                          confirmText: 'planner.select'.tr,
                          builder: (pickerContext, child) {
                            final isDark =
                                Theme.of(pickerContext).brightness ==
                                Brightness.dark;
                            return Theme(
                              data: Theme.of(pickerContext).copyWith(
                                colorScheme: ColorScheme.fromSeed(
                                  seedColor: AppColors.primaryGreen,
                                  primary: AppColors.primaryGreen,
                                  onPrimary: Colors.white,
                                  surface: pickerContext.appElevatedSurface,
                                  onSurface: pickerContext.appText,
                                  brightness:
                                      isDark
                                          ? Brightness.dark
                                          : Brightness.light,
                                ),
                              ),
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() => selectedStart = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.appElevatedSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: context.appBorder.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy',
                                ).format(selectedStart),
                                style: TextStyle(
                                  color: context.appText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              size: 18,
                              color: context.appMutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${DateFormat('d MMM').format(selectedStart)} – ${DateFormat('d MMM yyyy').format(previewEnd)} ($selectedDays ${'planner.days_short'.tr.trim()})',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PlannerPrimaryButton(
                      label: 'planner.apply'.tr,
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        controller.setCustomPlanRange(
                          start: selectedStart,
                          days: selectedDays,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        controller.setCustomPlanRange(
                          start: selectedStart,
                          days: selectedDays,
                        );
                        controller.autoFillPlan();
                      },
                      icon: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      label: Text(
                        'planner.auto_fill_plan'.tr,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: AppColors.primaryGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.appBackground,
        shape: BoxShape.circle,
        border: Border.all(color: context.appBorder.withValues(alpha: 0.55)),
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 74,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : context.appBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primaryGreen
                    : context.appBorder.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.28),
                      blurRadius: 10,
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
                color: isSelected ? Colors.white : context.appMutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : context.appText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 4.5,
              height: 4.5,
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
              CircleAvatar(
                radius: 18,
                backgroundColor: context.appSoftGreen,
                child: const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF43C756),
                  size: 21,
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
                width: 56,
                height: 56,
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
                            height: 1.1,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              _plannerLabel('planner.adherence', 'adherence'),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
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
                icon: AppNutrientTheme.caloriesIcon,
                iconColor: AppNutrientTheme.caloriesColor,
                value: '${controller.selectedCalories}',
                label: 'planner.kcal'.tr,
              ),
              _macroDivider(context),
              _macroCard(
                context,
                icon: AppNutrientTheme.proteinIcon,
                iconColor: AppNutrientTheme.proteinColor,
                value: '${controller.selectedProtein.toStringAsFixed(0)}g',
                label: 'planner.protein'.tr,
              ),
              _macroDivider(context),
              _macroCard(
                context,
                icon: AppNutrientTheme.carbsIcon,
                iconColor: AppNutrientTheme.carbsColor,
                value: '${controller.selectedCarbs.toStringAsFixed(0)}g',
                label: 'planner.carbs'.tr,
              ),
              _macroDivider(context),
              _macroCard(
                context,
                icon: AppNutrientTheme.fatIcon,
                iconColor: AppNutrientTheme.fatColor,
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
              height: 1.3,
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
            height: 1.3,
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
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

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
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '+ ${'planner.add_meal'.tr}',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
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
                          Flexible(
                            child: Text(
                              slot.labelKey.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appMutedText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
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
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(meal.calories * meal.servings).round()} ${'planner.kcal'.tr}  •  ${(meal.proteinGrams * meal.servings).toStringAsFixed(0)}g ${'planner.protein'.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
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
                      tooltip:
                          meal.status == MealPlanStatus.eaten
                              ? 'planner.eaten'.tr
                              : 'planner.mark_as_eaten'.tr,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (meal.status != MealPlanStatus.eaten) {
                          controller.changeStatus(meal, MealPlanStatus.eaten);
                        } else {
                          _showMealOptionsSheet(context, meal);
                        }
                      },
                      icon: Icon(
                        meal.status == MealPlanStatus.eaten
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color:
                            meal.status == MealPlanStatus.eaten
                                ? AppColors.primaryGreen
                                : context.appMutedText.withValues(alpha: 0.8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showMealOptionsSheet(context, meal),
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: context.appMutedText,
                      iconSize: 22,
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
    if (controller.recommendationsError.value.isNotEmpty &&
        controller.adminRecommendations.isEmpty) {
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: controller.recommendationsError.value,
      );
      return;
    }
    Get.toNamed(AppRoutes.mealPlannerMeals, arguments: {'slot': slot});
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
                          arguments: {
                            'meal': meal,
                            'isAlreadyPlanned': true,
                            'slot': meal.slot,
                          },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
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
        fontSize: 14.5,
        height: 1.35,
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

    Get.toNamed(AppRoutes.mealPlannerGrocery);
  }
}
