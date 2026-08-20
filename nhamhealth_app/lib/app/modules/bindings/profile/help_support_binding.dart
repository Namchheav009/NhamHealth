import 'package:get/get.dart';

import '../../controllers/profile/help_support_controller.dart';

class HelpSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpSupportController>(
      () => HelpSupportController(),
    );
  }
}