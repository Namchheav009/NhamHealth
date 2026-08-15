import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/home/views/home_view.dart';
import 'package:nhamhealth_flutter/app/modules/auth/views/account_created_view.dart';
import 'package:nhamhealth_flutter/app/modules/notifications/views/notifications_view.dart';
import 'package:nhamhealth_flutter/app/routes/app_pages.dart';
import 'package:nhamhealth_flutter/app/routes/app_routes.dart';

void main() {
  test('authenticated home route builds HomeView', () {
    final homePage = AppPages.pages.singleWhere(
      (page) => page.name == AppRoutes.home,
    );

    expect(homePage.page(), isA<HomeView>());
  });

  test('account-created route builds AccountCreatedView', () {
    final accountCreatedPage = AppPages.pages.singleWhere(
      (page) => page.name == AppRoutes.accountCreated,
    );

    expect(accountCreatedPage.page(), isA<AccountCreatedView>());
  });

  test('notifications route builds NotificationsView', () {
    final notificationsPage = AppPages.pages.singleWhere(
      (page) => page.name == AppRoutes.notifications,
    );

    expect(notificationsPage.page(), isA<NotificationsView>());
  });
}
