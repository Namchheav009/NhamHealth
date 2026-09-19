import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/ai_food_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/calories_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/food_nutrition_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/wellness/food_nutrition_repository.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_ai_service.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_recommendation_service.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/ai_food_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/ai_food_detected_food_sheet.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/ai_food_nutrition_result_content.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/ai_food_scan_content.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/ai_food_tips_sheet.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/page_skeleton.dart';
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

  Widget buildTestView() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: const AiFoodView(),
    );
  }

  testWidgets(
    'Header remains "AI Food Check" across scanner state and analysis success state',
    (tester) async {
      await tester.pumpWidget(buildTestView());
      await tester.pumpAndSettle();

      // In initial scan state:
      expect(find.text('AI Food Check'), findsOneWidget);
      expect(find.text('Know what you eat, live healthier'), findsOneWidget);
      expect(find.byType(AiFoodScanContent), findsOneWidget);
      expect(find.byType(AiFoodNutritionResultContent), findsNothing);

      // Transition to analysis success state:
      controller.nutrition.value = const FoodNutritionModel(
        name: 'Avocado Toast & Poached Egg',
        calories: 380,
        protein: 16,
        carbs: 28,
        fat: 22,
        sugar: 2.5,
        fiber: 7,
        sodium: 120,
        servingSize: 1,
        servingUnit: 'portion',
        confidence: 0.95,
        cuisine: 'Healthy',
      );
      await tester.pumpAndSettle();

      // Verify Header NEVER changes:
      expect(find.text('AI Food Check'), findsOneWidget);
      expect(find.text('Know what you eat, live healthier'), findsOneWidget);
      expect(find.text('Nutrition Details'), findsNothing);

      // Verify result content and bottom bar are rendered:
      expect(find.byType(AiFoodNutritionResultContent), findsOneWidget);
      expect(find.byType(AiFoodNutritionResultBottomBar), findsOneWidget);
      expect(find.text('Avocado Toast & Poached Egg'), findsOneWidget);
      expect(find.text('Save to Favorites'), findsNothing);
      expect(find.text("Add to Today's Food"), findsOneWidget);

      // When back button is tapped while viewing results, resets to scan state without leaving
      final backButton = find.byKey(
        const ValueKey<String>('ai-food-back-button'),
      );
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(controller.hasCompleteResult, isFalse);
      expect(find.byType(AiFoodScanContent), findsOneWidget);
      expect(find.byType(AiFoodNutritionResultContent), findsNothing);
      expect(find.text('AI Food Check'), findsOneWidget);
    },
  );

  testWidgets('displays page skeleton when model is loading', (tester) async {
    controller.isModelLoading.value = true;
    await tester.pumpWidget(buildTestView());
    await tester.pump();

    expect(find.byType(PageSkeleton), findsOneWidget);

    controller.isModelLoading.value = false;
    await tester.pumpAndSettle();

    expect(find.byType(PageSkeleton), findsNothing);
    expect(find.byType(AiFoodScanContent), findsOneWidget);
  });

  testWidgets(
    'tapping Detected Food card opens AiFoodDetectedFoodSheet and updates food name and type',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.selectedImage.value = File('test_image.jpg');
      await tester.pumpWidget(buildTestView());
      await tester.pumpAndSettle();

      final detectedFoodCard = find.text('Detected Food');
      expect(detectedFoodCard, findsOneWidget);

      await tester.tap(detectedFoodCard);
      await tester.pumpAndSettle();

      expect(find.byType(AiFoodDetectedFoodSheet), findsOneWidget);

      // Change food name to "Iced Coffee"
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, 'Iced Coffee');
      await tester.pumpAndSettle();

      // Select Drink / Beverage
      final drinkOption = find.text('Drink / Beverage');
      await tester.tap(drinkOption);
      await tester.pumpAndSettle();

      // Tap Save Changes
      final saveButton = find.text('Save Changes');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Sheet dismissed and controller updated
      expect(find.byType(AiFoodDetectedFoodSheet), findsNothing);
      expect(controller.detectedFoodName, 'Iced Coffee');
      expect(controller.inputKind.value, AiFoodInputKind.drink);
    },
  );

  testWidgets('tapping Tip card opens AiFoodTipsSheet', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    controller.selectedImage.value = File('test_image.jpg');
    await tester.pumpWidget(buildTestView());
    await tester.pumpAndSettle();

    final tipCard = find.text('Tip');
    expect(tipCard, findsOneWidget);

    await tester.tap(tipCard);
    await tester.pumpAndSettle();

    expect(find.byType(AiFoodTipsSheet), findsOneWidget);
    expect(find.text('Photography Tips'), findsOneWidget);
    expect(find.text('Good, Bright Lighting'), findsOneWidget);

    // Dismiss sheet
    final gotItButton = find.text('Got it, thanks!');
    await tester.tap(gotItButton);
    await tester.pumpAndSettle();

    expect(find.byType(AiFoodTipsSheet), findsNothing);
  });
}
