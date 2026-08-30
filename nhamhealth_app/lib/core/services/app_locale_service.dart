import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLocaleService {
  AppLocaleService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const englishLocale = Locale('en', 'US');
  static const khmerLocale = Locale('km', 'KH');
  static const fallbackLocale = englishLocale;
  static const _localeKey = 'app_locale';

  final FlutterSecureStorage _storage;

  Future<Locale> loadLocale() async {
    try {
      final languageCode = await _storage.read(key: _localeKey);
      return localeForLanguageCode(languageCode);
    } on Object {
      return fallbackLocale;
    }
  }

  Future<void> saveLocale(Locale locale) async {
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
