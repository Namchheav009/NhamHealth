import 'package:get/get.dart';

import '../controllers/calories_controller.dart';

class CaloriesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CaloriesController>()) {
      Get.lazyPut<CaloriesController>(() => CaloriesController(), fenix: true);
    }
  }
}
