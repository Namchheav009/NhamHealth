import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/meals/food_detail_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/meals/meal_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_category_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/meals/meal_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/meals/food_detail_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/meals/widgets/meal_filter_sheet.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/app_locale_service.dart';

class _FakeMealRepository implements MealRepository {
  MealModel? nextMealDetail;

  @override
  Future<MealModel> getMealDetail(
    int mealId, {
    String languageCode = 'en',
  }) async {
    if (nextMealDetail != null) return nextMealDetail!;
    return MealModel(
      id: 1,
      name: 'Khmer Chicken Curry',
      calories: 450,
      image: 'assets/images/meals/salad.png',
      category: 'Lunch',
      categoryId: 2,
    );
  }

  @override
  Future<List<MealCategoryModel>> getCategories({String? languageCode}) async =>
      const [
        MealCategoryModel(id: 1, name: 'Breakfast'),
        MealCategoryModel(id: 2, name: 'Lunch'),
      ];

  @override
  Future<Set<int>> getFavoriteMealIds() async => {};

  @override
  Future<List<MealModel>> getMeals({
    String keyword = '',
    int categoryId = 0,
    String? languageCode,
  }) async => [];

  @override
  Future<List<MealModel>> getPersonalizedMealIdeas({
    bool refresh = false,
  }) async => [];

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<void> setFavorite(int mealId, {required bool favorite}) async {}
}

void main() {
  late _FakeMealRepository fakeRepo;
  late AppLocaleService localeService;

  setUp(() {
    Get.reset();
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    fakeRepo = _FakeMealRepository();
    localeService = AppLocaleService();
  });

  tearDown(() {
    Get.reset();
  });

  MealModel createTestMeal() => MealModel(
    id: 1,
    name: 'Somlor Kari',
    description: 'A fragrant Cambodian curry made with tender chicken.',
    calories: 420,
    proteinGrams: 30,
    cookingTimeMinutes: 30,
    difficulty: 'Medium',
    servings: 4,
    image: 'assets/images/meals/salad.png',
    category: 'Lunch',
    categoryId: 2,
    ingredients: const [
      MealIngredientModel(
        name: 'Chicken breast',
        description: '',
        image: '',
        quantity: 300,
        unit: 'g',
      ),
      MealIngredientModel(
        name: 'Coconut milk',
        description: '',
        image: '',
        quantity: 200,
        unit: 'ml',
      ),
    ],
    steps: const [
      MealStepModel(number: 1, instruction: 'Sauté curry paste with aromatics.'),
      MealStepModel(number: 2, instruction: 'Add chicken and simmer until cooked.'),
    ],
  );

  Widget buildTestApp(Widget home) => GetMaterialApp(
    theme: AppTheme.light,
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    home: home,
  );

  group('MealFilterButton responsiveness', () {
    testWidgets('opens bottom sheet with drag handle on phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MealController(
        repository: fakeRepo,
        localeService: localeService,
      );
      Get.put<MealController>(controller);

      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            body: Center(child: MealFilterButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('meal-filter-button')));
      await tester.pumpAndSettle();

      // In phone bottom sheet, close button is NOT rendered in the header
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      // Header and clear all are present
      expect(find.text('Meal filters'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      Get.back<void>();
      await tester.pumpAndSettle();

      controller.onClose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens centered dialog with close button on tablet viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = MealController(
        repository: fakeRepo,
        localeService: localeService,
      );
      Get.put<MealController>(controller);

      await tester.pumpWidget(
        buildTestApp(
          const Scaffold(
            body: Center(child: MealFilterButton()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('meal-filter-button')));
      await tester.pumpAndSettle();

      // In tablet dialog, Dialog widget is present
      expect(find.byType(Dialog), findsOneWidget);
      // Close button is rendered in the dialog header
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('Meal filters'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);

      // Tapping close dismisses dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      controller.onClose();
      expect(tester.takeException(), isNull);
    });
  });

  group('FoodDetailView responsiveness', () {
    testWidgets('renders single column layout on phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final meal = createTestMeal();
      fakeRepo.nextMealDetail = meal;
      final controller = FoodDetailController(
        repository: fakeRepo,
        localeService: localeService,
        initialMeal: meal,
      );
      Get.put<FoodDetailController>(controller);

      await tester.pumpWidget(
        buildTestApp(const FoodDetailView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Somlor Kari'), findsOneWidget);
      expect(find.text('Chicken breast'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders portrait tablet layout with expanded width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final meal = createTestMeal();
      fakeRepo.nextMealDetail = meal;
      final controller = FoodDetailController(
        repository: fakeRepo,
        localeService: localeService,
        initialMeal: meal,
      );
      Get.put<FoodDetailController>(controller);

      await tester.pumpWidget(
        buildTestApp(const FoodDetailView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Somlor Kari'), findsOneWidget);
      expect(find.text('Chicken breast'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders 2-column side-by-side layout on landscape tablet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final meal = createTestMeal();
      fakeRepo.nextMealDetail = meal;
      final controller = FoodDetailController(
        repository: fakeRepo,
        localeService: localeService,
        initialMeal: meal,
      );
      Get.put<FoodDetailController>(controller);

      await tester.pumpWidget(
        buildTestApp(const FoodDetailView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Somlor Kari'), findsOneWidget);
      expect(find.text('Chicken breast'), findsOneWidget);

      // Verify that the overview and tabs appear side-by-side (different x coordinates)
      final titleTopLeft = tester.getTopLeft(find.text('Somlor Kari'));
      final tabTopLeft = tester.getTopLeft(find.textContaining('Ingredients'));
      expect(tabTopLeft.dx, greaterThan(titleTopLeft.dx + 200));

      // Switch to steps tab and verify instructions are visible
      await tester.tap(find.textContaining('How to make'));
      await tester.pumpAndSettle();
      expect(find.text('Sauté curry paste with aromatics.'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
