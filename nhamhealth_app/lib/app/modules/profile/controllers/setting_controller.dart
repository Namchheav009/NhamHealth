import 'package:get/get.dart';

class SettingsController extends GetxController {
  final selectedLanguage = 'English'.obs;

  void openPasswordSecurity() {}

  void openAppearance() {}

  void openLanguage() {}

  void openHelpSupport() {}

  void openTermsPrivacy() {}

  void logout() {}

  void goBack() {
    Get.back();
  }
}
