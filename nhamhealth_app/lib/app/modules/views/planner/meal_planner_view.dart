import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_nutrient_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/nham_app_bar.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../models/auth/authenticated_user_model.dart';
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

  int _activePlannerTab = 0;
  AuthenticatedUser? _authenticatedUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUser();
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

  Future<void> _loadUser() async {
    if (!Get.isRegistered<AuthService>()) return;
    final user = await Get.find<AuthService>().restoreSession();
    if (mounted) setState(() => _authenticatedUser = user);
  }

  void _selectBottomMenu(int index) {
    if (index == 2) return;
    final route = switch (index) {
      0 => AppRoutes.home,
      1 => AppRoutes.meals,
      3 => AppRoutes.community,
      _ => null,
    };
    if (route != null) Get.offNamed<void>(route);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    extendBody: true,
    body: AppBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontalFor(context),
                AppSpacing.pageTop,
                AppSpacing.pageHorizontalFor(context),
                0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxWideContentWidth,
                ),
                child: NhamAppBar(
                  user: _authenticatedUser,
                  unreadNotificationCount: 0,
                  onNotifications:
                      () => Get.toNamed<void>(AppRoutes.notifications),
                  onProfile:
                      () => Get.toNamed<void>(
                        AppRoutes.profile,
                        arguments: _authenticatedUser,
                      ),
                ),
              ),
            ),
            Expanded(
              child: Obx(
                () => RefreshIndicator(
                  onRefresh: _refreshUnifiedPlanner,
                  color: AppColors.primaryGreen,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalFor(context),
                      14,
                      AppSpacing.pageHorizontalFor(context),
                      AppSpacing.pagePaddingWithNavigationFor(context).bottom,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSpacing.maxContentWidth,
                          ),
                          child: LoadingContentTransition(
                            isLoading: !controller.hasLoadedOnce.value,
                            loading: const PageSkeleton.mealPlanner(),
                            content: IgnorePointer(
                              ignoring: controller.isAutoFilling.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _dateCard(context),
                                  if (controller
                                          .errorMessage
                                          .value
                                          .isNotEmpty ||
                                      controller
                                          .recommendationsError
                                          .value
                                          .isNotEmpty)
                                    _error(context),
                                  const SizedBox(height: 16),
                                  _tabSelector(context),
                                  const SizedBox(height: 6),
                                  if (_activePlannerTab == 0) ...[
                                    _dailyOverview(context),
                                    const SizedBox(height: 16),
                                    _aiAutoFillBanner(context),
                                    _sectionHeading(context),
                                    const SizedBox(height: 12),
                                    LoadingContentTransition(
                                      isLoading:
                                          controller.isAutoFilling.value ||
                                          controller.isLoadingDay.value,
                                      loading:
                                          controller.isAutoFilling.value
                                              ? _autoFillLoadingView(context)
                                              : const PageSkeleton.plannerSlots(),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children:
                                            MealPlanSlot.values
                                                .map(
                                                  (slot) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 12,
                                                        ),
                                                    child: _slotCard(
                                                      context,
                                                      slot,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _groceryListButton(context),
                                  ] else ...[
                                    _forecastAndWeekTab(context),
                                  ],
                                ],
                              ),
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
      minimum: AppSpacing.navigationMargin,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxNavigationWidth,
          ),
          child: AppBottomNavigation(
            selectedIndex: 2,
            onSelect: _selectBottomMenu,
          ),
        ),
      ),
    ),
  );

  Widget _groceryListButton(BuildContext context) => Obx(
    () => PlannerPrimaryButton(
      label: 'planner.generate_grocery_list'.tr,
      icon: Icons.shopping_bag_outlined,
      trailingIcon: Icons.arrow_forward_rounded,
      onPressed:
          controller.isAutoFilling.value ? null : () => _generate(context),
    ),
  );

  Widget _autoFillLoadingView(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      key: const ValueKey('planner-autofill-skeleton'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.appSoftGreen,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryGreen,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'planner.autofill_loading_title'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                controller.autoFillStatusKey.value.tr,
                style: TextStyle(color: context.appMutedText, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  minHeight: 5,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const PageSkeleton.plannerSlots(),
      ],
    ),
  );

  Future<void> _confirmAutoFill(BuildContext context) =>
      showAutoFillConfirmDialog(context, controller);

  Future<void> _refreshUnifiedPlanner() async {
    final futures = <Future<void>>[controller.refreshPlanner(force: true)];
    if (Get.isRegistered<WeightLossProjectionController>()) {
      futures.add(
        Get.find<WeightLossProjectionController>().loadForecast(
          forceRefresh: true,
        ),
      );
    }
    await Future.wait(futures);
  }

  Widget _dateCard(BuildContext context) {
    final start = controller.weekStart;
    final end = controller.weekDays.last;

    return Container(
      key: const ValueKey('planner-week-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
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
                child: TextButton(
                  key: const ValueKey('planner-week-picker-button'),
                  onPressed: () => _pickWeekDate(context),
                  style: TextButton.styleFrom(
                    foregroundColor: context.appText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'planner.selected_week'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: context.appMutedText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _weekArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => controller.changeWeek(1),
                context: context,
              ),
              const SizedBox(width: 6),
              InkWell(
                key: const ValueKey('planner-week-today-button'),
                onTap: () => controller.goToToday(),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
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
        ],
      ),
    );
  }

  Future<void> _pickWeekDate(BuildContext context) async {
    DateTime selectedStart = controller.planStartDate;
    int selectedDays = controller.planDaysCount.value.clamp(3, 7);

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
                      'planner.selected_week'.tr,
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
                    Row(
                      children: List.generate(5, (index) {
                        final days = index + 3;
                        final selected = days == selectedDays;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index == 4 ? 0 : 6),
                            child: OutlinedButton(
                              onPressed:
                                  () =>
                                      setSheetState(() => selectedDays = days),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 0,
                                ),
                                backgroundColor:
                                    selected
                                        ? AppColors.primaryGreen
                                        : context.appElevatedSurface,
                                foregroundColor:
                                    selected ? Colors.white : context.appText,
                                side: BorderSide(
                                  color:
                                      selected
                                          ? AppColors.primaryGreen
                                          : context.appBorder,
                                ),
                              ),
                              child: FittedBox(
                                child: Text(
                                  '$days ${'planner.days_short'.tr.trim()}',
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
                        );
                        if (picked != null) {
                          setSheetState(() => selectedStart = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: context.appElevatedSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.appBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy',
                                ).format(selectedStart),
                                style: TextStyle(
                                  color: context.appText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.edit_calendar_rounded,
                              color: context.appMutedText,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PlannerWeekDateStrip(
                      selectedDate: selectedStart,
                      onDateSelected:
                          (date) => setSheetState(() => selectedStart = date),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${DateFormat('d MMM').format(selectedStart)} – ${DateFormat('d MMM yyyy').format(previewEnd)} ($selectedDays ${'planner.days_short'.tr.trim()})',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        controller.setCustomPlanRange(
                          start: selectedStart,
                          days: selectedDays,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('planner.apply'.tr),
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : context.appBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appBorder.withValues(alpha: 0.6)),
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
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : context.appText,
                fontSize: 17,
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

  Widget _tabSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appBorder.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabPill(
              context: context,
              index: 0,
              icon: Icons.calendar_today_rounded,
              label: _plannerLabel('planner.tab_today', "Today's Plan"),
              isSelected: _activePlannerTab == 0,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tabPill(
              context: context,
              index: 1,
              icon: Icons.auto_graph_rounded,
              label: _plannerLabel('planner.tab_forecast', 'Forecast & Week'),
              isSelected: _activePlannerTab == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabPill({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_activePlannerTab != index) {
            setState(() => _activePlannerTab = index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? (context.appIsDark
                        ? const Color(0xFF1E293B)
                        : Colors.white)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color:
                    isSelected ? AppColors.primaryGreen : context.appMutedText,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? context.appText : context.appMutedText,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiAutoFillBanner(BuildContext context) {
    final hasEmptySlots = MealPlanSlot.values.any(
      (s) => controller.mealFor(s) == null,
    );
    if (!hasEmptySlots) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _goalAutoFillCard(
        context,
        accentColor: const Color(0xFF0F62FE),
        icon: Icons.directions_run_rounded,
        title: 'planner.autofill_title_loss'.tr,
        description: 'planner.autofill_desc_loss'.tr,
        buttonLabel: 'planner.autofill_btn_loss'.tr,
      ),
    );
  }

  Widget _goalAutoFillCard(
    BuildContext context, {
    required Color accentColor,
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
  }) {
    final isAnalyzed = controller.hasAnalyzedWeightLoss.value;

    return GestureDetector(
      onTap: () => _confirmAutoFill(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.12),
              accentColor.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                const Spacer(),
                if (isAnalyzed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.appBorder.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Text(
                      '✓ ${'planner.analyzed_badge'.tr}',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13, color: accentColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appMutedText,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: FilledButton(
                onPressed: () => _confirmAutoFill(context),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 11, color: accentColor),
                const SizedBox(width: 3),
                Text(
                  'planner.current_goal'.tr,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _forecastAndWeekTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.appSurfaceLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorder.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.weekly_progress'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'planner.meals_planned'.trParams({
                        'count': '${controller.selectedMeals.length}',
                        'total': '4',
                      }),
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.mealPlannerWeek),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text('planner.view_week'.tr),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(
                    color: context.appBorder.withValues(alpha: 0.8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _analysisPageCards(context),
      ],
    );
  }

  Widget _analysisPageCards(BuildContext context) {
    return Obx(() {
      final hasAnalysis = controller.hasAnalyzedWeightLoss.value;

      return Container(
        key: const ValueKey('planner-analysis-pages'),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
          boxShadow: context.appTileShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.primaryGreen,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'planner.analysis_center'.tr,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasAnalysis
                            ? 'planner.analysis_center_ready_desc'.tr
                            : 'planner.analysis_center_preview_desc'.tr,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _analysisPageCard(context, analyzed: hasAnalysis),
          ],
        ),
      );
    });
  }

  Widget _analysisPageCard(BuildContext context, {required bool analyzed}) {
    final accent =
        context.appIsDark ? const Color(0xFF72DDA7) : AppColors.darkGreen;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('open-weight-loss-analysis'),
        onTap: () => Get.toNamed(AppRoutes.mealPlannerWeightLossAnalysis),
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.trending_down_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.view_weight_loss_analysis'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      analyzed
                          ? 'planner.analysis_ready'.tr
                          : 'planner.analysis_preview'.tr,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dailyOverview(BuildContext context) {
    final progress = controller.adherenceProgress.clamp(0.0, 1.0);
    final hasMeals = controller.selectedMeals.isNotEmpty;

    return Container(
      key: const ValueKey('planner-daily-overview'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: context.appSoftGreen,
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.daily_overview'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 17,
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
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
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
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  LinearProgressIndicator(
                    key: const ValueKey('planner-daily-progress'),
                    value: progress,
                    minHeight: 12,
                    backgroundColor: context.appSoftGreen,
                    color: AppColors.primaryGreen,
                  ),
                  Positioned.fill(
                    child: Row(
                      children: List.generate(
                        controller.dailyMealGoal,
                        (index) => Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child:
                                index == controller.dailyMealGoal - 1
                                    ? const SizedBox.shrink()
                                    : Container(
                                      width: 1.5,
                                      color: context.appElevatedSurface,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
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
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
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
    final plannedCount =
        MealPlanSlot.values
            .where((slot) => controller.mealFor(slot) != null)
            .length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            size: 19,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'planner.meals_for_date'.trParams({
                  'date': DateFormat(
                    'EEE, d MMM',
                  ).format(controller.selectedDate),
                }),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'planner.tap_slot_to_choose'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'planner.planned_count_short'.trParams({
                  'count': '$plannedCount',
                }),
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (plannedCount > 0) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                tooltip: 'planner.day_options'.tr,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: context.appMutedText,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 220),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: context.appElevatedSurface,
                onSelected: (value) async {
                  if (value == 'reset_day') {
                    await controller.resetAllMealsToPlanned(
                      currentDayOnly: true,
                    );
                  } else if (value == 'reset_week') {
                    await controller.resetAllMealsToPlanned(
                      currentDayOnly: false,
                    );
                  } else if (value == 'clear_day') {
                    final confirmed = await _confirmClearDialog(
                      context,
                      title: 'planner.confirm_clear_day_title'.tr,
                      desc: 'planner.confirm_clear_day_desc'.tr,
                    );
                    if (confirmed == true) {
                      await controller.clearAllMeals(currentDayOnly: true);
                    }
                  } else if (value == 'clear_week') {
                    final confirmed = await _confirmClearDialog(
                      context,
                      title: 'planner.confirm_clear_week_title'.tr,
                      desc: 'planner.confirm_clear_week_desc'.tr,
                    );
                    if (confirmed == true) {
                      await controller.clearAllMeals(currentDayOnly: false);
                    }
                  }
                },
                itemBuilder:
                    (ctx) => [
                      if (controller.selectedMeals.any(
                        (m) => m.status != MealPlanStatus.planned,
                      ))
                        PopupMenuItem(
                          value: 'reset_day',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.restart_alt_rounded,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'planner.reset_day_to_planned'.tr,
                                  style: TextStyle(
                                    color: ctx.appText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (controller.weekDays.any(
                        (d) => controller
                            .mealsFor(d)
                            .any((m) => m.status != MealPlanStatus.planned),
                      ))
                        PopupMenuItem(
                          value: 'reset_week',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.restore_rounded,
                                size: 18,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'planner.reset_week_to_planned'.tr,
                                  style: TextStyle(
                                    color: ctx.appText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'clear_day',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_sweep_outlined,
                              size: 18,
                              color: AppColors.errorCoral,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'planner.clear_all_day_meals'.tr,
                                style: const TextStyle(
                                  color: AppColors.errorCoral,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_week',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_forever_outlined,
                              size: 18,
                              color: AppColors.errorCoral,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'planner.clear_all_week_meals'.tr,
                                style: const TextStyle(
                                  color: AppColors.errorCoral,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _slotCard(BuildContext context, MealPlanSlot slot) {
    final meal = controller.mealFor(slot);
    final theme = PlannerSlotTheme.of(slot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: ValueKey('planner-meal-card-${slot.name}'),
          constraints: const BoxConstraints(minHeight: 128),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('planner-slot-${slot.name}'),
              borderRadius: BorderRadius.circular(20),
              onTap:
                  meal == null
                      ? () => _openSlot(slot)
                      : () => _showMealOptionsSheet(context, meal),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
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
                      PlannerMealImage(
                        meal: meal,
                        width: 68,
                        height: 68,
                        radius: 16,
                      ),
                    const SizedBox(width: 12),
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
                                const SizedBox(width: 6),
                                _mealStatusBadge(context, meal.status),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              plannerMealName(meal),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 14.75,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department_outlined,
                                  size: 13,
                                  color: context.appMutedText,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '${(meal.calories * meal.servings).round()} ${'planner.kcal'.tr}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.appMutedText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 3,
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.appMutedText.withValues(
                                      alpha: 0.55,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 13,
                                  color: context.appMutedText,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    '${(meal.proteinGrams * meal.servings).toStringAsFixed(0)}g ${'planner.protein'.tr}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.appMutedText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip:
                                meal.status == MealPlanStatus.eaten
                                    ? 'planner.eaten'.tr
                                    : 'planner.mark_as_eaten'.tr,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 40),
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  meal.status == MealPlanStatus.eaten
                                      ? AppColors.primaryGreen.withValues(
                                        alpha: 0.11,
                                      )
                                      : context.appSurfaceLow,
                            ),
                            onPressed: () {
                              if (meal.status != MealPlanStatus.eaten) {
                                controller.changeStatus(
                                  meal,
                                  MealPlanStatus.eaten,
                                );
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
                                      : context.appMutedText.withValues(
                                        alpha: 0.8,
                                      ),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          IconButton(
                            style: IconButton.styleFrom(
                              minimumSize: const Size(40, 36),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed:
                                () => _showMealOptionsSheet(context, meal),
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
          ),
        ),
      ],
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

  Future<void> _showMealOptionsSheet(
    BuildContext context,
    PlannedMeal meal,
  ) => showModalBottomSheet<void>(
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
                  sheetAction(
                    Icons.check_circle_outline_rounded,
                    'planner.mark_as_eaten'.tr,
                    () {
                      Get.back<void>();
                      controller.changeStatus(meal, MealPlanStatus.eaten);
                    },
                    context: context,
                  ),
                if (meal.status != MealPlanStatus.skipped)
                  sheetAction(
                    Icons.skip_next_outlined,
                    'planner.mark_as_skipped'.tr,
                    () {
                      Get.back<void>();
                      controller.changeStatus(meal, MealPlanStatus.skipped);
                    },
                    context: context,
                  ),
                if (meal.status != MealPlanStatus.planned)
                  sheetAction(
                    Icons.undo_rounded,
                    'planner.reset_to_planned'.tr,
                    () {
                      Get.back<void>();
                      controller.changeStatus(meal, MealPlanStatus.planned);
                    },
                    context: context,
                  ),
                if (controller.selectedMeals.any(
                  (m) => m.status != MealPlanStatus.planned,
                ))
                  sheetAction(
                    Icons.restart_alt_rounded,
                    'planner.reset_all_to_planned'.tr,
                    () {
                      Get.back<void>();
                      controller.resetAllMealsToPlanned(currentDayOnly: true);
                    },
                    context: context,
                  ),
                sheetAction(
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
                sheetAction(Icons.sync_rounded, 'planner.replace_meal'.tr, () {
                  Get.back<void>();
                  Get.toNamed(
                    AppRoutes.mealPlannerMeals,
                    arguments: {'slot': meal.slot, 'replace': meal},
                  );
                }, context: context),
                sheetAction(
                  Icons.calendar_month_outlined,
                  'planner.move_meal'.tr,
                  () {
                    Get.back<void>();
                    move(context, meal);
                  },
                  context: context,
                ),
                sheetAction(
                  Icons.restaurant_menu_rounded,
                  'planner.change_serving'.tr,
                  () {
                    Get.back<void>();
                    serving(context, meal);
                  },
                  context: context,
                ),
                sheetAction(
                  Icons.delete_outline_rounded,
                  'planner.remove_meal'.tr,
                  () {
                    Get.back<void>();
                    remove0(context, meal);
                  },
                  danger: true,
                  context: context,
                ),
                if (controller.selectedMeals.length > 1)
                  sheetAction(
                    Icons.delete_sweep_outlined,
                    'planner.clear_all_day_meals'.tr,
                    () async {
                      Get.back<void>();
                      final confirmed = await _confirmClearDialog(
                        context,
                        title: 'planner.confirm_clear_day_title'.tr,
                        desc: 'planner.confirm_clear_day_desc'.tr,
                      );
                      if (confirmed == true) {
                        await controller.clearAllMeals(currentDayOnly: true);
                      }
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

  Widget sheetAction(
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

  Future<void> move(
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

  Future<void> serving(BuildContext context, PlannedMeal meal) async {
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

  Future<void> remove0(BuildContext context, PlannedMeal meal) async {
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

  Future<bool?> _confirmClearDialog(
    BuildContext context, {
    required String title,
    required String desc,
  }) async {
    return showGeneralDialog<bool>(
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
                          padding: const EdgeInsets.fromLTRB(28, 29, 28, 28),
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
                                  Icons.delete_sweep_rounded,
                                  color: AppColors.errorCoral,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                title,
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
                                desc,
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
                                            () => Navigator.pop(dialog, false),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: dialog.appBorder,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              21,
                                            ),
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
                                            () => Navigator.pop(dialog, true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.errorCoral,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              21,
                                            ),
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
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
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
