import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/daily_summary_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/home_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/nutrition_progress_model.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/home/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/home/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/home_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/widgets/daily_summary_card.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/widgets/greeting_section.dart';
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

    expect(
      find.byKey(const ValueKey<String>('home-wellness-scroll')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('home-wellness-cards')),
      findsOneWidget,
    );
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
      final controller = HomeController(
        repository: HomeRepository(provider: HomeProvider()),
      );
      Get.put<HomeController>(controller);

      await tester.pumpWidget(const GetMaterialApp(home: HomeView()));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('How are you feeling today?'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('home-tablet-layout')),
        size.width >= 768 ? findsOneWidget : findsNothing,
      );
      if (size.width >= 768) {
        expect(
          tester.getTopLeft(find.byType(GreetingSection)).dy,
          tester.getTopLeft(find.byType(DailySummaryCard)).dy,
        );
      }
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.onClose();
      await tester.pump();
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

    controller.addNutritionToToday(calories: 400, protein: 15, fat: 12);
    expect(controller.dashboard.value!.dailySummary.calories.value, '400');
    expect(controller.dashboard.value!.dailySummary.protein.value, '15');
    expect(controller.dashboard.value!.dailySummary.fat.value, '12');

    controller.selectDay(DateTime.now().subtract(const Duration(days: 1)));
    expect(controller.dashboard.value!.dailySummary.calories.value, '0');
  });

  test('dashboard refresh replaces stale wellness values', () async {
    final repository = _RefreshingHomeRepository();
    final controller = HomeController(repository: repository);

    await controller.loadDashboard();
    expect(controller.dashboard.value!.dailySummary.calories.value, '100');

    await controller.loadDashboard();
    expect(controller.dashboard.value!.dailySummary.calories.value, '250');
    expect(repository.lastRequestedDate, isNotNull);
    expect(repository.lastRequestedDate!.day, controller.selectedDay.value.day);
  });

  test('home startup refreshes a stale initial wellness snapshot', () async {
    Get.put<AuthService>(_SessionAuthService());
    final controller = HomeController(repository: _RefreshingHomeRepository());
    controller.dashboard.value = HomeDashboardModel(
      userName: 'User',
      dailySummary: _summary('0'),
      recommendedMeals: const [],
    );

    controller.onInit();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(controller.dashboard.value!.dailySummary.calories.value, '100');
    controller.onClose();
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

class _RefreshingHomeRepository extends HomeRepository {
  _RefreshingHomeRepository() : super(provider: HomeProvider());

  var _requestCount = 0;
  DateTime? lastRequestedDate;

  @override
  Future<HomeDashboardModel> getHomeDashboard({DateTime? date}) async {
    _requestCount++;
    lastRequestedDate = date;
    return HomeDashboardModel(
      userName: 'User',
      dailySummary: _summary(_requestCount == 1 ? '100' : '250'),
      recommendedMeals: const [],
    );
  }
}

DailySummaryModel _summary(String calories) => DailySummaryModel(
  calories: NutritionProgressModel(
    title: 'Calories',
    value: calories,
    target: '2000',
    progress: double.parse(calories) / 2000,
    unit: 'kcal',
  ),
  protein: _emptyProgress('Protein', '120', 'g'),
  fat: _emptyProgress('Fat', '78', 'g'),
  water: _emptyProgress('Water', '8', 'glasses'),
  fiber: _emptyProgress('Fiber', '25', 'g'),
  sugar: _emptyProgress('Sugar', '50', 'g'),
);

NutritionProgressModel _emptyProgress(
  String title,
  String target,
  String unit,
) => NutritionProgressModel(
  title: title,
  value: '0',
  target: target,
  progress: 0,
  unit: unit,
);
