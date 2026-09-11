import 'package:get/get.dart';

import '../../../../core/services/app_locale_service.dart';
import '../../../translations/meal_localization_helpers.dart';
import '../../models/meals/meal_model.dart';
import '../../repositories/meals/meal_repository.dart';

class FoodDetailController extends GetxController {
  FoodDetailController({
    required this.repository,
    AppLocaleService? localeService,
    MealModel? initialMeal,
  }) : _localeService = localeService,
       _initialMeal = initialMeal;

  static final Map<String, MealModel> _detailCache = <String, MealModel>{};

  final MealRepository repository;
  final AppLocaleService? _localeService;
  final MealModel? _initialMeal;
  final detail = Rxn<MealModel>();
  final isLoading = false.obs;
  final isDetailLoaded = false.obs;
  final errorMessage = ''.obs;
  final selectedContentTab = 0.obs;
  final isFavorite = false.obs;
  late final RxString languageCode;
  Worker? _localeWorker;
  int _requestVersion = 0;

  MealModel? get meal => detail.value;

  AppLocaleService? get _effectiveLocaleService {
    if (_localeService != null) return _localeService;
    if (Get.isRegistered<AppLocaleService>()) {
      return Get.find<AppLocaleService>();
    }
    return null;
  }

  String _currentAppLanguage() {
    final service = _effectiveLocaleService;
    if (service != null) {
      return service.currentLanguageCode == 'km' ? 'km' : 'en';
    }
    return (Get.locale?.languageCode == 'km') ? 'km' : 'en';
  }

  @override
  void onInit() {
    super.onInit();
    final currentLang = _currentAppLanguage();
    languageCode = currentLang.obs;

    final argument = _initialMeal ?? Get.arguments;
    if (argument is MealModel) {
      final cached = _detailCache['${argument.id}_$currentLang'];
      if (cached != null) {
        detail.value = cached;
        isDetailLoaded.value = true;
      } else {
        detail.value = _localizeMealModel(argument, currentLang);
        isDetailLoaded.value = argument.ingredients.isNotEmpty;
      }
      isFavorite.value = argument.isFavorite;
    }

    final service = _effectiveLocaleService;
    if (service != null) {
      _localeWorker = ever(service.currentLocale, (locale) {
        final nextLang = locale.languageCode == 'km' ? 'km' : 'en';
        if (languageCode.value != nextLang) {
          languageCode.value = nextLang;
          loadDetail();
        }
      });
    }

    loadDetail();
  }

  @override
  void onClose() {
    _localeWorker?.dispose();
    super.onClose();
  }

  Future<void> loadDetail() async {
    final mealId = detail.value?.id;
    if (mealId == null) {
      errorMessage.value = 'Meal details are unavailable.';
      isLoading.value = false;
      return;
    }
    final requestVersion = ++_requestVersion;
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final currentLang = _currentAppLanguage();
      languageCode.value = currentLang;
      final loadedMeal = await repository.getMealDetail(
        mealId,
        languageCode: currentLang,
      );
      if (requestVersion != _requestVersion) return;
      loadedMeal.isFavorite = isFavorite.value;
      detail.value = loadedMeal;
      isDetailLoaded.value = true;
      _detailCache['${mealId}_$currentLang'] = loadedMeal;
    } on Object catch (error) {
      if (requestVersion != _requestVersion) return;
      errorMessage.value = error.toString();
    } finally {
      if (requestVersion == _requestVersion) isLoading.value = false;
    }
  }

  MealModel _localizeMealModel(MealModel model, String targetLang) {
    if (targetLang == 'km') {
      return MealModel(
        id: model.id,
        name: localizeDishName(model.name),
        calories: model.calories,
        image: model.image,
        category: localizeCategory(model.category),
        categoryId: model.categoryId,
        proteinGrams: model.proteinGrams,
        description: localizeMealDescription(model.description),
        cookingTimeMinutes: model.cookingTimeMinutes,
        difficulty: localizeDifficulty(model.difficulty),
        servings: model.servings,
        recommendationReason:
            localizeRecommendationReason(model.recommendationReason),
        isFavorite: model.isFavorite,
        ingredients: model.ingredients,
        nutrition: model.nutrition,
        steps: model.steps,
        languageCode: 'km',
        tags: model.tags,
        moods: model.moods,
      );
    } else {
      return MealModel(
        id: model.id,
        name: localizeDishName(model.name),
        calories: model.calories,
        image: model.image,
        category: localizeCategory(model.category),
        categoryId: model.categoryId,
        proteinGrams: model.proteinGrams,
        description: localizeMealDescription(model.description),
        cookingTimeMinutes: model.cookingTimeMinutes,
        difficulty: localizeDifficulty(model.difficulty),
        servings: model.servings,
        recommendationReason: model.recommendationReason,
        isFavorite: model.isFavorite,
        ingredients: model.ingredients,
        nutrition: model.nutrition,
        steps: model.steps,
        languageCode: 'en',
        tags: model.tags,
        moods: model.moods,
      );
    }
  }

  void goBack() {
    Get.back();
  }

  void selectContentTab(int index) {
    if (index == 0 || index == 1) selectedContentTab.value = index;
  }

  Future<void> selectLanguage(String language) async {
    if (language != 'en' && language != 'km') return;
    if (languageCode.value == language && isDetailLoaded.value) return;
    languageCode.value = language;
    await loadDetail();
  }

  Future<void> toggleFavorite() async {
    final meal = detail.value;
    if (meal == null) return;
    final previous = isFavorite.value;
    final next = !previous;
    isFavorite.value = next;
    meal.isFavorite = next;
    detail.refresh();
    try {
      await repository.setFavorite(meal.id, favorite: next);
    } on Object {
      isFavorite.value = previous;
      meal.isFavorite = previous;
      detail.refresh();
    }
  }
}
