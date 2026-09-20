import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/help_support_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/help_support_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<HelpSupportController>(HelpSupportController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget createHelpSupportApp() {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: const HelpSupportView(),
    );
  }

  testWidgets('renders 2-column layout on tablet in landscape mode', (
    tester,
  ) async {
    // 1280 x 800 tablet in landscape
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createHelpSupportApp());
    await tester.pump();

    // Verify 2-column layout key is rendered
    expect(
      find.byKey(const ValueKey<String>('help-support-tablet-two-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('help-support-single-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('help-support-back-button')),
      findsOneWidget,
    );

    // Verify hero and contact cards exist
    expect(
      find.byKey(const ValueKey<String>('help-support-hero')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('help-contact-card')),
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

      await tester.pumpWidget(createHelpSupportApp());
      await tester.pump();

      // Verify single column key is rendered
      expect(
        find.byKey(const ValueKey<String>('help-support-single-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('help-support-tablet-two-column')),
        findsNothing,
      );

      // Verify content is constrained to <= 600 width in tablet portrait
      final singleColumn = find.byKey(
        const ValueKey<String>('help-support-single-column'),
      );
      final size = tester.getSize(singleColumn);
      expect(size.width, greaterThan(600.0));

      // Verify back button is present
      expect(
        find.byKey(const ValueKey<String>('help-support-back-button')),
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

    await tester.pumpWidget(createHelpSupportApp());
    await tester.pump();

    // Verify single column key is rendered
    expect(
      find.byKey(const ValueKey<String>('help-support-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('help-support-tablet-two-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('help-support-back-button')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('toggles FAQ item expansion on tap', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createHelpSupportApp());
    await tester.pump();

    final controller = Get.find<HelpSupportController>();
    expect(controller.expandedIndex.value, -1);

    // Tap the first FAQ header
    await tester.tap(find.byKey(const ValueKey<String>('help-faq-header-0')));
    await tester.pumpAndSettle();
    expect(controller.expandedIndex.value, 0);

    // Tap it again to collapse
    await tester.tap(find.byKey(const ValueKey<String>('help-faq-header-0')));
    await tester.pumpAndSettle();
    expect(controller.expandedIndex.value, -1);

    expect(tester.takeException(), isNull);
  });
}
