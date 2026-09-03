import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_theme_service.dart';

class AppearanceController extends GetxController {
  AppearanceController({AppThemeService? themeService})
    : _themeService = themeService ?? Get.find<AppThemeService>();

  final AppThemeService _themeService;
  late final selectedTheme = _themeService.themeMode.name.obs;

  void selectSystemMode() {
    _selectTheme(ThemeMode.system);
  }

  void selectLightMode() {
    _selectTheme(ThemeMode.light);
  }

  void selectDarkMode() {
    _selectTheme(ThemeMode.dark);
  }

  void _selectTheme(ThemeMode themeMode) {
    if (selectedTheme.value == themeMode.name) return;
    selectedTheme.value = themeMode.name;
    Get.changeThemeMode(themeMode);
    unawaited(_themeService.saveThemeMode(themeMode));
  }

  void goBack() {
    Get.back();
  }
}
