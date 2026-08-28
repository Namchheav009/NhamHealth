import 'package:get/get.dart';

import '../../models/meals/meal_model.dart';

class FoodDetailController extends GetxController {
  MealModel? get meal {
    final arguments = Get.arguments;
    return arguments is MealModel ? arguments : null;
  }

  void goBack() {
    Get.back();
  }
}
