import 'package:get/get.dart';

import 'translation_catalog.dart';

/// Localizes internal semantic keys while leaving API and user text untouched.
extension LocalizedText on String {
  String get trOrSelf {
    final languageCode = Get.locale?.languageCode;
    final catalogue =
        languageCode == 'km' ? khmerTranslations : englishTranslations;
    return catalogue.containsKey(this) ? tr : this;
  }
}
