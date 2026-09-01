import 'package:get/get.dart';

import '../../controllers/meals/how_to_make_controller.dart';

class HowToMakeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HowToMakeController>(() => HowToMakeController());
  }
}
