import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/wellness/models/food_nutrition_model.dart';

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
}
