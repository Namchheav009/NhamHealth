import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/setting_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/setting_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

class _TestSettingsController extends SettingsController {
  @override
  void onInit() {
    super.onInit();
    isLoading.value = false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
    Get.put<AuthService>(AuthService());
  });

  tearDown(() {
    Get.reset();
  });

  Widget createSettingsApp() {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: const SettingsView(),
    );
  }

  testWidgets('renders 2-column layout on tablet in landscape mode', (
    tester,
  ) async {
    // 1280 x 800 tablet in landscape
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    Get.put<SettingsController>(_TestSettingsController());

    await tester.pumpWidget(createSettingsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify 2-column layout key is rendered
    expect(
      find.byKey(const ValueKey<String>('settings-tablet-two-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-single-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('settings-back-button')),
      findsOneWidget,
    );

    // Verify expected section titles are present
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders centered constrained single-column layout on tablet in portrait mode',
    (tester) async {
      // 800 x 1280 tablet in portrait
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      Get.put<SettingsController>(_TestSettingsController());

      await tester.pumpWidget(createSettingsApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify single column key is rendered
      expect(
        find.byKey(const ValueKey<String>('settings-single-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-tablet-two-column')),
        findsNothing,
      );

      // Verify content is constrained to <= 600 width in tablet portrait
      final singleColumn = find.byKey(
        const ValueKey<String>('settings-single-column'),
      );
      final size = tester.getSize(singleColumn);
      expect(size.width, greaterThan(600.0));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders single-column layout on mobile phone', (tester) async {
    // 390 x 844 standard smartphone
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    Get.put<SettingsController>(_TestSettingsController());

    await tester.pumpWidget(createSettingsApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify single column key is rendered
    expect(
      find.byKey(const ValueKey<String>('settings-single-column')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-tablet-two-column')),
      findsNothing,
    );

    // Verify back button is present
    expect(
      find.byKey(const ValueKey<String>('settings-back-button')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });
}
