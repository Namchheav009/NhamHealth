import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/appearance_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/appearance_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/core/services/app_theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('selecting dark mode applies and persists the dark theme', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    final themeService = AppThemeService();
    Get.put(AppearanceController(themeService: themeService));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const AppearanceView(),
      ),
    );

    expect(
      Theme.of(tester.element(find.byType(AppearanceView))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(AppearanceView))).brightness,
      Brightness.dark,
    );
    expect(themeService.themeMode, ThemeMode.dark);

    await tester.tap(find.text('theme_system'));
    await tester.pumpAndSettle();

    expect(themeService.themeMode, ThemeMode.system);
    expect(
      Theme.of(tester.element(find.byType(AppearanceView))).brightness,
      tester.platformDispatcher.platformBrightness,
    );
  });
}
