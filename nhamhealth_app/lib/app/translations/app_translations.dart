import 'package:get/get.dart';

import 'translation_catalog.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': englishTranslations,
    'km_KH': khmerTranslations,
  };
}
