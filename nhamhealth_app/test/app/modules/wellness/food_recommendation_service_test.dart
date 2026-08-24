import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_nutrition_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_recommendation_model.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_recommendation_service.dart';

void main() {
  final service = FoodRecommendationService();

  test('uncertain AI result asks for confirmation', () {
    final result = service.create(
      food: _food(confidence: .55, needsConfirmation: true),
      currentCalories: 500,
      targetCalories: 2000,
    );

    expect(result.type, FoodRecommendationType.warning);
    expect(result.title, 'Confirm the Food First');
  });

  test('high protein meal receives positive macro guidance', () {
    final result = service.create(
      food: _food(protein: 32),
      currentCalories: 500,
      targetCalories: 2000,
    );

    expect(result.type, FoodRecommendationType.good);
    expect(result.title, 'Strong Protein Choice');
    expect(
      result.message,
      'Provides about @protein g protein and fits your remaining calories. Add vegetables for fiber.',
    );
    expect(result.messageParams, {'protein': '32'});
  });
}

FoodNutritionModel _food({
  double confidence = .9,
  double protein = 15,
  bool needsConfirmation = false,
}) => FoodNutritionModel(
  name: 'Test meal',
  calories: 420,
  protein: protein,
  carbs: 45,
  fat: 12,
  sugar: 5,
  servingSize: 1,
  servingUnit: 'plate',
  confidence: confidence,
  needsUserConfirmation: needsConfirmation,
);
