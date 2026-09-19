import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/meal_planner_flow_views.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/meal_planner_view.dart';
import 'package:nhamhealth_flutter/app/routes/app_routes.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/page_skeleton.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    Get.testMode = true;
  });

  tearDown(Get.reset);

  Widget createTestApp({required String initialRoute, dynamic arguments}) {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      initialRoute: initialRoute,
      getPages: [
        GetPage(
          name: AppRoutes.mealPlanner,
          page: () => const MealPlannerView(),
        ),
        GetPage(
          name: AppRoutes.mealPlannerCategories,
          page: () => const PlannerCategoryView(),
          arguments: arguments,
        ),
        GetPage(
          name: AppRoutes.mealPlannerMeals,
          page: () => const PlannerMealListView(),
          arguments: arguments,
        ),
        GetPage(
          name: AppRoutes.mealPlannerDetail,
          page: () => const PlannerMealDetailView(),
          arguments: arguments,
        ),
        GetPage(
          name: AppRoutes.mealPlannerWeek,
          page: () => const PlannerWeeklyView(),
        ),
        GetPage(
          name: AppRoutes.mealPlannerGrocery,
          page: () => const PlannerGroceryView(),
        ),
      ],
    );
  }

  testWidgets('MealPlannerView shows mealPlanner skeleton when loading', (
    tester,
  ) async {
    final controller = Get.put(MealPlannerController());
    controller.isLoading.value = true;
    controller.hasLoadedOnce.value = false;

    await tester.pumpWidget(createTestApp(initialRoute: AppRoutes.mealPlanner));
    await tester.pump();

    expect(find.byType(PageSkeleton), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('meal-planner-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets('PlannerWeeklyView shows plannerWeek skeleton when loading', (
    tester,
  ) async {
    final controller = Get.put(MealPlannerController());
    controller.isLoading.value = true;
    controller.hasLoadedOnce.value = false;

    await tester.pumpWidget(
      createTestApp(initialRoute: AppRoutes.mealPlannerWeek),
    );
    await tester.pump();

    expect(find.byType(PageSkeleton), findsWidgets);
    expect(
      find.byKey(const ValueKey<String>('planner-week-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets(
    'PlannerGroceryView shows plannerGrocery skeleton when loading without flashing empty state',
    (tester) async {
      final controller = Get.put(MealPlannerController());
      controller.isLoading.value = true;
      controller.hasLoadedOnce.value = false;

      await tester.pumpWidget(
        createTestApp(initialRoute: AppRoutes.mealPlannerGrocery),
      );
      await tester.pump();

      expect(find.byType(PageSkeleton), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('planner-grocery-skeleton')),
        findsOneWidget,
      );
      expect(find.text('No groceries yet'), findsNothing);
    },
  );

  testWidgets(
    'PlannerCategoryView shows plannerCategories skeleton when loading recommendations',
    (tester) async {
      final controller = Get.put(MealPlannerController());
      controller.isLoadingRecommendations.value = true;
      controller.adminRecommendations.clear();

      await tester.pumpWidget(
        createTestApp(
          initialRoute: AppRoutes.mealPlannerCategories,
          arguments: {'slot': MealPlanSlot.breakfast},
        ),
      );
      await tester.pump();

      expect(find.byType(PageSkeleton), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('planner-categories-skeleton')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'PlannerMealListView shows plannerMeals skeleton when loading recommendations',
    (tester) async {
      final controller = Get.put(MealPlannerController());
      controller.isLoadingRecommendations.value = true;
      controller.adminRecommendations.clear();

      await tester.pumpWidget(
        createTestApp(
          initialRoute: AppRoutes.mealPlannerMeals,
          arguments: {'slot': MealPlanSlot.breakfast},
        ),
      );
      await tester.pump();

      expect(find.byType(PageSkeleton), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('planner-meals-skeleton')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'MealPlannerView shows mealPlanner skeleton on reload without LinearProgressIndicator',
    (tester) async {
      final controller = Get.put(MealPlannerController());
      controller.hasLoadedOnce.value = true;
      controller.isLoading.value = true;

      await tester.pumpWidget(
        createTestApp(initialRoute: AppRoutes.mealPlanner),
      );
      await tester.pump();

      expect(find.byType(PageSkeleton), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('meal-planner-skeleton')),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'MealPlannerView shows plannerSlots skeleton during day change (isLoadingDay)',
    (tester) async {
      final controller = Get.put(MealPlannerController());
      controller.hasLoadedOnce.value = true;
      controller.isLoading.value = false;
      controller.isLoadingDay.value = true;

      await tester.pumpWidget(
        createTestApp(initialRoute: AppRoutes.mealPlanner),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('planner-slots-skeleton')),
        findsOneWidget,
      );
    },
  );

  testWidgets('PlannerWeeklyView shows plannerWeek skeleton on reload', (
    tester,
  ) async {
    final controller = Get.put(MealPlannerController());
    controller.hasLoadedOnce.value = true;
    controller.isLoading.value = true;

    await tester.pumpWidget(
      createTestApp(initialRoute: AppRoutes.mealPlannerWeek),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('planner-week-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets('PlannerGroceryView shows plannerGrocery skeleton on reload', (
    tester,
  ) async {
    final controller = Get.put(MealPlannerController());
    controller.hasLoadedOnce.value = true;
    controller.isLoading.value = true;

    await tester.pumpWidget(
      createTestApp(initialRoute: AppRoutes.mealPlannerGrocery),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('planner-grocery-skeleton')),
      findsOneWidget,
    );
  });

  testWidgets('PageSkeleton.box renders smoothly with custom dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageSkeleton.box(width: 80, height: 80, radius: 16),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PageSkeletonBox), findsOneWidget);
  });
}
