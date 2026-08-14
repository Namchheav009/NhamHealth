import 'package:get/get.dart';

import '../controllers/calories_controller.dart';

class CaloriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CaloriesController>(
      () => CaloriesController(),
    );
  }
}