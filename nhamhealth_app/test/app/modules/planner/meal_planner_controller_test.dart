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

String makeTestJwtToken(int userId) {
  final header = base64Url.encode(
    utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
  );
  final payload = base64Url.encode(
    utf8.encode(jsonEncode({'userId': userId, 'sub': 'user$userId'})),
  );
  return '$header.$payload.signature';
}

class _TestUserAuthService extends AuthService {
  _TestUserAuthService(this.userId);
  final int userId;

  @override
  Future<String?> readAccessToken() async => makeTestJwtToken(userId);
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

  test(
    'user-scoped duration storage preserves settings per user and defaults to 7 days for new users',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const storage = FlutterSecureStorage();

      // User 100 sets plan to 3 days
      final authUser1 = _TestUserAuthService(100);
      final controller1 = MealPlannerController(
        storage: storage,
        authService: authUser1,
      );
      controller1.setPlanDaysCount(3);
      expect(controller1.planDaysCount.value, 3);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await storage.read(key: 'meal_planner_days_count_100'), '3');

      // User 200 logs in for first time with no saved settings -> must default to 7 days
      final authUser2 = _TestUserAuthService(200);
      final controller2 = MealPlannerController(
        storage: storage,
        authService: authUser2,
      );
      await controller2.initPlanner();
      expect(controller2.planDaysCount.value, 7);

      // User 100 logs back in -> should restore 3 days
      final controller1Reloaded = MealPlannerController(
        storage: storage,
        authService: authUser1,
      );
      await controller1Reloaded.initPlanner();
      expect(controller1Reloaded.planDaysCount.value, 3);
    },
  );

  test(
    'autoFillPlan populates empty slots across planDays using recommendations',
    () async {
      final controller = withAdminMeals();
      expect(controller.selectedMeals.isEmpty, isTrue);

      final filled = await controller.autoFillPlan();
      expect(filled, greaterThan(0));
      expect(controller.selectedMeals.isNotEmpty, isTrue);

      // Calling autoFill again when slots are filled fills 0 new meals
      final secondRun = await controller.autoFillPlan();
      expect(secondRun, 0);
    },
  );

  test(
    'formatGroceryListText formats items by category and copyGroceryListToClipboard copies cleanly',
    () async {
      final controller = withAdminMeals();
      await controller.autoFillPlan();

      final text = controller.formatGroceryListText();
      expect(text.isNotEmpty, isTrue);
      expect(text, contains('NhamHealth'));

      final copied = await controller.copyGroceryListToClipboard();
      expect(copied, isTrue);
    },
  );

  test(
    'MealPlannerProvider saveBulkMeals calls bulk endpoint with list payload',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/meal-plans/bulk') {
          expect(request.method, 'POST');
          final decoded = jsonDecode(request.body) as List;
          expect(decoded.length, 2);
          return http.Response(
            jsonEncode([
              {
                'planId': 301,
                'planDate': '2026-10-01',
                'mealType': 'BREAKFAST',
                'plannerMealId': 101,
                'mealName': 'Bulk Oat',
                'calories': 350,
                'servings': 1,
              },
              {
                'planId': 302,
                'planDate': '2026-10-01',
                'mealType': 'LUNCH',
                'plannerMealId': 102,
                'mealName': 'Bulk Rice',
                'calories': 550,
                'servings': 1,
              },
            ]),
            200,
          );
        }
        return http.Response('[]', 404);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );

      final result = await provider.saveBulkMeals([
        {
          'planDate': '2026-10-01',
          'mealType': 'BREAKFAST',
          'plannerMealId': 101,
          'servings': 1.0,
        },
        {
          'planDate': '2026-10-01',
          'mealType': 'LUNCH',
          'plannerMealId': 102,
          'servings': 1.0,
        },
      ]);

      expect(result.length, 2);
      expect(result[0].planId, 301);
      expect(result[1].planId, 302);
    },
  );

  test(
    'autoFillPlan sends all empty slots via a single saveBulkMeals call',
    () async {
      var bulkCallCount = 0;
      var singleSaveCallCount = 0;
      var capturedBulkItems = <dynamic>[];

      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/meal-plans/bulk') {
          bulkCallCount++;
          final decoded = jsonDecode(request.body) as List;
          capturedBulkItems = decoded;
          return http.Response(
            jsonEncode(
              decoded
                  .map(
                    (item) => {
                      'planId': 999,
                      'planDate': item['planDate'],
                      'mealType': item['mealType'],
                      'plannerMealId': item['plannerMealId'],
                      'mealName': 'Saved Bulk Meal',
                      'calories': 400,
                      'servings': item['servings'],
                    },
                  )
                  .toList(),
            ),
            200,
          );
        }
        if (request.url.path == '/api/v1/meal-plans' &&
            request.method == 'POST') {
          singleSaveCallCount++;
          return http.Response('{}', 200);
        }
        return http.Response('[]', 200);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );

      final base = withAdminMeals();
      final controller = MealPlannerController(provider: provider);
      controller.adminRecommendations.addAll(base.adminRecommendations);
      controller.setPlanDaysCount(3);

      final filled = await controller.autoFillPlan();
      expect(filled, greaterThan(0));
      expect(bulkCallCount, 1);
      expect(singleSaveCallCount, 0);
      expect(capturedBulkItems.isNotEmpty, isTrue);
    },
  );
}
