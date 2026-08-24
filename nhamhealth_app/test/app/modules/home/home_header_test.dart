import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/home/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/home/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/widgets/home_header.dart';
import 'package:nhamhealth_flutter/app/routes/app_pages.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('profile button opens profile without a dropdown', (
    tester,
  ) async {
    final authService = _TrackingAuthService();
    Get.put<AuthService>(authService);
    Get.put<HomeController>(
      HomeController(repository: HomeRepository(provider: HomeProvider())),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: AppPages.pages,
        home: const Scaffold(body: HomeHeader()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-button')));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/profile');
    expect(find.byType(PopupMenuItem<int>), findsNothing);
  });

  testWidgets('profile button keeps the authenticated user avatar', (
    tester,
  ) async {
    Get.put<AuthService>(_TrackingAuthService());
    final controller = HomeController(
      repository: HomeRepository(provider: HomeProvider()),
    );
    Get.put<HomeController>(controller);
    controller.authenticatedUser.value = const AuthenticatedUser(
      id: 12,
      email: 'alex@example.com',
      role: 'USER',
      fullName: 'Alex Rivera',
    );

    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: HomeHeader())),
    );

    expect(find.text('AR'), findsOneWidget);

    expect(find.byKey(const ValueKey('profile-button')), findsOneWidget);
  });

  testWidgets('notification bell opens the notifications screen', (
    tester,
  ) async {
    Get.put<AuthService>(_TrackingAuthService());
    Get.put<HomeController>(
      HomeController(repository: HomeRepository(provider: HomeProvider())),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: AppPages.pages,
        home: const Scaffold(body: HomeHeader()),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('notifications-button')),
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/notifications');
    expect(find.text('Notifications'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('notifications-list')),
      findsOneWidget,
    );
  });
}

class _TrackingAuthService extends AuthService {
  bool didLogout = false;

  @override
  Future<void> logout() async {
    didLogout = true;
  }
}
