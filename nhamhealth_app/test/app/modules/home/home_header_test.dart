import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/auth/services/google_auth_service.dart';
import 'package:nhamhealth_flutter/app/modules/home/controllers/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/home/providers/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/home/repositories/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/home/views/widgets/home_header.dart';
import 'package:nhamhealth_flutter/app/routes/app_pages.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('profile menu logs out and opens the login screen', (
    tester,
  ) async {
    final authService = _TrackingAuthService();
    final googleAuthService = _TrackingGoogleAuthService();
    Get.put<AuthService>(authService);
    Get.put<GoogleAuthService>(googleAuthService);
    Get.put<HomeController>(
      HomeController(repository: HomeRepository(provider: HomeProvider())),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: AppPages.pages,
        home: const Scaffold(body: HomeHeader()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-menu-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(authService.didLogout, isTrue);
    expect(googleAuthService.didSignOut, isTrue);
    expect(Get.currentRoute, '/login');
  });
}

class _TrackingAuthService extends AuthService {
  bool didLogout = false;

  @override
  Future<void> logout() async {
    didLogout = true;
  }
}

class _TrackingGoogleAuthService extends GoogleAuthService {
  bool didSignOut = false;

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }
}
