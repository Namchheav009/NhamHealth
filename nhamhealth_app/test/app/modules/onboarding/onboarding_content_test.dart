import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/onboarding/onboarding_item.dart';
import 'package:nhamhealth_flutter/app/modules/views/onboarding/widgets/onboarding_content.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  const testItem = OnboardingItem(
    imagePath: 'assets/images/onboarding/onboarding1.png',
    title: 'onboarding.affordable_organic_goodness',
    description:
        'auth.get_affordable_organic_groceries_made_for_everyone_every_single_day',
  );

  testWidgets('renders OnboardingContent on tablet landscape', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: OnboardingContent(
            item: testItem,
            activePage: 0,
            pageCount: 2,
            buttonText: 'Next',
            showSkipButton: true,
            onNext: () {},
            onSkip: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Next'), findsOneWidget);
    expect(find.byType(OnboardingContent), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders OnboardingContent on tablet portrait', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: OnboardingContent(
            item: testItem,
            activePage: 0,
            pageCount: 2,
            buttonText: 'Next',
            showSkipButton: true,
            onNext: () {},
            onSkip: () {},
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Next'), findsOneWidget);
    expect(find.byType(OnboardingContent), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

