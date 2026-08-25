import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/notifications/notifications_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/notifications/notification_item.dart';
import 'package:nhamhealth_flutter/app/modules/views/notifications/notifications_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  tearDown(Get.reset);

  test('notification parses the actor profile', () {
    final notification = NotificationItem.fromJson({
      'id': 5,
      'type': 'COMMUNITY',
      'title': 'Maya Chen',
      'message': 'commented on your post.',
      'actorUserId': 7,
      'actorAvatarUrl': 'https://example.com/maya.jpg',
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    });

    expect(notification.actorUserId, 7);
    expect(notification.actorAvatarUrl, 'https://example.com/maya.jpg');
    expect(notification.copyWith(isUnread: false).actorAvatarUrl,
        'https://example.com/maya.jpg');
  });

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

  testWidgets('tapping a post notification opens its community post', (
    tester,
  ) async {
    final controller = Get.put(NotificationsController());
    controller.notifications.assignAll(
      [
        NotificationItem.fromJson({
          'id': 5,
          'type': 'COMMUNITY',
          'title': 'Maya Chen',
          'message': 'commented on your post.',
          'actorUserId': 7,
          'actorAvatarUrl': 'https://example.com/maya.jpg',
          'referenceType': 'POST',
          'referenceId': 42,
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      ],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage<void>(
            name: '/community/posts/:postId',
            page: () => Text('Post ${Get.parameters['postId']}'),
          ),
        ],
        home: const NotificationsView(),
      ),
    );

    final profileImage = tester
        .widgetList<Image>(find.byType(Image))
        .singleWhere((image) => image.image is NetworkImage);
    expect(
      (profileImage.image as NetworkImage).url,
      'https://example.com/maya.jpg',
    );
    await tester.tap(find.textContaining('Maya Chen', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('Post 42'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
