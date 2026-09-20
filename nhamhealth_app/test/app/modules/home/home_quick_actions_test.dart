import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/home/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/daily_summary_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/home_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/nutrition_progress_model.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/home/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/home_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/widgets/home_quick_actions.dart';
import 'package:nhamhealth_flutter/app/modules/views/home/widgets/nutrition_progress_card.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  @override
  Future<AuthenticatedUser?> restoreSession() async => null;
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('HomeQuickActions renders 3 core feature action buttons', (
    tester,
  ) async {
    Get.put<AuthService>(_FakeAuthService());
    final controller = HomeController(
      repository: HomeRepository(provider: HomeProvider()),
    );
    Get.put<HomeController>(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(body: HomeQuickActions()),
      ),
    );
    await tester.pump();

    // Verify Quick Actions header
    expect(find.text('Quick Actions'), findsOneWidget);

    // Verify 3 core actions
    expect(find.byKey(const ValueKey('home-action-scan-food')), findsOneWidget);
    expect(find.text('Scan Food'), findsOneWidget);

    expect(find.byKey(const ValueKey('home-action-log-water')), findsOneWidget);
    expect(find.text('Log Water'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);

    expect(find.byKey(const ValueKey('home-action-meal-plan')), findsOneWidget);
    expect(find.text('Meal Plan'), findsOneWidget);
    expect(find.text('Track your health faster'), findsOneWidget);
    expect(find.text('Analyze your meal with AI'), findsOneWidget);
    expect(find.text('Track intake'), findsOneWidget);
    expect(find.text('Plan your week'), findsOneWidget);

    expect(find.byKey(const ValueKey('home-action-ai-meal')), findsNothing);
    expect(find.text('AI Meal'), findsNothing);
    expect(find.text('Find Meals'), findsNothing);

    // Test log water 1-tap action
    await tester.tap(find.byKey(const ValueKey('home-action-log-water')));
    await tester.pump();

    expect(controller.dashboard.value?.dailySummary.water.value, '1');

    await tester.pumpWidget(const SizedBox.shrink());
    controller.onClose();
    await tester.pump();
  });

  testWidgets(
    'HomeQuickActions fits within 320px narrow screen without overflow',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.reset);

      Get.put<AuthService>(_FakeAuthService());
      final controller = HomeController(
        repository: HomeRepository(provider: HomeProvider()),
      );
      Get.put<HomeController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('km', 'KH'),
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: HomeQuickActions(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('សកម្មភាពរហ័ស'), findsOneWidget);
      expect(find.text('តាមដានសុខភាពរបស់អ្នកកាន់តែលឿន'), findsOneWidget);
      expect(find.text('ស្កេនអាហារ'), findsOneWidget);
      expect(find.text('វិភាគអាហាររបស់អ្នកជាមួយ AI'), findsOneWidget);
      expect(find.text('អាហារដោយ AI'), findsNothing);
      expect(find.text('ថែមទឹក'), findsOneWidget);
      expect(find.text('កត់ត្រាបរិមាណទឹក'), findsOneWidget);
      expect(find.text('គម្រោងអាហារ'), findsOneWidget);
      expect(find.text('រៀបចំគម្រោងប្រចាំសប្តាហ៍'), findsOneWidget);
      expect(find.text('រកមុខម្ហូប'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      controller.onClose();
      await tester.pump();
    },
  );

  testWidgets(
    'NutritionProgressCard shows only the primary value and progress',
    (tester) async {
      const underBudgetData = NutritionProgressModel(
        title: 'Calories',
        value: '1200',
        target: '2000',
        progress: 0.6,
        unit: 'kcal',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: NutritionProgressCard(
                data: underBudgetData,
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1200 / 2000'), findsOneWidget);
      expect(find.text('800 left'), findsNothing);

      const overBudgetData = NutritionProgressModel(
        title: 'Calories',
        value: '2200',
        target: '2000',
        progress: 1.0,
        unit: 'kcal',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: NutritionProgressCard(
                data: overBudgetData,
                icon: Icons.local_fire_department_rounded,
                iconColor: Colors.orange,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('2200 / 2000'), findsOneWidget);
      expect(find.text('200 over'), findsNothing);
    },
  );

  testWidgets('HomeView integrates all four HomeQuickActions', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(380, 800);
    addTearDown(tester.view.reset);

    Get.put<AuthService>(_FakeAuthService());
    final controller = HomeController(
      repository: HomeRepository(provider: HomeProvider()),
    );
    Get.put<HomeController>(controller);

    controller.dashboard.value = const HomeDashboardModel(
      userName: 'Visal',
      dailySummary: DailySummaryModel(
        calories: NutritionProgressModel(
          title: 'Calories',
          value: '0',
          target: '2000',
          progress: 0,
          unit: 'kcal',
        ),
        protein: NutritionProgressModel(
          title: 'Protein',
          value: '0',
          target: '80',
          progress: 0,
          unit: 'g',
        ),
        fat: NutritionProgressModel(
          title: 'Fat',
          value: '0',
          target: '70',
          progress: 0,
          unit: 'g',
        ),
        water: NutritionProgressModel(
          title: 'Water',
          value: '0',
          target: '8',
          progress: 0,
          unit: 'glasses',
        ),
        fiber: NutritionProgressModel(
          title: 'Fiber',
          value: '0',
          target: '25',
          progress: 0,
          unit: 'g',
        ),
        sugar: NutritionProgressModel(
          title: 'Sugar',
          value: '0',
          target: '50',
          progress: 0,
          unit: 'g',
        ),
      ),
      recommendedMeals: [],
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const HomeView(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HomeQuickActions), findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-scan-food')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-log-water')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-meal-plan')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-action-ai-meal')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.onClose();
    await tester.pump();
  });
}
