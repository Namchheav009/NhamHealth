import 'package:get/get.dart';

import '../../controllers/wellness/food_source_detail_controller.dart';

class FoodSourceDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FoodSourceDetailController>(() => FoodSourceDetailController());
  }
}
