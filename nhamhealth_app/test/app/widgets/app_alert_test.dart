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

    await AppAlert.notification(
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

    final replacement = AppAlert.notification(
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

  testWidgets('shows and confirms a SweetAlert-style action dialog', (
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

    final alert = AppAlert.actionSuccess(
      title: 'Password updated',
      message: 'Your password has been updated.',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Password updated'), findsOneWidget);
    expect(find.text('Your password has been updated.'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Success: Password updated. Your password has been updated.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('app-action-alert-confirm')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('app-action-alert-confirm')),
    );
    await tester.pumpAndSettle();
    await alert;
    expect(find.text('Password updated'), findsNothing);
    semantics.dispose();
  });
}
