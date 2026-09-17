import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/providers/planner/meal_planner_provider.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  MealPlannerController withAdminMeals() {
    final controller = MealPlannerController();
    final weekday = controller.selectedDate.weekday;
    controller.adminRecommendations.addAll([
      PlannedMeal(
        id: 101,
        name: 'Oatmeal with banana',
        calories: 360,
        proteinGrams: 12,
        carbsGrams: 54,
        slot: MealPlanSlot.breakfast,
        recommendedWeekday: weekday,
        ingredients: const ['Oats', 'Banana', 'Milk'],
        ingredientDetails: const [
          PlannerIngredient(name: 'Oats', quantity: 50, unit: 'g'),
          PlannerIngredient(name: 'Banana', quantity: 1),
          PlannerIngredient(name: 'Milk', quantity: 200, unit: 'ml'),
        ],
      ),
      PlannedMeal(
        id: 102,
        name: 'Egg toast',
        calories: 420,
        slot: MealPlanSlot.breakfast,
        recommendedWeekday: weekday,
        ingredients: const ['Eggs'],
      ),
      PlannedMeal(
        id: 103,
        name: 'Rice bowl',
        calories: 610,
        slot: MealPlanSlot.lunch,
        recommendedWeekday: weekday,
        ingredients: const ['Rice'],
      ),
      PlannedMeal(
        id: 104,
        name: 'Fish dinner',
        calories: 520,
        slot: MealPlanSlot.dinner,
        recommendedWeekday: controller.weekDays[1].weekday,
        ingredients: const ['Fish'],
      ),
    ]);
    return controller;
  }

  test(
    'planner keeps daily meals separate and builds a unique grocery list',
    () {
      final controller = withAdminMeals();

      final breakfast = controller.suggestionsFor(MealPlanSlot.breakfast).first;
      final lunch = controller.suggestionsFor(MealPlanSlot.lunch).first;
      controller.addMeal(breakfast);
      controller.addMeal(lunch);

      expect(controller.completedSlots, 2);
      expect(controller.selectedCalories, breakfast.calories + lunch.calories);
      expect(
        controller.groceryItems.map((item) => item.name),
        containsAll(breakfast.ingredients),
      );

      controller.selectDay(1);
      expect(controller.selectedMeals, isEmpty);

      final dinner = controller.suggestionsFor(MealPlanSlot.dinner).first;
      controller.addMeal(dinner);
      expect(controller.selectedMeals.single.id, dinner.id);
      expect(
        controller.groceryItems.map((item) => item.name),
        containsAll(dinner.ingredients),
      );
      expect(
        controller.groceryItems.map((item) => item.key).toSet().length,
        controller.groceryItems.length,
      );
    },
  );

  test('adding another meal in the same slot replaces the previous meal', () {
    final controller = withAdminMeals();
    final breakfasts = controller.suggestionsFor(MealPlanSlot.breakfast);

    controller.addMeal(breakfasts.first);
    controller.addMeal(breakfasts.last);

    expect(controller.selectedMeals.single.id, breakfasts.last.id);
    expect(controller.selectedCalories, breakfasts.last.calories);
  });

  test('admin recommendations take priority for their configured weekday', () {
    final controller = MealPlannerController();
    final weekday = controller.selectedDate.weekday;
    final curated = PlannedMeal(
      id: 99,
      name: 'Admin recommended meal',
      calories: 480,
      proteinGrams: 32,
      slot: MealPlanSlot.lunch,
      ingredients: const ['Rice', 'Fish'],
      recommendedWeekday: weekday,
    );

    controller.adminRecommendations.add(curated);

    expect(controller.suggestionsFor(MealPlanSlot.lunch), [curated]);
    expect(controller.suggestionsFor(MealPlanSlot.breakfast), isEmpty);
    controller.selectDay((controller.selectedDayIndex.value + 1) % 7);
    expect(controller.suggestionsFor(MealPlanSlot.lunch), isEmpty);
  });

  test('planner recommendation parses the admin API response', () {
    final meal = PlannedMeal.fromJson({
      'mealId': 42,
      'mealName': 'Grilled fish',
      'calories': 510.4,
      'proteinGrams': 38,
      'mealSlot': 'DINNER',
      'dayOfWeek': 'FRIDAY',
      'ingredients': ['Fish', 'Lime'],
      'imageUrl': '/uploads/fish.webp',
      'note': 'Recommended by the nutrition team',
    });

    expect(meal.id, 42);
    expect(meal.slot, MealPlanSlot.dinner);
    expect(meal.recommendedWeekday, DateTime.friday);
    expect(meal.ingredients, ['Fish', 'Lime']);
    expect(meal.recommendationNote, 'Recommended by the nutrition team');
  });

  test(
    'servings update nutrition and duplicate grocery quantities combine',
    () {
      final controller = withAdminMeals();
      final breakfast = controller.suggestionsFor(MealPlanSlot.breakfast).first;
      controller.addMeal(breakfast, servings: 2);

      expect(controller.selectedCalories, breakfast.calories * 2);
      expect(controller.selectedCarbs, breakfast.carbsGrams * 2);
      final oats = controller.groceryItems.firstWhere(
        (item) => item.name == 'Oats',
      );
      expect(oats.quantity, 100);
    },
  );

  test('adherence progress counts eaten meals but not skipped meals', () async {
    final controller = withAdminMeals();
    final breakfast = controller.suggestionsFor(MealPlanSlot.breakfast).first;
    final lunch = controller.suggestionsFor(MealPlanSlot.lunch).first;
    await controller.addMeal(breakfast);
    await controller.addMeal(lunch);

    expect(controller.adherenceProgress, 0);
    await controller.changeStatus(
      controller.mealFor(MealPlanSlot.breakfast)!,
      MealPlanStatus.eaten,
    );
    await controller.changeStatus(
      controller.mealFor(MealPlanSlot.lunch)!,
      MealPlanStatus.skipped,
    );

    expect(controller.eatenMeals, 1);
    expect(controller.skippedMeals, 1);
    expect(controller.dailyMealGoal, 4);
    expect(controller.dailyGoalComplete, isFalse);
    expect(controller.adherenceProgress, 0.25);
  });

  test(
    'goToDate navigates to the target week and selects the correct weekday',
    () {
      final controller = MealPlannerController();
      final initialDate = controller.selectedDate;

      // Jump 2 weeks into the future
      final target = initialDate.add(const Duration(days: 14));
      controller.goToDate(target);

      expect(controller.weekOffset.value, 2);
      expect(controller.selectedDayIndex.value, target.weekday - 1);
      expect(controller.selectedDate.year, target.year);
      expect(controller.selectedDate.month, target.month);
      expect(controller.selectedDate.day, target.day);

      // Reset back to today
      controller.goToToday();
      expect(controller.weekOffset.value, 0);
      expect(controller.selectedDayIndex.value, DateTime.now().weekday - 1);
    },
  );

  test('user can customize plan duration between 3 and 7 days', () {
    final controller = MealPlannerController();
    expect(controller.planDaysCount.value, 7);
    expect(controller.planDays.length, 7);

    // Set to 3 days
    controller.setPlanDaysCount(3);
    expect(controller.planDaysCount.value, 3);
    expect(controller.planDays.length, 3);

    // Clamping test: cannot be less than 3
    controller.setPlanDaysCount(2);
    expect(controller.planDaysCount.value, 3);

    // Clamping test: cannot be more than 7
    controller.setPlanDaysCount(10);
    expect(controller.planDaysCount.value, 7);

    // Custom range: start date + 5 days
    final customStart = DateTime(2026, 10, 1);
    controller.setCustomPlanRange(start: customStart, days: 5);
    expect(controller.planDaysCount.value, 5);
    expect(controller.planDays.length, 5);
    expect(controller.planStartDate, customStart);
    expect(controller.planEndDate, customStart.add(const Duration(days: 4)));
    expect(controller.planDays.first, customStart);
    expect(controller.planDays.last, customStart.add(const Duration(days: 4)));
  });

  test(
    'MealPlannerProvider fetches dynamic range, day meals, and day recommendations',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/api/v1/meal-plans/day')) {
          expect(request.url.queryParameters['date'], '2026-10-02');
          return http.Response(
            jsonEncode([
              {
                'planId': 10,
                'planDate': '2026-10-02',
                'mealType': 'LUNCH',
                'plannerMealId': 101,
                'mealName': 'Beef soup',
                'calories': 450,
                'servings': 1,
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/meal-plans') {
          expect(request.url.queryParameters['startDate'], '2026-10-01');
          expect(request.url.queryParameters['endDate'], '2026-10-05');
          expect(request.url.queryParameters['days'], '5');
          return http.Response(
            jsonEncode([
              {
                'planId': 11,
                'planDate': '2026-10-01',
                'mealType': 'BREAKFAST',
                'plannerMealId': 102,
                'mealName': 'Chicken soup',
                'calories': 380,
                'servings': 1,
              },
            ]),
            200,
          );
        }
        if (request.url.path.contains('/api/v1/meal-planner/recommendations')) {
          expect(request.url.queryParameters['dayOfWeek'], 'MONDAY');
          return http.Response(
            jsonEncode([
              {
                'mealId': 103,
                'mealName': 'Monday Salad',
                'calories': 250,
                'mealSlot': 'LUNCH',
                'dayOfWeek': 'MONDAY',
              },
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );

      final dayMeals = await provider.getDay(DateTime(2026, 10, 2));
      expect(dayMeals.length, 1);
      expect(dayMeals.first.name, 'Beef soup');

      final rangeMeals = await provider.getRange(
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 5),
        days: 5,
      );
      expect(rangeMeals.length, 1);
      expect(rangeMeals.first.name, 'Chicken soup');

      final recs = await provider.getRecommendations(dayOfWeek: 'MONDAY');
      expect(recs.length, 1);
      expect(recs.first.name, 'Monday Salad');
    },
  );

  test(
    'controller dynamically fetches range and day meals from provider',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/api/v1/meal-plans/day')) {
          return http.Response(
            jsonEncode([
              {
                'planId': 20,
                'planDate': request.url.queryParameters['date'],
                'mealType': 'DINNER',
                'plannerMealId': 201,
                'mealName': 'Dynamic Day Dinner',
                'calories': 500,
                'servings': 1,
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/meal-plans') {
          return http.Response(
            jsonEncode([
              {
                'planId': 21,
                'planDate': request.url.queryParameters['startDate'],
                'mealType': 'BREAKFAST',
                'plannerMealId': 202,
                'mealName': 'Dynamic Range Breakfast',
                'calories': 350,
                'servings': 1,
              },
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );

      final controller = MealPlannerController(provider: provider);
      await controller.loadWeek();

      expect(controller.mealsFor(controller.planStartDate).isNotEmpty, isTrue);
      expect(
        controller.mealsFor(controller.planStartDate).first.name,
        'Dynamic Range Breakfast',
      );

      // Selecting another day triggers dynamic load for that day
      controller.selectDay(2);
      await controller.loadDayMeals(controller.selectedDate);
      expect(controller.selectedMeals.isNotEmpty, isTrue);
      expect(controller.selectedMeals.first.name, 'Dynamic Day Dinner');
    },
  );

  test(
    'when users choose 3 days it shows 3 days and choose 4 days shows 4 days',
    () {
      final controller = MealPlannerController();

      controller.setPlanDaysCount(3);
      expect(controller.planDaysCount.value, 3);
      expect(controller.planDays.length, 3);
      expect(controller.weekDays.length, 3);

      controller.setPlanDaysCount(4);
      expect(controller.planDaysCount.value, 4);
      expect(controller.planDays.length, 4);
      expect(controller.weekDays.length, 4);

      controller.setPlanDaysCount(5);
      expect(controller.planDaysCount.value, 5);
      expect(controller.planDays.length, 5);
      expect(controller.weekDays.length, 5);
    },
  );
}
