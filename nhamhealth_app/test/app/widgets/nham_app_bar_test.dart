import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/widgets/nham_app_bar.dart';

void main() {
  testWidgets(
    'top-bar action group contains favorites, notifications and profile',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: NhamAppBar(
              user: null,
              unreadNotificationCount: 0,
              onNotifications: () {},
              onProfile: () {},
            ),
          ),
        ),
      );

      final favoritesButton = find.byKey(const ValueKey('favorites-button'));
      final notificationsButton = find.byKey(
        const ValueKey<String>('notifications-button'),
      );
      final profileButton = find.byKey(const ValueKey('profile-button'));

      expect(favoritesButton, findsOneWidget);
      expect(notificationsButton, findsOneWidget);
      expect(profileButton, findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline_rounded), findsOneWidget);
      expect(
        tester.getCenter(favoritesButton).dx,
        lessThan(tester.getCenter(notificationsButton).dx),
      );
      expect(
        tester.getCenter(notificationsButton).dx,
        lessThan(tester.getCenter(profileButton).dx),
      );
    },
  );
}
