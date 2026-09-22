import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/weight_loss_projection_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/weight_loss_forecast_model.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/meal_planner_flow_views.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/meal_planner_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/planner_shared.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/ingredient_avatar.dart';
import 'package:nhamhealth_flutter/app/routes/app_routes.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() => Get.testMode = true);
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    Get.testMode = true;
  });
  tearDown(Get.reset);

  testWidgets('Auto Fill uses choices without text input or tile assertion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.reset);
    final planner = Get.put(MealPlannerController());
    await planner.addMeal(
      const PlannedMeal(
        id: 901,
        name: 'Saved breakfast',
        calories: 320,
        slot: MealPlanSlot.breakfast,
        ingredients: ['Oats'],
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showAutoFillConfirmDialog(context, planner),
                  child: const Text('Open Auto Fill'),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('Open Auto Fill'));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Maintain Health'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('2  Food preferences'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Peanut'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('2  Food preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rebalance Entire Week'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto-Fill Weight Loss Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Replace your planned meals?'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('Replace your planned meals?'), findsNothing);
    expect(find.text('Auto-Fill Weight Loss Plan'), findsOneWidget);

    await tester.tap(find.text('2  Food preferences'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pregnant / breastfeeding'));
    await tester.pumpAndSettle();
    expect(find.text('Auto-Fill unavailable'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Auto-Fill unavailable'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('Meal Planner shows a skeleton during Auto Fill', (tester) async {
    final planner = Get.put(MealPlannerController());
    planner.hasLoadedOnce.value = true;
    planner.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const MealPlannerView(),
      ),
    );

    planner.isAutoFilling.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('planner-autofill-skeleton')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('planner-week-card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('planner-daily-overview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('planner-slots-skeleton')),
      findsOneWidget,
    );
    expect(find.text('Creating your meal plan'), findsOneWidget);
    expect(
      find.text('Checking your goal and food preferences…'),
      findsOneWidget,
    );

    planner.autoFillStatusKey.value = 'planner.autofill_loading_refreshing';
    await tester.pump();
    expect(find.text('Updating your saved meals…'), findsOneWidget);

    planner.isAutoFilling.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('planner-autofill-skeleton')),
      findsNothing,
    );
  });

  testWidgets('Auto Fill success sheet works without an AI result', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => showAiAutoFillResultSheet(context, filledCount: 4),
                  child: const Text('Open result'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open result'));
    await tester.pumpAndSettle();
    expect(find.text('Your meal plan is ready'), findsOneWidget);
    expect(find.text('Successfully filled 4 meals!'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('planner-autofill-success-sheet')),
      findsNothing,
    );
  });

  testWidgets('keeps meal cards consistent without forecast suggestions', (
    tester,
  ) async {
    final planner = Get.put(MealPlannerController());
    planner.healthGoal.value = MealPlannerHealthGoal.loseWeight;
    await planner.addMeal(
      const PlannedMeal(
        id: 802,
        name: 'Planned Rice Bowl',
        calories: 510,
        slot: MealPlanSlot.lunch,
        ingredients: ['Rice'],
      ),
    );
    final forecastController = Get.put(WeightLossProjectionController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const MealPlannerView(),
      ),
    );
    forecastController.forecast.value = WeightLossForecast.fromJson({
      'currentWeightKg': 75,
      'targetWeightKg': 72,
      'projectedWeightLossKg': 2,
      'projectedEndWeightKg': 73,
      'bmrCalories': 1600,
      'tdeeCalories': 2300,
      'dailyPlannedCalories': 1800,
      'dailyDeficitCalories': 500,
      'timeframeDays': 28,
      'weeklyPaceKg': 0.45,
      'paceStatus': 'OPTIMAL',
      'paceDescription': 'Healthy pace',
      'calorieWarning': false,
      'calorieWarningMessage': '',
      'recommendedFoods': [
        {
          'itemType': 'FOOD',
          'sourceId': 901,
          'sourceTable': 'planner_meals',
          'name': 'AI Grilled Chicken Bowl',
          'category': 'Lunch',
          'calories': 420,
          'proteinGrams': 38,
          'carbsGrams': 35,
          'fatGrams': 10,
          'servingUnit': 'bowl',
          'servingSize': 1,
          'imageUrl': '',
          'rationale': 'High protein lunch.',
          'ibmBadge': 'AI',
        },
      ],
      'recommendedBeverages': <Map<String, dynamic>>[],
      'aiAnalysisSummary': 'Balanced plan',
      'hasPlannedMeals': true,
    });
    forecastController.isLoading.value = false;
    await tester.pump();

    expect(
      find.byKey(const ValueKey('planner-ingredient-analysis-banner')),
      findsNothing,
    );
    expect(find.text('AI Ingredient Analysis'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('planner-meal-card-lunch')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    final lunchCard = find.byKey(const ValueKey('planner-meal-card-lunch'));
    expect(
      find.descendant(of: lunchCard, matching: find.byType(PlannerMealImage)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: lunchCard, matching: find.text('Planned Rice Bowl')),
      findsOneWidget,
    );
    expect(find.text('AI Grilled Chicken Bowl'), findsNothing);
    expect(find.text('Suggested alternative'), findsNothing);
    expect(
      find.byKey(const ValueKey('planner-ai-suggestion-lunch')),
      findsNothing,
    );
    expect(
      tester.getSize(lunchCard).height,
      tester
          .getSize(find.byKey(const ValueKey('planner-meal-card-breakfast')))
          .height,
    );
  });

  testWidgets('user can add a suggested meal to the selected day', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1000);
    addTearDown(tester.view.reset);

    final controller = Get.put(MealPlannerController());
    controller.adminRecommendations.add(
      PlannedMeal(
        id: 101,
        name: 'Oatmeal with banana',
        calories: 360,
        proteinGrams: 12,
        slot: MealPlanSlot.breakfast,
        recommendedWeekday: controller.selectedDate.weekday,
        category: 'Breakfast',
        ingredients: const ['Oats', 'Banana'],
        imageUrl: 'assets/images/meals/healthy_salad.jpg',
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: AppRoutes.mealPlanner,
        getPages: [
          GetPage(
            name: AppRoutes.mealPlanner,
            page: () => const MealPlannerView(),
          ),
          GetPage(
            name: AppRoutes.mealPlannerCategories,
            page: () => const PlannerCategoryView(),
          ),
          GetPage(
            name: AppRoutes.mealPlannerMeals,
            page: () => const PlannerMealListView(),
          ),
          GetPage(
            name: AppRoutes.mealPlannerDetail,
            page: () => const PlannerMealDetailView(),
          ),
          GetPage(
            name: AppRoutes.mealPlannerGrocery,
            page: () => const PlannerGroceryView(),
          ),
        ],
      ),
    );

    expect(find.text('Meal Planner'), findsOneWidget);
    expect(find.textContaining('0/4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('planner-daily-overview')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('planner-daily-progress')),
          )
          .value,
      0,
    );

    final breakfastSlot = find.byKey(const ValueKey('planner-slot-breakfast'));
    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.ensureVisible(breakfastSlot);
    await tester.tap(breakfastSlot);
    await tester.pumpAndSettle();
    expect(find.text('Select Meal'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('planner-slot-filters')),
      findsOneWidget,
    );
    expect(find.text('Find healthy meals for your day'), findsNothing);
    expect(find.text('Filter by nutrition'), findsNothing);
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Filter by nutrition'), findsOneWidget);
    await tester.tap(find.text('Low calorie'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final mealCard = find.ancestor(
      of: find.text('Oatmeal with banana'),
      matching: find.byType(InkWell),
    );
    final quickAdd = find.descendant(
      of: mealCard,
      matching: find.byIcon(Icons.add_rounded),
    );
    await tester.tap(quickAdd);
    // The planner can display a continuously animated image/skeleton while the
    // route transition completes, so a bounded pump is more deterministic than
    // waiting for every animation in the tree to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Oatmeal with banana'), findsOneWidget);
    expect(find.textContaining('0/4'), findsOneWidget);
    expect(find.text('360'), findsOneWidget);

    Get.closeAllSnackbars();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.tap(find.text('Generate grocery list'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Organized grocery list'), findsOneWidget);
    expect(find.text('Selected day'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('grocery-page-item-oats|')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('grocery-page-item-oats|')),
        matching: find.byType(IngredientAvatar),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('grocery-page-item-oats|')),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('grocery-page-item-oats|')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Meals using this ingredient'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('grocery-detail-image-oats|')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grocery-detail-toggle-oats|')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('grocery-detail-analyze-oats|')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('grocery-detail-toggle-oats|')),
    );
    await tester.tap(find.byKey(const ValueKey('grocery-detail-toggle-oats|')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1 of 2 items checked'), findsOneWidget);
    await tester.ensureVisible(find.text('Full week'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Full week'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('grocery-page-item-oats|')),
      findsOneWidget,
    );
    expect(find.text('Grocery List'), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('meal options are scrollable on a short screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 700);
    addTearDown(tester.view.reset);

    final controller = Get.put(MealPlannerController());
    await controller.addMeal(
      const PlannedMeal(
        id: 101,
        name: 'Scrambled Egg & Avocado Breakfast',
        calories: 470,
        slot: MealPlanSlot.breakfast,
        ingredients: ['Egg', 'Avocado'],
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const MealPlannerView(),
      ),
    );
    final slot = find.byKey(const ValueKey('planner-slot-breakfast'));
    await tester.drag(find.byType(ListView), const Offset(0, -360));
    await tester.pumpAndSettle();
    await tester.ensureVisible(slot);
    await tester.pumpAndSettle();
    await tester.tap(slot);
    await tester.pumpAndSettle();

    expect(find.text('Mark as eaten'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(find.text('Remove meal'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'user can customize plan duration (3-7 days) and open custom plan modal',
    (tester) async {
      final controller = Get.put(MealPlannerController());
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const MealPlannerView(),
        ),
      );

      // Initial state: "Selected week" and 7 days
      expect(find.text('Selected week'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('planner-week-picker-button')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('planner-week-card'))).height,
        lessThan(205),
      );
      expect(
        find.byKey(const ValueKey('planner-week-today-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('planner-day-6')), findsOneWidget);

      // Tap the date form / Detail button to open the custom plan sheet
      await tester.tap(
        find.byKey(const ValueKey('planner-week-picker-button')),
      );
      await tester.pumpAndSettle();

      // Verify modal is open with duration choices (3 to 7 days)
      expect(find.text('Customize plan'), findsOneWidget);
      expect(find.byKey(const ValueKey('modal-duration-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('modal-duration-4')), findsOneWidget);
      expect(find.byKey(const ValueKey('modal-duration-5')), findsOneWidget);

      // Select 3 days inside modal and apply
      await tester.tap(find.byKey(const ValueKey('modal-duration-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(controller.planDaysCount.value, 3);
      expect(find.byKey(const ValueKey('planner-day-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('planner-day-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('planner-day-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('planner-day-3')), findsNothing);

      // Now open modal again and select 4 days
      await tester.tap(
        find.byKey(const ValueKey('planner-week-picker-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('modal-duration-4')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(controller.planDaysCount.value, 4);
      expect(find.byKey(const ValueKey('planner-day-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('planner-day-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('planner-day-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('planner-day-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('planner-day-4')), findsNothing);

      // Change week to +1
      controller.changeWeek(1);
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);

      // Tapping "Today" brings back to today
      await tester.tap(find.byKey(const ValueKey('planner-week-today-button')));
      await tester.pumpAndSettle();
      expect(controller.weekOffset.value, 0);
      expect(find.text('Customize plan'), findsNothing);
    },
  );
}
