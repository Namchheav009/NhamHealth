import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_realtime_event.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_alert.dart';
import '../../models/planner/ai_autofill_response_model.dart';
import '../../models/planner/ai_meal_recommendation_model.dart';
import '../../models/planner/meal_plan.dart';
import '../../providers/planner/meal_planner_provider.dart';
import '../../repositories/meals/meal_repository.dart';
import '../../repositories/profile/profile_repository.dart';
import '../home/home_controller.dart';
import '../wellness/wellness_controller.dart';

class MealPlannerController extends GetxController {
  MealPlannerController({
    MealPlannerProvider? provider,
    ProfileRepository? profileRepository,
    FlutterSecureStorage? storage,
    AuthService? authService,
    Stream<NotificationRealtimeEvent>? realtimeEvents,
  }) : _provider = provider,
       _profileRepository = profileRepository,
       _storage = storage ?? const FlutterSecureStorage(),
       _authService = authService,
       _realtimeEvents = realtimeEvents {
    if (provider == null) {
      isLoading.value = false;
      isLoadingRecommendations.value = false;
      hasLoadedOnce.value = true;
      hasLoadedRecommendationsOnce.value = true;
    }
  }

  static const _storageDaysKey = 'meal_planner_days_count';
  static const _storageStartDateKey = 'meal_planner_start_date';
  static const _storageHealthGoalKey = 'meal_planner_health_goal';
  static const _storageDietaryPreferencesKey =
      'meal_planner_dietary_preferences';
  static const _storageAnalyzedWeightLossKey =
      'meal_planner_analyzed_weight_loss';
  static const _storageAnalyzedMaintainHealthKey =
      'meal_planner_analyzed_maintain_health';
  static const _storageGroceryCheckedKey = 'meal_planner_grocery_checked';
  static const _storageWaterKey = 'meal_planner_water';

  static const dailyWaterGoalGlasses = 8;

  final MealPlannerProvider? _provider;
  final ProfileRepository? _profileRepository;
  final FlutterSecureStorage _storage;
  final AuthService? _authService;
  final Stream<NotificationRealtimeEvent>? _realtimeEvents;
  StreamSubscription<NotificationRealtimeEvent>? _notificationSubscription;
  final selectedDayIndex = 0.obs;
  final weekOffset = 0.obs;
  final planDaysCount = 7.obs;
  final customStartDate = Rxn<DateTime>();
  final healthGoal = MealPlannerHealthGoal.loseWeight.obs;
  final dietaryPreferences = const MealPlannerDietaryPreferences().obs;
  final plans = <String, List<PlannedMeal>>{}.obs;
  final adminRecommendations = <PlannedMeal>[].obs;
  final dailyWaterGlasses = 0.obs;
  final checkedGroceryKeys = <String>{}.obs;
  final isLoading = true.obs;
  final isLoadingRecommendations = true.obs;
  final isLoadingDay = false.obs;
  final isSaving = false.obs;
  final isAutoFilling = false.obs;
  final isRecommendingMeal = false.obs;
  final autoFillStatusKey = 'planner.autofill_loading_preparing'.obs;
  final errorMessage = ''.obs;
  final recommendationsError = ''.obs;
  final hasLoadedOnce = false.obs;
  final hasLoadedRecommendationsOnce = false.obs;
  final imageRefreshKey = 0.obs;
  final unreadNotificationCount = 0.obs;
  final lastAiAutoFillResult = Rxn<AiAutoFillPlanResponse>();
  final hasAnalyzedWeightLoss = false.obs;
  final hasAnalyzedMaintainHealth = false.obs;
  bool get hasAnalyzedBoth =>
      hasAnalyzedWeightLoss.value && hasAnalyzedMaintainHealth.value;
  final lastWeightLossResult = Rxn<AiAutoFillPlanResponse>();
  final lastMaintainHealthResult = Rxn<AiAutoFillPlanResponse>();

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final idx = planDays.indexWhere(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
    selectedDayIndex.value =
        idx >= 0 ? idx : (today.weekday - 1).clamp(0, planDaysCount.value - 1);
    unawaited(initPlanner());
    unawaited(loadUnreadNotificationCount());
    _notificationSubscription = _realtimeEvents?.listen(
      (_) => unawaited(loadUnreadNotificationCount()),
    );
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    super.onClose();
  }

  Future<void> initPlanner() => _initPlanner();

  Future<void> loadUnreadNotificationCount() async {
    if (!Get.isRegistered<MealRepository>()) return;
    try {
      unreadNotificationCount.value =
          await Get.find<MealRepository>().getUnreadNotificationCount();
    } on Object {
      // The planner must remain usable if the notification badge cannot load.
    }
  }

  Future<void> openNotifications() async {
    await Get.toNamed<void>(AppRoutes.notifications);
    await loadUnreadNotificationCount();
  }

  Future<String?> _resolveUserId() async {
    try {
      final auth =
          _authService ??
          (Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null);
      if (auth != null) {
        final token = await auth.readAccessToken();
        if (token != null && token.isNotEmpty) {
          final parts = token.split('.');
          if (parts.length >= 2) {
            final normalized = base64Url.normalize(parts[1]);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final json = jsonDecode(decoded) as Map<String, dynamic>;
            final raw = json['userId'] ?? json['id'] ?? json['sub'];
            if (raw != null) return raw.toString();
          }
        }
      }
    } catch (_) {
      // Ignore token parse error
    }
    return null;
  }

  Future<String> _userScopedKey(String baseKey) async {
    final userId = await _resolveUserId();
    if (userId != null && userId.isNotEmpty) {
      return '${baseKey}_$userId';
    }
    return baseKey;
  }

  Future<void> _initPlanner() async {
    try {
      final daysKey = await _userScopedKey(_storageDaysKey);
      final startKey = await _userScopedKey(_storageStartDateKey);
      final goalKey = await _userScopedKey(_storageHealthGoalKey);
      final preferencesKey = await _userScopedKey(
        _storageDietaryPreferencesKey,
      );

      final savedGoal = await _storage.read(key: goalKey);
      healthGoal.value = MealPlannerHealthGoal.values.firstWhere(
        (goal) => goal.apiValue == savedGoal,
        // Keep the existing first-run experience until BMI analysis has loaded;
        // the forecast then replaces this with GAIN, MAINTAIN, or LOSE.
        orElse: () => MealPlannerHealthGoal.loseWeight,
      );
      if (savedGoal == null) {
        try {
          await _storage.write(key: goalKey, value: healthGoal.value.apiValue);
        } catch (_) {}
      }

      final savedPreferences = await _storage.read(key: preferencesKey);
      if (savedPreferences != null && savedPreferences.isNotEmpty) {
        final decoded = jsonDecode(savedPreferences);
        if (decoded is Map) {
          dietaryPreferences.value = MealPlannerDietaryPreferences.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }

      final savedDays = await _storage.read(key: daysKey);
      if (savedDays != null) {
        final parsed = int.tryParse(savedDays);
        if (parsed != null && parsed >= 3 && parsed <= 7) {
          planDaysCount.value = parsed;
        } else {
          planDaysCount.value = 7;
        }
      } else {
        planDaysCount.value = 7;
      }
      final savedStart = await _storage.read(key: startKey);
      if (savedStart != null) {
        final parsedDate = DateTime.tryParse(savedStart);
        if (parsedDate != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final start = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
          );
          final end = start.add(Duration(days: planDaysCount.value - 1));
          // If the custom start period has ended before today, clear it so the
          // user always gets today's real-time date and week!
          if (end.isBefore(today)) {
            customStartDate.value = null;
            await _storage.delete(key: startKey);
          } else {
            customStartDate.value = start;
            if (today.isBefore(start)) {
              selectedDayIndex.value = 0;
            }
          }
        }
      }

      final analyzedLossKey = await _userScopedKey(
        _storageAnalyzedWeightLossKey,
      );
      final analyzedMaintainKey = await _userScopedKey(
        _storageAnalyzedMaintainHealthKey,
      );
      final savedAnalyzedLoss = await _storage.read(key: analyzedLossKey);
      final savedAnalyzedMaintain = await _storage.read(
        key: analyzedMaintainKey,
      );
      hasAnalyzedWeightLoss.value = savedAnalyzedLoss == 'true';
      hasAnalyzedMaintainHealth.value = savedAnalyzedMaintain == 'true';
      await _loadGroceryCheckedState();
    } catch (_) {
      // Secure storage read error ignored
    }
    await syncToToday(forceRefresh: true);
  }

  DateTime get planStartDate {
    if (customStartDate.value != null) {
      return customStartDate.value!;
    }
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return DateTime(
      monday.year,
      monday.month,
      monday.day,
    ).add(Duration(days: weekOffset.value * 7));
  }

  DateTime get planEndDate =>
      planStartDate.add(Duration(days: planDaysCount.value - 1));

  List<DateTime> get planDays => List.generate(
    planDaysCount.value,
    (index) => planStartDate.add(Duration(days: index)),
  );

  DateTime get weekStart => planStartDate;
  List<DateTime> get weekDays => planDays;

  DateTime get selectedDate {
    if (selectedDayIndex.value >= planDays.length) {
      selectedDayIndex.value = planDays.length - 1;
    }
    return planDays[selectedDayIndex.value];
  }

  List<PlannedMeal> get selectedMeals =>
      plans[_dateKey(selectedDate)] ?? const [];
  List<PlannedMeal> mealsFor(DateTime date) =>
      plans[_dateKey(date)] ?? const [];
  int get selectedCalories => selectedMeals.fold(
    0,
    (sum, m) => sum + (m.calories * m.servings).round(),
  );
  double get selectedProtein =>
      selectedMeals.fold(0, (sum, m) => sum + m.proteinGrams * m.servings);
  double get selectedCarbs =>
      selectedMeals.fold(0, (sum, m) => sum + m.carbsGrams * m.servings);
  double get selectedFat =>
      selectedMeals.fold(0, (sum, m) => sum + m.fatGrams * m.servings);
  Iterable<PlannedMeal> get selectedEatenMeals =>
      selectedMeals.where((meal) => meal.status == MealPlanStatus.eaten);
  int get eatenCalories => selectedEatenMeals.fold(
    0,
    (sum, meal) => sum + (meal.calories * meal.servings).round(),
  );
  double get eatenProtein => selectedEatenMeals.fold(
    0,
    (sum, meal) => sum + meal.proteinGrams * meal.servings,
  );
  double get eatenCarbs => selectedEatenMeals.fold(
    0,
    (sum, meal) => sum + meal.carbsGrams * meal.servings,
  );
  double get eatenFat => selectedEatenMeals.fold(
    0,
    (sum, meal) => sum + meal.fatGrams * meal.servings,
  );
  int get completedSlots =>
      selectedMeals.map((meal) => meal.slot).toSet().length;
  int get eatenMeals => selectedEatenMeals.length;
  int get skippedMeals =>
      selectedMeals
          .where((meal) => meal.status == MealPlanStatus.skipped)
          .length;
  int get dailyMealGoal => MealPlanSlot.values.length;
  bool get dailyGoalComplete => eatenMeals == dailyMealGoal;
  double get adherenceProgress => eatenMeals / dailyMealGoal;
  Iterable<PlannedMeal> get _currentPlanMeals =>
      planDays.expand((date) => mealsFor(date));
  int get planMealCount => _currentPlanMeals.length;
  double get planProgress {
    final total = planDaysCount.value * dailyMealGoal;
    if (total <= 0) return 0.0;
    return (planMealCount / total).clamp(0.0, 1.0);
  }

  bool get planIsEmpty => planMealCount == 0;
  bool get plansAreEmpty =>
      plans.isEmpty || plans.values.every((list) => list.isEmpty);

  int get weeklyMealCount => planMealCount;
  double get weeklyProgress => planProgress;
  int get weeklyEatenMeals =>
      _currentPlanMeals.where((m) => m.status == MealPlanStatus.eaten).length;
  bool get weekIsEmpty => planIsEmpty;

  List<GroceryItem> get groceryItems => _groceryItemsFor(_currentPlanMeals);

  Future<String?> lookupIngredientImageUrl(String ingredientName) =>
      _provider?.lookupIngredientImageUrl(ingredientName) ??
      Future<String?>.value();

  /// Ingredients for the four saved slots on the selected day only.
  List<GroceryItem> groceryItemsForDate(DateTime date) =>
      _groceryItemsFor(mealsFor(date));

  List<GroceryItem> _groceryItemsFor(Iterable<PlannedMeal> meals) {
    final combined = <String, GroceryItem>{};
    for (final meal in meals) {
      final ingredients =
          meal.ingredientDetails.isEmpty
              ? meal.ingredients.map((name) => PlannerIngredient(name: name))
              : meal.ingredientDetails;
      for (final ingredient in ingredients) {
        final name = ingredient.name.trim();
        if (name.isEmpty) continue;
        final unit = ingredient.unit.trim();
        final key = '${name.toLowerCase()}|${unit.toLowerCase()}';
        final old = combined[key];
        combined[key] = GroceryItem(
          name: name,
          unit: unit,
          quantity: (old?.quantity ?? 0) + ingredient.quantity * meal.servings,
          category: _groceryCategory(name),
          sourceMeals: [
            ...?old?.sourceMeals,
            if (meal.name.isNotEmpty &&
                (old == null || !old.sourceMeals.contains(meal.name)))
              meal.name,
          ],
        );
      }
    }
    final result =
        combined.values.toList()..sort((a, b) {
          final group = a.category.compareTo(b.category);
          return group == 0 ? a.name.compareTo(b.name) : group;
        });
    return result;
  }

  List<PlannedMeal> suggestionsFor(MealPlanSlot slot) {
    return adminRecommendations
        .where(
          (meal) =>
              meal.slot == slot &&
              (meal.recommendedWeekday == null ||
                  meal.recommendedWeekday == selectedDate.weekday),
        )
        .toList();
  }

  /// Returns all available meals for this slot, prioritizing today's recommendations,
  /// followed by other recommendations for this slot, or fallback to all meals.
  List<PlannedMeal> availableMealsFor(MealPlanSlot slot) {
    final todayRecs = suggestionsFor(slot);
    final otherSlotMeals =
        adminRecommendations
            .where(
              (meal) =>
                  meal.slot == slot && !todayRecs.any((r) => r.id == meal.id),
            )
            .toList();
    final combined = [...todayRecs, ...otherSlotMeals];
    if (combined.isNotEmpty) return combined;
    return adminRecommendations.toList();
  }

  List<PlannerMealCategory> categoriesFor(MealPlanSlot slot) {
    final categories = <int, PlannerMealCategory>{};
    final meals = availableMealsFor(slot);
    for (final meal in meals) {
      final id = meal.categoryId;
      if (id == null || meal.category.isEmpty) continue;
      categories.putIfAbsent(
        id,
        () => PlannerMealCategory(
          id: id,
          name: meal.category,
          imageUrl: meal.imageUrl,
        ),
      );
    }
    if (categories.isEmpty) {
      for (final meal in adminRecommendations) {
        final id = meal.categoryId;
        if (id == null || meal.category.isEmpty) continue;
        categories.putIfAbsent(
          id,
          () => PlannerMealCategory(
            id: id,
            name: meal.category,
            imageUrl: meal.imageUrl,
          ),
        );
      }
    }
    final values =
        categories.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  Future<void> refreshPlanner({bool force = false}) async {
    imageRefreshKey.value++;
    await Future.wait([
      loadRecommendations(force: force),
      loadWeek(force: force),
    ]);
  }

  Future<void> setHealthGoal(MealPlannerHealthGoal goal) async {
    if (healthGoal.value == goal) return;
    healthGoal.value = goal;
    try {
      final goalKey = await _userScopedKey(_storageHealthGoalKey);
      await _storage.write(key: goalKey, value: goal.apiValue);
    } catch (_) {}
    await loadRecommendations(force: true);
  }

  Future<void> applyBmiWeightDirection(String direction) async {
    final goal = switch (direction.toUpperCase()) {
      'GAIN' => MealPlannerHealthGoal.gainWeight,
      'LOSE' => MealPlannerHealthGoal.loseWeight,
      _ => MealPlannerHealthGoal.maintainHealth,
    };
    await setHealthGoal(goal);
  }

  Future<void> setDietaryPreferences(
    MealPlannerDietaryPreferences preferences,
  ) async {
    dietaryPreferences.value = preferences;
    try {
      final key = await _userScopedKey(_storageDietaryPreferencesKey);
      await _storage.write(key: key, value: jsonEncode(preferences.toJson()));
    } catch (_) {
      // The current selection remains usable even if secure storage is unavailable.
    }
  }

  Future<void> loadRecommendations({bool force = false}) async {
    if (_provider == null || (!force && isLoadingRecommendations.value)) return;
    isLoadingRecommendations.value = true;
    recommendationsError.value = '';
    try {
      adminRecommendations.assignAll(
        await _provider.getRecommendations(goal: healthGoal.value),
      );
    } catch (_) {
      adminRecommendations.clear();
      recommendationsError.value = 'planner.recommendations_error'.tr;
    } finally {
      isLoadingRecommendations.value = false;
      hasLoadedRecommendationsOnce.value = true;
    }
  }

  Future<void> loadWeek({bool force = false}) async {
    if (_provider == null || (!force && isLoading.value)) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      List<PlannedMeal> meals;
      try {
        meals = await _provider.getRange(
          start: planStartDate,
          end: planEndDate,
          days: planDaysCount.value,
        );
      } catch (_) {
        final mondays =
            planDays.map((d) {
              final day = DateTime(d.year, d.month, d.day);
              return day.subtract(Duration(days: day.weekday - 1));
            }).toSet();
        meals = [];
        for (final monday in mondays) {
          meals.addAll(await _provider.getWeek(monday));
        }
      }
      final newPlans = <String, List<PlannedMeal>>{};
      for (final day in planDays) {
        newPlans[_dateKey(day)] = <PlannedMeal>[];
      }
      for (final meal in meals) {
        final date = meal.planDate;
        if (date != null) {
          final key = _dateKey(date);
          final existing = newPlans[key] ?? const [];
          if (!existing.any(
            (m) =>
                (m.planId != null && m.planId == meal.planId) ||
                (m.slot == meal.slot && m.id == meal.id),
          )) {
            newPlans[key] = [...existing, meal];
          }
        }
      }
      plans.addAll(newPlans);
    } catch (_) {
      errorMessage.value = 'planner.load_error'.tr;
    } finally {
      isLoading.value = false;
      hasLoadedOnce.value = true;
    }
  }

  Future<void> loadPlan({bool force = false}) => loadWeek(force: force);

  Future<void> selectDay(int index, {bool force = false}) async {
    if (index >= 0 && index < planDays.length) {
      selectedDayIndex.value = index;
      await loadWaterIntake(selectedDate);
      await loadDayMeals(selectedDate, force: force);
    }
  }

  Future<void> loadDayMeals(DateTime date, {bool force = false}) async {
    if (_provider == null) return;
    final key = _dateKey(date);
    if (!force && plans.containsKey(key) && plans[key]!.isNotEmpty) {
      return;
    }
    isLoadingDay.value = true;
    try {
      final dayMeals = await _provider.getDay(date);
      plans[key] = dayMeals;
      final dayRecs = await _provider.getRecommendations(
        date: date,
        goal: healthGoal.value,
      );
      if (dayRecs.isNotEmpty) {
        for (final rec in dayRecs) {
          if (!adminRecommendations.any(
            (m) => m.id == rec.id && m.slot == rec.slot,
          )) {
            adminRecommendations.add(rec);
          }
        }
      }
    } catch (_) {
      // Keep existing local plans if request fails
    } finally {
      isLoadingDay.value = false;
    }
  }

  void setPlanDaysCount(int count) {
    final clamped = count.clamp(3, 7);
    if (planDaysCount.value == clamped) return;
    planDaysCount.value = clamped;
    if (selectedDayIndex.value >= clamped) {
      selectedDayIndex.value = clamped - 1;
    }
    unawaited(_persistSettings());
    unawaited(loadWeek());
  }

  void changeWeek(int amount) {
    if (customStartDate.value != null) {
      customStartDate.value = customStartDate.value!.add(
        Duration(days: amount * planDaysCount.value),
      );
    } else {
      weekOffset.value += amount;
    }
    selectedDayIndex.value = 0;
    unawaited(_persistSettings());
    unawaited(loadWeek());
  }

  Future<void> syncToToday({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (customStartDate.value != null) {
      final start = customStartDate.value!;
      final end = start.add(Duration(days: planDaysCount.value - 1));
      final containsToday = !today.isBefore(start) && !today.isAfter(end);
      // Expired ranges should return to the live week. Future ranges are an
      // intentional planning choice and must survive app resume/restart.
      if (end.isBefore(today)) {
        customStartDate.value = null;
        planDaysCount.value = 7;
        unawaited(() async {
          try {
            final startKey = await _userScopedKey(_storageStartDateKey);
            final daysKey = await _userScopedKey(_storageDaysKey);
            await _storage.delete(key: startKey);
            await _storage.write(key: daysKey, value: '7');
          } catch (_) {}
        }());
      } else if (!containsToday) {
        selectedDayIndex.value = selectedDayIndex.value.clamp(
          0,
          planDaysCount.value - 1,
        );
        imageRefreshKey.value++;
        await loadWaterIntake(selectedDate);
        if (forceRefresh || !hasLoadedOnce.value) {
          await refreshPlanner(force: true);
          await loadDayMeals(selectedDate, force: true);
        }
        return;
      }
    }
    weekOffset.value = 0;
    final idx = planDays.indexWhere(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
    selectedDayIndex.value =
        idx >= 0 ? idx : (today.weekday - 1).clamp(0, planDaysCount.value - 1);
    imageRefreshKey.value++;
    await loadWaterIntake(selectedDate);
    if (forceRefresh || !hasLoadedOnce.value) {
      await refreshPlanner(force: true);
      await loadDayMeals(selectedDate, force: true);
    }
  }

  void goToToday({bool resetCustomRange = true}) {
    if (resetCustomRange && customStartDate.value != null) {
      customStartDate.value = null;
      planDaysCount.value = 7;
      unawaited(() async {
        try {
          final startKey = await _userScopedKey(_storageStartDateKey);
          final daysKey = await _userScopedKey(_storageDaysKey);
          await _storage.delete(key: startKey);
          await _storage.write(key: daysKey, value: '7');
        } catch (_) {}
      }());
    }
    weekOffset.value = 0;
    unawaited(syncToToday(forceRefresh: true));
  }

  void goToDate(DateTime target) {
    final normalized = DateTime(target.year, target.month, target.day);
    if (planDaysCount.value == 7 && customStartDate.value == null) {
      final today = DateTime.now();
      final currentMonday = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: today.weekday - 1));
      final targetMonday = normalized.subtract(
        Duration(days: normalized.weekday - 1),
      );
      final diffWeeks =
          (targetMonday.difference(currentMonday).inDays / 7).round();
      final changed = weekOffset.value != diffWeeks;
      weekOffset.value = diffWeeks;
      selectedDayIndex.value = normalized.weekday - 1;
      unawaited(loadWaterIntake(selectedDate));
      if (changed) {
        unawaited(loadWeek());
      }
    } else {
      final targetIndex = planDays.indexWhere(
        (d) =>
            d.year == normalized.year &&
            d.month == normalized.month &&
            d.day == normalized.day,
      );
      if (targetIndex >= 0) {
        selectedDayIndex.value = targetIndex;
        unawaited(loadWaterIntake(selectedDate));
      } else {
        customStartDate.value = normalized;
        selectedDayIndex.value = 0;
        unawaited(loadWaterIntake(selectedDate));
        unawaited(_persistSettings());
        unawaited(loadWeek());
      }
    }
  }

  void setCustomPlanRange({required DateTime start, int? days}) {
    customStartDate.value = DateTime(start.year, start.month, start.day);
    if (days != null) {
      planDaysCount.value = days.clamp(3, 7);
    }
    selectedDayIndex.value = 0;
    unawaited(_persistSettings());
    unawaited(loadWeek());
  }

  Future<void> _persistSettings() async {
    try {
      final daysKey = await _userScopedKey(_storageDaysKey);
      final startKey = await _userScopedKey(_storageStartDateKey);

      await _storage.write(key: daysKey, value: '${planDaysCount.value}');
      if (customStartDate.value != null) {
        await _storage.write(
          key: startKey,
          value: customStartDate.value!.toIso8601String(),
        );
      } else {
        await _storage.delete(key: startKey);
      }
    } catch (_) {
      // Secure storage write error ignored
    }
  }

  Future<bool> addMeal(
    PlannedMeal meal, {
    double servings = 1,
    MealPlanSlot? targetSlot,
  }) async {
    if (isSaving.value) return false;
    final slotToUse = targetSlot ?? meal.slot;
    final key = _dateKey(selectedDate);
    final previous = List<PlannedMeal>.from(plans[key] ?? const []);
    final mealWithSlot = meal.copyWith(
      slot: slotToUse,
      planDate: selectedDate,
      servings: servings,
    );
    _put(key, mealWithSlot);
    if (_provider == null) return true;
    isSaving.value = true;
    try {
      final saved = await _provider.saveMeal(
        selectedDate,
        mealWithSlot,
        servings,
        goal: healthGoal.value,
      );
      _put(key, saved.copyWith(slot: slotToUse));
      return true;
    } catch (_) {
      plans[key] = previous;
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> replaceMeal(
    PlannedMeal current,
    PlannedMeal replacement, {
    double servings = 1,
  }) async {
    if (isSaving.value) return false;
    final provider = _provider;
    final planId = current.planId;
    final slotToUse = current.slot;
    final repWithSlot = replacement.copyWith(slot: slotToUse);
    if (provider == null || planId == null) {
      return addMeal(repWithSlot, servings: servings, targetSlot: slotToUse);
    }
    isSaving.value = true;
    try {
      final saved = await provider.updateMeal(
        planId,
        mealId: replacement.id,
        servings: servings,
        goal: healthGoal.value,
      );
      final key = _dateKey(selectedDate);
      final updated = List<PlannedMeal>.from(plans[key] ?? const [])
        ..removeWhere((m) => m.slot == slotToUse || m.planId == planId);
      final finalMeal = saved.copyWith(slot: slotToUse);
      updated.add(finalMeal);
      updated.sort((a, b) => a.slot.index.compareTo(b.slot.index));
      plans[key] = updated;
      return true;
    } catch (_) {
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<AiMealRecommendationResult?> getAiMealRecommendation({
    required MealPlanSlot slot,
    DateTime? date,
    PlannedMeal? currentMeal,
    String? actionType,
  }) async {
    if (_provider == null) return null;
    final targetDate = date ?? selectedDate;
    final act = actionType ?? (currentMeal != null ? 'SWAP' : 'ADD');
    try {
      isRecommendingMeal.value = true;
      final result = await _provider.recommendMeal(
        date: targetDate,
        slot: slot,
        goal: healthGoal.value,
        preferences: dietaryPreferences.value,
        currentMealId: currentMeal?.id,
        actionType: act,
      );
      return result;
    } catch (e) {
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.ai_recommendation_error'.tr,
      );
      return null;
    } finally {
      isRecommendingMeal.value = false;
    }
  }

  Future<bool> moveMeal(PlannedMeal meal, DateTime target) async {
    if (isSaving.value) return false;
    final oldKey = _dateKey(meal.planDate ?? selectedDate),
        newKey = _dateKey(target);
    if (oldKey == newKey) return true;
    final oldPlans = List<PlannedMeal>.from(plans[oldKey] ?? const []),
        targetPlans = List<PlannedMeal>.from(plans[newKey] ?? const []);
    plans[oldKey] = oldPlans.where((m) => m.slot != meal.slot).toList();
    _put(newKey, meal.copyWith(planDate: target));
    final provider = _provider;
    final planId = meal.planId;
    if (provider == null || planId == null) return true;
    isSaving.value = true;
    try {
      _put(newKey, await provider.updateMeal(planId, date: target));
      return true;
    } catch (_) {
      plans[oldKey] = oldPlans;
      plans[newKey] = targetPlans;
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> changeServing(PlannedMeal meal, double servings) async {
    if (isSaving.value) return;
    final key = _dateKey(meal.planDate ?? selectedDate);
    _put(key, meal.copyWith(servings: servings));
    final provider = _provider;
    final planId = meal.planId;
    if (provider == null || planId == null) return;
    isSaving.value = true;
    try {
      _put(key, await provider.updateMeal(planId, servings: servings));
    } catch (_) {
      _put(key, meal);
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> changeStatus(PlannedMeal meal, MealPlanStatus status) async {
    if (isSaving.value || meal.status == status) return;
    final isMarkingEaten =
        status == MealPlanStatus.eaten && meal.status != MealPlanStatus.eaten;
    final isMarkingSkipped =
        status == MealPlanStatus.skipped &&
        meal.status != MealPlanStatus.skipped;
    final nutritionDirection =
        isMarkingEaten
            ? 1.0
            : (meal.status == MealPlanStatus.eaten ? -1.0 : 0.0);
    final nutritionServings =
        meal.status == MealPlanStatus.eaten
            ? (meal.actualServings ?? meal.servings)
            : meal.servings;
    final mealDate = meal.planDate ?? selectedDate;
    final key = _dateKey(meal.planDate ?? selectedDate);
    final updated = meal.copyWith(
      status: status,
      completedAt: status == MealPlanStatus.eaten ? DateTime.now() : null,
      actualServings: status == MealPlanStatus.eaten ? meal.servings : null,
      clearCompletedAt: status != MealPlanStatus.eaten,
      clearActualServings: status != MealPlanStatus.eaten,
    );
    _put(key, updated);
    _applyWellnessDelta(
      meal,
      date: mealDate,
      servings: nutritionServings,
      direction: nutritionDirection,
    );

    if (isMarkingEaten) {
      HapticFeedback.lightImpact();
      AppAlert.toast(message: 'planner.meal_marked_eaten'.tr);
    } else if (isMarkingSkipped) {
      HapticFeedback.selectionClick();
      AppAlert.toast(message: 'planner.meal_marked_skipped'.tr);
    }

    final provider = _provider;
    final planId = meal.planId;
    if (provider == null || planId == null) return;
    isSaving.value = true;
    try {
      _put(
        key,
        await provider.updateMeal(
          planId,
          status: status,
          actualServings: status == MealPlanStatus.eaten ? meal.servings : null,
        ),
      );
      await _refreshNutritionViews(meal.planDate ?? selectedDate);
    } catch (_) {
      _put(key, meal);
      _applyWellnessDelta(
        meal,
        date: mealDate,
        servings: nutritionServings,
        direction: -nutritionDirection,
      );
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _applyWellnessDelta(
    PlannedMeal meal, {
    required DateTime date,
    required double servings,
    required double direction,
  }) {
    if (direction == 0 || !Get.isRegistered<WellnessController>()) return;
    Get.find<WellnessController>().applyMealNutritionDelta(
      date: date,
      calories: meal.calories * servings * direction,
      protein: meal.proteinGrams * servings * direction,
      carbs: meal.carbsGrams * servings * direction,
      fat: meal.fatGrams * servings * direction,
    );
  }

  Future<void> removeMeal(MealPlanSlot slot) async {
    if (isSaving.value) return;
    final key = _dateKey(selectedDate), meal = mealFor(slot);
    if (meal == null) return;
    plans[key] = List<PlannedMeal>.from(plans[key] ?? const [])
      ..removeWhere((m) => m.slot == slot);
    final provider = _provider;
    final planId = meal.planId;
    if (provider == null || planId == null) return;
    isSaving.value = true;
    try {
      await provider.deleteMeal(planId);
      await _refreshNutritionViews(meal.planDate ?? selectedDate);
    } catch (_) {
      _put(key, meal);
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _refreshNutritionViews(DateTime date) async {
    if (Get.isRegistered<WellnessController>()) {
      final wellness = Get.find<WellnessController>();
      if (_dateKey(wellness.selectedDate.value) == _dateKey(date)) {
        await wellness.loadDailyWellness();
      }
    }
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (_dateKey(home.selectedDay.value) == _dateKey(date)) {
        await home.loadDashboard();
      }
    }
  }

  Future<void> resetAllMealsToPlanned({bool currentDayOnly = true}) async {
    final dates = currentDayOnly ? [selectedDate] : planDays;
    final mealsToReset = <PlannedMeal>[];
    final backup = <String, List<PlannedMeal>>{};

    for (final d in dates) {
      final key = _dateKey(d);
      final dayMeals = mealsFor(d);
      backup[key] = List<PlannedMeal>.from(plans[key] ?? const []);
      for (final m in dayMeals) {
        if (m.status != MealPlanStatus.planned) {
          mealsToReset.add(m);
          final updated = m.copyWith(
            status: MealPlanStatus.planned,
            planDate: m.planDate ?? d,
            clearCompletedAt: true,
            clearActualServings: true,
          );
          _put(key, updated);
        }
      }
    }

    if (mealsToReset.isEmpty) {
      AppAlert.toast(message: 'planner.all_meals_already_planned'.tr);
      return;
    }

    plans.refresh();
    HapticFeedback.lightImpact();
    AppAlert.toast(message: 'planner.all_meals_reset_planned'.tr);

    final provider = _provider;
    if (provider == null) return;
    isSaving.value = true;
    try {
      final planIds = mealsToReset
          .map((meal) => meal.planId)
          .whereType<int>()
          .toList(growable: false);
      if (planIds.isNotEmpty) {
        final savedMeals = await provider.updateMealStatuses(
          planIds,
          MealPlanStatus.planned,
        );
        for (final saved in savedMeals) {
          final date = saved.planDate;
          if (date != null) {
            _put(_dateKey(date), saved);
          }
        }
      }
    } catch (_) {
      for (final entry in backup.entries) {
        plans[entry.key] = entry.value;
      }
      plans.refresh();
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> clearAllMeals({bool currentDayOnly = true}) async {
    final dates = currentDayOnly ? [selectedDate] : planDays;
    final mealsToDelete = <PlannedMeal>[];
    for (final d in dates) {
      mealsToDelete.addAll(mealsFor(d));
    }
    if (mealsToDelete.isEmpty) return;

    final backup = <String, List<PlannedMeal>>{};
    for (final d in dates) {
      final k = _dateKey(d);
      backup[k] = List<PlannedMeal>.from(plans[k] ?? const []);
      plans[k] = [];
    }
    plans.refresh();
    if (!currentDayOnly) {
      hasAnalyzedWeightLoss.value = false;
      hasAnalyzedMaintainHealth.value = false;
      lastWeightLossResult.value = null;
      lastMaintainHealthResult.value = null;
      lastAiAutoFillResult.value = null;
      unawaited(_persistAnalyzedGoals());
    }
    HapticFeedback.mediumImpact();
    AppAlert.toast(message: 'planner.all_meals_cleared'.tr);

    final provider = _provider;
    if (provider == null) return;
    isSaving.value = true;
    try {
      final planIds = mealsToDelete
          .map((meal) => meal.planId)
          .whereType<int>()
          .toList(growable: false);
      if (planIds.isNotEmpty) {
        await provider.deleteMeals(planIds);
      }
    } catch (_) {
      for (final entry in backup.entries) {
        plans[entry.key] = entry.value;
      }
      plans.refresh();
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
    } finally {
      isSaving.value = false;
    }
  }

  PlannedMeal? mealFor(MealPlanSlot slot) {
    for (final meal in selectedMeals) {
      if (meal.slot == slot) return meal;
    }
    return null;
  }

  DateTime get yesterdayDate => selectedDate.subtract(const Duration(days: 1));
  List<PlannedMeal> get yesterdayMeals => mealsFor(yesterdayDate);

  PlannedMeal? yesterdayMealFor(
    MealPlanSlot slot, {
    MealPlanSlot? fallbackSlot,
  }) {
    final dayMeals = yesterdayMeals;
    for (final m in dayMeals) {
      if (m.slot == slot) return m;
    }
    if (fallbackSlot != null) {
      for (final m in dayMeals) {
        if (m.slot == fallbackSlot) return m;
      }
    }
    return null;
  }

  Future<bool> copyFromYesterday(
    MealPlanSlot targetSlot, {
    MealPlanSlot? fromSlot,
  }) async {
    final sourceSlot = fromSlot ?? targetSlot;
    final sourceMeal = yesterdayMealFor(sourceSlot);
    if (sourceMeal == null) return false;
    final newMeal = sourceMeal.copyWith(
      slot: targetSlot,
      planDate: selectedDate,
      status: MealPlanStatus.planned,
      clearCompletedAt: true,
      clearActualServings: true,
    );
    final ok = await addMeal(
      newMeal,
      servings: sourceMeal.servings,
      targetSlot: targetSlot,
    );
    if (ok) {
      HapticFeedback.lightImpact();
      AppAlert.toast(
        message: 'planner.copied_yesterday_success'.trParams({
          'slot': targetSlot.labelKey.tr,
          'meal': sourceMeal.name,
        }),
      );
    }
    return ok;
  }

  Future<bool> copyAllFromYesterday() async {
    final sourceMeals = yesterdayMeals;
    if (sourceMeals.isEmpty) {
      AppAlert.toast(message: 'planner.no_yesterday_meals'.tr);
      return false;
    }
    if (isSaving.value) return false;
    var anyCopied = false;
    for (final meal in sourceMeals) {
      final copy = meal.copyWith(
        slot: meal.slot,
        planDate: selectedDate,
        status: MealPlanStatus.planned,
        clearCompletedAt: true,
        clearActualServings: true,
      );
      final ok = await addMeal(
        copy,
        servings: meal.servings,
        targetSlot: meal.slot,
      );
      if (ok) anyCopied = true;
    }
    if (anyCopied) {
      HapticFeedback.mediumImpact();
      AppAlert.toast(message: 'planner.copied_all_yesterday_success'.tr);
    }
    return anyCopied;
  }

  // --- Water Intake Tracker ---
  Future<void> loadWaterIntake(DateTime date) async {
    if (_profileRepository != null) {
      try {
        final dashboard = await _profileRepository.getDashboard(date: date);
        dailyWaterGlasses.value = (dashboard.water?.current ?? 0).round().clamp(
          0,
          20,
        );
      } catch (_) {
        // Keep the last server value visible if refreshing fails.
      }
      return;
    }

    // Local fallback is only for isolated/offline controller usage. The app
    // injects ProfileRepository so Planner and Daily Wellness share one source.
    try {
      final baseKey = '${_storageWaterKey}_${_dateKey(date)}';
      final key = await _userScopedKey(baseKey);
      final saved = await _storage.read(key: key);
      if (saved != null) {
        dailyWaterGlasses.value = (int.tryParse(saved) ?? 0).clamp(0, 20);
      } else {
        dailyWaterGlasses.value = 0;
      }
    } catch (_) {
      dailyWaterGlasses.value = 0;
    }
  }

  Future<void> incrementWater() async {
    if (dailyWaterGlasses.value >= 20) return;
    if (_profileRepository != null) {
      final dashboard = await _profileRepository.addDailyNutrition(
        water: 1,
        date: selectedDate,
      );
      dailyWaterGlasses.value = (dashboard.water?.current ?? 0).round().clamp(
        0,
        20,
      );
      return;
    }
    dailyWaterGlasses.value++;
    HapticFeedback.lightImpact();
    await _persistWaterIntake();
    if (dailyWaterGlasses.value == dailyWaterGoalGlasses) {
      HapticFeedback.mediumImpact();
      AppAlert.toast(message: 'planner.water_goal_reached'.tr);
    }
  }

  Future<void> decrementWater() async {
    if (dailyWaterGlasses.value <= 0) return;
    dailyWaterGlasses.value--;
    HapticFeedback.selectionClick();
    await _persistWaterIntake();
  }

  Future<void> setWaterGlasses(int count) async {
    final clamped = count.clamp(0, 20);
    if (dailyWaterGlasses.value == clamped) return;
    dailyWaterGlasses.value = clamped;
    HapticFeedback.selectionClick();
    await _persistWaterIntake();
  }

  Future<void> _persistWaterIntake() async {
    try {
      final baseKey = '${_storageWaterKey}_${_dateKey(selectedDate)}';
      final key = await _userScopedKey(baseKey);
      await _storage.write(key: key, value: '${dailyWaterGlasses.value}');
    } catch (_) {}
  }

  Future<void> openWaterTracker() async {
    await Get.toNamed<void>(AppRoutes.water, arguments: selectedDate);
    await loadWaterIntake(selectedDate);
  }

  // --- Interactive Grocery Checklist ---
  Future<void> _loadGroceryCheckedState() async {
    try {
      final key = await _userScopedKey(_storageGroceryCheckedKey);
      final saved = await _storage.read(key: key);
      if (saved != null && saved.isNotEmpty) {
        final dynamic decoded = jsonDecode(saved);
        if (decoded is List) {
          checkedGroceryKeys.assignAll(decoded.map((e) => e.toString()));
        }
      }
    } catch (_) {}
  }

  Future<void> toggleGroceryItemChecked(String itemKey) async {
    if (checkedGroceryKeys.contains(itemKey)) {
      checkedGroceryKeys.remove(itemKey);
    } else {
      checkedGroceryKeys.add(itemKey);
    }
    checkedGroceryKeys.refresh();
    await _persistGroceryCheckedState();
  }

  Future<void> setAllGroceryChecked(
    Iterable<String> keys,
    bool isChecked,
  ) async {
    if (isChecked) {
      checkedGroceryKeys.addAll(keys);
    } else {
      checkedGroceryKeys.removeAll(keys);
    }
    checkedGroceryKeys.refresh();
    await _persistGroceryCheckedState();
  }

  Future<void> _persistGroceryCheckedState() async {
    try {
      final key = await _userScopedKey(_storageGroceryCheckedKey);
      await _storage.write(
        key: key,
        value: jsonEncode(checkedGroceryKeys.toList()),
      );
    } catch (_) {}
  }

  void putOptimisticMeal(PlannedMeal meal) {
    final key = _dateKey(meal.planDate ?? selectedDate);
    _put(key, meal);
  }

  void _put(String key, PlannedMeal meal) {
    final updated = List<PlannedMeal>.from(plans[key] ?? const [])..removeWhere(
      (m) =>
          m.slot == meal.slot ||
          (meal.planId != null && m.planId == meal.planId),
    );
    updated.add(meal);
    updated.sort((a, b) => a.slot.index.compareTo(b.slot.index));
    plans[key] = updated;
  }

  void applyAiAutoFillResult(
    AiAutoFillPlanResponse response, {
    bool fillEmptyOnly = true,
  }) {
    lastAiAutoFillResult.value = response;
    if (response.goal.toUpperCase() == 'LOSE_WEIGHT') {
      hasAnalyzedWeightLoss.value = true;
      lastWeightLossResult.value = response;
    } else {
      hasAnalyzedMaintainHealth.value = true;
      lastMaintainHealthResult.value = response;
    }
    unawaited(_persistAnalyzedGoals());

    if (!fillEmptyOnly) {
      for (final date in planDays) {
        plans[_dateKey(date)] = [];
      }
    }
    for (final saved in response.createdPlans) {
      final date = saved.planDate;
      if (date != null) {
        _put(_dateKey(date), saved);
      }
    }
    plans.refresh();
  }

  Future<void> _persistAnalyzedGoals() async {
    try {
      final lossKey = await _userScopedKey(_storageAnalyzedWeightLossKey);
      final maintainKey = await _userScopedKey(
        _storageAnalyzedMaintainHealthKey,
      );
      await _storage.write(
        key: lossKey,
        value: hasAnalyzedWeightLoss.value ? 'true' : 'false',
      );
      await _storage.write(
        key: maintainKey,
        value: hasAnalyzedMaintainHealth.value ? 'true' : 'false',
      );
    } catch (_) {}
  }

  Future<int> autoFillPlan({
    bool fillEmptyOnly = true,
    int? targetTimeframeDays,
  }) async {
    if (isSaving.value) return 0;

    lastAiAutoFillResult.value = null;

    if (healthGoal.value == MealPlannerHealthGoal.loseWeight &&
        dietaryPreferences.value.medicalFlags.contains(
          'PREGNANT_OR_BREASTFEEDING',
        )) {
      await AppAlert.actionError(
        title: 'planner.medical_review_required'.tr,
        message: 'planner.pregnancy_weight_loss_warning'.tr,
      );
      return 0;
    }

    isSaving.value = true;
    try {
      if (_provider != null) {
        try {
          final response = await _provider.aiAutoFillPlan(
            startDate: planStartDate,
            days: planDaysCount.value,
            goal: healthGoal.value,
            targetTimeframeDays: targetTimeframeDays ?? 28,
            fillEmptyOnly: fillEmptyOnly,
            preferences: dietaryPreferences.value,
          );
          applyAiAutoFillResult(response, fillEmptyOnly: fillEmptyOnly);

          if (response.filledCount > 0) {
            HapticFeedback.mediumImpact();
          } else {
            AppAlert.toast(message: 'planner.auto_fill_no_empty'.tr);
          }
          return response.filledCount;
        } catch (error) {
          if (error is MealPlannerProviderException &&
              error.statusCode == 400) {
            await AppAlert.actionError(
              title: 'planner.error'.tr,
              message: 'planner.restrictions_no_match'.tr,
            );
            return 0;
          }
          // Fall back to local slot filling if AI auto-fill endpoint errors
        }
      }

      // Offline / fallback algorithm
      if (adminRecommendations.isEmpty && _provider != null) {
        await loadRecommendations();
      }

      if (adminRecommendations.isEmpty) {
        AppAlert.toast(message: 'planner.auto_fill_no_recommendations'.tr);
        return 0;
      }

      final emptySlots = <({DateTime date, MealPlanSlot slot})>[];
      for (final date in planDays) {
        final currentMeals = mealsFor(date);
        final distinctMealKeys = <String>{};
        for (final slot in MealPlanSlot.values) {
          final planned = currentMeals.firstWhereOrNull((m) => m.slot == slot);
          final isDuplicate =
              planned != null && !distinctMealKeys.add(_mealIdentity(planned));
          if (planned == null || isDuplicate || !fillEmptyOnly) {
            emptySlots.add((date: date, slot: slot));
          }
        }
      }
      if (emptySlots.isEmpty) {
        AppAlert.toast(message: 'planner.auto_fill_no_empty'.tr);
        return 0;
      }

      final previousPlans = <String, List<PlannedMeal>>{
        for (final date in planDays)
          _dateKey(date): List<PlannedMeal>.from(
            plans[_dateKey(date)] ?? const [],
          ),
      };
      final recentUsage = <int, int>{};
      for (final meals in previousPlans.values) {
        for (final meal in meals) {
          recentUsage.update(meal.id, (count) => count + 1, ifAbsent: () => 1);
        }
      }
      final usedIdsByDate = <String, Set<int>>{
        for (final entry in previousPlans.entries)
          entry.key:
              fillEmptyOnly
                  ? entry.value.map((meal) => meal.id).toSet()
                  : <int>{},
      };
      var filledCount = 0;
      final bulkPayload = <Map<String, dynamic>>[];
      for (final entry in emptySlots) {
        final slotRecs =
            adminRecommendations
                .where(
                  (meal) =>
                      meal.slot == entry.slot &&
                      _matchesDietaryPreferences(meal),
                )
                .toList();
        if (slotRecs.isEmpty) continue;

        final weekdayRecs =
            slotRecs
                .where(
                  (m) =>
                      m.recommendedWeekday == null ||
                      m.recommendedWeekday == entry.date.weekday,
                )
                .toList();
        final pool = weekdayRecs.isNotEmpty ? weekdayRecs : slotRecs;

        final dayDiff = entry.date.difference(planStartDate).inDays.abs();
        final key = _dateKey(entry.date);
        final usedToday = usedIdsByDate.putIfAbsent(key, () => <int>{});
        var eligible =
            pool.where((meal) => !usedToday.contains(meal.id)).toList();
        if (eligible.isEmpty) eligible = pool;

        final fresh =
            eligible.where((meal) => (recentUsage[meal.id] ?? 0) == 0).toList();
        if (fresh.isNotEmpty) eligible = fresh;

        final minimumUsage = eligible
            .map((meal) => recentUsage[meal.id] ?? 0)
            .reduce((a, b) => a < b ? a : b);
        eligible =
            eligible
                .where((meal) => (recentUsage[meal.id] ?? 0) == minimumUsage)
                .toList();
        final rotationIndex =
            (dayDiff * MealPlanSlot.values.length + entry.slot.index) %
            eligible.length;
        final selectedRec = eligible[rotationIndex];

        final optimistic = selectedRec.copyWith(
          planDate: entry.date,
          slot: entry.slot,
          servings: 1,
        );
        _put(key, optimistic);
        usedToday.add(selectedRec.id);
        recentUsage.update(
          selectedRec.id,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        bulkPayload.add({
          'planDate': _dateKey(entry.date),
          'mealType': entry.slot.name.toUpperCase(),
          'plannerMealId': selectedRec.id,
          'servings': 1.0,
          'weightGoal': healthGoal.value.apiValue,
        });
        filledCount++;
      }

      if (_provider != null && bulkPayload.isNotEmpty) {
        try {
          final savedMeals = await _provider.saveBulkMeals(bulkPayload);
          for (final saved in savedMeals) {
            final date = saved.planDate;
            if (date != null) {
              _put(_dateKey(date), saved);
            }
          }
        } catch (_) {
          for (final entry in previousPlans.entries) {
            plans[entry.key] = entry.value;
          }
          plans.refresh();
          await AppAlert.actionError(
            title: 'planner.error'.tr,
            message: 'planner.save_error'.tr,
          );
          return 0;
        }
      }
      plans.refresh();

      if (filledCount == 0) {
        AppAlert.toast(message: 'planner.restrictions_no_match'.tr);
        return 0;
      }

      HapticFeedback.mediumImpact();
      return filledCount;
    } finally {
      isSaving.value = false;
    }
  }

  String formatGroceryListText({DateTime? date}) {
    final items = date == null ? groceryItems : groceryItemsForDate(date);
    if (items.isEmpty) return '';

    final buffer = StringBuffer();
    final dateRange =
        date == null
            ? '${DateFormat('d MMM').format(planStartDate)} – ${DateFormat('d MMM yyyy').format(planEndDate)}'
            : DateFormat('d MMM yyyy').format(date);

    buffer.writeln('🛒 ${'planner.grocery_list'.tr}');
    buffer.writeln(
      date == null
          ? '📅 $dateRange (${planDaysCount.value} ${'planner.days_short'.tr.trim()})'
          : '📅 $dateRange',
    );
    buffer.writeln('');

    final grouped = <String, List<GroceryItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    for (final entry in grouped.entries) {
      final categoryName = entry.key.tr;
      buffer.writeln('[$categoryName]');
      for (final item in entry.value) {
        final q = item.quantityLabel;
        if (q.isNotEmpty) {
          buffer.writeln('• ${item.name}: $q');
        } else {
          buffer.writeln('• ${item.name}');
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('🌿 NhamHealth Meal Planner');
    return buffer.toString().trim();
  }

  Future<bool> copyGroceryListToClipboard({DateTime? date}) async {
    final text = formatGroceryListText(date: date);
    if (text.isEmpty) {
      AppAlert.toast(message: 'planner.empty_grocery_list'.tr);
      return false;
    }
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    AppAlert.toast(message: 'planner.grocery_copied'.tr);
    return true;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _mealIdentity(PlannedMeal meal) {
    final normalizedName =
        meal.name
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
            .trim();
    return normalizedName.isEmpty ? 'meal-${meal.id}' : normalizedName;
  }

  String _groceryCategory(String value) {
    final name = value.toLowerCase();
    if (RegExp(r'milk|yogurt|cheese|cream').hasMatch(name)) {
      return 'planner.grocery_dairy';
    }
    if (RegExp(r'chicken|fish|egg|tofu|beef|pork|nut|cashew').hasMatch(name)) {
      return 'planner.grocery_protein';
    }
    if (RegExp(r'rice|oat|bread|noodle|flour').hasMatch(name)) {
      return 'planner.grocery_grains';
    }
    return 'planner.grocery_produce';
  }

  bool _matchesDietaryPreferences(PlannedMeal meal) {
    final preferences = dietaryPreferences.value;
    final searchable =
        <String>[
          meal.name,
          meal.category,
          meal.description,
          ...meal.ingredients,
          ...meal.tags,
        ].join(' ').toLowerCase();
    final prohibited = <String>[
      if (preferences.diet == MealPlannerDiet.vegetarian ||
          preferences.diet == MealPlannerDiet.vegan) ...[
        'beef',
        'pork',
        'chicken',
        'fish',
        'shrimp',
        'prawn',
        'meat',
        'សាច់',
        'ត្រី',
        'បង្គា',
      ],
      if (preferences.diet == MealPlannerDiet.vegan) ...[
        'egg',
        'milk',
        'cheese',
        'yogurt',
        'butter',
        'cream',
        'honey',
        'ស៊ុត',
        'ទឹកដោះ',
        'ឈីស',
        'យ៉ាអួ',
      ],
      if (preferences.medicalFlags.contains('DIABETES')) ...[
        'sugary drink',
        'sweetened',
        'syrup',
        'soda',
        'soft drink',
      ],
      if (preferences.medicalFlags.contains('HYPERTENSION')) ...[
        'high sodium',
        'salty',
        'bacon',
        'sausage',
        'processed meat',
      ],
      for (final allergen in preferences.allergens)
        ..._allergenSearchTerms(allergen),
      ...preferences.excludedIngredients,
    ];
    return prohibited
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .every((item) => !searchable.contains(item));
  }

  List<String> _allergenSearchTerms(String allergen) {
    return switch (allergen.trim().toLowerCase()) {
      'peanut' => const ['peanut', 'groundnut', 'សណ្តែកដី'],
      'milk' => const [
        'milk',
        'dairy',
        'cheese',
        'yogurt',
        'butter',
        'cream',
        'whey',
        'ទឹកដោះ',
        'ឈីស',
        'យ៉ាអួ',
      ],
      'egg' => const ['egg', 'ស៊ុត'],
      'wheat' => const ['wheat', 'flour', 'bread', 'pasta', 'ស្រូវសាលី'],
      'fish' => const ['fish', 'salmon', 'tuna', 'bass', 'ត្រី'],
      'shrimp' => const [
        'shrimp',
        'prawn',
        'shellfish',
        'crab',
        'lobster',
        'បង្គា',
        'ក្តាម',
      ],
      'soy' => const ['soy', 'soya', 'tofu', 'សណ្តែកសៀង', 'តៅហ៊ូ'],
      'tree nuts' => const [
        'almond',
        'walnut',
        'cashew',
        'pecan',
        'pistachio',
        'hazelnut',
        'macadamia',
        'tree nut',
      ],
      'sesame' => const ['sesame', 'tahini', 'ល្ង'],
      _ => [allergen],
    };
  }
}
