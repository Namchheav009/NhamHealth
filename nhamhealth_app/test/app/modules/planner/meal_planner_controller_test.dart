import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/ai_meal_recommendation_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/providers/planner/meal_planner_provider.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/planner_shared.dart';
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
      final firstDay = controller.selectedDate;

      controller.selectDay(1);
      expect(controller.selectedMeals, isEmpty);
      expect(controller.groceryItemsForDate(controller.selectedDate), isEmpty);

      final dinner = controller.suggestionsFor(MealPlanSlot.dinner).first;
      controller.addMeal(dinner);
      expect(controller.selectedMeals.single.id, dinner.id);
      expect(
        controller
            .groceryItemsForDate(controller.selectedDate)
            .map((item) => item.name),
        containsAll(dinner.ingredients),
      );
      expect(
        controller.groceryItemsForDate(firstDay).map((item) => item.name),
        isNot(contains('Fish')),
      );
      expect(
        controller.formatGroceryListText(date: firstDay),
        isNot(contains('Fish')),
      );
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

  test('grocery items combine quantities and track their planned meals', () {
    final controller = withAdminMeals();
    controller.addMeal(
      controller.suggestionsFor(MealPlanSlot.breakfast).first,
      servings: 2,
    );
    controller.addMeal(
      const PlannedMeal(
        id: 105,
        name: 'Oat pancakes',
        calories: 430,
        slot: MealPlanSlot.lunch,
        ingredients: [],
        ingredientDetails: [
          PlannerIngredient(name: ' Oats ', quantity: 25, unit: 'g'),
          PlannerIngredient(name: '  '),
        ],
      ),
    );

    final oats = controller.groceryItems.singleWhere(
      (item) => item.name == 'Oats',
    );
    expect(oats.quantity, 125);
    expect(oats.sourceMeals, ['Oatmeal with banana', 'Oat pancakes']);
    expect(controller.groceryItems.any((item) => item.name.isEmpty), isFalse);
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
    expect(controller.eatenCalories, 0);
    expect(controller.eatenProtein, 0);
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
    expect(controller.eatenCalories, breakfast.calories);
    expect(controller.eatenProtein, breakfast.proteinGrams);

    await controller.changeStatus(
      controller.mealFor(MealPlanSlot.breakfast)!,
      MealPlanStatus.planned,
    );
    expect(controller.eatenCalories, 0);
    expect(controller.eatenProtein, 0);
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

  test('ingredient image lookup prefers the exact database match', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/ingredients');
      expect(request.url.queryParameters['query'], 'Greek yogurt');
      expect(request.url.queryParameters['lang'], 'en');
      return http.Response(
        jsonEncode([
          {
            'id': 2,
            'name': 'Yogurt drink',
            'imageUrl': 'https://cdn.example.com/yogurt-drink.jpg',
          },
          {
            'id': 1,
            'name': 'Greek yogurt',
            'imageUrl': 'https://cdn.example.com/greek-yogurt.jpg',
          },
        ]),
        200,
      );
    });
    final provider = MealPlannerProvider(
      authService: _FakeAuthService(),
      client: client,
    );

    expect(
      await provider.lookupIngredientImageUrl('Greek yogurt'),
      'https://cdn.example.com/greek-yogurt.jpg',
    );
  });

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
      await controller.initPlanner();
      await controller.loadWeek(force: true);

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
    'day recommendations retain the same meal when configured for different slots',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.contains('/api/v1/meal-plans/day') ||
            request.url.path == '/api/v1/meal-plans') {
          return http.Response('[]', 200);
        }
        if (request.url.path.contains('/api/v1/meal-planner/recommendations')) {
          if (!request.url.queryParameters.containsKey('date')) {
            return http.Response('[]', 200);
          }
          return http.Response(
            jsonEncode([
              {
                'mealId': 301,
                'mealName': 'Fruit yogurt',
                'calories': 220,
                'mealSlot': 'BREAKFAST',
                'dayOfWeek': 'ALL',
              },
              {
                'mealId': 301,
                'mealName': 'Fruit yogurt',
                'calories': 220,
                'mealSlot': 'SNACK',
                'dayOfWeek': 'ALL',
              },
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      final controller = MealPlannerController(
        provider: MealPlannerProvider(
          authService: _FakeAuthService(),
          client: client,
        ),
      );

      await controller.initPlanner();
      await controller.loadDayMeals(controller.selectedDate, force: true);

      expect(
        controller.adminRecommendations
            .where((meal) => meal.id == 301)
            .map((meal) => meal.slot),
        containsAll([MealPlanSlot.breakfast, MealPlanSlot.snack]),
      );
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
      expect(
        capturedBulkItems.every((item) => item['weightGoal'] == 'LOSE_WEIGHT'),
        isTrue,
      );
    },
  );

  test(
    'offline auto-fill does not reuse one meal in multiple daily slots',
    () async {
      var capturedBulkItems = <dynamic>[];
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/meal-planner/ai-autofill') {
          return http.Response('Unavailable', 503);
        }
        if (request.url.path == '/api/v1/meal-plans/bulk') {
          final decoded = jsonDecode(request.body) as List;
          capturedBulkItems = decoded;
          return http.Response(
            jsonEncode(
              decoded
                  .map(
                    (item) => {
                      'planId': 700 + decoded.indexOf(item),
                      'planDate': item['planDate'],
                      'mealType': item['mealType'],
                      'plannerMealId': item['plannerMealId'],
                      'mealName': 'Saved varied meal',
                      'calories': 400,
                      'servings': item['servings'],
                    },
                  )
                  .toList(),
            ),
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
      controller.setPlanDaysCount(3);
      for (final slot in MealPlanSlot.values) {
        controller.adminRecommendations.addAll([
          PlannedMeal(
            id: 1,
            name: 'Shared meal',
            calories: 400,
            slot: slot,
            ingredients: const [],
          ),
          PlannedMeal(
            id: 10 + slot.index,
            name: 'Unique ${slot.name}',
            calories: 400,
            slot: slot,
            ingredients: const [],
          ),
        ]);
      }

      final filled = await controller.autoFillPlan();

      expect(filled, greaterThanOrEqualTo(4));
      final firstDate = capturedBulkItems.first['planDate'];
      final firstDayIds =
          capturedBulkItems
              .where((item) => item['planDate'] == firstDate)
              .map((item) => item['plannerMealId'])
              .toList();
      expect(firstDayIds.length, 4);
      expect(firstDayIds.toSet().length, 4);
    },
  );

  test(
    'fill-empty mode repairs duplicate meals that already occupy daily slots',
    () async {
      var capturedBulkItems = <dynamic>[];
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/meal-planner/ai-autofill') {
          return http.Response('Unavailable', 503);
        }
        if (request.url.path == '/api/v1/meal-plans/bulk') {
          final decoded = jsonDecode(request.body) as List;
          capturedBulkItems = decoded;
          return http.Response(
            jsonEncode(
              decoded
                  .map(
                    (item) => {
                      'planId': 800 + decoded.indexOf(item),
                      'planDate': item['planDate'],
                      'mealType': item['mealType'],
                      'plannerMealId': item['plannerMealId'],
                      'mealName': 'Repaired meal',
                      'calories': 400,
                      'servings': item['servings'],
                    },
                  )
                  .toList(),
            ),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      final controller = MealPlannerController(
        provider: MealPlannerProvider(
          authService: _FakeAuthService(),
          client: client,
        ),
      );
      controller.setPlanDaysCount(3);
      final selectedDate = controller.selectedDate;

      for (final slot in MealPlanSlot.values) {
        controller.putOptimisticMeal(
          PlannedMeal(
            id: 1,
            planId: 100 + slot.index,
            name: 'Repeated meal',
            calories: 400,
            slot: slot,
            planDate: selectedDate,
            ingredients: const [],
          ),
        );
        controller.adminRecommendations.addAll([
          PlannedMeal(
            id: 1,
            name: 'Repeated meal',
            calories: 400,
            slot: slot,
            ingredients: const [],
          ),
          PlannedMeal(
            id: 20 + slot.index,
            name: 'Fresh ${slot.name}',
            calories: 400,
            slot: slot,
            ingredients: const [],
          ),
        ]);
      }

      final filled = await controller.autoFillPlan(fillEmptyOnly: true);

      expect(filled, greaterThanOrEqualTo(3));
      final selectedDateKey =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final repairedSlots =
          capturedBulkItems
              .where((item) => item['planDate'] == selectedDateKey)
              .map((item) => item['mealType'])
              .toSet();
      expect(repairedSlots, {'LUNCH', 'DINNER', 'SNACK'});
      expect(
        controller.mealsFor(selectedDate).map((meal) => meal.id).toSet().length,
        4,
      );
    },
  );

  test(
    'autoFillPlan rolls back optimistic meals when bulk save fails',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/meal-planner/ai-autofill') {
          return http.Response('Unavailable', 503);
        }
        if (request.url.path == '/api/v1/meal-plans/bulk') {
          return http.Response('Unable to save', 500);
        }
        return http.Response('[]', 200);
      });
      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );
      final recommendations = withAdminMeals().adminRecommendations.toList();
      final controller = MealPlannerController(provider: provider);
      controller.adminRecommendations.addAll(recommendations);
      controller.setPlanDaysCount(3);
      final existing = recommendations.first.copyWith(
        planDate: controller.selectedDate,
      );
      controller.putOptimisticMeal(existing);

      final filled = await controller.autoFillPlan();

      expect(filled, 0);
      expect(controller.planMealCount, 1);
      expect(controller.mealFor(MealPlanSlot.breakfast)?.id, existing.id);
    },
  );

  test('availableMealsFor and targetSlot meal planning flow operations', () async {
    final controller = MealPlannerController();
    final todayWeekday = controller.selectedDate.weekday;
    final otherWeekday = todayWeekday == 7 ? 1 : todayWeekday + 1;

    final todayBreakfast = PlannedMeal(
      id: 201,
      name: 'Today Breakfast',
      calories: 350,
      slot: MealPlanSlot.breakfast,
      ingredients: const ['Eggs', 'Toast'],
      recommendedWeekday: todayWeekday,
      categoryId: 1,
      category: 'Morning Healthy',
    );
    final otherDayBreakfast = PlannedMeal(
      id: 202,
      name: 'Other Day Breakfast',
      calories: 320,
      slot: MealPlanSlot.breakfast,
      ingredients: const ['Oats'],
      recommendedWeekday: otherWeekday,
      categoryId: 2,
      category: 'Quick Morning',
    );
    final lunchMeal = PlannedMeal(
      id: 203,
      name: 'Khmer Fried Rice',
      calories: 550,
      slot: MealPlanSlot.lunch,
      ingredients: const ['Rice', 'Vegetables'],
      recommendedWeekday: todayWeekday,
      categoryId: 3,
      category: 'Rice & Noodles',
    );

    controller.adminRecommendations.addAll([
      todayBreakfast,
      otherDayBreakfast,
      lunchMeal,
    ]);

    // 1. availableMealsFor returns both today's recommendation and other day recommendation for breakfast
    final breakfastAvailable = controller.availableMealsFor(
      MealPlanSlot.breakfast,
    );
    expect(breakfastAvailable.length, 2);
    expect(breakfastAvailable.first.id, todayBreakfast.id);
    expect(breakfastAvailable.last.id, otherDayBreakfast.id);

    // 2. categoriesFor returns categories derived from available meals
    final breakfastCategories = controller.categoriesFor(
      MealPlanSlot.breakfast,
    );
    expect(breakfastCategories.any((c) => c.name == 'Morning Healthy'), isTrue);
    expect(breakfastCategories.any((c) => c.name == 'Quick Morning'), isTrue);

    // 3. Fallback when a slot has no recommendations: returns all catalog recommendations
    final snackAvailable = controller.availableMealsFor(MealPlanSlot.snack);
    expect(snackAvailable.isNotEmpty, isTrue);

    // 4. addMeal with targetSlot: user chooses a Lunch template meal for Dinner slot
    final added = await controller.addMeal(
      lunchMeal,
      targetSlot: MealPlanSlot.dinner,
      servings: 2,
    );
    expect(added, isTrue);
    final dinnerMeal = controller.mealFor(MealPlanSlot.dinner);
    expect(dinnerMeal, isNotNull);
    expect(dinnerMeal!.name, lunchMeal.name);
    expect(dinnerMeal.slot, MealPlanSlot.dinner);
    expect(dinnerMeal.servings, 2);

    // Ensure lunch slot was not overwritten
    expect(controller.mealFor(MealPlanSlot.lunch), isNull);

    // 5. replaceMeal replaces the meal in the exact slot
    final replaced = await controller.replaceMeal(
      dinnerMeal,
      todayBreakfast,
      servings: 1,
    );
    expect(replaced, isTrue);
    final updatedDinner = controller.mealFor(MealPlanSlot.dinner);
    expect(updatedDinner, isNotNull);
    expect(updatedDinner!.name, todayBreakfast.name);
    expect(updatedDinner.slot, MealPlanSlot.dinner);
    expect(updatedDinner.servings, 1);
  });

  test(
    'syncToToday resets to today, clears expired custom dates, and increments imageRefreshKey',
    () async {
      final controller = MealPlannerController();
      final initialImageKey = controller.imageRefreshKey.value;

      // Simulate moving to next week and picking day index 5
      controller.changeWeek(2);
      controller.selectedDayIndex.value = 4;
      expect(controller.weekOffset.value, 2);
      expect(controller.selectedDayIndex.value, 4);

      // Call syncToToday
      await controller.syncToToday(forceRefresh: false);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(controller.weekOffset.value, 0);
      expect(controller.selectedDate.year, today.year);
      expect(controller.selectedDate.month, today.month);
      expect(controller.selectedDate.day, today.day);
      expect(controller.imageRefreshKey.value, greaterThan(initialImageKey));
    },
  );

  test(
    'goToToday resets customStartDate and sets selectedDate to today when custom range is active',
    () async {
      final controller = MealPlannerController();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Set a custom future plan for 5 days starting next week
      final futureStart = today.add(const Duration(days: 7));
      controller.setCustomPlanRange(start: futureStart, days: 5);

      expect(controller.customStartDate.value, isNotNull);
      expect(controller.planDaysCount.value, 5);
      expect(controller.selectedDate.day, futureStart.day);

      // Trigger goToToday
      controller.goToToday();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.customStartDate.value, isNull);
      expect(controller.planDaysCount.value, 7);
      expect(controller.weekOffset.value, 0);
      expect(controller.selectedDate.year, today.year);
      expect(controller.selectedDate.month, today.month);
      expect(controller.selectedDate.day, today.day);
    },
  );

  test(
    'goToDate navigates within custom plan without resetting customStartDate',
    () {
      final controller = MealPlannerController();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      controller.setCustomPlanRange(start: today, days: 5);
      expect(controller.selectedDayIndex.value, 0);

      // Navigate to 3rd day of the custom plan
      final day3 = today.add(const Duration(days: 2));
      controller.goToDate(day3);

      expect(controller.selectedDayIndex.value, 2);
      expect(controller.customStartDate.value, today);
      expect(controller.selectedDate.day, day3.day);
    },
  );

  test('syncToToday preserves an intentional future custom range', () async {
    final controller = MealPlannerController();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final futureStart = today.add(const Duration(days: 7));

    controller.setCustomPlanRange(start: futureStart, days: 5);
    await controller.syncToToday(forceRefresh: true);

    expect(controller.customStartDate.value, futureStart);
    expect(controller.planDaysCount.value, 5);
    expect(controller.selectedDate, futureStart);
  });

  test('PlannedMeal.fromJson parses images from alternative backend keys', () {
    final meal1 = PlannedMeal.fromJson({
      'mealId': 10,
      'mealName': 'Salmon Salad',
      'mainImageUrl': '/uploads/meals/salmon.webp',
      'mealType': 'LUNCH',
    });
    expect(meal1.imageUrl, '/uploads/meals/salmon.webp');

    final meal2 = PlannedMeal.fromJson({
      'mealId': 11,
      'mealName': 'Berry Smoothie',
      'image': 'https://cdn.example.com/smoothie.jpg',
      'mealType': 'BREAKFAST',
    });
    expect(meal2.imageUrl, 'https://cdn.example.com/smoothie.jpg');

    final meal3 = PlannedMeal.fromJson({
      'mealId': 12,
      'mealName': 'Chicken Rice',
      'thumbnail': 'assets/images/meals/chicken.jpg',
      'mealType': 'DINNER',
    });
    expect(meal3.imageUrl, 'assets/images/meals/chicken.jpg');
  });

  test(
    'plannerImageUrl resolves localhost, relative paths, and assets properly',
    () {
      expect(
        plannerImageUrl('assets/images/test.jpg'),
        'assets/images/test.jpg',
      );
      expect(plannerImageUrl(''), '');

      final localhostUrl = plannerImageUrl(
        'http://localhost:8080/uploads/meals/food.jpg',
      );
      expect(localhostUrl.contains('localhost:8080'), isFalse);
      expect(localhostUrl.endsWith('/uploads/meals/food.jpg'), isTrue);

      final relativeUrl = plannerImageUrl('/uploads/meals/soup.png');
      expect(relativeUrl.endsWith('/uploads/meals/soup.png'), isTrue);
      expect(relativeUrl.startsWith('http'), isTrue);
    },
  );

  test(
    'weeklyProgress and weeklyEatenMeals accurately reflect planned and eaten meals',
    () {
      final controller = MealPlannerController(
        provider: MealPlannerProvider(
          authService: _FakeAuthService(),
          client: MockClient((_) async => http.Response('[]', 200)),
        ),
      );

      final monday = controller.weekDays.first;
      final mondayKey =
          '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';

      expect(controller.weeklyMealCount, 0);
      expect(controller.weeklyProgress, 0.0);
      expect(controller.weeklyEatenMeals, 0);

      // Add one planned meal
      controller.plans[mondayKey] = [
        const PlannedMeal(
          id: 1,
          name: 'Oatmeal',
          slot: MealPlanSlot.breakfast,
          calories: 320,
          status: MealPlanStatus.planned,
          ingredients: ['Oats'],
        ),
      ];

      expect(controller.weeklyMealCount, 1);
      expect(controller.weeklyEatenMeals, 0);
      expect(controller.weeklyProgress, greaterThan(0.0));
      expect(controller.weeklyProgress, lessThanOrEqualTo(1.0));

      // Add an eaten meal
      controller.plans[mondayKey] = [
        ...controller.plans[mondayKey]!,
        const PlannedMeal(
          id: 2,
          name: 'Chicken Rice',
          slot: MealPlanSlot.lunch,
          calories: 550,
          status: MealPlanStatus.eaten,
          ingredients: ['Chicken', 'Rice'],
        ),
      ];

      expect(controller.weeklyMealCount, 2);
      expect(controller.weeklyEatenMeals, 1);
    },
  );

  test(
    'controller keeps Weight Loss when a legacy Maintain Health goal is requested',
    () async {
      String? lastRequestedGoal;
      final client = MockClient((request) async {
        if (request.url.path.contains('recommendations')) {
          lastRequestedGoal = request.url.queryParameters['goal'];
          return http.Response(
            jsonEncode([
              {
                'recommendationId': 501,
                'mealId': 101,
                'mealName': 'High Protein Salmon Bowl',
                'calories': 420,
                'proteinGrams': 38.0,
                'recommendationNote':
                    'IBM Granite • Preserves lean mass during deficit',
              },
            ]),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('[]', 200);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );

      final controller = MealPlannerController(provider: provider);
      await controller.initPlanner();

      expect(controller.healthGoal.value, MealPlannerHealthGoal.loseWeight);

      await controller.loadRecommendations(force: true);
      expect(controller.healthGoal.value, MealPlannerHealthGoal.loseWeight);
      expect(lastRequestedGoal, 'LOSE_WEIGHT');
      expect(
        controller.adminRecommendations.first.recommendationNote,
        contains('IBM Granite'),
      );

      await controller.setHealthGoal(MealPlannerHealthGoal.maintainHealth);
      expect(controller.healthGoal.value, MealPlannerHealthGoal.maintainHealth);
      expect(lastRequestedGoal, 'MAINTAIN_HEALTH');
    },
  );

  String testDateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test(
    'resetAllMealsToPlanned resets eaten and skipped meals back to planned',
    () async {
      final updatedMealPayloads = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        if (request.method == 'PUT' &&
            request.url.path == '/api/v1/meal-plans/bulk/status') {
          updatedMealPayloads.add(
            jsonDecode(request.body) as Map<String, dynamic>,
          );
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('[]', 200);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );
      final controller = MealPlannerController(provider: provider);

      final todayKey = testDateKey(controller.selectedDate);
      final tomorrowKey = testDateKey(
        controller.selectedDate.add(const Duration(days: 1)),
      );

      controller.plans[todayKey] = [
        PlannedMeal(
          id: 1,
          planId: 1,
          name: 'Breakfast Bowl',
          slot: MealPlanSlot.breakfast,
          calories: 300,
          status: MealPlanStatus.eaten,
          ingredients: ['Oats'],
        ),
        PlannedMeal(
          id: 2,
          planId: 2,
          name: 'Chicken Salad',
          slot: MealPlanSlot.lunch,
          calories: 500,
          status: MealPlanStatus.skipped,
          ingredients: ['Chicken'],
        ),
        PlannedMeal(
          id: 3,
          planId: 3,
          name: 'Fish Dinner',
          slot: MealPlanSlot.dinner,
          calories: 450,
          status: MealPlanStatus.planned,
          ingredients: ['Fish'],
        ),
      ];

      controller.plans[tomorrowKey] = [
        PlannedMeal(
          id: 4,
          planId: 4,
          name: 'Avocado Toast',
          slot: MealPlanSlot.breakfast,
          calories: 280,
          status: MealPlanStatus.eaten,
          ingredients: ['Bread'],
        ),
      ];

      // Reset today only
      await controller.resetAllMealsToPlanned(currentDayOnly: true);

      expect(controller.plans[todayKey]![0].status, MealPlanStatus.planned);
      expect(controller.plans[todayKey]![1].status, MealPlanStatus.planned);
      expect(controller.plans[todayKey]![2].status, MealPlanStatus.planned);
      // Tomorrow should still be eaten
      expect(controller.plans[tomorrowKey]![0].status, MealPlanStatus.eaten);
      expect(updatedMealPayloads.single['planIds'], [1, 2]);
      expect(updatedMealPayloads.single['status'], 'PLANNED');

      // Now reset all week
      await controller.resetAllMealsToPlanned(currentDayOnly: false);
      expect(controller.plans[tomorrowKey]![0].status, MealPlanStatus.planned);
      expect(updatedMealPayloads.length, 2);
      expect(updatedMealPayloads.last['planIds'], [4]);
    },
  );

  test('clearAllMeals deletes meals for today or entire week', () async {
    final deletedMealIds = <int>[];
    final client = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path == '/api/v1/meal-plans/bulk/delete') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        deletedMealIds.addAll(
          (body['planIds'] as List<dynamic>).map((id) => id as int),
        );
        return http.Response('', 204);
      }
      return http.Response('[]', 200);
    });

    final provider = MealPlannerProvider(
      authService: _FakeAuthService(),
      client: client,
    );
    final controller = MealPlannerController(provider: provider);

    final todayKey = testDateKey(controller.selectedDate);
    final tomorrowKey = testDateKey(
      controller.selectedDate.add(const Duration(days: 1)),
    );

    controller.plans[todayKey] = [
      PlannedMeal(
        id: 10,
        planId: 10,
        name: 'Breakfast',
        slot: MealPlanSlot.breakfast,
        calories: 300,
        status: MealPlanStatus.planned,
        ingredients: ['Oats'],
      ),
      PlannedMeal(
        id: 20,
        planId: 20,
        name: 'Lunch',
        slot: MealPlanSlot.lunch,
        calories: 500,
        status: MealPlanStatus.planned,
        ingredients: ['Chicken'],
      ),
    ];

    controller.plans[tomorrowKey] = [
      PlannedMeal(
        id: 30,
        planId: 30,
        name: 'Dinner',
        slot: MealPlanSlot.dinner,
        calories: 450,
        status: MealPlanStatus.planned,
        ingredients: ['Fish'],
      ),
    ];

    // Clear today only
    await controller.clearAllMeals(currentDayOnly: true);

    expect(controller.plans[todayKey], isEmpty);
    expect(controller.plans[tomorrowKey]!.length, 1);
    expect(deletedMealIds, containsAll([10, 20]));

    // Clear all week
    await controller.clearAllMeals(currentDayOnly: false);
    expect(controller.plans[tomorrowKey], isEmpty);
    expect(deletedMealIds, containsAll([10, 20, 30]));
  });

  test(
    'AiMealRecommendationResult parses ADD and SWAP responses correctly',
    () {
      final json = {
        'recommendedMeal': {
          'plannerMealId': 501,
          'mealName': 'Healthy Khmer Soup',
          'calories': 380,
          'proteinGrams': 26.5,
          'mealSlot': 'LUNCH',
        },
        'alternatives': [
          {
            'plannerMealId': 502,
            'mealName': 'Steamed Fish with Greens',
            'calories': 350,
            'proteinGrams': 30.0,
            'mealSlot': 'LUNCH',
          },
        ],
        'aiRationale': 'សមស្របសម្រាប់ការគ្រប់គ្រងទម្ងន់',
        'actionType': 'ADD',
        'modelUsed': 'gemini-3.5-flash-lite',
      };

      final result = AiMealRecommendationResult.fromJson(
        json,
        defaultSlot: MealPlanSlot.lunch,
      );

      expect(result.recommendedMeal.id, 501);
      expect(result.recommendedMeal.name, 'Healthy Khmer Soup');
      expect(result.recommendedMeal.calories, 380);
      expect(result.recommendedMeal.slot, MealPlanSlot.lunch);
      expect(result.alternatives.length, 1);
      expect(result.alternatives.first.id, 502);
      expect(result.aiRationale, 'សមស្របសម្រាប់ការគ្រប់គ្រងទម្ងន់');
      expect(result.actionType, 'ADD');
      expect(result.modelUsed, 'gemini-3.5-flash-lite');
    },
  );

  test(
    'controller.getAiMealRecommendation requests AI suggestion and returns result',
    () async {
      Map<String, dynamic>? capturedRequest;
      final client = MockClient((request) async {
        if (request.url.path.contains('/api/v1/meal-planner/recommend-meal')) {
          capturedRequest = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'recommendedMeal': {
                'plannerMealId': 601,
                'mealName': 'Brown Rice Bowl',
                'calories': 420,
                'proteinGrams': 22.0,
                'mealSlot': 'DINNER',
              },
              'alternatives': [],
              'aiRationale': 'ល្អសម្រាប់អាហារពេលល្ងាច',
              'actionType': 'SWAP',
              'modelUsed': 'gemini-3.5-flash-lite',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('[]', 404);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: client,
      );
      final controller = MealPlannerController(
        provider: provider,
        storage: const FlutterSecureStorage(),
        authService: _FakeAuthService(),
      );
      await controller.setDietaryPreferences(
        const MealPlannerDietaryPreferences(
          diet: MealPlannerDiet.vegan,
          allergens: ['milk'],
          excludedIngredients: ['mushroom'],
          medicalFlags: ['DIABETES'],
        ),
      );

      final res = await controller.getAiMealRecommendation(
        slot: MealPlanSlot.dinner,
      );

      expect(res, isNotNull);
      expect(res!.recommendedMeal.id, 601);
      expect(res.recommendedMeal.name, 'Brown Rice Bowl');
      expect(res.actionType, 'SWAP');
      expect(res.aiRationale, 'ល្អសម្រាប់អាហារពេលល្ងាច');
      expect(capturedRequest?['diet'], 'VEGAN');
      expect(capturedRequest?['allergens'], ['milk']);
      expect(capturedRequest?['excludedIngredients'], ['mushroom']);
      expect(capturedRequest?['medicalFlags'], ['DIABETES']);
    },
  );

  group('Phase 2 UX Enhancements', () {
    test('yesterdayMealFor finds yesterday meal with slot fallback', () async {
      final controller = withAdminMeals();
      final yesterday = controller.yesterdayDate;
      final yesterdayBreakfast = PlannedMeal(
        id: 201,
        name: 'Yesterday Porridge',
        calories: 320,
        slot: MealPlanSlot.breakfast,
        planDate: yesterday,
        ingredients: const ['Rice', 'Water'],
      );
      final yesterdayDinner = PlannedMeal(
        id: 202,
        name: 'Yesterday Salmon',
        calories: 550,
        slot: MealPlanSlot.dinner,
        planDate: yesterday,
        ingredients: const ['Salmon'],
      );

      controller.putOptimisticMeal(yesterdayBreakfast);
      controller.putOptimisticMeal(yesterdayDinner);

      // Breakfast matches breakfast
      final foundBreakfast = controller.yesterdayMealFor(
        MealPlanSlot.breakfast,
      );
      expect(foundBreakfast, isNotNull);
      expect(foundBreakfast!.name, 'Yesterday Porridge');

      // Lunch fallback to dinner (leftover from dinner)
      final foundLunchFallback = controller.yesterdayMealFor(
        MealPlanSlot.lunch,
        fallbackSlot: MealPlanSlot.dinner,
      );
      expect(foundLunchFallback, isNotNull);
      expect(foundLunchFallback!.name, 'Yesterday Salmon');

      // Non-existent slot returns null
      final foundSnack = controller.yesterdayMealFor(MealPlanSlot.snack);
      expect(foundSnack, isNull);
    });

    test('copyFromYesterday copies yesterday meal into today slot', () async {
      final controller = withAdminMeals();
      final yesterday = controller.yesterdayDate;
      final yesterdayDinner = PlannedMeal(
        id: 202,
        name: 'Roast Chicken',
        calories: 520,
        slot: MealPlanSlot.dinner,
        planDate: yesterday,
        ingredients: const ['Chicken'],
      );
      controller.putOptimisticMeal(yesterdayDinner);

      // Copy dinner to today's lunch as leftover
      final success = await controller.copyFromYesterday(
        MealPlanSlot.lunch,
        fromSlot: MealPlanSlot.dinner,
      );
      expect(success, isTrue);

      final todayLunch = controller.mealFor(MealPlanSlot.lunch);
      expect(todayLunch, isNotNull);
      expect(todayLunch!.name, 'Roast Chicken');
      expect(todayLunch.slot, MealPlanSlot.lunch);
      expect(todayLunch.status, MealPlanStatus.planned);
    });

    test('copyAllFromYesterday copies all yesterday meals to today', () async {
      final controller = withAdminMeals();
      final yesterday = controller.yesterdayDate;
      controller.putOptimisticMeal(
        PlannedMeal(
          id: 301,
          name: 'Noodle Soup',
          calories: 400,
          slot: MealPlanSlot.breakfast,
          planDate: yesterday,
          ingredients: const ['Noodles'],
        ),
      );
      controller.putOptimisticMeal(
        PlannedMeal(
          id: 302,
          name: 'Salad Bowl',
          calories: 350,
          slot: MealPlanSlot.lunch,
          planDate: yesterday,
          ingredients: const ['Salad'],
        ),
      );

      final ok = await controller.copyAllFromYesterday();
      expect(ok, isTrue);

      expect(controller.mealFor(MealPlanSlot.breakfast)?.name, 'Noodle Soup');
      expect(controller.mealFor(MealPlanSlot.lunch)?.name, 'Salad Bowl');
    });

    test(
      'water tracker increments, decrements, and sets glasses with clamp',
      () async {
        final controller = withAdminMeals();
        expect(controller.dailyWaterGlasses.value, 0);

        await controller.incrementWater();
        expect(controller.dailyWaterGlasses.value, 1);

        await controller.incrementWater();
        expect(controller.dailyWaterGlasses.value, 2);

        await controller.decrementWater();
        expect(controller.dailyWaterGlasses.value, 1);

        await controller.decrementWater();
        expect(controller.dailyWaterGlasses.value, 0);

        // Cannot go below 0
        await controller.decrementWater();
        expect(controller.dailyWaterGlasses.value, 0);

        // Set directly
        await controller.setWaterGlasses(8);
        expect(controller.dailyWaterGlasses.value, 8);

        // Clamps to 20
        await controller.setWaterGlasses(25);
        expect(controller.dailyWaterGlasses.value, 20);
      },
    );

    test('grocery checklist toggles and persists checked keys', () async {
      final controller = withAdminMeals();
      expect(controller.checkedGroceryKeys.isEmpty, isTrue);

      await controller.toggleGroceryItemChecked('oats|g');
      expect(controller.checkedGroceryKeys.contains('oats|g'), isTrue);

      await controller.toggleGroceryItemChecked('oats|g');
      expect(controller.checkedGroceryKeys.contains('oats|g'), isFalse);

      await controller.setAllGroceryChecked(['item1', 'item2', 'item3'], true);
      expect(controller.checkedGroceryKeys.length, 3);
      expect(controller.checkedGroceryKeys.contains('item1'), isTrue);

      await controller.setAllGroceryChecked(['item1', 'item2'], false);
      expect(controller.checkedGroceryKeys.length, 1);
      expect(controller.checkedGroceryKeys.contains('item3'), isTrue);
    });
  });
}
