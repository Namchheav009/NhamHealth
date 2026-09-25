import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/ai_food_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/calories_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_analysis_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_nutrition_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/plate_item_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/wellness/food_nutrition_repository.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_ai_service.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_decomposition_service.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_recommendation_service.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/plate_breakdown_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/ai_food_nutrition_result_content.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  late AiFoodController controller;

  setUp(() {
    Get.testMode = true;
    controller = AiFoodController(
      aiService: FoodAiService(),
      nutritionRepository: FoodNutritionRepository(),
      recommendationService: FoodRecommendationService(),
      caloriesController: CaloriesController(),
      wellnessController: WellnessController(),
      profileRepository: ProfileRepository(authService: AuthService()),
    );
    Get.put<AiFoodController>(controller);
  });

  tearDown(() {
    Get.delete<AiFoodController>();
    controller.onClose();
  });

  testWidgets(
    'renders Plate Breakdown button in Nutrition Details and opens PlateBreakdownView',
    (tester) async {
      controller.nutrition.value = const FoodNutritionModel(
        name: 'Beef Lok Lak',
        calories: 650,
        protein: 42,
        carbs: 45,
        fat: 28,
        sugar: 6,
        fiber: 4,
        sodium: 890,
        servingSize: 1,
        servingUnit: 'plate',
        confidence: 0.92,
        cuisine: 'Cambodian',
      );
      controller.plateItems.assignAll([
        PlateItemState(
          id: '1',
          name: 'Beef Tenderloin',
          baseCalories: 350,
          baseProtein: 35,
          baseCarbs: 0,
          baseFat: 18,
          portionMultiplier: 1.0,
          isSelected: true,
        ),
        PlateItemState(
          id: '2',
          name: 'Jasmine Rice',
          baseCalories: 220,
          baseProtein: 4,
          baseCarbs: 40,
          baseFat: 1,
          portionMultiplier: 1.0,
          isSelected: true,
        ),
        PlateItemState(
          id: '3',
          name: 'Salad & Tomato',
          baseCalories: 40,
          baseProtein: 1,
          baseCarbs: 5,
          baseFat: 0,
          portionMultiplier: 1.0,
          isSelected: true,
        ),
      ]);

      // Verify plate items were initialized
      expect(controller.plateItems.length, 3);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: AiFoodNutritionResultContent(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Plate Breakdown button is visible
      expect(find.text('Plate Breakdown'), findsOneWidget);
      expect(
        find.text('View and customize items on this plate'),
        findsOneWidget,
      );

      // Test rendering PlateBreakdownView directly
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: PlateBreakdownView(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify PlateBreakdownView contains elements
      expect(find.text('Plate Breakdown'), findsOneWidget);
      expect(
        find.text('AI-detected ingredients from your item'),
        findsOneWidget,
      );
      expect(find.text('Detected ingredients'), findsOneWidget);
      expect(find.text('3 ingredients found'), findsOneWidget);
      expect(find.text('Analyzed by AI'), findsOneWidget);
      expect(find.text('Beef Tenderloin'), findsOneWidget);
      expect(find.text('Jasmine Rice'), findsOneWidget);
      expect(find.text('Salad & Tomato'), findsOneWidget);
      expect(
        find.text('Review and adjust ingredients if needed.'),
        findsOneWidget,
      );
      expect(find.text('Add ingredient'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    },
  );

  testWidgets(
    'renders Matcha Bubble Tea breakdown with 4 ingredients matching screenshot design',
    (tester) async {
      controller.nutrition.value = const FoodNutritionModel(
        name: 'Matcha Bubble Tea',
        calories: 220,
        protein: 2,
        carbs: 12,
        fat: 3,
        sugar: 8,
        servingSize: 1,
        servingUnit: 'cup',
        mealType: 'drink',
      );
      controller.plateItems.assignAll([
        PlateItemState(
          id: '1',
          name: 'Matcha powder',
          baseCalories: 15,
          baseProtein: 1,
          baseCarbs: 2,
          baseFat: 0,
          baseServingSize: 5,
          unit: 'g',
          confidence: 0.95,
          role: 'Main flavor',
        ),
        PlateItemState(
          id: '2',
          name: 'Milk',
          baseCalories: 80,
          baseProtein: 4,
          baseCarbs: 6,
          baseFat: 4,
          baseServingSize: 120,
          unit: 'ml',
          confidence: 0.90,
          role: 'Creamy base',
        ),
        PlateItemState(
          id: '3',
          name: 'Tapioca pearls',
          baseCalories: 100,
          baseProtein: 0,
          baseCarbs: 25,
          baseFat: 0,
          baseServingSize: 30,
          unit: 'g',
          confidence: 0.70,
          role: 'Boba topping',
        ),
        PlateItemState(
          id: '4',
          name: 'Sweetener',
          baseCalories: 32,
          baseProtein: 0,
          baseCarbs: 8,
          baseFat: 0,
          baseServingSize: 8,
          unit: 'g',
          confidence: 0.65,
          role: 'Added sugar',
        ),
      ]);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: PlateBreakdownView(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Matcha Bubble Tea'), findsOneWidget);
      expect(find.text('2g P  •  12g C  •  3g F'), findsNothing);
      expect(find.text('Portion: Regular'), findsNothing);
      expect(find.text('4 ingredients found'), findsOneWidget);

      expect(find.text('Matcha powder'), findsOneWidget);
      expect(find.text('Main flavor'), findsOneWidget);
      expect(find.text('5 g'), findsOneWidget);

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Creamy base'), findsOneWidget);
      expect(find.text('120 ml'), findsOneWidget);

      expect(find.text('Tapioca pearls'), findsOneWidget);
      expect(find.text('Boba topping'), findsOneWidget);
      expect(find.text('30 g'), findsOneWidget);

      expect(find.text('Sweetener'), findsOneWidget);
      expect(find.text('Added sugar'), findsOneWidget);
      expect(find.text('8 g'), findsOneWidget);

      expect(find.textContaining('High confidence'), findsNWidgets(2));
      expect(find.textContaining('Medium confidence'), findsNWidgets(2));
    },
  );

  testWidgets(
    'automatically decomposes Fried Rice into authentic ingredients on PlateBreakdownView',
    (tester) async {
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

      controller.nutrition.value = friedRice;
      // Simulate controller initializing plate items with decomposition
      controller.plateItems.assignAll(
        FoodDecompositionService.decompose(friedRice),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: PlateBreakdownView(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify header & meal info
      expect(find.text('Plate Breakdown'), findsOneWidget);
      expect(find.text('Fried Rice'), findsOneWidget);

      // Verify Plate Composition Card is removed
      expect(find.text('Plate Composition'), findsNothing);

      // Verify AI Ingredient Insights Card is rendered
      expect(find.text('AI Ingredient Insights'), findsOneWidget);

      // Verify authentic ingredients are rendered, NOT "Fried Rice" as an ingredient
      expect(find.text('Cooked Jasmine Rice'), findsOneWidget);
      expect(find.text('Scrambled Egg'), findsOneWidget);
      expect(find.text('Vegetable Cooking Oil'), findsOneWidget);
      expect(find.text('Spring Onions & Carrots'), findsOneWidget);
      expect(find.text('Soy Sauce & Garlic'), findsOneWidget);
    },
  );
}
