import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/core/services/app_locale_service.dart';

void main() {
  group('AppLocaleService.localeForLanguageCode', () {
    test('returns Khmer for the Khmer language code', () {
      expect(
        AppLocaleService.localeForLanguageCode('km'),
        AppLocaleService.khmerLocale,
      );
    });

    test('falls back to English for missing or unsupported codes', () {
      expect(
        AppLocaleService.localeForLanguageCode(null),
        AppLocaleService.englishLocale,
      );
      expect(
        AppLocaleService.localeForLanguageCode('fr'),
        AppLocaleService.englishLocale,
      );
    });
  });
}
