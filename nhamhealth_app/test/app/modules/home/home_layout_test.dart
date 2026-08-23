import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/home/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/home/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/home_view.dart';
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

  for (final size in <Size>[
    const Size(320, 700),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets('home layout is responsive at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      Get.put<AuthService>(_SessionAuthService());
      Get.put<HomeController>(
        HomeController(repository: HomeRepository(provider: HomeProvider())),
      );

      await tester.pumpWidget(const GetMaterialApp(home: HomeView()));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('How are you feeling today?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('AI nutrition is kept per day on the dashboard', () async {
    final controller = HomeController(
      repository: HomeRepository(provider: HomeProvider()),
    );
    Get.put<AuthService>(_SessionAuthService());
    Get.put<HomeController>(controller);
    await controller.loadDashboard();

    controller.addNutritionToToday(calories: 400, protein: 15);
    expect(controller.dashboard.value!.dailySummary.calories.value, '400');
    expect(controller.dashboard.value!.dailySummary.protein.value, '15');

    controller.selectDay(DateTime.now().subtract(const Duration(days: 1)));
    expect(controller.dashboard.value!.dailySummary.calories.value, '0');
  });

}

class _SessionAuthService extends AuthService {
  _SessionAuthService([this.user]);

  final AuthenticatedUser? user;

  @override
  Future<AuthenticatedUser?> restoreSession() async => user;
}
