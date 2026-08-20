import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageController extends GetxController {
  final selectedLanguage = 'English'.obs;

  void selectEnglish() {
    selectedLanguage.value = 'English';

    Get.updateLocale(
      const Locale('en', 'US'),
    );
  }

  void selectKhmer() {
    selectedLanguage.value = 'Khmer';

    Get.updateLocale(
      const Locale('km', 'KH'),
    );
  }

  void goBack() {
    Get.back();
  }
}