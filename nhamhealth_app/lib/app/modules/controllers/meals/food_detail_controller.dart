import 'package:get/get.dart';

import '../../models/meals/meal_model.dart';
import '../../repositories/meals/meal_repository.dart';

class FoodDetailController extends GetxController {
  FoodDetailController({required this.repository});
  final MealRepository repository;
  final detail = Rxn<MealModel>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  MealModel? get meal => detail.value;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    if (argument is MealModel) detail.value = argument;
    loadDetail();
  }

  Future<void> loadDetail() async {
    final mealId = detail.value?.id;
    if (mealId == null) {
      errorMessage.value = 'Meal details are unavailable.';
      isLoading.value = false;
      return;
    }
    try {
      errorMessage.value = '';
      detail.value = await repository.getMealDetail(mealId);
    } on Object catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void goBack() {
    Get.back();
  }
}
