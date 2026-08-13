import 'package:get/get.dart';

import '../controllers/wellness_controller.dart';

class WellnessBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WellnessController>(
      () => WellnessController(),
    );
  }
}