import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/core/services/app_locale_service.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/language_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/language_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

class _FakeLocaleService extends AppLocaleService {
  @override
  Future<void> saveLocale(Locale locale) async {
    currentLocale.value = locale;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    final localeService = _FakeLocaleService();
    localeService.currentLocale.value = AppLocaleService.englishLocale;
    Get.put<AppLocaleService>(localeService);
    Get.put<LanguageController>(LanguageController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget createLanguageApp() {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: const LanguageView(),
    );
  }

  testWidgets('renders 2-column layout on tablet in landscape mode', (
    tester,
  ) async {
    // 1280 x 800 tablet in landscape
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createLanguageApp());
    await tester.pump();

    // Verify 2-column layout key is rendered
    expect(
      find.byKey(const ValueKey<String>('language-tablet-two-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('language-single-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('language-back-button')),
      findsOneWidget,
    );

    // Verify language options are rendered
    expect(
      find.byKey(const ValueKey<String>('language-option-km')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('language-option-en')),
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

      await tester.pumpWidget(createLanguageApp());
      await tester.pump();

      // Verify single column key is rendered
      expect(
        find.byKey(const ValueKey<String>('language-single-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('language-tablet-two-column')),
        findsNothing,
      );

      // Verify content is constrained to <= 600 width in tablet portrait
      final singleColumn = find.byKey(
        const ValueKey<String>('language-single-column'),
      );
      final size = tester.getSize(singleColumn);
      expect(size.width, greaterThan(600.0));

      // Verify back button is present
      expect(
        find.byKey(const ValueKey<String>('language-back-button')),
        findsOneWidget,
      );

      // Verify language options are rendered
      expect(
        find.byKey(const ValueKey<String>('language-option-km')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('language-option-en')),
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

    await tester.pumpWidget(createLanguageApp());
    await tester.pump();

    // Verify single column key is rendered
    expect(
      find.byKey(const ValueKey<String>('language-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('language-tablet-two-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('language-back-button')),
      findsOneWidget,
    );

    // Verify language options are rendered
    expect(
      find.byKey(const ValueKey<String>('language-option-km')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('language-option-en')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });
}
