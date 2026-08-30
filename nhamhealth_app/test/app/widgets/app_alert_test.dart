import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/app_alert.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('shows, replaces, and dismisses an accessible alert', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );

    await AppAlert.success(
      title: 'Profile saved',
      message: 'Your photo is available on your dashboard.',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Profile saved'), findsOneWidget);
    expect(
      find.text('Your photo is available on your dashboard.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Success: Profile saved. Your photo is available on your dashboard.',
      ),
      findsOneWidget,
    );

    final replacement = AppAlert.success(
      title: 'Latest alert',
      message: 'This message should remain visible.',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await replacement;
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Profile saved'), findsNothing);
    expect(find.text('Latest alert'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss notification'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Latest alert'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}
