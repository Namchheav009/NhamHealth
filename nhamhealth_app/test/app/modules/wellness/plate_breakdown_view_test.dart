import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/ai_food_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/calories_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_nutrition_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/plate_item_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/wellness/food_nutrition_repository.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_ai_service.dart';
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
      await tester.pumpAndSettle();

      // Verify PlateBreakdownView contains elements
      expect(find.text('Plate Breakdown'), findsNWidgets(2));
      expect(find.text('3 of 3 items selected'), findsOneWidget);
      expect(find.text('Beef Tenderloin'), findsOneWidget);
      expect(find.text('Jasmine Rice'), findsOneWidget);
      expect(find.text('Salad & Tomato'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    },
  );
}
