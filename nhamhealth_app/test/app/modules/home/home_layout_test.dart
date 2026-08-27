import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/home/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/home/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/home_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/widgets/mood_card.dart';
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

    final wellnessScroll = find.byKey(
      const ValueKey<String>('home-wellness-scroll'),
    );
    expect(
      tester.widget<ListView>(wellnessScroll).scrollDirection,
      Axis.horizontal,
    );
    await tester.drag(wellnessScroll, const Offset(-500, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey<String>('home-wellness-sugar')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    controller.onClose();
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

  testWidgets('home content scrolls above the bottom navigation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 560);
    addTearDown(tester.view.reset);

    Get.put<AuthService>(_SessionAuthService());
    final controller = HomeController(
      repository: HomeRepository(provider: HomeProvider()),
    );
    Get.put<HomeController>(controller);

    await tester.pumpWidget(const GetMaterialApp(home: HomeView()));
    await tester.pump(const Duration(milliseconds: 900));

    final homeScroll = find.byType(SingleChildScrollView);
    final scrollWidget = tester.widget<SingleChildScrollView>(homeScroll);
    final padding = scrollWidget.padding! as EdgeInsets;
    expect(padding.bottom, greaterThanOrEqualTo(114));
    expect(
      scrollWidget.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );

    final verticalScrollable =
        find
            .descendant(of: homeScroll, matching: find.byType(Scrollable))
            .first;
    final position = tester.state<ScrollableState>(verticalScrollable).position;
    final initialOffset = position.pixels;

    await tester.drag(homeScroll, const Offset(0, -260));
    await tester.pump(const Duration(milliseconds: 300));

    expect(position.pixels, greaterThan(initialOffset));
    expect(tester.takeException(), isNull);
    controller.onClose();
  });

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

  testWidgets('mood card fits its old UI row at maximum home text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.2)),
          child: Scaffold(
            body: SizedBox(
              height: 78,
              child: MoodCard(
                emoji: '😊',
                label: 'Happy',
                selected: false,
                onTap: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Happy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}

class _SessionAuthService extends AuthService {
  _SessionAuthService() : user = null;

  final AuthenticatedUser? user;

  @override
  Future<AuthenticatedUser?> restoreSession() async => user;
}
