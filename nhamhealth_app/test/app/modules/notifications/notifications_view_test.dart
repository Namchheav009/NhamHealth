import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/notifications/notifications_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('notification page matches the reference sections', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const NotificationsView(),
      ),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('Earlier'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('notifications-back-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
