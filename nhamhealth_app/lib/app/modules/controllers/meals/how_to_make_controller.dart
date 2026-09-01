import 'package:get/get.dart';
import '../../models/meals/meal_model.dart';

class HowToMakeController extends GetxController {
  MealModel? get meal =>
      Get.arguments is MealModel ? Get.arguments as MealModel : null;
  List<MealStepModel> get steps => meal?.steps ?? const [];

  void goBack() {
    Get.back();
  }
}
