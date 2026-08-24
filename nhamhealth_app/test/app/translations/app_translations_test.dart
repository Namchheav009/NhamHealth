import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('English and Khmer expose the same translation keys', () {
    final translations = AppTranslations().keys;
    final englishKeys = translations['en_US']!.keys.toSet();
    final khmerKeys = translations['km_KH']!.keys.toSet();

    expect(khmerKeys, englishKeys);
  });

  test('contains localized language screen labels', () {
    final translations = AppTranslations().keys;

    expect(translations['en_US']!['language'], 'Language');
    expect(translations['km_KH']!['language'], 'ភាសា');
  });

  test('contains Khmer labels for every major page group', () {
    final khmer = AppTranslations().keys['km_KH']!;

    expect(khmer['Sign In'], 'ចូលគណនី');
    expect(khmer['Recommended Meals'], 'អាហារដែលបានណែនាំ');
    expect(khmer['Favorite foods'], 'អាហារចំណូលចិត្ត');
    expect(khmer['Food Detail'], 'ព័ត៌មានលម្អិតអាហារ');
    expect(khmer['Password & Security'], 'ពាក្យសម្ងាត់ និងសុវត្ថិភាព');
    expect(khmer['Daily Wellness'], 'សុខុមាលភាពប្រចាំថ្ងៃ');
    expect(khmer['AI Food Check'], 'ពិនិត្យអាហារដោយ AI');
  });

  testWidgets('changing the GetX locale updates visible page copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const _LocalizedPageProbe(),
      ),
    );

    expect(find.text('Recommended Meals'), findsOneWidget);
    expect(find.text('Daily Wellness'), findsOneWidget);
    expect(find.text('AI Food Check'), findsOneWidget);

    Get.updateLocale(const Locale('km', 'KH'));
    await tester.pump();

    expect(find.text('អាហារដែលបានណែនាំ'), findsOneWidget);
    expect(find.text('សុខុមាលភាពប្រចាំថ្ងៃ'), findsOneWidget);
    expect(find.text('ពិនិត្យអាហារដោយ AI'), findsOneWidget);
    expect(find.text('Recommended Meals'), findsNothing);
  });
}

class _LocalizedPageProbe extends StatelessWidget {
  const _LocalizedPageProbe();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('Recommended Meals'.tr),
        Text('Daily Wellness'.tr),
        Text('AI Food Check'.tr),
      ],
    ),
  );
}
