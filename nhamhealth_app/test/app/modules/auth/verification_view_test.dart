import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/auth/verification_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_colors.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('verification details stay readable when the app theme is dark', (
    tester,
  ) async {
    Get.put<AuthService>(AuthService());
    final controller = Get.put(VerificationController());
    controller.userEmail.value = 'person@example.com';

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const VerificationView(),
      ),
    );
    await tester.pump();

    final destination = tester.widget<Text>(find.text('person@example.com'));
    final prompt = tester.widget<Text>(
      find.text("Didn't receive the code?"),
    );

    expect(destination.style?.color, AppColors.primaryText);
    expect(prompt.style?.color, AppColors.primaryText);

    await tester.pumpWidget(const SizedBox.shrink());
    Get.delete<VerificationController>();
  });
}
