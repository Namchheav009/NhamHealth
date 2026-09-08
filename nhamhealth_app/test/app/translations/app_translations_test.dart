import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

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

    expect(translations['en_US']!['settings.language'], 'Language');
    expect(translations['km_KH']!['settings.language'], 'ភាសា');
  });

  testWidgets('semantic keys are namespaced and raw API text is preserved', (
    tester,
  ) async {
    final translations = AppTranslations().keys;
    final englishKeys = translations['en_US']!.keys;

    expect(
      englishKeys.every((key) => RegExp(r'^[a-z]+\.[a-z0-9_]+$').hasMatch(key)),
      isTrue,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('km', 'KH'),
        home: const SizedBox.shrink(),
      ),
    );
    expect('API-provided meal name'.trOrSelf, 'API-provided meal name');
    expect('common.save'.trOrSelf, 'រក្សាទុក');
  });

  test('contains Khmer labels for every major page group', () {
    final khmer = AppTranslations().keys['km_KH']!;

    expect(khmer['auth.sign_in'], 'ចូលគណនី');
    expect(khmer['meals.recommended_title'], 'អាហារណែនាំ');
    expect(khmer['favorites.favorite_foods'], 'អាហារចំណូលចិត្ត');
    expect(khmer['common.food_detail'], 'ព័ត៌មានអាហារ');
    expect(
      khmer['profile.password_and_security'],
      'ពាក្យសម្ងាត់ និងសុវត្ថិភាព',
    );
    expect(khmer['wellness.daily_title'], 'សុខភាពប្រចាំថ្ងៃ');
    expect(khmer['wellness.ai_food_check'], 'ពិនិត្យអាហារដោយ AI');
    expect(khmer['assistant.quick_questions'], 'សំណួររហ័ស');
    expect(khmer['community.recipe_details'], 'ព័ត៌មានរូបមន្ត');
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
    expect(find.text('Quick questions'), findsOneWidget);
    expect(find.text('Recipe details'), findsOneWidget);
    expect(find.text('Confirm the Food First'), findsOneWidget);
    expect(
      find.text(
        'Use cup for Coffee with Milk so nutrition can be scaled safely.',
      ),
      findsOneWidget,
    );

    Get.updateLocale(const Locale('km', 'KH'));
    await tester.pump();

    expect(find.text('អាហារណែនាំ'), findsOneWidget);
    expect(find.text('សុខភាពប្រចាំថ្ងៃ'), findsOneWidget);
    expect(find.text('ពិនិត្យអាហារដោយ AI'), findsOneWidget);
    expect(find.text('សំណួររហ័ស'), findsOneWidget);
    expect(find.text('ព័ត៌មានរូបមន្ត'), findsOneWidget);
    expect(find.text('បញ្ជាក់អាហារមុន'), findsOneWidget);
    expect(
      find.text(
        'សូមប្រើឯកតា cup សម្រាប់ Coffee with Milk ដើម្បីឱ្យការគណនាអាហារូបត្ថម្ភត្រឹមត្រូវ។',
      ),
      findsOneWidget,
    );
    expect(find.text('Recommended Meals'), findsNothing);
  });
}

class _LocalizedPageProbe extends StatelessWidget {
  const _LocalizedPageProbe();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('meals.recommended_title'.tr),
        Text('wellness.daily_title'.tr),
        Text('wellness.ai_food_check'.tr),
        Text('assistant.quick_questions'.tr),
        Text('community.recipe_details'.tr),
        Text('wellness.confirm_food_first'.tr),
        Text(
          'home.use_unit_for_food_so_nutrition_can_be_scaled_safely'.trParams({
            'unit': 'cup',
            'food': 'Coffee with Milk',
          }),
        ),
      ],
    ),
  );
}
