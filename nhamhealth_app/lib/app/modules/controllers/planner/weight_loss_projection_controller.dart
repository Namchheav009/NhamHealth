import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import '../../models/planner/meal_plan.dart';
import '../../models/planner/weight_loss_forecast_model.dart';
import '../../providers/planner/meal_planner_provider.dart';
import '../profile/profile_controller.dart';
import 'meal_planner_controller.dart';

class WeightLossProjectionController extends GetxController {
  WeightLossProjectionController({
    MealPlannerProvider? provider,
    FlutterSecureStorage? storage,
  }) : _provider = provider,
       _storage = storage ?? const FlutterSecureStorage();

  final MealPlannerProvider? _provider;
  final FlutterSecureStorage _storage;
  static const _forecastCacheKey = 'meal_planner_weight_goal_forecast';

  final selectedTimeframeDays = 30.obs;
  final forecast = Rxn<WeightLossForecast>();
  final goalForecastCache = Rxn<WeightLossForecast>();
  final activeAnalysisGoal = Rx<MealPlannerHealthGoal>(
    MealPlannerHealthGoal.loseWeight,
  );
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final requiresProfileReview = false.obs;
  final selectedTab = 0.obs; // 0: Suitable Foods, 1: Healthy Beverages
  Worker? _healthGoalWorker;
  Worker? _weekOffsetWorker;
  Worker? _startDateWorker;
  Worker? _planDaysWorker;
  Worker? _weightWorker;
  Worker? _heightWorker;
  bool _forecastRefreshQueued = false;
  int _forecastRequestId = 0;

  static const List<int> availableTimeframes = [7, 30, 90];

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<MealPlannerController>()) {
      final planner = Get.find<MealPlannerController>();
      activeAnalysisGoal.value = planner.healthGoal.value;
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
    if (Get.isRegistered<ProfileController>()) {
      final profile = Get.find<ProfileController>();
      _weightWorker = ever<double>(
        profile.weight,
        (_) => _scheduleForecastRefresh(),
      );
      _heightWorker = ever<double>(
        profile.height,
        (_) => _scheduleForecastRefresh(),
      );
    }
    unawaited(_restoreForecastThenRefresh());
  }

  Future<void> _restoreForecastThenRefresh() async {
    await _restoreForecast();
    await loadForecast();
  }

  Future<String> _userForecastKey() async {
    try {
      final auth =
          Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      final token = await auth?.readAccessToken();
      if (token != null && token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final decoded = utf8.decode(
            base64Url.decode(base64Url.normalize(parts[1])),
          );
          final payload = jsonDecode(decoded);
          if (payload is Map) {
            final userId = payload['userId'] ?? payload['id'] ?? payload['sub'];
            if (userId != null) return '${_forecastCacheKey}_$userId';
          }
        }
      }
    } catch (_) {
      // Fall back to the legacy key when authentication data is unavailable.
    }
    return _forecastCacheKey;
  }

  Future<void> _restoreForecast() async {
    try {
      final raw = await _storage.read(key: await _userForecastKey());
      if (raw == null || raw.isEmpty) return;
      final payload = jsonDecode(raw);
      if (payload is! Map) return;
      final cached = WeightLossForecast.fromJson(
        Map<String, dynamic>.from(payload),
      );
      forecast.value = cached;
      goalForecastCache.value = cached;
      activeAnalysisGoal.value = switch (cached.resolvedWeightDirection) {
        'GAIN' => MealPlannerHealthGoal.gainWeight,
        'MAINTAIN' => MealPlannerHealthGoal.maintainHealth,
        _ => MealPlannerHealthGoal.loseWeight,
      };
    } catch (_) {
      // A corrupt or unavailable cache must not block a live forecast.
    }
  }

  Future<void> _persistForecast(WeightLossForecast value) async {
    try {
      await _storage.write(
        key: await _userForecastKey(),
        value: jsonEncode(value.toJson()),
      );
    } catch (_) {
      // The live result remains usable when local secure storage is unavailable.
    }
  }

  @override
  void onClose() {
    _healthGoalWorker?.dispose();
    _weekOffsetWorker?.dispose();
    _startDateWorker?.dispose();
    _planDaysWorker?.dispose();
    _weightWorker?.dispose();
    _heightWorker?.dispose();
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
    requiresProfileReview.value = false;

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
    activeAnalysisGoal.value =
        planner?.healthGoal.value ?? MealPlannerHealthGoal.maintainHealth;

    try {
      final result = await provider.getWeightLossForecast(
        days: selectedTimeframeDays.value,
        startDate: planner?.planStartDate,
        goal: planner?.healthGoal.value ?? MealPlannerHealthGoal.maintainHealth,
      );
      if (requestId == _forecastRequestId) {
        requiresProfileReview.value = false;
        forecast.value = result;
        goalForecastCache.value = result;
        unawaited(_persistForecast(result));
      }
    } on MealPlannerProviderException catch (e) {
      if (requestId == _forecastRequestId) {
        errorMessage.value = e.message;
        requiresProfileReview.value = e.statusCode == 400;
        // Keep the last saved analysis available for offline/later viewing.
      }
    } catch (_) {
      if (requestId == _forecastRequestId) {
        errorMessage.value = 'planner.forecast_unavailable'.tr;
        requiresProfileReview.value = false;
        // Keep the last saved analysis available for offline/later viewing.
      }
    } finally {
      if (requestId == _forecastRequestId) isLoading.value = false;
    }
  }

  /// Shows the analysis for the currently selected goal using cached data when possible.
  Future<void> showGoalAnalysis({bool forceRefresh = false}) async {
    if (Get.isRegistered<MealPlannerController>()) {
      activeAnalysisGoal.value =
          Get.find<MealPlannerController>().healthGoal.value;
    }
    final cached = goalForecastCache.value;
    if (!forceRefresh && cached != null) {
      forecast.value = cached;
      return;
    }
    if (cached == null) forecast.value = null;
    await loadForecast(forceRefresh: forceRefresh);
  }

  MealPlannerHealthGoal? get recommendedGoal {
    final result = forecast.value;
    if (result == null || !result.hasBiometricProfile) return null;
    return switch (result.recommendedDirection) {
      'GAIN' => MealPlannerHealthGoal.gainWeight,
      'LOSE' => MealPlannerHealthGoal.loseWeight,
      'MAINTAIN' => MealPlannerHealthGoal.maintainHealth,
      _ => null,
    };
  }

  bool get hasGoalRecommendation {
    if (!Get.isRegistered<MealPlannerController>()) return false;
    final recommendation = recommendedGoal;
    return recommendation != null &&
        recommendation != Get.find<MealPlannerController>().healthGoal.value;
  }

  Future<void> applyRecommendedGoal() async {
    if (!Get.isRegistered<MealPlannerController>()) return;
    final recommendation = recommendedGoal;
    if (recommendation == null) return;
    final planner = Get.find<MealPlannerController>();
    await planner.setHealthGoal(recommendation);
    activeAnalysisGoal.value = recommendation;
    await loadForecast(forceRefresh: true);
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
      final saved = await provider.saveMeal(
        targetDate,
        planned,
        servings,
        goal: activeAnalysisGoal.value,
      );

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
      final goal = plannerCtrl?.healthGoal.value ?? activeAnalysisGoal.value;
      final preferences =
          plannerCtrl?.dietaryPreferences.value ??
          const MealPlannerDietaryPreferences();
      if (goal == MealPlannerHealthGoal.loseWeight &&
          preferences.medicalFlags.contains('PREGNANT_OR_BREASTFEEDING')) {
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
