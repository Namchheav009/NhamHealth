import 'package:get/get.dart';

import '../../models/meals/meal_model.dart';
import '../../repositories/meals/meal_repository.dart';

class FoodDetailController extends GetxController {
  FoodDetailController({required this.repository});
  final MealRepository repository;
  final detail = Rxn<MealModel>();
  final isLoading = false.obs;
  final isDetailLoaded = false.obs;
  final errorMessage = ''.obs;
  final selectedContentTab = 0.obs;
  final isFavorite = false.obs;
  int _requestVersion = 0;

  MealModel? get meal => detail.value;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is MealModel) {
      detail.value = argument;
      isFavorite.value = argument.isFavorite;
    }
    loadDetail();
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
      final loadedMeal = await repository.getMealDetail(mealId);
      if (requestVersion != _requestVersion) return;
      loadedMeal.isFavorite = isFavorite.value;
      detail.value = loadedMeal;
      isDetailLoaded.value = true;
    } on Object catch (error) {
      if (requestVersion != _requestVersion) return;
      errorMessage.value = error.toString();
    } finally {
      if (requestVersion == _requestVersion) isLoading.value = false;
    }
  }

  void goBack() {
    Get.back();
  }

  void selectContentTab(int index) {
    if (index == 0 || index == 1) selectedContentTab.value = index;
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
