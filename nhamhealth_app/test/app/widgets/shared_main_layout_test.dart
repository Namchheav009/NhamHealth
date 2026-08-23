import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/widgets/home_bottom_navigation.dart';
import 'package:nhamhealth_flutter/app/modules/views/feed/feed_page.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/widgets/page_skeleton.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';
import 'package:nhamhealth_flutter/app/modules/bindings/feed/feed_binding.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shared bottom navigation keeps the Home dimensions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(25, 0, 25, 14),
            child: AppBottomNavigation(
              selectedIndex: 3,
              onSelect: (index) => selected = index,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppBottomNavigation)).height, 84);
    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    expect(selected, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('community skeleton fits the reference phone width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: PageSkeleton.community(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PageSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Community uses the shared bar and loading shell', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);
    Get.put<AuthService>(_CommunityAuthService());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/feed',
        getPages: [
          GetPage<void>(
            name: '/feed',
            page: () => const FeedPage(),
            binding: FeedBinding(),
          ),
          GetPage<void>(
            name: '/home',
            page: () => const Scaffold(body: Text('Home destination')),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppBottomNavigation), findsOneWidget);
    expect(find.byType(PageSkeleton), findsOneWidget);
    expect(tester.getSize(find.byType(AppBottomNavigation)).height, 84);

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
  });
}

class _CommunityAuthService extends AuthService {
  @override
  Future<AuthenticatedUser?> restoreSession() async => null;

  @override
  Future<String?> readAccessToken() async => null;
}
