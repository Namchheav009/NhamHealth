import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import '../../models/planner/meal_plan.dart';
import '../../models/planner/weight_loss_forecast_model.dart';
import '../../providers/planner/meal_planner_provider.dart';
import 'meal_planner_controller.dart';

class WeightLossProjectionController extends GetxController {
  WeightLossProjectionController({MealPlannerProvider? provider})
    : _provider = provider;

  final MealPlannerProvider? _provider;

  final selectedTimeframeDays = 28.obs;
  final forecast = Rxn<WeightLossForecast>();
  final weightLossForecast = Rxn<WeightLossForecast>();
  final activeAnalysisGoal = Rx<MealPlannerHealthGoal>(
    MealPlannerHealthGoal.loseWeight,
  );
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final selectedTab = 0.obs; // 0: Suitable Foods, 1: Healthy Beverages
  Worker? _healthGoalWorker;
  Worker? _weekOffsetWorker;
  Worker? _startDateWorker;
  Worker? _planDaysWorker;
  bool _forecastRefreshQueued = false;
  int _forecastRequestId = 0;

  static const List<int> availableTimeframes = [7, 14, 28, 56, 84];

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<MealPlannerController>()) {
      final planner = Get.find<MealPlannerController>();
      activeAnalysisGoal.value = MealPlannerHealthGoal.loseWeight;
      _healthGoalWorker = ever<MealPlannerHealthGoal>(
        planner.healthGoal,
        (_) => _scheduleForecastRefresh(),
      );
      _weekOffsetWorker = ever<int>(
        planner.weekOffset,
        (_) => _scheduleForecastRefresh(),
      );
      _startDateWorker = ever<DateTime?>(
        planner.customStartDate,
        (_) => _scheduleForecastRefresh(),
      );
      _planDaysWorker = ever<int>(
        planner.planDaysCount,
        (_) => _scheduleForecastRefresh(),
      );
    }
    unawaited(loadForecast());
  }

  @override
  void onClose() {
    _healthGoalWorker?.dispose();
    _weekOffsetWorker?.dispose();
    _startDateWorker?.dispose();
    _planDaysWorker?.dispose();
    super.onClose();
  }

  void _scheduleForecastRefresh() {
    if (_forecastRefreshQueued) return;
    _forecastRefreshQueued = true;
    scheduleMicrotask(() {
      _forecastRefreshQueued = false;
      unawaited(loadForecast(forceRefresh: true));
    });
  }

  MealPlannerProvider? _resolveProvider() {
    if (_provider != null) return _provider;
    if (Get.isRegistered<MealPlannerProvider>()) {
      return Get.find<MealPlannerProvider>();
    }
    if (Get.isRegistered<AuthService>()) {
      return MealPlannerProvider(authService: Get.find<AuthService>());
    }
    return null;
  }

  Future<void> loadForecast({bool forceRefresh = false}) async {
    final requestId = ++_forecastRequestId;
    isLoading.value = true;
    errorMessage.value = '';

    final provider = _resolveProvider();
    if (provider == null) {
      errorMessage.value = 'planner.forecast_unavailable'.tr;
      isLoading.value = false;
      return;
    }

    final planner =
        Get.isRegistered<MealPlannerController>()
            ? Get.find<MealPlannerController>()
            : null;
    activeAnalysisGoal.value = MealPlannerHealthGoal.loseWeight;

    try {
      final result = await provider.getWeightLossForecast(
        days: selectedTimeframeDays.value,
        startDate: planner?.planStartDate,
        goal: MealPlannerHealthGoal.loseWeight,
      );
      if (requestId == _forecastRequestId) {
        forecast.value = result;
        weightLossForecast.value = result;
      }
    } catch (e) {
      if (requestId == _forecastRequestId) {
        errorMessage.value = 'planner.forecast_unavailable'.tr;
        forecast.value = null;
      }
    } finally {
      if (requestId == _forecastRequestId) isLoading.value = false;
    }
  }

  /// Shows the Weight Loss analysis, using its cached forecast when available.
  Future<void> showAnalysisGoal({bool forceRefresh = false}) async {
    activeAnalysisGoal.value = MealPlannerHealthGoal.loseWeight;
    final cached = weightLossForecast.value;
    if (!forceRefresh && cached != null) {
      forecast.value = cached;
      return;
    }
    if (cached == null) forecast.value = null;
    await loadForecast(forceRefresh: forceRefresh);
  }

  void setTimeframeDays(int days) {
    if (selectedTimeframeDays.value == days) return;
    selectedTimeframeDays.value = days;
    unawaited(loadForecast());
  }

  void setSelectedTab(int tabIndex) {
    selectedTab.value = tabIndex;
  }

  /// Adds an AI-recommended food or beverage directly into the user's meal plan.
  Future<bool> addRecommendationToPlan({
    required BuildContext context,
    required ForecastRecommendationItem item,
    required DateTime targetDate,
    required MealPlanSlot slot,
    double servings = 1.0,
  }) async {
    if (isSaving.value) return false;
    final provider = _resolveProvider();
    if (provider == null) {
      AppAlert.toast(context: context, message: 'planner.save_error'.tr);
      return false;
    }

    isSaving.value = true;
    try {
      final planned = item.toPlannedMeal(slot: slot);
      final saved = await provider.saveMeal(targetDate, planned, servings);

      // Show the saved meal (including its ingredients) immediately, so the
      // integrated grocery list stays in sync while the full plan reloads.
      if (Get.isRegistered<MealPlannerController>()) {
        final plannerCtrl = Get.find<MealPlannerController>();
        plannerCtrl.putOptimisticMeal(
          saved.copyWith(planDate: targetDate, slot: slot),
        );
        unawaited(plannerCtrl.refreshPlanner(force: true));
      }

      if (context.mounted) {
        AppAlert.toast(
          context: context,
          message: 'planner.item_added_to_plan'.trParams({
            'item': item.name,
            'slot': slot.name.capitalizeFirst ?? slot.name,
          }),
        );
      }

      // Re-query forecast to reflect the newly planned calories
      unawaited(loadForecast());
      return true;
    } catch (e) {
      if (context.mounted) {
        AppAlert.toast(context: context, message: 'planner.save_error'.tr);
      }
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Auto-fills the plan using the selected goal and dietary preferences.
  Future<bool> autoFillPlanForTarget({
    required BuildContext context,
    bool fillEmptyOnly = true,
  }) async {
    if (isSaving.value) return false;
    final provider = _resolveProvider();
    if (provider == null) {
      AppAlert.toast(context: context, message: 'planner.save_error'.tr);
      return false;
    }

    isSaving.value = true;
    try {
      final plannerCtrl =
          Get.isRegistered<MealPlannerController>()
              ? Get.find<MealPlannerController>()
              : null;
      final startDate = plannerCtrl?.planStartDate ?? DateTime.now();
      final days = plannerCtrl?.planDaysCount.value ?? 7;
      const goal = MealPlannerHealthGoal.loseWeight;
      final preferences =
          plannerCtrl?.dietaryPreferences.value ??
          const MealPlannerDietaryPreferences();
      if (preferences.medicalFlags.contains('PREGNANT_OR_BREASTFEEDING')) {
        if (context.mounted) {
          AppAlert.toast(
            context: context,
            message: 'planner.pregnancy_weight_loss_warning'.tr,
          );
        }
        return false;
      }

      final res = await provider.aiAutoFillPlan(
        startDate: startDate,
        days: days,
        goal: goal,
        targetTimeframeDays: selectedTimeframeDays.value,
        fillEmptyOnly: fillEmptyOnly,
        preferences: preferences,
      );

      if (plannerCtrl != null) {
        plannerCtrl.applyAiAutoFillResult(res, fillEmptyOnly: fillEmptyOnly);
      }

      // Refresh forecast with updated plans to immediately reflect new deficit
      await loadForecast(forceRefresh: true);

      if (context.mounted) {
        AppAlert.toast(
          context: context,
          message: 'planner.ai_autofill_forecast_success'.trParams({
            'count': '${res.filledCount}',
            'loss': res.totalProjectedLossKg.toStringAsFixed(1),
          }),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppAlert.toast(context: context, message: 'planner.save_error'.tr);
      }
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
