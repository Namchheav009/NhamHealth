import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/app_locale_service.dart';
import '../../../routes/app_routes.dart';

class ChooseLanguageController extends GetxController {
  final selectedLanguage = AppLocaleService.englishLocale.languageCode.obs;
  final isContinuing = false.obs;

  AppLocaleService get _localeService => Get.find<AppLocaleService>();

  @override
  void onInit() {
    super.onInit();
    selectedLanguage.value =
        (Get.locale ?? AppLocaleService.fallbackLocale).languageCode;
  }

  Future<void> selectEnglish() =>
      _selectLanguage(AppLocaleService.englishLocale);

  Future<void> selectKhmer() => _selectLanguage(AppLocaleService.khmerLocale);

  Future<void> _selectLanguage(Locale locale) async {
    if (selectedLanguage.value == locale.languageCode &&
        Get.locale == locale) {
      return;
    }
    selectedLanguage.value = locale.languageCode;
    await Get.updateLocale(locale);
  }

  Future<void> continueToOnboarding() async {
    if (isContinuing.value) return;
    isContinuing.value = true;
    final locale = AppLocaleService.localeForLanguageCode(
      selectedLanguage.value,
    );
    await Get.updateLocale(locale);
    await _localeService.saveLocale(locale);
    Get.offAllNamed(AppRoutes.onboarding);
  }

  Future<void> skipForNow() async {
    if (isContinuing.value) return;
    selectedLanguage.value = AppLocaleService.englishLocale.languageCode;
    await continueToOnboarding();
  }
}
