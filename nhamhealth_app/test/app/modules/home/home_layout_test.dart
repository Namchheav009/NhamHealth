import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/auth/models/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/home/controllers/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/home/providers/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/home/repositories/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/home/views/pages/home_view.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('home layout fits the reference phone width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    Get.put<AuthService>(_SessionAuthService());
    final controller = HomeController(
      repository: HomeRepository(provider: HomeProvider()),
    );
    Get.put<HomeController>(controller);
    controller.authenticatedUser.value = const AuthenticatedUser(
      id: 1,
      email: 'user@example.com',
      role: 'USER',
      fullName: 'Nham User',
    );

    await tester.pumpWidget(const GetMaterialApp(home: HomeView()));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('How are you feeling today?'), findsOneWidget);
    expect(find.text('AI Recommendation'), findsOneWidget);
    expect(find.text('Your Daily Wellness'), findsOneWidget);
    expect(find.text('Recommended Meals'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile navigation shows the logged-in user', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    const user = AuthenticatedUser(
      id: 12,
      email: 'alex@example.com',
      role: 'USER',
      fullName: 'Alex Rivera',
    );
    Get.put<AuthService>(_SessionAuthService(user));
    Get.put<HomeController>(
      HomeController(repository: HomeRepository(provider: HomeProvider())),
    );

    await tester.pumpWidget(const GetMaterialApp(home: HomeView()));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byKey(const ValueKey<String>('nav-profile')));
    await tester.pumpAndSettle();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('alex@example.com'), findsNWidgets(2));
    expect(find.text('User'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('profile-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('How are you feeling today?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SessionAuthService extends AuthService {
  _SessionAuthService([this.user]);

  final AuthenticatedUser? user;

  @override
  Future<AuthenticatedUser?> restoreSession() async => user;
}
