import 'package:get/get.dart';

import '../../controllers/onboarding/choose_language_controller.dart';

class ChooseLanguageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChooseLanguageController>(() => ChooseLanguageController());
  }
}
