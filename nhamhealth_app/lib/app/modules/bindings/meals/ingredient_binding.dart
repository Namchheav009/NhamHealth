import 'package:get/get.dart';

import '../../controllers/meals/ingredient_controller.dart';

class IngredientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IngredientController>(
      () => IngredientController(),
    );
  }
}