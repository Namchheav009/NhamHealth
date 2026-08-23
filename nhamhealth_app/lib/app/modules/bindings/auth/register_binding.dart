import 'package:get/get.dart';

import '../../controllers/auth/register_controller.dart';
import '../../controllers/auth/login_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterController>(RegisterController.new);
    Get.lazyPut<LoginController>(LoginController.new);
  }
}
