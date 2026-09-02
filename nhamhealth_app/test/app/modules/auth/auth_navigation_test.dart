import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/auth/login_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/auth/register_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/auth/account_created_view.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/google_login_request.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/login_request.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/login_response.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/register_request.dart';
import 'package:nhamhealth_flutter/app/modules/services/auth/google_auth_service.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/home/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/home_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/notifications/notifications_view.dart';
import 'package:nhamhealth_flutter/app/routes/app_pages.dart';
import 'package:nhamhealth_flutter/app/routes/app_routes.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('password login opens HomeView', (tester) async {
    final authService = _SuccessfulAuthService();
    await _pumpRouter(tester, authService);
    final controller = LoginController(
      authService: authService,
      googleAuth: _SuccessfulGoogleAuthService(),
    );

    await controller.login('user@example.com', 'StrongPass123!');
    await tester.pumpAndSettle();

    expect(find.byType(HomeView), findsOneWidget);
    expect(
      Get.find<HomeController>().authenticatedUser.value?.email,
      'user@example.com',
    );
  });

  testWidgets(
    'registration shows success while loading then opens Home without history',
    (tester) async {
      final authService = _SuccessfulAuthService();
      await _pumpRouter(tester, authService);
      final controller = RegisterController(
        authService: authService,
        googleAuth: _SuccessfulGoogleAuthService(),
      );

      await controller.register(
        fullName: 'New User',
        email: 'user@example.com',
        password: 'StrongPass123!',
        confirmPassword: 'StrongPass123!',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(Get.currentRoute, AppRoutes.accountCreated);
      expect(find.byType(AccountCreatedView), findsOneWidget);
      expect(find.text('Preparing your home...'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.home);
      expect(find.byType(HomeView), findsOneWidget);
      expect(Get.key.currentState?.canPop(), isFalse);
    },
  );

  testWidgets('Google authentication opens HomeView', (tester) async {
    final authService = _SuccessfulAuthService();
    await _pumpRouter(tester, authService);
    final controller = LoginController(
      authService: authService,
      googleAuth: _SuccessfulGoogleAuthService(),
    );

    await controller.loginWithGoogle();
    await tester.pumpAndSettle();

    expect(authService.googleToken, 'google-id-token');
    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('authenticated home opens notifications and returns home', (
    tester,
  ) async {
    final authService = _SuccessfulAuthService();
    await _pumpRouter(tester, authService);
    final controller = LoginController(
      authService: authService,
      googleAuth: _SuccessfulGoogleAuthService(),
    );

    await controller.login('user@example.com', 'StrongPass123!');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.home);
    await tester.tap(
      find.byKey(const ValueKey<String>('notifications-button')),
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.notifications);
    expect(find.byType(NotificationsView), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('notifications-back-button')),
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.home);
    expect(find.byType(HomeView), findsOneWidget);
  });
}

Future<void> _pumpRouter(WidgetTester tester, AuthService authService) async {
  Get.put<AuthService>(authService);
  Get.put<GoogleAuthService>(_SuccessfulGoogleAuthService());
  await tester.pumpWidget(
    GetMaterialApp(
      getPages: AppPages.pages,
      home: const Scaffold(body: SizedBox()),
    ),
  );
  await tester.pumpAndSettle();
}

class _SuccessfulAuthService extends AuthService {
  String? googleToken;

  static const _response = LoginResponse(
    accessToken: 'access-token',
    tokenType: 'Bearer',
    expiresIn: 86400,
    refreshToken: 'refresh-token',
    refreshExpiresIn: 604800,
    user: AuthenticatedUser(id: 7, email: 'user@example.com', role: 'USER'),
  );

  @override
  Future<LoginResponse> login(LoginRequest request) async => _response;

  @override
  Future<LoginResponse> register(RegisterRequest request) async => _response;

  @override
  Future<LoginResponse> loginWithGoogle(GoogleLoginRequest request) async {
    googleToken = request.idToken;
    return _response;
  }
}

class _SuccessfulGoogleAuthService extends GoogleAuthService {
  @override
  Future<String?> signInAndGetIdToken() async => 'google-id-token';
}
