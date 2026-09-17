import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/meal_planner_flow_views.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/meal_planner_view.dart';
import 'package:nhamhealth_flutter/app/routes/app_routes.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('user can add a suggested meal to the selected day', (
    tester,
  ) async {
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
        ],
      ),
    );

    expect(find.text('Meal Planner'), findsOneWidget);
    expect(find.textContaining('0/4'), findsOneWidget);

    final breakfastSlot = find.byKey(const ValueKey('planner-slot-breakfast'));
    await tester.drag(find.byType(ListView), const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.ensureVisible(breakfastSlot);
    await tester.tap(breakfastSlot);
    await tester.pumpAndSettle();
    expect(find.text('Choose a category'), findsOneWidget);
    await tester.tap(find.text('All'));
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
    await tester.pumpAndSettle();

    expect(find.text('Oatmeal with banana'), findsOneWidget);
    expect(find.textContaining('0/4'), findsOneWidget);
    expect(find.text('360'), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
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
}
