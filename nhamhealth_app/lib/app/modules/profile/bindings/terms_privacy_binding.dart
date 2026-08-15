import 'package:get/get.dart';

import '../controllers/terms_privacy_controller.dart';

class TermsPrivacyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TermsPrivacyController>(
      () => TermsPrivacyController(),
    );
  }
}