import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/onboarding/choose_language_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/onboarding/choose_language_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('selecting a language translates the page immediately', (
    tester,
  ) async {
    final controller = Get.put(ChooseLanguageController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const ChooseLanguageView(),
      ),
    );

    expect(find.byKey(const Key('choose-language-english')), findsOneWidget);
    expect(find.byKey(const Key('choose-language-khmer')), findsOneWidget);
    expect(find.text('Choose Your\nLanguage'), findsOneWidget);
    expect(find.text('Welcome'), findsNothing);
    expect(
      find.image(const AssetImage('assets/images/onboarding/vagetables.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('choose-language-khmer')));
    await tester.pumpAndSettle();

    expect(controller.selectedLanguage.value, 'km');
    expect(Get.locale, const Locale('km', 'KH'));
    expect(find.text('ជ្រើសរើស\nភាសារបស់អ្នក'), findsOneWidget);
    expect(find.text('បន្ទាប់'), findsOneWidget);
    expect(find.text('រំលងសិន'), findsOneWidget);
    expect(find.text('Choose Your\nLanguage'), findsNothing);

    await tester.tap(find.byKey(const Key('choose-language-english')));
    await tester.pumpAndSettle();

    expect(controller.selectedLanguage.value, 'en');
    expect(Get.locale, const Locale('en', 'US'));
    expect(find.text('Choose Your\nLanguage'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
