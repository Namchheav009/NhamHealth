import 'package:get/get.dart';

<<<<<<< HEAD
class FoodDetailController extends GetxController {
=======
import '../../models/meals/meal_model.dart';

class FoodDetailController extends GetxController {
  MealModel? get meal {
    final arguments = Get.arguments;
    return arguments is MealModel ? arguments : null;
  }

>>>>>>> de26f8c42978dce467e11832233dcabe163d6bc0
  void goBack() {
    Get.back();
  }
}
