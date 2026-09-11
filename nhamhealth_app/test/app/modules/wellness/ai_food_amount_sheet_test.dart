import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/ai_food_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/calories_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/wellness/food_nutrition_repository.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_ai_service.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_recommendation_service.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/ai_food_amount_sheet.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  late AiFoodController controller;

  setUp(() {
    controller = AiFoodController(
      aiService: FoodAiService(),
      nutritionRepository: FoodNutritionRepository(),
      recommendationService: FoodRecommendationService(),
      caloriesController: CaloriesController(),
      wellnessController: WellnessController(),
      profileRepository: ProfileRepository(authService: AuthService()),
    );
  });

  tearDown(() {
    controller.onClose();
  });

  Widget buildTestSheet() {
    return GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      home: Scaffold(body: AiFoodAmountSheet(controller: controller)),
    );
  }

  testWidgets(
    'renders food amount sheet with icons, quick select chips, and preview',
    (tester) async {
      controller.setInputKind(AiFoodInputKind.food);
      controller.setFoodAmount(0.5);

      await tester.pumpWidget(buildTestSheet());
      await tester.pumpAndSettle();

      // Verify header icon and title
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
      expect(find.text('Edit food amount'), findsOneWidget);
      expect(find.text('Adjust the amount you actually ate.'), findsOneWidget);

      // Verify quick select chips
      expect(find.text('1/4'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('1.5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Verify preview box and info notice
      expect(find.text('Preview (estimated)'), findsOneWidget);
      expect(
        find.text('Nutrition will be recalculated based on the new amount.'),
        findsOneWidget,
      );

      // Tap quick select chip 1.5
      await tester.tap(find.text('1.5'));
      await tester.pumpAndSettle();
      expect(controller.foodAmount.value, 1.5);
    },
  );

  testWidgets(
    'renders drink amount sheet with cup sizes, slider, and sugar % selector',
    (tester) async {
      controller.setInputKind(AiFoodInputKind.drink);
      controller.setDrinkCupMl(350);
      controller.setDrinkConsumedFraction(0.5);
      controller.setDrinkSugarPercentage(50);

      await tester.pumpWidget(buildTestSheet());
      await tester.pumpAndSettle();

      // Verify header icon and title
      expect(find.byIcon(Icons.local_drink_rounded), findsWidgets);
      expect(find.text('Edit drink amount'), findsOneWidget);
      expect(
        find.text('Select the cup size and how much you drank.'),
        findsOneWidget,
      );

      // Verify cup sizes
      expect(find.text('S'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Verify sugar level section and chips
      expect(find.text('Sugar level'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(
        find.text('25%'),
        findsWidgets,
      ); // May appear in slider and sugar chips
      expect(find.text('50%'), findsWidgets);
      expect(find.text('75%'), findsWidgets);
      expect(find.text('100%'), findsWidgets);

      // Verify volume to analyse preview
      expect(find.text('Volume to analyse'), findsOneWidget);
      expect(find.text('175 ml'), findsOneWidget);

      // Tap sugar % chip 25%
      await tester.tap(find.text('25%').last);
      await tester.pumpAndSettle();
      expect(controller.drinkSugarPercentage.value, 25);

      // Tap cup size L
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();
      expect(controller.drinkCupMl.value, 500);
    },
  );
}
