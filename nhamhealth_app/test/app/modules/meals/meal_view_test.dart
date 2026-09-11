import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/meals/meal_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_category_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/meals/meal_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/meals/meal_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/app_locale_service.dart';

class TestMealRepository implements MealRepository {
  @override
  Future<List<MealCategoryModel>> getCategories({String? languageCode}) async => [
    const MealCategoryModel(id: 1, name: 'Breakfast'),
    const MealCategoryModel(id: 2, name: 'Lunch'),
  ];

  @override
  Future<List<MealModel>> getMeals({String keyword = '', int categoryId = 0, String? languageCode}) async => [
    MealModel(
      id: 1,
      name: 'Bai Sach Chrouk',
      calories: 1108,
      image: 'assets/images/meals/healthy_salad.jpg',
      category: 'Breakfast',
      categoryId: 1,
      cookingTimeMinutes: 20,
    ),
  ];

  @override
  Future<List<MealModel>> getPersonalizedMealIdeas({bool refresh = false}) async => [
    MealModel(
      id: 2,
      name: 'Fish Amok',
      calories: 550,
      image: 'assets/images/meals/healthy_salad.jpg',
      category: 'Lunch',
      categoryId: 2,
      cookingTimeMinutes: 30,
      recommendationReason: 'A balanced, varied option selected for your daily wellness goals.',
    ),
  ];

  @override
  Future<Set<int>> getFavoriteMealIds() async => {};

  @override
  Future<MealModel> getMealDetail(int mealId, {String languageCode = 'en'}) async {
    throw UnimplementedError();
  }

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<void> setFavorite(int mealId, {required bool favorite}) async {}
}

void main() {
  testWidgets('MealView renders and updates on locale change', (tester) async {
    final localeService = AppLocaleService();
    final repo = TestMealRepository();
    final controller = MealController(repository: repo, localeService: localeService);
    Get.put<MealController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const MealView(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    // Switch locale to Khmer
    localeService.currentLocale.value = const Locale('km');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    controller.onClose();
    Get.reset();
  });
}

