import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_nutrition_model.dart';

void main() {
  test('parses mixed numeric JSON safely', () {
    final food = FoodNutritionModel.fromJson({
      'id': '7',
      'name': 'Chicken Rice',
      'calories': 520,
      'protein': '32.5',
      'carbs': 65.0,
      'fat': null,
      'sugar': '4',
      'servingSize': '1',
      'servingUnit': 'plate',
    });
    expect(food.id, 7);
    expect(food.protein, 32.5);
    expect(food.fat, 0);
  });

  test('normalizes an empty AI food name', () {
    final food = FoodNutritionModel.fromJson({
      'name': '   ',
      'calories': 100,
      'protein': 2,
      'carbs': 20,
      'fat': 1,
      'sugar': 4,
      'servingSize': 1,
      'servingUnit': 'cup',
    });

    expect(food.name, 'Unknown food');
  });

  test('trims a successful AI food name', () {
    final food = FoodNutritionModel.fromJson({
      'name': '  Iced coffee  ',
      'calories': 120,
      'protein': 2,
      'carbs': 22,
      'fat': 3,
      'sugar': 18,
      'servingSize': 1,
      'servingUnit': 'glass',
    });

    expect(food.name, 'Iced coffee');
  });

  test('shows the user correction while preserving nutrition values', () {
    final food = FoodNutritionModel(
      analysisId: 42,
      name: 'AI detected food',
      calories: 320,
      protein: 12,
      carbs: 40,
      fat: 8,
      sugar: 5,
      servingSize: 1,
      servingUnit: 'bowl',
    );

    final corrected = food.withCorrection(
      correctedName: '  User corrected food  ',
      size: 2,
      unit: 'bowls',
    );

    expect(corrected.name, 'User corrected food');
    expect(corrected.mealName, 'User corrected food');
    expect(corrected.calories, 320);
    expect(corrected.servingSize, 2);
    expect(corrected.servingUnit, 'bowls');
    expect(corrected.analysisId, 42);
  });

  test('correction replaces stale single-food name and description', () {
    final food = FoodNutritionModel.fromJson({
      'name': 'Beef yellow curry',
      'components': [
        {
          'name': 'Beef yellow curry soup with vegetables',
          'visibleEvidence': 'yellow curry broth with chunks of beef',
          'calories': 320,
        },
      ],
    });
    final corrected = food.withCorrection(
      correctedName: ' Mchu Kroeung Beef ',
      size: 500,
      unit: 'g',
    );
    final restored = FoodNutritionModel.fromJson(corrected.toJson());
    expect(restored.components.single.name, 'Mchu Kroeung Beef');
    expect(
      restored.components.single.visibleEvidence,
      'Food name corrected to Mchu Kroeung Beef.',
    );
    expect(restored.components.single.calories, 320);
    expect(food.components.single.name, 'Beef yellow curry soup with vegetables');
  });

  test('parses structured components, candidates, and database nutrition', () {
    final food = FoodNutritionModel.fromJson({
      'analysisId': 123,
      'name': 'Khmer Grilled Chicken Rice',
      'mealName': 'Khmer Grilled Chicken Rice',
      'foodDetected': true,
      'cuisine': 'Cambodian',
      'type': 'food',
      'mealIdentityConfidence': 0.87,
      'portionConfidence': 0.68,
      'preparationConfidence': 0.79,
      'needsUserConfirmation': true,
      'dataSource': 'DATABASE_CALCULATED',
      'components': [
        {
          'name': 'Cooked jasmine rice',
          'estimatedAmount': 220,
          'unit': 'g',
          'confidence': 0.89,
          'portionConfidence': 0.66,
          'preparationMethod': 'steamed',
          'visibleEvidence': 'white rice covering half the plate',
          'componentType': 'food',
          'liquidVolumeMl': 0,
          'beverageType': 'none',
          'databaseMatched': true,
          'matchedFoodId': 45,
          'matchedFoodName': 'Cooked Jasmine Rice',
          'databaseMatchConfidence': 0.94,
          'calories': 286,
          'protein': 5.9,
          'carbohydrates': 61.6,
          'fat': 0.7,
          'sugar': 0.2,
          'fiber': 0.9,
          'sodium': 2.2,
          'nutritionSource': 'DATABASE_CALCULATED',
          'requiresUserConfirmation': false,
        },
      ],
      'candidates': [
        {'name': 'Khmer Grilled Chicken Rice', 'confidence': 0.87},
        {'name': 'Thai Chicken Rice', 'confidence': 0.08},
      ],
      'nutrition': {
        'calories': 620,
        'protein': 34.2,
        'carbohydrates': 78.4,
        'fat': 19.1,
        'sugar': 11.6,
        'fiber': 5.8,
        'sodium': 790,
        'source': 'DATABASE_CALCULATED',
        'complete': true,
      },
    });

    expect(food.mealName, 'Khmer Grilled Chicken Rice');
    expect(food.cuisine, 'Cambodian');
    expect(food.calories, 620);
    expect(food.fiber, 5.8);
    expect(food.sodium, 790);
    expect(food.components.single.matchedFoodId, 45);
    expect(food.candidates.length, 2);
    expect(food.hasCompleteNutrition, isTrue);
  });

  test('parses drink classification and calculates plain-water volume', () {
    final food = FoodNutritionModel.fromJson({
      'name': 'Water and iced tea',
      'type': 'drink',
      'components': [
        {
          'name': 'Mineral water',
          'estimatedAmount': 330,
          'unit': 'ml',
          'componentType': 'drink',
          'liquidVolumeMl': 300,
          'beverageType': 'plain_water',
        },
        {
          'name': 'Iced tea',
          'estimatedAmount': 250,
          'unit': 'ml',
          'componentType': 'drink',
          'liquidVolumeMl': 210,
          'beverageType': 'coffee_tea',
        },
      ],
    });

    expect(food.hasDrink, isTrue);
    expect(food.drinkVolumeMl, 510);
    expect(food.plainWaterVolumeMl, 300);
    expect(food.isPlainWaterOnly, isFalse);
  });

  test('treats hybrid AI fallback nutrition as complete but estimated', () {
    final food = FoodNutritionModel.fromJson({
      'name': 'Iced Coffee',
      'needsUserConfirmation': true,
      'dataSource': 'HYBRID_ESTIMATED',
      'nutrition': {
        'calories': 180,
        'protein': 4,
        'carbohydrates': 28,
        'fat': 6,
        'sugar': 22,
        'fiber': 0,
        'sodium': 90,
        'source': 'HYBRID_ESTIMATED',
        'complete': true,
      },
    });

    expect(food.hasCompleteNutrition, isTrue);
    expect(food.hasNutritionEstimate, isTrue);
    expect(food.isDatabaseCalculated, isFalse);
    expect(food.nutritionSourceLabel, 'Database + AI estimate');
  });
}
