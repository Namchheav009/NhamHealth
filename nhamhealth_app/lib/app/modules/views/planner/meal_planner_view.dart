import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/current_user_service.dart';
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
import '../../../widgets/scroll_aware_scaffold.dart';
import '../../controllers/meals/food_detail_controller.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../models/meals/meal_model.dart';
import '../../models/planner/ai_meal_recommendation_model.dart';
import '../../models/planner/meal_plan.dart';
import '../../models/planner/weight_loss_forecast_model.dart';
import '../../providers/planner/meal_planner_provider.dart';
import 'planner_shared.dart';

String _plannerLabel(String key, String fallback) {
  final translated = key.tr;
  return translated == key ? fallback : translated;
}

Future<MealModel> _plannerMealAsFoodDetail(PlannedMeal meal) async {
  final provider = Get.find<MealPlannerProvider>();
  final ingredientImages = await Future.wait(
    meal.ingredientDetails.map(
      (ingredient) => provider.lookupIngredientImageUrl(ingredient.name),
    ),
  );
  return MealModel(
    id: meal.id,
    name: meal.name,
    calories: meal.calories,
    image: meal.imageUrl,
    category:
        meal.category.isEmpty ? 'planner.uncategorized'.tr : meal.category,
    categoryId: meal.categoryId ?? 0,
    proteinGrams: meal.proteinGrams,
    description: meal.description,
    cookingTimeMinutes: meal.cookingTimeMinutes,
    totalTimeMinutes: meal.cookingTimeMinutes,
    difficulty: meal.difficulty,
    servings: meal.servings.round(),
    recommendationReason: meal.recommendationNote,
    ingredients: List.generate(meal.ingredientDetails.length, (index) {
      final ingredient = meal.ingredientDetails[index];
      return MealIngredientModel(
        name: ingredient.name,
        description: '',
        image: ingredientImages[index] ?? '',
        quantity: ingredient.quantity,
        unit: ingredient.unit,
      );
    }, growable: false),
    nutrition: [
      MealNutritionModel(
        name: 'common.protein'.tr,
        amount: meal.proteinGrams,
        unit: 'g',
      ),
      MealNutritionModel(
        name: 'planner.carbs'.tr,
        amount: meal.carbsGrams,
        unit: 'g',
      ),
      MealNutritionModel(
        name: 'common.fat'.tr,
        amount: meal.fatGrams,
        unit: 'g',
      ),
    ],
    steps: meal.instructions.indexed
        .map(
          (entry) => MealStepModel(number: entry.$1 + 1, instruction: entry.$2),
        )
        .toList(growable: false),
    tags: meal.tags.indexed
        .map((entry) => MealLabelModel(id: entry.$1, name: entry.$2))
        .toList(growable: false),
  );
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
  Worker? _currentUserWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUser();
    _bindCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !controller.hasLoadedOnce.value) {
        controller.syncToToday();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _currentUserWorker?.dispose();
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
    if (Get.isRegistered<CurrentUserService>()) {
      Get.find<CurrentUserService>().setUser(user);
    }
    if (mounted) setState(() => _authenticatedUser = user);
  }

  void _bindCurrentUser() {
    if (!Get.isRegistered<CurrentUserService>()) return;
    final currentUser = Get.find<CurrentUserService>();
    _authenticatedUser = currentUser.user.value ?? _authenticatedUser;
    _currentUserWorker = ever<AuthenticatedUser?>(currentUser.user, (user) {
      if (mounted) setState(() => _authenticatedUser = user);
    });
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
  Widget build(BuildContext context) => ScrollAwareScaffold(
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
                child: Obx(
                  () => NhamAppBar(
                    user: _authenticatedUser,
                    unreadNotificationCount:
                        controller.unreadNotificationCount.value,
                    onNotifications: controller.openNotifications,
                    onProfile:
                        () => Get.toNamed<void>(
                          AppRoutes.profile,
                          arguments: _authenticatedUser,
                        ),
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
                    primary: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalFor(context),
                      18,
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
                            isLoading:
                                controller.isLoading.value &&
                                !controller.hasLoadedOnce.value,
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
                                  const SizedBox(height: 10),
                                  _tabSelector(context),
                                  const SizedBox(height: 12),
                                  if (_activePlannerTab == 0) ...[
                                    _goalStatusRow(context),
                                    const SizedBox(height: 12),
                                    _dailyOverview(context),
                                    const SizedBox(height: 12),
                                    _mealTimelineCard(context),
                                    const SizedBox(height: 12),
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
      icon: Icons.shopping_cart_outlined,
      trailingIcon: Icons.chevron_right_rounded,
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
    final futures = <Future<void>>[
      controller.refreshPlanner(force: true),
      controller.loadUnreadNotificationCount(),
    ];
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
    final selectedDate = controller.selectedDate;

    return Container(
      key: const ValueKey('planner-week-card'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          _weekArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap:
                () => controller.goToDate(
                  selectedDate.subtract(const Duration(days: 1)),
                ),
            context: context,
          ),
          Expanded(
            child: TextButton(
              key: const ValueKey('planner-week-picker-button'),
              onPressed: () => _pickWeekDate(context),
              style: TextButton.styleFrom(
                foregroundColor: context.appText,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 2),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, d MMM yyyy').format(selectedDate),
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: context.appMutedText,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _weekArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap:
                () => controller.goToDate(
                  selectedDate.add(const Duration(days: 1)),
                ),
            context: context,
          ),
          const SizedBox(width: 6),
          InkWell(
            key: const ValueKey('planner-week-today-button'),
            onTap: controller.goToToday,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                'planner.today'.tr,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Center(child: Icon(icon, size: 19, color: context.appMutedText)),
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
      padding: const EdgeInsets.all(3),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
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
                color: isSelected ? Colors.white : context.appMutedText,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.appMutedText,
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
        accentColor: AppColors.primaryGreen,
        icon: Icons.restaurant_menu_rounded,
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
          color:
              context.appIsDark
                  ? context.appSurfaceLow
                  : accentColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.28)),
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
    final projection =
        Get.isRegistered<WeightLossProjectionController>()
            ? Get.find<WeightLossProjectionController>()
            : null;
    if (projection == null) return _forecastDashboard(context, null);
    return Obx(() => _forecastDashboard(context, projection.forecast.value));
  }

  Widget _forecastDashboard(
    BuildContext context,
    WeightLossForecast? forecast,
  ) {
    final planned = controller.weeklyMealCount;
    final total = controller.planDaysCount.value * controller.dailyMealGoal;
    final progress =
        total == 0 ? 0.0 : (planned / total).clamp(0.0, 1.0).toDouble();
    final days = forecast?.timeframeDays ?? 7;
    final goal = controller.healthGoal.value;
    final goalLabel = switch (goal) {
      MealPlannerHealthGoal.gainWeight => 'planner.goal_gain_weight'.tr,
      MealPlannerHealthGoal.maintainHealth => 'planner.goal_maintain_health'.tr,
      MealPlannerHealthGoal.loseWeight => 'planner.goal_lose_weight'.tr,
    };
    final goalIcon = switch (goal) {
      MealPlannerHealthGoal.gainWeight => Icons.trending_up_rounded,
      MealPlannerHealthGoal.maintainHealth => Icons.trending_flat_rounded,
      MealPlannerHealthGoal.loseWeight => Icons.trending_down_rounded,
    };
    final weightChange =
        forecast == null
            ? 0.0
            : forecast.projectedEndWeightKg - forecast.currentWeightKg;
    final projectedChange =
        weightChange.abs() < 0.05
            ? '0.0'
            : '${weightChange > 0 ? '+' : '−'}${weightChange.abs().toStringAsFixed(1)}';
    final calorieGap = forecast?.dailyDeficitCalories.abs().round() ?? 0;
    final pace = forecast?.paceDescription.trim();
    final paceLabel =
        pace?.isNotEmpty == true
            ? pace!
            : _plannerLabel('planner.steady_healthy', 'Steady & healthy');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('planner-weekly-progress-card'),
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        color: AppColors.primaryGreen,
                        backgroundColor: context.appSoftGreen,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$planned/$total',
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _plannerLabel('planner.meals_short', 'meals'),
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plannerLabel(
                        'planner.weekly_progress',
                        'Weekly Progress',
                      ),
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _plannerLabel(
                        'planner.nutrition_journey_week',
                        'Your nutrition journey this week',
                      ),
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.mealPlannerWeek),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          key: const ValueKey('planner-goal-analysis-card'),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appBorder.withValues(alpha: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.track_changes_rounded,
                    color: AppColors.primaryGreen,
                    size: 23,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _plannerLabel('planner.analysis_center', 'Goal Analysis'),
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed<void>(AppRoutes.profile),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 34),
                    ),
                    child: Text(
                      _plannerLabel('planner.update_info', 'Update info'),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _plannerLabel(
                            'planner.weight_goal_analysis',
                            'Weight Goal Analysis',
                          ),
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _plannerLabel(
                            'planner.based_on_profile',
                            'Based on your profile and current plan',
                          ),
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      forecast?.paceStatusKey.tr ??
                          _plannerLabel('planner.ready', 'Ready'),
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _goalInsightGrid(
                context,
                children: [
                  _goalInsightTile(
                    context,
                    Icons.emoji_events_outlined,
                    _plannerLabel('planner.goal', 'Goal'),
                    goalLabel,
                    const Color(0xFFE9FAEE),
                    AppColors.primaryGreen,
                  ),
                  _goalInsightTile(
                    context,
                    goalIcon,
                    _plannerLabel(
                      'planner.projected_change',
                      'Projected change',
                    ),
                    '$projectedChange kg\n$days days',
                    const Color(0xFFFFEDEE),
                    const Color(0xFFFF5364),
                  ),
                  _goalInsightTile(
                    context,
                    Icons.schedule_rounded,
                    _plannerLabel('planner.target_pace', 'Target pace'),
                    paceLabel,
                    const Color(0xFFFFF5DC),
                    const Color(0xFFF5A000),
                  ),
                  _goalInsightTile(
                    context,
                    Icons.restaurant_rounded,
                    _plannerLabel('planner.meal_strategy', 'Meal strategy'),
                    _plannerLabel(
                      'planner.high_protein_balanced',
                      'High-protein balanced meals',
                    ),
                    const Color(0xFFEAF6FF),
                    const Color(0xFF2C8DDB),
                  ),
                  _goalInsightTile(
                    context,
                    Icons.directions_run_rounded,
                    _plannerLabel('planner.activity_focus', 'Activity focus'),
                    _plannerLabel(
                      'planner.light_daily_movement',
                      'Light daily movement',
                    ),
                    const Color(0xFFF2EAFE),
                    const Color(0xFF8B4CE8),
                  ),
                  _goalInsightTile(
                    context,
                    Icons.bar_chart_rounded,
                    _plannerLabel(
                      'planner.calories_approach',
                      'Calories approach',
                    ),
                    '${goal == MealPlannerHealthGoal.gainWeight
                        ? 'planner.daily_surplus'.tr
                        : goal == MealPlannerHealthGoal.maintainHealth
                        ? 'planner.daily_balance'.tr
                        : _plannerLabel('planner.moderate_deficit', 'Moderate deficit')}\n$calorieGap kcal/day',
                    const Color(0xFFE9FAEE),
                    AppColors.primaryGreen,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  key: const ValueKey('open-weight-loss-analysis'),
                  onPressed:
                      () => Get.toNamed<void>(
                        AppRoutes.mealPlannerWeightLossAnalysis,
                      ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.insights_rounded, size: 18),
                  label: Text(
                    'planner.view_weight_loss_analysis'.tr,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: context.appElevatedSurface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primaryGreen,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _plannerLabel(
                          'planner.recommended_current_plan',
                          'Recommended for your current goal. Built to support steady, healthy progress.',
                        ),
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 10,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _goalInsightTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color background,
    Color accent,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
    decoration: BoxDecoration(
      color: context.appIsDark ? context.appSurfaceLow : background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent, size: 22),
        const Spacer(),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 10,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.appText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    ),
  );

  Widget _goalInsightGrid(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppSpacing.isTabletFor(context) ? 3 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final height = AppSpacing.isTabletFor(context) ? 108.0 : 116.0;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              children
                  .map(
                    (child) =>
                        SizedBox(width: width, height: height, child: child),
                  )
                  .toList(),
        );
      },
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

  Widget _goalStatusRow(BuildContext context) {
    final projectionController =
        Get.isRegistered<WeightLossProjectionController>()
            ? Get.find<WeightLossProjectionController>()
            : null;
    final forecast = projectionController?.forecast.value;
    final loss = forecast?.projectedWeightLossKg.toStringAsFixed(1);
    final weeks = ((forecast?.timeframeDays ?? 28) / 7).ceil();
    final goal = controller.healthGoal.value;
    final goalLabel = switch (goal) {
      MealPlannerHealthGoal.gainWeight => 'planner.goal_gain_weight'.tr,
      MealPlannerHealthGoal.maintainHealth => 'planner.goal_maintain_health'.tr,
      MealPlannerHealthGoal.loseWeight => 'planner.goal_lose_weight'.tr,
    };
    final goalIcon = switch (goal) {
      MealPlannerHealthGoal.gainWeight => Icons.trending_up_rounded,
      MealPlannerHealthGoal.maintainHealth => Icons.balance_rounded,
      MealPlannerHealthGoal.loseWeight => Icons.trending_down_rounded,
    };

    return Row(
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.appBorder.withValues(alpha: 0.7),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(goalIcon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plannerLabel('planner.your_goal', 'Your Goal'),
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 9.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        goalLabel,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (loss != null &&
                          goal == MealPlannerHealthGoal.loseWeight)
                        Text(
                          '${_plannerLabel('planner.lose', 'Lose')} $loss kg · '
                          '$weeks ${_plannerLabel('planner.weeks_left', 'weeks left')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 8.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 66),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_plannerLabel('planner.on_track', "You're on track!")} ✨",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'planner.keep_going_on_track'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMutedText, fontSize: 8.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dailyOverview(BuildContext context) {
    return Container(
      key: const ValueKey('planner-daily-overview'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plannerLabel(
                        'planner.todays_nutrition',
                        "Today's Nutrition",
                      ),
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _plannerLabel(
                        'planner.daily_target_subtitle',
                        'Based on your daily target',
                      ),
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${controller.eatenMeals}/${controller.dailyMealGoal} '
                '${_plannerLabel('planner.meals_short', 'meals')}',
                style: TextStyle(
                  color: context.appText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            key: const ValueKey('planner-nutrition-scroll'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _macroCard(
                  context,
                  key: const ValueKey('planner-water-nutrient'),
                  icon: AppNutrientTheme.waterIcon,
                  iconColor: AppNutrientTheme.waterColor,
                  value: '${controller.dailyWaterGlasses.value}',
                  target: '${MealPlannerController.dailyWaterGoalGlasses}',
                  label: 'common.water'.tr,
                  unit: 'common.glasses'.tr,
                  progress:
                      controller.dailyWaterGlasses.value /
                      MealPlannerController.dailyWaterGoalGlasses,
                  onTap: controller.openWaterTracker,
                ),
                const SizedBox(width: 16),
                _macroCard(
                  context,
                  icon: AppNutrientTheme.caloriesIcon,
                  iconColor: AppNutrientTheme.caloriesColor,
                  value: '${controller.selectedCalories}',
                  target: '2000',
                  label: 'planner.kcal'.tr,
                  unit: 'planner.kcal'.tr,
                  progress: controller.selectedCalories / 2000,
                  progressKey: const ValueKey('planner-daily-progress'),
                ),
                const SizedBox(width: 16),
                _macroCard(
                  context,
                  icon: AppNutrientTheme.proteinIcon,
                  iconColor: AppNutrientTheme.proteinColor,
                  value: controller.selectedProtein.toStringAsFixed(0),
                  target: '120',
                  label: 'planner.protein'.tr,
                  unit: 'g',
                  progress: controller.selectedProtein / 120,
                ),
                const SizedBox(width: 16),
                _macroCard(
                  context,
                  icon: AppNutrientTheme.carbsIcon,
                  iconColor: AppNutrientTheme.carbsColor,
                  value: controller.selectedCarbs.toStringAsFixed(0),
                  target: '250',
                  label: 'planner.carbs'.tr,
                  unit: 'g',
                  progress: controller.selectedCarbs / 250,
                ),
                const SizedBox(width: 16),
                _macroCard(
                  context,
                  icon: AppNutrientTheme.fatIcon,
                  iconColor: AppNutrientTheme.fatColor,
                  value: controller.selectedFat.toStringAsFixed(0),
                  target: '78',
                  label: 'planner.fat'.tr,
                  unit: 'g',
                  progress: controller.selectedFat / 78,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String target,
    required String label,
    required String unit,
    required double progress,
    Key? key,
    Key? progressKey,
    VoidCallback? onTap,
  }) => InkWell(
    key: key,
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onTap == null ? context.appMutedText : iconColor,
                    fontSize: 11,
                    fontWeight:
                        onTap == null ? FontWeight.w600 : FontWeight.w800,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(Icons.add_circle_rounded, size: 13, color: iconColor),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '$value / $target',
            style: TextStyle(
              color: context.appText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unit,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              key: progressKey,
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              color: onTap == null ? AppColors.primaryGreen : iconColor,
              backgroundColor:
                  onTap == null
                      ? context.appSoftGreen
                      : iconColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    ),
  );

  // Kept temporarily for backward-compatible widget snapshots; the live
  // planner uses the compact, tappable Water nutrient above.
  // ignore: unused_element
  Widget _waterTrackerCard(BuildContext context) {
    const waterBlue = Color(0xFF0284C7);
    final count = controller.dailyWaterGlasses.value;
    final total = MealPlannerController.dailyWaterGoalGlasses;
    final progress = (count / total).clamp(0.0, 1.0);
    final isGoalReached = count >= total;

    return Container(
      key: const ValueKey('planner-water-tracker-card'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isGoalReached
                  ? waterBlue.withValues(alpha: 0.6)
                  : context.appBorder.withValues(alpha: 0.7),
        ),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: waterBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: waterBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.water_tracker_title'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'planner.water_tap_to_log'.tr,
                      style: TextStyle(
                        color: waterBlue,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: waterBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '/$total',
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${count * 250} ml',
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Interactive 8 glasses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(total, (index) {
              final isFilled = index < count;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == total - 1 ? 0 : 4),
                  child: InkWell(
                    key: ValueKey('planner-water-glass-$index'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: controller.openWaterTracker,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            isFilled
                                ? waterBlue.withValues(alpha: 0.16)
                                : context.appSurfaceLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isFilled
                                  ? waterBlue.withValues(alpha: 0.5)
                                  : context.appBorder.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        isFilled
                            ? Icons.water_drop_rounded
                            : Icons.water_drop_outlined,
                        size: 18,
                        color:
                            isFilled
                                ? waterBlue
                                : context.appMutedText.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: context.appBorder.withValues(alpha: 0.4),
                    valueColor: const AlwaysStoppedAnimation<Color>(waterBlue),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                key: const ValueKey('planner-water-minus-btn'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'planner.water_tap_to_log'.tr,
                onPressed: controller.openWaterTracker,
                icon: const Icon(Icons.edit_rounded, size: 17),
                style: IconButton.styleFrom(
                  backgroundColor: context.appSurfaceLow,
                  foregroundColor: context.appText,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const ValueKey('planner-water-plus-btn'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'planner.water_tap_to_log'.tr,
                onPressed: controller.openWaterTracker,
                icon: const Icon(Icons.add_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: waterBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (isGoalReached) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: waterBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: waterBlue,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'planner.water_goal_reached'.tr,
                      style: const TextStyle(
                        color: waterBlue,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealTimelineCard(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 5),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading(context),
        const SizedBox(height: 12),
        LoadingContentTransition(
          isLoading:
              controller.isAutoFilling.value || controller.isLoadingDay.value,
          loading:
              controller.isAutoFilling.value
                  ? _autoFillLoadingView(context)
                  : const PageSkeleton.plannerSlots(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                MealPlanSlot.values
                    .map(
                      (slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _timelineSlotRow(context, slot),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeading(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            size: 19,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _plannerLabel('planner.meal_for_today', 'Meal for Today'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _plannerLabel(
                  'planner.plan_meals_consistent',
                  'Plan your meals and stay consistent',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          key: const ValueKey('planner-day-actions-menu'),
          icon: Icon(
            Icons.more_horiz_rounded,
            color: context.appMutedText,
            size: 20,
          ),
          tooltip: 'planner.day_options'.tr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: context.appElevatedSurface,
          onSelected: (value) async {
            switch (value) {
              case 'copy_yesterday':
                await controller.copyAllFromYesterday();
                break;
              case 'reset_planned':
                await controller.resetAllMealsToPlanned(currentDayOnly: true);
                break;
              case 'clear_meals':
                await controller.clearAllMeals(currentDayOnly: true);
                break;
            }
          },
          itemBuilder:
              (context) => [
                if (controller.yesterdayMeals.isNotEmpty)
                  PopupMenuItem(
                    value: 'copy_yesterday',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.copy_all_rounded,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'planner.copy_all_from_yesterday'.tr,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (controller.selectedMeals.any(
                  (m) => m.status != MealPlanStatus.planned,
                ))
                  PopupMenuItem(
                    value: 'reset_planned',
                    child: Row(
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 18,
                          color: context.appMutedText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'planner.reset_all_to_planned'.tr,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (controller.selectedMeals.isNotEmpty)
                  PopupMenuItem(
                    value: 'clear_meals',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.favoriteRed,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'planner.clear_all_day_meals'.tr,
                            style: const TextStyle(
                              color: AppColors.favoriteRed,
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
    );
  }

  Widget _timelineSlotRow(BuildContext context, MealPlanSlot slot) {
    final meal = controller.mealFor(slot);
    final theme = PlannerSlotTheme.of(slot);
    final index = MealPlanSlot.values.indexOf(slot);
    final time = switch (slot) {
      MealPlanSlot.breakfast => '7:00 AM',
      MealPlanSlot.lunch => '12:00 PM',
      MealPlanSlot.dinner => '6:00 PM',
      MealPlanSlot.snack => '3:00 PM',
    };

    return IntrinsicHeight(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (index < MealPlanSlot.values.length - 1)
            Positioned(
              left: 4,
              top: 34,
              bottom: -12,
              child: Container(
                width: 1,
                color: context.appBorder.withValues(alpha: 0.8),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appElevatedSurface),
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 72,
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: theme.soft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(theme.icon, color: theme.accent, size: 17),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.labelKey.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            time,
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('planner-slot-${slot.name}'),
                    onTap:
                        meal == null
                            ? () => _openSlot(slot)
                            : () => _showMealOptionsSheet(context, meal),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      key: ValueKey('planner-meal-card-${slot.name}'),
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: context.appElevatedSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.appBorder.withValues(alpha: 0.8),
                        ),
                      ),
                      child:
                          meal == null
                              ? _emptyTimelineSlot(context, slot)
                              : _filledTimelineSlot(context, meal),
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

  Widget _emptyTimelineSlot(BuildContext context, MealPlanSlot slot) {
    final fallbackSlot =
        slot == MealPlanSlot.lunch ? MealPlanSlot.dinner : null;
    final yesterdayMeal = controller.yesterdayMealFor(
      slot,
      fallbackSlot: fallbackSlot,
    );
    final isDinnerLeftover =
        fallbackSlot != null &&
        yesterdayMeal != null &&
        yesterdayMeal.slot == MealPlanSlot.dinner;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.appMutedText),
          ),
          child: Icon(Icons.add_rounded, color: context.appMutedText, size: 20),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_plannerLabel('planner.add_your', 'Add your')} '
                '${slot.labelKey.tr.toLowerCase()}',
                style: TextStyle(
                  color: context.appText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              if (yesterdayMeal != null)
                Text(
                  isDinnerLeftover
                      ? 'planner.leftover_from_dinner'.tr
                      : 'planner.copy_yesterday'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  _plannerLabel(
                    'planner.find_healthy_meals',
                    'Find healthy and tasty meals',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appMutedText, fontSize: 8.5),
                ),
            ],
          ),
        ),
        if (yesterdayMeal != null) ...[
          const SizedBox(width: 4),
          InkWell(
            key: ValueKey('planner-copy-yesterday-${slot.name}'),
            borderRadius: BorderRadius.circular(8),
            onTap:
                () => controller.copyFromYesterday(
                  slot,
                  fromSlot: isDinnerLeftover ? MealPlanSlot.dinner : slot,
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 13,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isDinnerLeftover
                        ? 'planner.leftover_from_yesterday'.tr
                        : 'planner.copy_yesterday'.tr,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 21),
        ),
      ],
    );
  }

  Widget _filledTimelineSlot(BuildContext context, PlannedMeal meal) => Row(
    children: [
      PlannerMealImage(meal: meal, width: 44, height: 44, radius: 10),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plannerMealName(meal),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appText,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${(meal.calories * meal.servings).round()} ${'planner.kcal'.tr} · '
              '${(meal.proteinGrams * meal.servings).toStringAsFixed(0)}g '
              '${'planner.protein'.tr}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appMutedText, fontSize: 8.5),
            ),
          ],
        ),
      ),
      const SizedBox(width: 4),
      Semantics(
        button: true,
        toggled: meal.status == MealPlanStatus.eaten,
        label:
            meal.status == MealPlanStatus.eaten
                ? 'planner.reset_to_planned'.tr
                : 'planner.mark_as_eaten'.tr,
        child: IconButton(
          key: ValueKey('planner-mark-eaten-${meal.slot.name}'),
          tooltip:
              meal.status == MealPlanStatus.eaten
                  ? 'planner.reset_to_planned'.tr
                  : 'planner.mark_as_eaten'.tr,
          onPressed:
              controller.isSaving.value
                  ? null
                  : () => controller.changeStatus(
                    meal,
                    meal.status == MealPlanStatus.eaten
                        ? MealPlanStatus.planned
                        : MealPlanStatus.eaten,
                  ),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          padding: EdgeInsets.zero,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOutBack,
            child: Icon(
              meal.status == MealPlanStatus.eaten
                  ? Icons.check_rounded
                  : Icons.check_circle_outline_rounded,
              key: ValueKey(meal.status == MealPlanStatus.eaten),
              size: meal.status == MealPlanStatus.eaten ? 18 : 20,
              color:
                  meal.status == MealPlanStatus.eaten
                      ? Colors.white
                      : AppColors.primaryGreen,
            ),
          ),
          style: IconButton.styleFrom(
            backgroundColor:
                meal.status == MealPlanStatus.eaten
                    ? AppColors.primaryGreen
                    : context.appSoftGreen,
            disabledBackgroundColor: context.appSoftGreen,
          ),
        ),
      ),
      IconButton(
        onPressed: () => _showMealOptionsSheet(context, meal),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 22, height: 30),
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert_rounded,
          size: 17,
          color: context.appMutedText,
        ),
      ),
    ],
  );

  Widget _slotCard(BuildContext context, MealPlanSlot slot) {
    final meal = controller.mealFor(slot);
    final theme = PlannerSlotTheme.of(slot);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: ValueKey('planner-meal-card-${slot.name}'),
          constraints: const BoxConstraints(minHeight: 92),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(14),
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
                  horizontal: 10,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    if (meal == null)
                      Container(
                        width: 42,
                        height: 42,
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
                        width: 58,
                        height: 58,
                        radius: 13,
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
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
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
                  () async {
                    Get.back<void>();
                    final foodDetail = await _plannerMealAsFoodDetail(meal);
                    Get.toNamed<void>(
                      AppRoutes.foodDetail,
                      arguments: FoodDetailArguments(
                        meal: foodDetail,
                        loadRemoteDetail: false,
                        favoritesEnabled: false,
                      ),
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
                  Icons.delete_outline_rounded,
                  'planner.remove_meal'.tr,
                  () {
                    Get.back<void>();
                    remove0(context, meal);
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

  Future<void> _recommendAndShowSheet(
    BuildContext context, {
    required MealPlanSlot slot,
    PlannedMeal? currentMeal,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appSurfaceLow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder:
        (sheetContext) => _AiMealRecommendationSheet(
          slot: slot,
          currentMeal: currentMeal,
          controller: controller,
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

class _AiMealRecommendationSheet extends StatefulWidget {
  const _AiMealRecommendationSheet({
    required this.slot,
    this.currentMeal,
    required this.controller,
  });

  final MealPlanSlot slot;
  final PlannedMeal? currentMeal;
  final MealPlannerController controller;

  @override
  State<_AiMealRecommendationSheet> createState() =>
      _AiMealRecommendationSheetState();
}

class _AiMealRecommendationSheetState
    extends State<_AiMealRecommendationSheet> {
  bool _loading = true;
  AiMealRecommendationResult? _result;
  String? _errorMessage;
  int? _applyingMealId;

  bool get isSwap => widget.currentMeal != null;

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  Future<void> _fetchRecommendation() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final res = await widget.controller.getAiMealRecommendation(
        slot: widget.slot,
        currentMeal: widget.currentMeal,
      );
      if (!mounted) return;
      if (res != null) {
        setState(() {
          _result = res;
          _loading = false;
        });
      } else {
        final err = widget.controller.recommendationsError.value;
        setState(() {
          _errorMessage =
              err.isNotEmpty ? err : 'planner.ai_recommendation_error'.tr;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'planner.ai_recommendation_error'.tr;
        _loading = false;
      });
    }
  }

  Future<void> _applyMeal(PlannedMeal meal) async {
    if (_applyingMealId != null) return;
    setState(() => _applyingMealId = meal.id);
    try {
      bool success;
      if (isSwap) {
        success = await widget.controller.replaceMeal(
          widget.currentMeal!,
          meal,
        );
      } else {
        success = await widget.controller.addMeal(
          meal,
          targetSlot: widget.slot,
        );
      }
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
        AppAlert.toast(
          message:
              isSwap
                  ? 'planner.meal_swapped_success'.tr
                  : 'planner.meal_added_success'.tr,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _applyingMealId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSwap
                              ? 'planner.ai_swap_title'.tr
                              : 'planner.ai_recommend_title'.tr,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.slot.labelKey.tr,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(child: _buildBody(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSwap
                  ? 'planner.ai_recommending_swap'.tr
                  : 'planner.ai_recommending_add'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _result == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: context.appMutedText,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'planner.ai_recommendation_error'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchRecommendation,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('planner.retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final recMeal = _result!.recommendedMeal;
    final rationale = _result!.aiRationale;
    final alts = _result!.alternatives;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rationale.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rationale,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildHeroMealCard(context, recMeal),
        if (alts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'planner.other_alternatives'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.appBorder.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${alts.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.appMutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...alts.map((alt) => _buildAlternativeTile(context, alt)),
        ],
      ],
    );
  }

  Widget _buildHeroMealCard(BuildContext context, PlannedMeal meal) {
    final isBusy = _applyingMealId == meal.id;
    return Container(
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PlannerMealImage(meal: meal, width: 64, height: 64, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plannerMealName(meal),
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _metricBadge(
                          context,
                          Icons.local_fire_department_outlined,
                          '${meal.calories.round()} ${'planner.kcal'.tr}',
                        ),
                        _metricBadge(
                          context,
                          Icons.bolt_rounded,
                          '${meal.proteinGrams.toStringAsFixed(0)}g ${'planner.protein'.tr}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: isBusy ? null : () => _applyMeal(meal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child:
                  isBusy
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSwap
                                ? Icons.sync_rounded
                                : Icons.add_circle_outline_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSwap
                                ? 'planner.accept_and_swap'.tr
                                : 'planner.accept_and_add'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeTile(BuildContext context, PlannedMeal meal) {
    final isBusy = _applyingMealId == meal.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          PlannerMealImage(meal: meal, width: 48, height: 48, radius: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plannerMealName(meal),
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${meal.calories.round()} ${'planner.kcal'.tr} • ${meal.proteinGrams.toStringAsFixed(0)}g ${'planner.protein'.tr}',
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isBusy ? null : () => _applyMeal(meal),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppColors.primaryGreen),
              foregroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                isBusy
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryGreen,
                        ),
                      ),
                    )
                    : Text(
                      'planner.select'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _metricBadge(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: context.appMutedText),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
