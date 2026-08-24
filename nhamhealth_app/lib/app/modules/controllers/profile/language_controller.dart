import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_locale_service.dart';

class LanguageController extends GetxController {
  final selectedLanguage = AppLocaleService.englishLocale.languageCode.obs;

  AppLocaleService get _localeService => Get.find<AppLocaleService>();

  @override
  void onInit() {
    super.onInit();
    selectedLanguage.value =
        (Get.locale ?? AppLocaleService.fallbackLocale).languageCode;
  }

  Future<void> selectEnglish() {
    return _selectLocale(AppLocaleService.englishLocale);
  }

  Future<void> selectKhmer() {
    return _selectLocale(AppLocaleService.khmerLocale);
  }

  Future<void> _selectLocale(Locale locale) async {
    selectedLanguage.value = locale.languageCode;
    Get.updateLocale(locale);
    await _localeService.saveLocale(locale);
  }

  void goBack() {
    Get.back();
  }
}
