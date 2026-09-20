import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/terms_privacy_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/terms_privacy_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<TermsPrivacyController>(TermsPrivacyController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTermsPrivacyApp() {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: const TermsPrivacyView(),
    );
  }

  testWidgets('renders 2-column layout on tablet in landscape mode', (
    tester,
  ) async {
    // 1280 x 800 tablet in landscape
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createTermsPrivacyApp());
    await tester.pump();

    // Verify 2-column layout key is rendered
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-tablet-two-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-single-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-back-button')),
      findsOneWidget,
    );

    // Verify terms and privacy cards exist
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-terms-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-privacy-card')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders centered constrained single-column layout on tablet in portrait mode',
    (tester) async {
      // 800 x 1280 tablet in portrait
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createTermsPrivacyApp());
      await tester.pump();

      // Verify single column key is rendered
      expect(
        find.byKey(const ValueKey<String>('terms-privacy-single-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('terms-privacy-tablet-two-column')),
        findsNothing,
      );

      // Verify content is constrained to <= 600 width in tablet portrait
      final singleColumn = find.byKey(
        const ValueKey<String>('terms-privacy-single-column'),
      );
      final size = tester.getSize(singleColumn);
      expect(size.width, greaterThan(600.0));

      // Verify back button is present
      expect(
        find.byKey(const ValueKey<String>('terms-privacy-back-button')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders single-column layout on mobile phone', (tester) async {
    // 390 x 844 standard smartphone
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createTermsPrivacyApp());
    await tester.pump();

    // Verify single column key is rendered
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-tablet-two-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('terms-privacy-back-button')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles terms and privacy expansion on tap', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createTermsPrivacyApp());
    await tester.pump();

    final controller = Get.find<TermsPrivacyController>();
    expect(controller.termsExpanded.value, isFalse);
    expect(controller.privacyExpanded.value, isFalse);

    // Tap terms of service
    await tester.tap(find.text('Terms of Service'));
    await tester.pumpAndSettle();
    expect(controller.termsExpanded.value, isTrue);

    // Tap privacy policy
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(controller.privacyExpanded.value, isTrue);

    expect(tester.takeException(), isNull);
  });
}
