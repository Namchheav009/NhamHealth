import 'dart:async';

import 'package:get/get.dart';

import '../../models/planner/meal_plan.dart';
import '../../providers/planner/meal_planner_provider.dart';

class MealPlannerController extends GetxController {
  MealPlannerController({MealPlannerProvider? provider}) : _provider = provider;
  final MealPlannerProvider? _provider;
  final selectedDayIndex = 0.obs;
  final weekOffset = 0.obs;
  final plans = <String, List<PlannedMeal>>{}.obs;
  final adminRecommendations = <PlannedMeal>[].obs;
  final isLoading = false.obs;
  final isLoadingRecommendations = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final recommendationsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    selectedDayIndex.value = DateTime.now().weekday - 1;
    unawaited(refreshPlanner());
  }

  DateTime get weekStart {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return DateTime(
      monday.year,
      monday.month,
      monday.day,
    ).add(Duration(days: weekOffset.value * 7));
  }

  List<DateTime> get weekDays =>
      List.generate(7, (index) => weekStart.add(Duration(days: index)));
  DateTime get selectedDate => weekDays[selectedDayIndex.value];
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
  Iterable<PlannedMeal> get _currentWeekMeals =>
      weekDays.expand((date) => mealsFor(date));
  int get weeklyMealCount => _currentWeekMeals.length;
  double get weeklyProgress => weeklyMealCount / 28;
  bool get weekIsEmpty => weeklyMealCount == 0;

  List<GroceryItem> get groceryItems {
    final combined = <String, GroceryItem>{};
    for (final meal in _currentWeekMeals) {
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
    final curated =
        adminRecommendations
            .where(
              (meal) =>
                  meal.slot == slot &&
                  (meal.recommendedWeekday == null ||
                      meal.recommendedWeekday == selectedDate.weekday),
            )
            .toList();
    return curated;
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
    final values = categories.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
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
      final meals = await _provider.getWeek(weekStart);
      for (final day in weekDays) {
        plans.remove(_dateKey(day));
      }
      for (final meal in meals) {
        final date = meal.planDate;
        if (date != null) {
          plans[_dateKey(date)] = [...plans[_dateKey(date)] ?? const [], meal];
        }
      }
    } catch (_) {
      errorMessage.value = 'planner.load_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  void selectDay(int index) => selectedDayIndex.value = index;
  void changeWeek(int amount) {
    weekOffset.value += amount;
    selectedDayIndex.value = 0;
    unawaited(loadWeek());
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
      Get.snackbar('planner.error'.tr, 'planner.save_error'.tr);
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
      Get.snackbar('planner.error'.tr, 'planner.save_error'.tr);
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
