import 'package:get/get.dart';

import '../../controllers/auth/login_controller.dart';
import '../../controllers/auth/register_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(LoginController.new);
    Get.lazyPut<RegisterController>(RegisterController.new);
  }
}
