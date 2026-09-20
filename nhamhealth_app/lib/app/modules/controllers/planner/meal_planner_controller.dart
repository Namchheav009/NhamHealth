import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import '../../models/planner/meal_plan.dart';
import '../../providers/planner/meal_planner_provider.dart';

class MealPlannerController extends GetxController {
  MealPlannerController({
    MealPlannerProvider? provider,
    FlutterSecureStorage? storage,
    AuthService? authService,
  }) : _provider = provider,
       _storage = storage ?? const FlutterSecureStorage(),
       _authService = authService {
    if (provider == null) {
      isLoading.value = false;
      isLoadingRecommendations.value = false;
      hasLoadedOnce.value = true;
      hasLoadedRecommendationsOnce.value = true;
    }
  }

  static const _storageDaysKey = 'meal_planner_days_count';
  static const _storageStartDateKey = 'meal_planner_start_date';

  final MealPlannerProvider? _provider;
  final FlutterSecureStorage _storage;
  final AuthService? _authService;
  final selectedDayIndex = 0.obs;
  final weekOffset = 0.obs;
  final planDaysCount = 7.obs;
  final customStartDate = Rxn<DateTime>();
  final plans = <String, List<PlannedMeal>>{}.obs;
  final adminRecommendations = <PlannedMeal>[].obs;
  final isLoading = true.obs;
  final isLoadingRecommendations = true.obs;
  final isLoadingDay = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final recommendationsError = ''.obs;
  final hasLoadedOnce = false.obs;
  final hasLoadedRecommendationsOnce = false.obs;
  final imageRefreshKey = 0.obs;

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
  }

  Future<void> initPlanner() => _initPlanner();

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
          }
        }
      }
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

  Future<void> loadRecommendations({bool force = false}) async {
    if (_provider == null || (!force && isLoadingRecommendations.value)) return;
    isLoadingRecommendations.value = true;
    recommendationsError.value = '';
    try {
      adminRecommendations.assignAll(await _provider.getRecommendations());
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

  Future<void> syncToToday({bool forceRefresh = false}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (customStartDate.value != null) {
      final end = customStartDate.value!.add(
        Duration(days: planDaysCount.value - 1),
      );
      if (end.isBefore(today)) {
        customStartDate.value = null;
        unawaited(() async {
          try {
            final startKey = await _userScopedKey(_storageStartDateKey);
            await _storage.delete(key: startKey);
          } catch (_) {}
        }());
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
    if (forceRefresh || !hasLoadedOnce.value) {
      await refreshPlanner(force: true);
      await loadDayMeals(selectedDate, force: true);
    }
  }

  void goToToday() {
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
    final isMarkingEaten =
        status == MealPlanStatus.eaten && meal.status != MealPlanStatus.eaten;
    final isMarkingSkipped =
        status == MealPlanStatus.skipped &&
        meal.status != MealPlanStatus.skipped;
    final key = _dateKey(meal.planDate ?? selectedDate);
    final updated = meal.copyWith(
      status: status,
      completedAt: status == MealPlanStatus.eaten ? DateTime.now() : null,
      actualServings: status == MealPlanStatus.eaten ? meal.servings : null,
      clearCompletedAt: status != MealPlanStatus.eaten,
      clearActualServings: status != MealPlanStatus.eaten,
    );
    _put(key, updated);

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
    final updated = List<PlannedMeal>.from(plans[key] ?? const [])..removeWhere(
      (m) =>
          m.slot == meal.slot ||
          (meal.planId != null && m.planId == meal.planId),
    );
    updated.add(meal);
    updated.sort((a, b) => a.slot.index.compareTo(b.slot.index));
    plans[key] = updated;
  }

  Future<int> autoFillPlan() async {
    if (isSaving.value) return 0;

    if (adminRecommendations.isEmpty && _provider != null) {
      await loadRecommendations();
    }

    if (adminRecommendations.isEmpty) {
      AppAlert.toast(message: 'planner.auto_fill_no_recommendations');
      return 0;
    }

    final emptySlots = <({DateTime date, MealPlanSlot slot})>[];
    for (final date in planDays) {
      final currentMeals = mealsFor(date);
      for (final slot in MealPlanSlot.values) {
        final alreadyPlanned = currentMeals.any((m) => m.slot == slot);
        if (!alreadyPlanned) {
          emptySlots.add((date: date, slot: slot));
        }
      }
    }

    if (emptySlots.isEmpty) {
      AppAlert.toast(message: 'planner.auto_fill_no_empty');
      return 0;
    }

    isSaving.value = true;
    var filledCount = 0;
    try {
      final bulkPayload = <Map<String, dynamic>>[];
      for (final entry in emptySlots) {
        final slotRecs =
            adminRecommendations.where((m) => m.slot == entry.slot).toList();
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
        final selectedRec = pool[dayDiff % pool.length];

        final key = _dateKey(entry.date);
        final optimistic = selectedRec.copyWith(
          planDate: entry.date,
          servings: 1,
        );
        _put(key, optimistic);
        bulkPayload.add({
          'planDate': _dateKey(entry.date),
          'mealType': entry.slot.name.toUpperCase(),
          'plannerMealId': selectedRec.id,
          'servings': 1.0,
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
          // Fallback to optimistic state if bulk network call fails
        }
      }
      plans.refresh();

      if (filledCount > 0) {
        HapticFeedback.mediumImpact();
        AppAlert.toast(
          message: 'planner.auto_fill_success'.trParams({
            'count': '$filledCount',
          }),
        );
      }
      return filledCount;
    } finally {
      isSaving.value = false;
    }
  }

  String formatGroceryListText() {
    final items = groceryItems;
    if (items.isEmpty) return '';

    final buffer = StringBuffer();
    final start = planStartDate;
    final end = planEndDate;
    final dateRange =
        '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}';

    buffer.writeln('🛒 ${'planner.grocery_list'.tr}');
    buffer.writeln(
      '📅 $dateRange (${planDaysCount.value} ${'planner.days_short'.tr.trim()})',
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

  Future<bool> copyGroceryListToClipboard() async {
    final text = formatGroceryListText();
    if (text.isEmpty) {
      AppAlert.toast(message: 'planner.empty_grocery_list');
      return false;
    }
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    AppAlert.toast(message: 'planner.grocery_copied');
    return true;
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
