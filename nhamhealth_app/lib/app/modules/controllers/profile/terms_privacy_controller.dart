import 'package:get/get.dart';

class TermsPrivacyController extends GetxController {
  final termsExpanded = false.obs;
  final privacyExpanded = false.obs;

  void toggleTerms() {
    termsExpanded.toggle();
  }

  void togglePrivacy() {
    privacyExpanded.toggle();
  }

  void goBack() {
    Get.back();
  }
}
