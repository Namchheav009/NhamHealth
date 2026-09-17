import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';

void main() {
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
}
