import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../widgets/app_alert.dart';
import '../../models/planner/meal_plan.dart';
import '../../providers/planner/meal_planner_provider.dart';

class MealPlannerController extends GetxController {
  MealPlannerController({
    MealPlannerProvider? provider,
    FlutterSecureStorage? storage,
  }) : _provider = provider,
       _storage = storage ?? const FlutterSecureStorage();

  static const _storageDaysKey = 'meal_planner_days_count';
  static const _storageStartDateKey = 'meal_planner_start_date';

  final MealPlannerProvider? _provider;
  final FlutterSecureStorage _storage;
  final selectedDayIndex = 0.obs;
  final weekOffset = 0.obs;
  final planDaysCount = 7.obs;
  final customStartDate = Rxn<DateTime>();
  final plans = <String, List<PlannedMeal>>{}.obs;
  final adminRecommendations = <PlannedMeal>[].obs;
  final isLoading = false.obs;
  final isLoadingRecommendations = false.obs;
  final isLoadingDay = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final recommendationsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    selectedDayIndex.value = DateTime.now().weekday - 1;
    unawaited(refreshPlanner());
    unawaited(_initPlanner());
  }

  Future<void> _initPlanner() async {
    try {
      final savedDays = await _storage.read(key: _storageDaysKey);
      if (savedDays != null) {
        final parsed = int.tryParse(savedDays);
        if (parsed != null && parsed >= 3 && parsed <= 7) {
          planDaysCount.value = parsed;
        }
      }
      final savedStart = await _storage.read(key: _storageStartDateKey);
      if (savedStart != null) {
        final parsedDate = DateTime.tryParse(savedStart);
        if (parsedDate != null) {
          customStartDate.value = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
          );
        }
      }
    } catch (_) {
      // Secure storage read error ignored
    }
    if (selectedDayIndex.value >= planDaysCount.value) {
      selectedDayIndex.value = 0;
    }
    await refreshPlanner();
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
  int get completedSlots =>
      selectedMeals.map((meal) => meal.slot).toSet().length;
  int get eatenMeals =>
      selectedMeals.where((meal) => meal.status == MealPlanStatus.eaten).length;
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
  double get planProgress =>
      planMealCount / (planDaysCount.value * dailyMealGoal);
  bool get planIsEmpty => planMealCount == 0;

  int get weeklyMealCount => planMealCount;
  double get weeklyProgress => planProgress;
  bool get weekIsEmpty => planIsEmpty;

  List<GroceryItem> get groceryItems {
    final combined = <String, GroceryItem>{};
    for (final meal in _currentPlanMeals) {
      final ingredients =
          meal.ingredientDetails.isEmpty
              ? meal.ingredients.map((name) => PlannerIngredient(name: name))
              : meal.ingredientDetails;
      for (final ingredient in ingredients) {
        final key =
            '${ingredient.name.toLowerCase()}|${ingredient.unit.toLowerCase()}';
        final old = combined[key];
        combined[key] = GroceryItem(
          name: ingredient.name,
          unit: ingredient.unit,
          quantity: (old?.quantity ?? 0) + ingredient.quantity * meal.servings,
          category: _groceryCategory(ingredient.name),
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

  List<PlannerMealCategory> categoriesFor(MealPlanSlot slot) {
    final categories = <int, PlannerMealCategory>{};
    for (final meal in suggestionsFor(slot)) {
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
    final values =
        categories.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  Future<void> refreshPlanner() async =>
      Future.wait([loadRecommendations(), loadWeek()]);

  Future<void> loadRecommendations() async {
    if (_provider == null || isLoadingRecommendations.value) return;
    isLoadingRecommendations.value = true;
    recommendationsError.value = '';
    try {
      adminRecommendations.assignAll(await _provider.getRecommendations());
    } catch (_) {
      adminRecommendations.clear();
      recommendationsError.value = 'planner.recommendations_error'.tr;
    } finally {
      isLoadingRecommendations.value = false;
    }
  }

  Future<void> loadWeek() async {
    if (_provider == null || isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      for (final day in planDays) {
        plans.remove(_dateKey(day));
        plans[_dateKey(day)] = <PlannedMeal>[];
      }
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
      for (final meal in meals) {
        final date = meal.planDate;
        if (date != null) {
          final key = _dateKey(date);
          final existing = plans[key] ?? const [];
          if (!existing.any(
            (m) =>
                (m.planId != null && m.planId == meal.planId) ||
                (m.slot == meal.slot && m.id == meal.id),
          )) {
            plans[key] = [...existing, meal];
          }
        }
      }
    } catch (_) {
      errorMessage.value = 'planner.load_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPlan() => loadWeek();

  Future<void> selectDay(int index, {bool force = false}) async {
    if (index >= 0 && index < planDays.length) {
      selectedDayIndex.value = index;
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
      final dayRecs = await _provider.getRecommendations(date: date);
      if (dayRecs.isNotEmpty) {
        for (final rec in dayRecs) {
          if (!adminRecommendations.any((m) => m.id == rec.id)) {
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

  void goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    customStartDate.value = null;
    weekOffset.value = 0;
    unawaited(_storage.delete(key: _storageStartDateKey));
    final idx = planDays.indexWhere(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );
    selectedDayIndex.value = idx >= 0 ? idx : 0;
    unawaited(loadWeek());
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
      if (changed) {
        unawaited(loadWeek());
      }
    } else {
      customStartDate.value = normalized;
      selectedDayIndex.value = 0;
      unawaited(_persistSettings());
      unawaited(loadWeek());
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
      await _storage.write(
        key: _storageDaysKey,
        value: '${planDaysCount.value}',
      );
      if (customStartDate.value != null) {
        await _storage.write(
          key: _storageStartDateKey,
          value: customStartDate.value!.toIso8601String(),
        );
      } else {
        await _storage.delete(key: _storageStartDateKey);
      }
    } catch (_) {
      // Secure storage write error ignored
    }
  }

  Future<bool> addMeal(PlannedMeal meal, {double servings = 1}) async {
    if (isSaving.value) return false;
    final key = _dateKey(selectedDate);
    final previous = List<PlannedMeal>.from(plans[key] ?? const []);
    final optimistic = meal.copyWith(
      planDate: selectedDate,
      servings: servings,
    );
    _put(key, optimistic);
    if (_provider == null) return true;
    isSaving.value = true;
    try {
      _put(key, await _provider.saveMeal(selectedDate, meal, servings));
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
    final provider = _provider;
    final planId = current.planId;
    if (provider == null || planId == null) {
      return addMeal(replacement, servings: servings);
    }
    isSaving.value = true;
    try {
      final saved = await provider.updateMeal(
        planId,
        mealId: replacement.id,
        servings: servings,
      );
      _put(_dateKey(selectedDate), saved);
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

  Future<bool> moveMeal(PlannedMeal meal, DateTime target) async {
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
    try {
      _put(newKey, await provider.updateMeal(planId, date: target));
      return true;
    } catch (_) {
      plans[oldKey] = oldPlans;
      plans[newKey] = targetPlans;
      return false;
    }
  }

  Future<void> changeServing(PlannedMeal meal, double servings) async {
    final key = _dateKey(meal.planDate ?? selectedDate);
    _put(key, meal.copyWith(servings: servings));
    final provider = _provider;
    final planId = meal.planId;
    if (provider == null || planId == null) return;
    try {
      _put(key, await provider.updateMeal(planId, servings: servings));
    } catch (_) {
      _put(key, meal);
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
    }
  }

  Future<void> changeStatus(PlannedMeal meal, MealPlanStatus status) async {
    if (isSaving.value || meal.status == status) return;
    final key = _dateKey(meal.planDate ?? selectedDate);
    final updated = meal.copyWith(
      status: status,
      completedAt: status == MealPlanStatus.eaten ? DateTime.now() : null,
      actualServings: status == MealPlanStatus.eaten ? meal.servings : null,
      clearCompletedAt: status != MealPlanStatus.eaten,
      clearActualServings: status != MealPlanStatus.eaten,
    );
    _put(key, updated);
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

  Future<void> removeMeal(MealPlanSlot slot) async {
    final key = _dateKey(selectedDate), meal = mealFor(slot);
    if (meal == null) return;
    plans[key] = List<PlannedMeal>.from(plans[key] ?? const [])
      ..removeWhere((m) => m.slot == slot);
    final provider = _provider;
    final planId = meal.planId;
    if (provider == null || planId == null) return;
    try {
      await provider.deleteMeal(planId);
    } catch (_) {
      _put(key, meal);
      await AppAlert.actionError(
        title: 'planner.error'.tr,
        message: 'planner.save_error'.tr,
      );
    }
  }

  PlannedMeal? mealFor(MealPlanSlot slot) {
    for (final meal in selectedMeals) {
      if (meal.slot == slot) return meal;
    }
    return null;
  }

  void _put(String key, PlannedMeal meal) {
    final updated = List<PlannedMeal>.from(plans[key] ?? const [])
      ..removeWhere((m) => m.slot == meal.slot);
    updated.add(meal);
    updated.sort((a, b) => a.slot.index.compareTo(b.slot.index));
    plans[key] = updated;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
}
