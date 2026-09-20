import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/onboarding/choose_language_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/onboarding/choose_language_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('renders two-column responsive layout on tablet in landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    Get.put(ChooseLanguageController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const ChooseLanguageView(),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('choose-language-tablet-layout')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('choose-language-english')), findsOneWidget);
    expect(find.byKey(const Key('choose-language-khmer')), findsOneWidget);
    expect(find.byKey(const Key('choose-language-skip')), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/onboarding/vagetables.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders balanced responsive layout on tablet in portrait', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.reset);

    Get.put(ChooseLanguageController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const ChooseLanguageView(),
      ),
    );
    await tester.pump();

    // Portrait tablet uses the single-column centered layout (not the 2-column wide layout)
    expect(
      find.byKey(const ValueKey<String>('choose-language-tablet-layout')),
      findsNothing,
    );
    expect(find.byKey(const Key('choose-language-english')), findsOneWidget);
    expect(find.byKey(const Key('choose-language-khmer')), findsOneWidget);
    expect(find.byKey(const Key('choose-language-skip')), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/onboarding/vagetables.png')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders standard mobile phone layout', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    Get.put(ChooseLanguageController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: const ChooseLanguageView(),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('choose-language-tablet-layout')),
      findsNothing,
    );
    expect(find.byKey(const Key('choose-language-english')), findsOneWidget);
    expect(find.byKey(const Key('choose-language-khmer')), findsOneWidget);
    expect(find.text('Choose Your\nLanguage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
