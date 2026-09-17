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

  testWidgets('notification completes silently when banners are disabled', (
    tester,
  ) async {
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

    expect(find.text('Profile saved'), findsNothing);
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

  testWidgets('shows and confirms branded confirmAction dialog', (
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

    final confirmFuture = AppAlert.confirmAction(
      title: 'community.unfollow_member_question',
      message: 'community.unfollow_member_warning',
      confirmText: 'community.unfollow_button',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey<String>('app-confirm-alert-cancel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('app-confirm-alert-confirm')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('app-confirm-alert-confirm')),
    );
    await tester.pumpAndSettle();

    final result = await confirmFuture;
    expect(result, isTrue);
    semantics.dispose();
  });
}
