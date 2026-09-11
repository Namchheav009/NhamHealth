import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/ai_food_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/calories_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_nutrition_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/wellness/food_nutrition_repository.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_ai_service.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_recommendation_service.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  test('builds food and drink amount summaries before analysis', () {
    final controller = AiFoodController(
      aiService: FoodAiService(),
      nutritionRepository: FoodNutritionRepository(),
      recommendationService: FoodRecommendationService(),
      caloriesController: CaloriesController(),
      wellnessController: WellnessController(),
      profileRepository: ProfileRepository(authService: AuthService()),
    );

    controller.setFoodAmount(.5);
    controller.setFoodUnit('bowl');
    expect(controller.selectedAmountLabel, '0.5 bowl');

    controller.adjustFoodAmount(.25);
    expect(controller.selectedAmountLabel, '0.75 bowl');

    controller.setInputKind(AiFoodInputKind.drink);
    controller.setDrinkCupMl(350);
    controller.setDrinkConsumedFraction(.5);
    expect(controller.selectedAmountLabel, '175 ml');

    controller.onClose();
  });

  test('uncertain AI nutrition cannot be added before user confirmation', () {
    final controller = AiFoodController(
      aiService: FoodAiService(),
      nutritionRepository: FoodNutritionRepository(),
      recommendationService: FoodRecommendationService(),
      caloriesController: CaloriesController(),
      wellnessController: WellnessController(),
      profileRepository: ProfileRepository(authService: AuthService()),
    );
    controller.nutrition.value = const FoodNutritionModel(
      name: 'Possible fried rice',
      calories: 420,
      protein: 14,
      carbs: 62,
      fat: 12,
      sugar: 4,
      servingSize: 1,
      servingUnit: 'bowl',
      confidence: 0.62,
      needsUserConfirmation: true,
    );

    expect(controller.canAddFood, isFalse);

    controller.isUserConfirmed.value = true;
    expect(controller.canAddFood, isTrue);

    controller.onClose();
  });

  test('adjusts drink nutrition when sugar percentage is modified', () {
    final controller = AiFoodController(
      aiService: FoodAiService(),
      nutritionRepository: FoodNutritionRepository(),
      recommendationService: FoodRecommendationService(),
      caloriesController: CaloriesController(),
      wellnessController: WellnessController(),
      profileRepository: ProfileRepository(authService: AuthService()),
    );

    controller.setInputKind(AiFoodInputKind.drink);
    controller.setDrinkCupMl(350);
    controller.setDrinkConsumedFraction(1.0);
    expect(controller.drinkSugarPercentage.value, 100);

    controller.setDrinkSugarPercentage(50);
    expect(controller.drinkSugarPercentage.value, 50);

    final baseDrink = const FoodNutritionModel(
      name: 'Milk Tea',
      mealType: 'drink',
      calories: 200,
      protein: 4,
      carbs: 35,
      fat: 5,
      sugar: 20,
      servingSize: 350,
      servingUnit: 'ml',
    );

    final scaled50Sugar = baseDrink.withPortionScale(
      factor: 1.0,
      size: 350,
      unit: 'ml',
      sugarFactor: 0.5,
    );

    // 50% sugar: sugar drops from 20g to 10g (delta = -10g)
    // carbs drops by 10g: 35g - 10g = 25g
    // calories drops by 10g * 4 kcal = 40 kcal: 200 kcal - 40 kcal = 160 kcal
    expect(scaled50Sugar.sugar, 10);
    expect(scaled50Sugar.carbs, 25);
    expect(scaled50Sugar.calories, 160);

    controller.onClose();
  });
}
