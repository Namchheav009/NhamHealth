import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/home/views/pages/home_view.dart';
import 'package:nhamhealth_flutter/app/modules/notifications/views/pages/notifications_view.dart';
import 'package:nhamhealth_flutter/app/routes/app_pages.dart';
import 'package:nhamhealth_flutter/app/routes/app_routes.dart';

void main() {
  test('authenticated home route builds HomeView', () {
    final homePage = AppPages.pages.singleWhere(
      (page) => page.name == AppRoutes.home,
    );

    expect(homePage.page(), isA<HomeView>());
  });

  test('notifications route builds NotificationsView', () {
    final notificationsPage = AppPages.pages.singleWhere(
      (page) => page.name == AppRoutes.notifications,
    );

    expect(notificationsPage.page(), isA<NotificationsView>());
  });
}
