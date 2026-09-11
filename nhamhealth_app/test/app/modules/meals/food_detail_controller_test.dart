import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/meals/food_detail_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_category_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/meals/meal_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/meals/food_detail_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/app_locale_service.dart';

class FakeMealRepository implements MealRepository {
  final List<String> requestedLanguages = [];
  MealModel? nextMealDetail;

  @override
  Future<MealModel> getMealDetail(int mealId, {String languageCode = 'en'}) async {
    requestedLanguages.add(languageCode);
    if (nextMealDetail != null) return nextMealDetail!;
    return MealModel(
      id: mealId,
      name: languageCode == 'km' ? 'បាយសាច់ជ្រូក' : 'Bai Sach Chrouk',
      calories: 500,
      image: 'assets/images/meals/salad.png',
      category: languageCode == 'km' ? 'អាហារពេលព្រឹក' : 'Breakfast',
      categoryId: 1,
      languageCode: languageCode,
    );
  }

  @override
  Future<List<MealCategoryModel>> getCategories({String? languageCode}) async => [];

  @override
  Future<Set<int>> getFavoriteMealIds() async => {};

  @override
  Future<List<MealModel>> getMeals({
    String keyword = '',
    int categoryId = 0,
    String? languageCode,
  }) async => [];

  @override
  Future<List<MealModel>> getPersonalizedMealIdeas({bool refresh = false}) async => [];

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<void> setFavorite(int mealId, {required bool favorite}) async {}
}

void main() {
  setUp(() {
    Get.reset();
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
  });

  tearDown(() {
    Get.reset();
  });

  test('FoodDetailController initializes with current app locale', () async {
    final localeService = AppLocaleService();
    localeService.currentLocale.value = AppLocaleService.khmerLocale;
    final fakeRepo = FakeMealRepository();

    final controller = FoodDetailController(
      repository: fakeRepo,
      localeService: localeService,
    );

    controller.detail.value = MealModel(
      id: 10,
      name: 'Initial Meal',
      calories: 500,
      image: '',
      category: 'Breakfast',
      categoryId: 1,
    );

    controller.onInit();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.languageCode.value, 'km');
    expect(fakeRepo.requestedLanguages, contains('km'));
    expect(controller.meal?.name, 'បាយសាច់ជ្រូក');
    expect(controller.meal?.category, 'អាហារពេលព្រឹក');

    controller.onClose();
  });

  test('FoodDetailController automatically updates and reloads when app locale changes', () async {
    final localeService = AppLocaleService();
    localeService.currentLocale.value = AppLocaleService.englishLocale;
    final fakeRepo = FakeMealRepository();

    final controller = FoodDetailController(
      repository: fakeRepo,
      localeService: localeService,
    );

    controller.detail.value = MealModel(
      id: 10,
      name: 'Initial Meal',
      calories: 500,
      image: '',
      category: 'Breakfast',
      categoryId: 1,
    );

    controller.onInit();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.languageCode.value, 'en');
    expect(fakeRepo.requestedLanguages.last, 'en');
    expect(controller.meal?.name, 'Bai Sach Chrouk');

    // Simulate changing app locale to Khmer in settings
    localeService.currentLocale.value = AppLocaleService.khmerLocale;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.languageCode.value, 'km');
    expect(fakeRepo.requestedLanguages.last, 'km');
    expect(controller.meal?.name, 'បាយសាច់ជ្រូក');

    // Simulate changing app locale back to English
    localeService.currentLocale.value = AppLocaleService.englishLocale;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(controller.languageCode.value, 'en');
    expect(fakeRepo.requestedLanguages.last, 'en');
    expect(controller.meal?.name, 'Bai Sach Chrouk');

    controller.onClose();
  });

  testWidgets('FoodDetailView does not render manual language selector toggle', (tester) async {
    final localeService = AppLocaleService();
    localeService.currentLocale.value = AppLocaleService.khmerLocale;
    final fakeRepo = FakeMealRepository();

    final controller = FoodDetailController(
      repository: fakeRepo,
      localeService: localeService,
    );
    controller.detail.value = MealModel(
      id: 10,
      name: 'បាយសាច់ជ្រូក',
      calories: 500,
      image: 'assets/images/meals/salad.png',
      category: 'អាហារពេលព្រឹក',
      categoryId: 1,
      languageCode: 'km',
    );
    Get.put<FoodDetailController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: AppLocaleService.khmerLocale,
        home: const FoodDetailView(),
      ),
    );
    await tester.pumpAndSettle();

    // The manual toggle buttons 'EN' and 'ខ្មែរ' must NOT be rendered on FoodDetailView
    expect(find.text('EN'), findsNothing);
    // Note: meal title or Khmer texts may exist, but the standalone switcher option should not exist
    expect(find.text('បាយសាច់ជ្រូក'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('FoodDetailController immediately localizes argument meal description to Khmer without delay', () async {
    final localeService = AppLocaleService();
    localeService.currentLocale.value = AppLocaleService.khmerLocale;
    final fakeRepo = FakeMealRepository();

    final englishMeal = MealModel(
      id: 1,
      name: 'Bai Sach Chrouk',
      calories: 1108,
      image: '',
      category: 'Breakfast',
      categoryId: 1,
      description:
          "Cambodia's most-loved breakfast — charcoal-grilled marinated pork over broken rice, with a bowl of clear broth and a heap of quick pickles.",
      languageCode: 'en',
    );

    final controller = FoodDetailController(
      repository: fakeRepo,
      localeService: localeService,
      initialMeal: englishMeal,
    );

    controller.onInit();

    // Even before loadDetail completes, controller.meal is ALREADY localized to Khmer!
    expect(controller.meal?.name, 'បាយសាច់ជ្រូក');
    expect(controller.meal?.category, 'អាហារពេលព្រឹក');
    expect(
      controller.meal?.description,
      "អាហារពេលព្រឹកដែលពេញនិយមបំផុតរបស់ប្រទេសកម្ពុជា — សាច់ជ្រូកអាំងដុតធ្យូងពីលើអង្ករសម្រូប ជាមួយនឹងទឹកស៊ុបថ្លា និងម្ហូបជ្រក់មួយចាន។",
    );

    controller.onClose();
  });

  test('MealIngredientModel.fromJson strips scraper debug notes from description', () {
    final model = MealIngredientModel.fromJson({
      'name': 'cucumber, tomato and a fried egg',
      'description': 'Auto-created from reviewed scraped recipe source: Cambodia Cooking Recipes',
      'imageUrl': '',
      'quantity': null,
      'unit': '',
    }, baseUrl: 'http://localhost:8080');

    expect(model.description, '');
    expect(model.name, 'cucumber, tomato and a fried egg');
  });

  testWidgets('FoodDetailView renders ingredients without amount overflow or scraper notes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 1600);
    addTearDown(tester.view.reset);

    final localeService = AppLocaleService();
    localeService.currentLocale.value = AppLocaleService.khmerLocale;
    final fakeRepo = FakeMealRepository();

    final testMeal = MealModel(
      id: 10,
      name: 'បាយសាច់ជ្រូក',
      calories: 500,
      image: 'assets/images/meals/salad.png',
      category: 'អាហារពេលព្រឹក',
      categoryId: 1,
      languageCode: 'km',
      ingredients: const [
        MealIngredientModel(
          name: 'cucumber, tomato and a fried egg',
          description: 'Auto-created from reviewed scraped recipe source: Cambodia Cooking Recipes',
          image: '',
          quantity: null,
          unit: '',
        ),
        MealIngredientModel(
          name: 'spring onion and a pinch of white pepper',
          description: 'Auto-created from reviewed scraped recipe source: Cambodia Cooking Recipes',
          image: '',
          quantity: null,
          unit: '',
        ),
        MealIngredientModel(
          name: 'pork',
          description: '',
          image: '',
          quantity: 200,
          unit: 'g',
        ),
      ],
    );
    fakeRepo.nextMealDetail = testMeal;

    final controller = FoodDetailController(
      repository: fakeRepo,
      localeService: localeService,
      initialMeal: testMeal,
    );
    Get.put<FoodDetailController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        locale: AppLocaleService.khmerLocale,
        home: const FoodDetailView(),
      ),
    );
    await tester.pumpAndSettle();

    // Ingredient names must be visible
    expect(find.text('cucumber, tomato and a fried egg'), findsOneWidget);
    expect(find.text('spring onion and a pinch of white pepper'), findsOneWidget);
    expect(find.text('pork'), findsOneWidget);

    // Scraper debug notes must NEVER appear in the UI
    expect(find.textContaining('Auto-created'), findsNothing);
    expect(find.textContaining('scraped recipe source'), findsNothing);

    // Amount pill shows '—' for ingredients with null quantity, and '200 g' for pork
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('200 g'), findsOneWidget);

    // No RenderFlex overflow or layout error
    expect(tester.takeException(), isNull);
  });
}
