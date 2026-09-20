import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_analysis_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_nutrition_model.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_decomposition_service.dart';

void main() {
  group('FoodDecompositionService Tests', () {
    test('decomposes Fried Rice into authentic culinary ingredients', () {
      final friedRice = FoodNutritionModel(
        name: 'Fried Rice',
        calories: 510,
        protein: 18,
        carbs: 72,
        fat: 17,
        sugar: 4,
        servingSize: 350,
        servingUnit: 'g',
        components: [
          DetectedFoodComponentModel.fromJson({
            'name': 'Fried Rice',
            'estimatedAmount': 350,
            'unit': 'g',
            'confidence': 0.9,
          }),
          DetectedFoodComponentModel.fromJson({
            'name': 'Soy Sauce',
            'estimatedAmount': 30,
            'unit': 'ml',
            'confidence': 0.9,
          }),
        ],
      );

      final items = FoodDecompositionService.decompose(friedRice);

      // Verify it did NOT output "Fried Rice" as an ingredient of itself
      final hasWholeDish = items.any(
        (i) => i.name.toLowerCase() == 'fried rice',
      );
      expect(hasWholeDish, isFalse);

      // Verify authentic ingredients are present
      final names = items.map((i) => i.name).toList();
      expect(names, contains('Cooked Jasmine Rice'));
      expect(names, contains('Scrambled Egg'));
      expect(names, contains('Vegetable Cooking Oil'));
      expect(names, contains('Spring Onions & Carrots'));
      expect(names, contains('Soy Sauce & Garlic'));

      // Verify roles
      final rice = items.firstWhere((i) => i.name == 'Cooked Jasmine Rice');
      expect(rice.role, 'Carb base');
      expect(rice.baseCalories, greaterThan(200));

      final egg = items.firstWhere((i) => i.name == 'Scrambled Egg');
      expect(egg.role, 'Whole protein');
      expect(egg.baseProtein, greaterThan(4));

      final oil = items.firstWhere((i) => i.name == 'Vegetable Cooking Oil');
      expect(oil.role, 'Cooking fat');
      expect(oil.baseFat, greaterThan(8));

      // Sum of calories should approximate the parent dish calories
      final totalItemCals = items.fold<double>(0, (s, i) => s + i.baseCalories);
      expect((totalItemCals - friedRice.calories).abs(), lessThan(35));
    });

    test('decomposes Chicken Fried Rice to include chicken', () {
      const chickenFriedRice = FoodNutritionModel(
        name: 'Chicken Fried Rice',
        calories: 540,
        protein: 28,
        carbs: 70,
        fat: 16,
        sugar: 3,
        servingSize: 370,
        servingUnit: 'g',
      );

      final items = FoodDecompositionService.decompose(chickenFriedRice);
      final names = items.map((i) => i.name).toList();
      expect(names, contains('Diced Chicken Breast'));
      expect(names, contains('Cooked Jasmine Rice'));
      expect(names, contains('Scrambled Egg'));
    });

    test('decomposes Beef Lok Lak correctly', () {
      const lokLak = FoodNutritionModel(
        name: 'Beef Lok Lak',
        calories: 560,
        protein: 38,
        carbs: 42,
        fat: 25,
        sugar: 6,
        servingSize: 380,
        servingUnit: 'g',
      );

      final items = FoodDecompositionService.decompose(lokLak);
      final names = items.map((i) => i.name).toList();
      expect(names, contains('Beef Tenderloin Cubes'));
      expect(names, contains('Steamed Jasmine Rice'));
      expect(names, contains('Crisp Lettuce & Tomatoes'));
      expect(names, contains('Lime & Black Pepper Sauce'));
    });

    test('decomposes Bai Sach Chrouk correctly', () {
      const baiSachChrouk = FoodNutritionModel(
        name: 'Bai Sach Chrouk',
        calories: 500,
        protein: 25,
        carbs: 65,
        fat: 16,
        sugar: 5,
        servingSize: 370,
        servingUnit: 'g',
      );

      final items = FoodDecompositionService.decompose(baiSachChrouk);
      final names = items.map((i) => i.name).toList();
      expect(names, contains('Grilled Marinated Pork'));
      expect(names, contains('Broken Jasmine Rice'));
      expect(names, contains('Pickled Daikon & Cucumber'));
      expect(names, contains('Scallion & Garlic Oil'));
      expect(names, contains('Clear Scallion Broth'));
    });

    test('heuristically decomposes an unlisted custom food', () {
      const customFood = FoodNutritionModel(
        name: 'Tofu Veggie Sauté',
        calories: 320,
        protein: 16,
        carbs: 35,
        fat: 14,
        sugar: 4,
        servingSize: 300,
        servingUnit: 'g',
      );

      final items = FoodDecompositionService.decompose(customFood);
      expect(items.length, greaterThanOrEqualTo(3));

      // Should not repeat the full dish name
      final hasWholeDish = items.any(
        (i) => i.name.toLowerCase() == 'tofu veggie sauté',
      );
      expect(hasWholeDish, isFalse);

      final roles = items.map((i) => i.role).toList();
      expect(roles, contains('Carb base'));
      expect(roles, contains('Protein source'));
      expect(roles, contains('Cooking fat'));
    });

    test('retains existing components if already granular with 3+ items', () {
      final multiPlate = FoodNutritionModel(
        name: 'Steamed Rice with Grilled Chicken',
        calories: 450,
        protein: 35,
        carbs: 50,
        fat: 12,
        sugar: 2,
        servingSize: 350,
        servingUnit: 'g',
        components: [
          DetectedFoodComponentModel.fromJson({
            'name': 'Steamed Rice',
            'estimatedAmount': 200,
            'unit': 'g',
            'calories': 220,
            'confidence': 0.9,
          }),
          DetectedFoodComponentModel.fromJson({
            'name': 'Grilled Chicken',
            'estimatedAmount': 120,
            'unit': 'g',
            'calories': 190,
            'confidence': 0.9,
          }),
          DetectedFoodComponentModel.fromJson({
            'name': 'Clear Soup',
            'estimatedAmount': 100,
            'unit': 'ml',
            'calories': 40,
            'confidence': 0.9,
          }),
        ],
      );

      final items = FoodDecompositionService.decompose(multiPlate);
      expect(items.length, 3);
      expect(items[0].name, 'Steamed Rice');
      expect(items[1].name, 'Grilled Chicken');
      expect(items[2].name, 'Clear Soup');
    });

    test('retains a complete two-component AI analysis and its metadata', () {
      final soup = FoodNutritionModel(
        name: 'Beef soup',
        calories: 260,
        protein: 30,
        carbs: 4,
        fat: 12,
        sugar: 1,
        servingSize: 520,
        servingUnit: 'g',
        components: [
          DetectedFoodComponentModel.fromJson({
            'name': 'Soup broth',
            'estimatedAmount': 400,
            'unit': 'ml',
            'confidence': 0.88,
            'portionConfidence': 0.72,
            'preparationMethod': 'simmered',
            'visibleEvidence': 'Yellow broth fills most of the bowl',
            'nutritionSource': 'AI_ESTIMATED',
            'requiresUserConfirmation': true,
          }),
          DetectedFoodComponentModel.fromJson({
            'name': 'Beef pieces',
            'estimatedAmount': 120,
            'unit': 'g',
            'confidence': 0.91,
            'portionConfidence': 0.81,
            'databaseMatched': true,
            'databaseMatchConfidence': 0.94,
            'imageUrl': 'https://cdn.example.com/beef.jpg',
            'nutritionSource': 'DATABASE_CALCULATED',
          }),
        ],
      );

      final items = FoodDecompositionService.decompose(soup);

      expect(items.map((item) => item.name), ['Soup broth', 'Beef pieces']);
      expect(items.first.portionConfidence, 0.72);
      expect(items.first.preparationMethod, 'simmered');
      expect(items.first.requiresUserConfirmation, isTrue);
      expect(items.last.databaseMatched, isTrue);
      expect(items.last.databaseMatchConfidence, 0.94);
      expect(items.last.imageUrl, 'https://cdn.example.com/beef.jpg');
      expect(items.last.nutritionSource, 'DATABASE_CALCULATED');
    });

    test('keeps one image-grounded component for a simple food', () {
      final apple = FoodNutritionModel(
        name: 'Apple',
        calories: 95,
        protein: 0.5,
        carbs: 25,
        fat: 0.3,
        sugar: 19,
        servingSize: 1,
        servingUnit: 'piece',
        components: [
          DetectedFoodComponentModel.fromJson({
            'name': 'Apple',
            'estimatedAmount': 1,
            'unit': 'piece',
            'confidence': 0.98,
          }),
        ],
      );

      final items = FoodDecompositionService.decompose(apple);

      expect(items, hasLength(1));
      expect(items.single.name, 'Apple');
    });
  });
}
