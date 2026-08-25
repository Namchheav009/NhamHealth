import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/widgets/nham_app_bar.dart';

void main() {
  testWidgets('chat replaces language in the same top-bar action group', (
    tester,
  ) async {
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

    final chatButton = find.byKey(const ValueKey('chat-button'));
    final notificationsButton = find.byKey(
      const ValueKey<String>('notifications-button'),
    );

    expect(chatButton, findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('language-page-button')), findsNothing);
    expect(tester.getSize(chatButton), const Size(42, 44));
    expect(
      tester.getCenter(chatButton).dx,
      lessThan(tester.getCenter(notificationsButton).dx),
    );

    final icon = tester.widget<Icon>(
      find.byIcon(Icons.chat_bubble_outline_rounded),
    );
    expect(icon.color, const Color(0xFF333333));
  });
}
