import 'package:get/get.dart';
import '../../models/meals/meal_model.dart';

class IngredientController extends GetxController {
  MealModel? get meal =>
      Get.arguments is MealModel ? Get.arguments as MealModel : null;
  List<MealIngredientModel> get ingredients => meal?.ingredients ?? const [];

  void goBack() {
    Get.back();
  }
}
