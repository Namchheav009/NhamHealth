import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppearanceController extends GetxController {
  final selectedTheme = 'light'.obs;

  void selectLightMode() {
    selectedTheme.value = 'light';
    Get.changeThemeMode(ThemeMode.light);
  }

  void selectDarkMode() {
    selectedTheme.value = 'dark';
    Get.changeThemeMode(ThemeMode.dark);
  }

  void goBack() {
    Get.back();
  }
}