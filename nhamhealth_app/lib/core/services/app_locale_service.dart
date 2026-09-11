import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class AppLocaleService extends GetxService {
  AppLocaleService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    final active = Get.locale;
    if (active != null) {
      currentLocale.value = active;
    }
  }

  static const englishLocale = Locale('en', 'US');
  static const khmerLocale = Locale('km', 'KH');
  static const fallbackLocale = englishLocale;
  static const _localeKey = 'app_locale';

  final FlutterSecureStorage _storage;
  final currentLocale = fallbackLocale.obs;

  String get currentLanguageCode => currentLocale.value.languageCode;

  Future<Locale> loadLocale() async {
    try {
      final languageCode = await _storage.read(key: _localeKey);
      final locale = localeForLanguageCode(languageCode);
      currentLocale.value = locale;
      return locale;
    } on Object {
      currentLocale.value = fallbackLocale;
      return fallbackLocale;
    }
  }

  Future<void> saveLocale(Locale locale) async {
    currentLocale.value = locale;
    try {
      await _storage.write(key: _localeKey, value: locale.languageCode);
    } on Object {
      // The in-memory locale still works when secure storage is unavailable.
    }
  }

  static Locale localeForLanguageCode(String? languageCode) {
    return languageCode == khmerLocale.languageCode
        ? khmerLocale
        : englishLocale;
  }
}
