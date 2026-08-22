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
}
