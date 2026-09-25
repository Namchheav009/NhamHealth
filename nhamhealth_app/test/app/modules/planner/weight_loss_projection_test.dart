import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/weight_loss_projection_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/weight_loss_forecast_model.dart';
import 'package:nhamhealth_flutter/app/modules/providers/planner/meal_planner_provider.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/weight_loss_projection_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  @override
  Future<String?> readAccessToken() async => 'mock-jwt-token';
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('WeightLossForecast Model Tests', () {
    test('correctly parses JSON payload', () {
      final json = {
        'currentWeightKg': 80.0,
        'age': 30,
        'heightCm': 175.0,
        'bmi': 26.1,
        'projectedBmi': 25.3,
        'healthyWeightMinKg': 56.7,
        'healthyWeightMaxKg': 76.3,
        'bmiStatus': 'OVERWEIGHT',
        'recommendedWeightDirection': 'LOSE',
        'activityLevel': 'MODERATE',
        'hasBiometricProfile': true,
        'energyEstimateUsesDefaults': false,
        'targetWeightKg': 77.0,
        'projectedWeightLossKg': 2.58,
        'projectedEndWeightKg': 77.42,
        'bmrCalories': 1749.0,
        'tdeeCalories': 2711.0,
        'dailyPlannedCalories': 2000.0,
        'dailyDeficitCalories': 711.0,
        'timeframeDays': 28,
        'weeklyPaceKg': 0.65,
        'paceStatus': 'OPTIMAL',
        'paceDescription': 'Clinically optimal rate.',
        'calorieWarning': false,
        'calorieWarningMessage': '',
        'recommendedFoods': [
          {
            'itemType': 'FOOD',
            'sourceId': 101,
            'sourceTable': 'planner_meals',
            'name': 'High Protein Chicken Rice',
            'category': 'Lunch',
            'calories': 480.0,
            'proteinGrams': 42.0,
            'carbsGrams': 50.0,
            'fatGrams': 8.0,
            'servingUnit': 'plate',
            'servingSize': 1.0,
            'imageUrl': 'https://example.com/chicken.jpg',
            'rationale': 'IBM Granite Insight: High protein preserves muscle.',
            'ibmBadge': 'IBM Granite 3.3',
          },
        ],
        'recommendedBeverages': [
          {
            'itemType': 'BEVERAGE',
            'sourceId': 202,
            'sourceTable': 'food_nutrition',
            'name': 'Green Tea',
            'category': 'Healthy Beverage',
            'calories': 2.0,
            'proteinGrams': 0.0,
            'carbsGrams': 0.0,
            'fatGrams': 0.0,
            'servingUnit': 'cup',
            'servingSize': 1.0,
            'imageUrl': '',
            'rationale':
                'IBM Granite Insight: EGCG catechins support fat oxidation.',
            'ibmBadge': 'IBM Granite 3.3',
          },
        ],
        'aiAnalysisSummary': 'You are on track to lose ~2.6 kg sustainably.',
      };

      final forecast = WeightLossForecast.fromJson(json);

      expect(forecast.currentWeightKg, 80.0);
      expect(forecast.age, 30);
      expect(forecast.heightCm, 175.0);
      expect(forecast.bmi, 26.1);
      expect(forecast.resolvedProjectedBmi, 25.3);
      expect(forecast.resolvedHealthyWeightMinKg, 56.7);
      expect(forecast.resolvedHealthyWeightMaxKg, 76.3);
      expect(forecast.bmiStatusKey, 'profile.bmi_overweight_range');
      expect(forecast.shouldLoseWeight, isTrue);
      expect(forecast.activityLevelKey, 'planner.activity_moderate');
      expect(forecast.hasBmiContext, isTrue);
      expect(forecast.energyEstimateUsesDefaults, isFalse);
      expect(forecast.projectedWeightLossKg, 2.58);
      expect(forecast.dailyDeficitCalories, 711.0);
      expect(forecast.isOptimal, isTrue);
      expect(forecast.isSurplus, isFalse);
      expect(forecast.recommendedFoods.length, 1);
      expect(forecast.recommendedFoods.first.name, 'High Protein Chicken Rice');
      expect(forecast.recommendedFoods.first.isFood, isTrue);
      expect(forecast.recommendedBeverages.length, 1);
      expect(forecast.recommendedBeverages.first.name, 'Green Tea');
      expect(forecast.recommendedBeverages.first.isBeverage, isTrue);
      expect(forecast.hasPlannedMeals, isFalse);
    });

    test('generates fallback model with valid values', () {
      final fallback = WeightLossForecast.fallback(
        currentWeightKg: 75.0,
        timeframeDays: 14,
        dailyDeficit: 600.0,
      );

      expect(fallback.currentWeightKg, 75.0);
      expect(fallback.timeframeDays, 14);
      expect(fallback.projectedWeightLossKg, greaterThan(0));
      expect(fallback.projectedEndWeightKg, lessThan(75.0));
    });

    test('maintenance fallback does not invent weight loss', () {
      final forecast = WeightLossForecast.fallback(
        currentWeightKg: 75,
        goal: MealPlannerHealthGoal.maintainHealth,
      );

      expect(forecast.projectedWeightLossKg, 0);
      expect(forecast.projectedEndWeightKg, 75);
      expect(forecast.dailyDeficitCalories, 0);
      expect(forecast.paceStatus, 'BALANCED');
    });

    test('gain fallback uses a surplus and projects weight upward', () {
      final forecast = WeightLossForecast.fallback(
        currentWeightKg: 52,
        goal: MealPlannerHealthGoal.gainWeight,
        timeframeDays: 30,
      );

      expect(forecast.shouldGainWeight, isTrue);
      expect(forecast.dailyDeficitCalories, lessThan(0));
      expect(forecast.projectedWeightLossKg, 0);
      expect(forecast.projectedEndWeightKg, greaterThan(52));
      expect(forecast.isSurplus, isTrue);
    });

    test('gain-specific pace statuses map to clear UI labels', () {
      final forecast = WeightLossForecast.fromJson({
        ...WeightLossForecast.fallback(
          goal: MealPlannerHealthGoal.gainWeight,
        ).toJson(),
        'paceStatus': 'GAIN_OPTIMAL',
      });

      expect(forecast.isOptimal, isTrue);
      expect(forecast.paceStatusKey, 'planner.pace_gain_optimal');
    });

    test('selected gain goal is distinct from BMI recommendation', () {
      final forecast = WeightLossForecast.fromJson({
        ...WeightLossForecast.fallback(
          goal: MealPlannerHealthGoal.gainWeight,
        ).toJson(),
        'effectiveGoal': 'GAIN_WEIGHT',
        'recommendedWeightDirection': 'MAINTAIN',
      });

      expect(forecast.shouldGainWeight, isTrue);
      expect(forecast.recommendedDirection, 'MAINTAIN');
    });
  });

  group('WeightLossProjectionController Tests', () {
    test('surfaces the profile requirement returned by the API', () async {
      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'detail':
                  'Complete your date of birth, height and weight before using a weight-loss plan.',
            }),
            400,
          ),
        ),
      );
      final controller = WeightLossProjectionController(provider: provider);

      await controller.loadForecast();

      expect(controller.forecast.value, isNull);
      expect(controller.requiresProfileReview.value, isTrue);
      expect(
        controller.errorMessage.value,
        contains('date of birth, height and weight'),
      );
    });

    test(
      'forecast follows the selected meal plan dates and health goal',
      () async {
        final planner = Get.put(MealPlannerController());
        await planner.initPlanner();
        final firstDate = DateTime.now().add(const Duration(days: 14));
        final secondDate = firstDate.add(const Duration(days: 7));
        String dateString(DateTime date) =>
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        planner.customStartDate.value = firstDate;
        planner.healthGoal.value = MealPlannerHealthGoal.loseWeight;
        final queries = <Uri>[];
        final provider = MealPlannerProvider(
          authService: _FakeAuthService(),
          client: MockClient((request) async {
            queries.add(request.url);
            return http.Response(
              jsonEncode(WeightLossForecast.fallback().toJson()),
              200,
            );
          }),
        );
        final forecast = Get.put(
          WeightLossProjectionController(provider: provider),
        );

        await forecast.loadForecast(forceRefresh: true);
        expect(
          queries.last.queryParameters['startDate'],
          dateString(firstDate),
        );
        expect(queries.last.queryParameters['goal'], 'LOSE_WEIGHT');

        planner.customStartDate.value = secondDate;
        await forecast.loadForecast(forceRefresh: true);
        expect(
          queries.last.queryParameters['startDate'],
          dateString(secondDate),
        );
      },
    );

    test('loads forecast and updates timeframe', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('weight-loss-forecast')) {
          final days = request.url.queryParameters['days'] ?? '28';
          return http.Response(
            jsonEncode({
              'currentWeightKg': 70.0,
              'targetWeightKg': 67.0,
              'projectedWeightLossKg': int.parse(days) == 90 ? 4.8 : 2.4,
              'projectedEndWeightKg': int.parse(days) == 90 ? 65.2 : 67.6,
              'bmrCalories': 1600.0,
              'tdeeCalories': 2400.0,
              'dailyPlannedCalories': 1800.0,
              'dailyDeficitCalories': 600.0,
              'timeframeDays': int.parse(days),
              'weeklyPaceKg': 0.55,
              'paceStatus': 'OPTIMAL',
              'paceDescription': 'Great pace',
              'calorieWarning': false,
              'calorieWarningMessage': '',
              'recommendedFoods': [],
              'recommendedBeverages': [],
              'aiAnalysisSummary': 'Consistent progress',
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: mockClient,
      );

      final controller = WeightLossProjectionController(provider: provider);
      await controller.loadForecast();

      expect(controller.isLoading.value, isFalse);
      expect(controller.forecast.value, isNotNull);
      expect(controller.forecast.value!.projectedWeightLossKg, 2.4);

      expect(controller.selectedTimeframeDays.value, 30);

      // Change to the long-term competition/demo outlook.
      controller.setTimeframeDays(90);
      await controller.loadForecast();

      expect(controller.selectedTimeframeDays.value, 90);
      expect(controller.forecast.value!.projectedWeightLossKg, 4.8);

      // Tab switching
      controller.setSelectedTab(1);
      expect(controller.selectedTab.value, 1);
    });

    test('recommended BMI goal requires explicit user confirmation', () async {
      final planner = Get.put(MealPlannerController());
      planner.healthGoal.value = MealPlannerHealthGoal.loseWeight;
      final response = WeightLossForecast.fallback(
        goal: MealPlannerHealthGoal.maintainHealth,
        hasBiometricProfile: true,
        bmi: 22.0,
        recommendedWeightDirection: 'MAINTAIN',
      );
      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: MockClient(
          (_) async => http.Response(jsonEncode(response.toJson()), 200),
        ),
      );
      final controller = WeightLossProjectionController(provider: provider);

      await controller.loadForecast();

      expect(planner.healthGoal.value, MealPlannerHealthGoal.loseWeight);
      expect(controller.hasGoalRecommendation, isTrue);

      await controller.applyRecommendedGoal();

      expect(planner.healthGoal.value, MealPlannerHealthGoal.maintainHealth);
      expect(controller.hasGoalRecommendation, isFalse);
    });
  });

  group('WeightLossProjectionView Widget Tests', () {
    testWidgets('turns a generic 400 into an actionable profile review state', (
      tester,
    ) async {
      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'status': 400, 'error': 'Bad Request'}),
            400,
          ),
        ),
      );
      Get.put<WeightLossProjectionController>(
        WeightLossProjectionController(provider: provider),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Material(
            child: SingleChildScrollView(
              child: WeightLossProjectionView(embedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('weight-goal-profile-review-state')),
        findsOneWidget,
      );
      expect(find.text('Health profile review needed'), findsOneWidget);
      expect(find.text('Review Health Profile'), findsOneWidget);
      expect(find.text('Bad Request'), findsNothing);
    });

    testWidgets('shows an easy-to-read preview before meals are planned', (
      tester,
    ) async {
      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(WeightLossForecast.fallback().toJson()),
            200,
          ),
        ),
      );
      Get.put<WeightLossProjectionController>(
        WeightLossProjectionController(provider: provider),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Material(
            child: SingleChildScrollView(
              child: WeightLossProjectionView(embedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('weight-goal-forecast-card')),
        findsOneWidget,
      );
      expect(find.text('Weight Loss Forecast'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('weight-goal-profile-context-missing')),
        findsOneWidget,
      );
      expect(find.text('Complete your health profile'), findsOneWidget);
    });

    testWidgets('maintenance selection keeps a maintenance forecast', (
      tester,
    ) async {
      final planner = Get.put(MealPlannerController());
      planner.healthGoal.value = MealPlannerHealthGoal.maintainHealth;
      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(
              WeightLossForecast.fallback(
                goal: MealPlannerHealthGoal.maintainHealth,
                hasPlannedMeals: true,
              ).toJson(),
            ),
            200,
          ),
        ),
      );
      Get.put<WeightLossProjectionController>(
        WeightLossProjectionController(provider: provider),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Material(
            child: SingleChildScrollView(
              child: WeightLossProjectionView(embedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Weight Maintenance Forecast'), findsOneWidget);
      expect(find.text('Weight Loss Forecast'), findsNothing);
    });

    testWidgets('renders forecast inline without a second page scaffold', (
      tester,
    ) async {
      Get.put<WeightLossProjectionController>(WeightLossProjectionController());

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Material(
            child: SingleChildScrollView(
              child: WeightLossProjectionView(embedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('embedded-weight-loss-forecast')),
        findsOneWidget,
      );
      expect(find.text('Weight Loss Forecast'), findsOneWidget);
      expect(find.byType(Scaffold), findsNothing);
    });

    testWidgets('renders hero card, metrics, and tab views cleanly', (
      tester,
    ) async {
      final mockForecast = WeightLossForecast(
        currentWeightKg: 75.0,
        targetWeightKg: 72.0,
        projectedWeightLossKg: 2.3,
        projectedEndWeightKg: 72.7,
        bmrCalories: 1650.0,
        tdeeCalories: 2500.0,
        dailyPlannedCalories: 1950.0,
        dailyDeficitCalories: 550.0,
        timeframeDays: 28,
        weeklyPaceKg: 0.50,
        paceStatus: 'OPTIMAL',
        paceDescription: 'Clinically optimal rate.',
        calorieWarning: false,
        calorieWarningMessage: '',
        recommendedFoods: [
          const ForecastRecommendationItem(
            itemType: 'FOOD',
            sourceId: 50,
            sourceTable: 'planner_meals',
            name: 'Grilled Salmon Bowl',
            category: 'Lunch',
            calories: 460.0,
            proteinGrams: 36.0,
            carbsGrams: 40.0,
            fatGrams: 12.0,
            servingUnit: 'bowl',
            servingSize: 1.0,
            imageUrl: '',
            rationale:
                'IBM Granite Insight: Rich in lean protein to preserve muscle.',
            ibmBadge: 'IBM Granite 3.3',
          ),
        ],
        recommendedBeverages: [
          const ForecastRecommendationItem(
            itemType: 'BEVERAGE',
            sourceId: 60,
            sourceTable: 'food_nutrition',
            name: 'Unsweetened Green Tea',
            category: 'Healthy Beverage',
            calories: 2.0,
            proteinGrams: 0.0,
            carbsGrams: 0.0,
            fatGrams: 0.0,
            servingUnit: 'cup',
            servingSize: 1.0,
            imageUrl: '',
            rationale: 'IBM Granite Insight: EGCG supports fat oxidation.',
            ibmBadge: 'IBM Granite 3.3',
          ),
        ],
        aiAnalysisSummary:
            'Your planned deficit ensures healthy, sustainable weight loss.',
        hasPlannedMeals: true,
      );

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(mockForecast.toJson()), 200);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: mockClient,
      );

      final controller = WeightLossProjectionController(provider: provider);
      Get.put<WeightLossProjectionController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const WeightLossProjectionView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Hero Card
      expect(find.textContaining('−2.3 kg'), findsOneWidget);
      expect(find.textContaining('75.0 kg'), findsOneWidget);
      expect(find.textContaining('72.7 kg'), findsOneWidget);
      expect(find.text('1 week'), findsOneWidget);
      expect(find.text('1 month'), findsOneWidget);
      expect(find.text('3 months'), findsOneWidget);

      // Check Energy Deficit
      expect(find.textContaining('550 kcal'), findsOneWidget);
      expect(find.textContaining('2500 kcal'), findsOneWidget);

      expect(find.text('Meals for weight loss'), findsNothing);
      expect(find.byKey(const ValueKey('tab-suitable-foods')), findsNothing);
    });

    testWidgets('does not render meal recommendations on goal analysis', (
      tester,
    ) async {
      final webForecast = WeightLossForecast(
        currentWeightKg: 78.0,
        targetWeightKg: 74.0,
        projectedWeightLossKg: 3.2,
        projectedEndWeightKg: 74.8,
        bmrCalories: 1700.0,
        tdeeCalories: 2600.0,
        dailyPlannedCalories: 2000.0,
        dailyDeficitCalories: 600.0,
        timeframeDays: 28,
        weeklyPaceKg: 0.55,
        paceStatus: 'OPTIMAL',
        paceDescription: 'Great pace',
        calorieWarning: false,
        calorieWarningMessage: '',
        recommendedFoods: [
          const ForecastRecommendationItem(
            itemType: 'FOOD',
            sourceId: 701,
            sourceTable: 'planner_meals',
            name: 'Chicken Satay Salad with Ginger-Lime Dressing',
            category: 'Healthy Lunch',
            calories: 390.0,
            proteinGrams: 42.0,
            carbsGrams: 14.0,
            fatGrams: 18.0,
            servingUnit: 'plate',
            servingSize: 1.0,
            imageUrl: '',
            rationale:
                'IBM Granite Insight (BBC Good Food): High protein-to-calorie ratio (42g protein, 390 kcal).',
            ibmBadge: 'IBM Granite 3.3',
          ),
        ],
        recommendedBeverages: [
          const ForecastRecommendationItem(
            itemType: 'BEVERAGE',
            sourceId: 702,
            sourceTable: 'food_nutrition',
            name: 'Matcha Green Tea with Fresh Mint',
            category: 'Healthy Beverage',
            calories: 4.0,
            proteinGrams: 0.5,
            carbsGrams: 0.5,
            fatGrams: 0.0,
            servingUnit: 'cup',
            servingSize: 1.0,
            imageUrl: '',
            rationale:
                'IBM Granite Insight (Healthline): Loaded with EGCG catechins and clean energy.',
            ibmBadge: 'IBM Granite 3.3',
          ),
        ],
        aiAnalysisSummary: 'Consistent weight loss with nutrient-dense meals.',
        hasPlannedMeals: true,
      );

      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode(webForecast.toJson()), 200);
      });

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: mockClient,
      );

      final controller = WeightLossProjectionController(provider: provider);
      Get.put<WeightLossProjectionController>(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const WeightLossProjectionView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meals for weight loss'), findsNothing);
      expect(
        find.text('Chicken Satay Salad with Ginger-Lime Dressing'),
        findsNothing,
      );
      expect(find.text('Matcha Green Tea with Fresh Mint'), findsNothing);
    });

    testWidgets(
      'when only Weight Loss analyzed -> shows only Weight Loss, no goal switcher',
      (tester) async {
        final planner = Get.put(MealPlannerController());
        planner.hasAnalyzedWeightLoss.value = true;
        planner.hasAnalyzedMaintainHealth.value = false;
        planner.healthGoal.value = MealPlannerHealthGoal.loseWeight;

        final lossForecast = WeightLossForecast.fallback(
          goal: MealPlannerHealthGoal.loseWeight,
          hasPlannedMeals: true,
        );

        final provider = MealPlannerProvider(
          authService: _FakeAuthService(),
          client: MockClient(
            (_) async => http.Response(jsonEncode(lossForecast.toJson()), 200),
          ),
        );

        Get.put<WeightLossProjectionController>(
          WeightLossProjectionController(provider: provider),
        );

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const Material(
              child: SingleChildScrollView(
                child: WeightLossProjectionView(embedded: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Weight Loss content is visible
        expect(find.text('Weight Loss Forecast'), findsOneWidget);
        expect(find.text('Focus on gradual weight loss'), findsOneWidget);

        // Maintain Health and Dual Switcher must NOT be shown
        expect(find.byKey(const ValueKey('dual-goal-switcher')), findsNothing);
        expect(find.text('Health Maintenance Outlook'), findsNothing);
        expect(find.text('Maintain Your Balance'), findsNothing);
        expect(
          find.byKey(const ValueKey('dual-goal-comparison-card')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'maintain-health analysis preserves the selected planner goal',
      (tester) async {
        final planner = Get.put(MealPlannerController());
        await planner.initPlanner();
        planner.hasAnalyzedWeightLoss.value = false;
        planner.hasAnalyzedMaintainHealth.value = true;
        planner.healthGoal.value = MealPlannerHealthGoal.maintainHealth;

        final maintainForecast = WeightLossForecast.fallback(
          goal: MealPlannerHealthGoal.maintainHealth,
          hasPlannedMeals: true,
        );
        final requestedGoals = <String?>[];

        final provider = MealPlannerProvider(
          authService: _FakeAuthService(),
          client: MockClient((request) async {
            requestedGoals.add(request.url.queryParameters['goal']);
            return http.Response(jsonEncode(maintainForecast.toJson()), 200);
          }),
        );

        Get.put<WeightLossProjectionController>(
          WeightLossProjectionController(provider: provider),
        );

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const Material(
              child: SingleChildScrollView(
                child: WeightLossProjectionView(embedded: true),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('dual-goal-switcher')), findsNothing);
        expect(find.text('Weight Maintenance Forecast'), findsOneWidget);
        expect(find.text('Weight Loss Forecast'), findsNothing);
        expect(requestedGoals, isNotEmpty);
        expect(requestedGoals, contains('MAINTAIN_HEALTH'));
        expect(requestedGoals.last, 'MAINTAIN_HEALTH');
        expect(
          find.byKey(const ValueKey('dual-goal-comparison-card')),
          findsNothing,
        );
      },
    );

    testWidgets('legacy dual-goal flags never show the removed goal', (
      tester,
    ) async {
      final planner = Get.put(MealPlannerController());
      planner.hasAnalyzedWeightLoss.value = true;
      planner.hasAnalyzedMaintainHealth.value = true;

      final lossForecast = WeightLossForecast.fallback(
        goal: MealPlannerHealthGoal.loseWeight,
        hasPlannedMeals: true,
      );
      final maintainForecast = WeightLossForecast.fallback(
        goal: MealPlannerHealthGoal.maintainHealth,
        hasPlannedMeals: true,
      );

      final provider = MealPlannerProvider(
        authService: _FakeAuthService(),
        client: MockClient((req) async {
          final uri = req.url.toString();
          final isMaintain = uri.contains('MAINTAIN');
          return http.Response(
            jsonEncode((isMaintain ? maintainForecast : lossForecast).toJson()),
            200,
          );
        }),
      );

      final projController = WeightLossProjectionController(provider: provider);
      Get.put<WeightLossProjectionController>(projController);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Material(
            child: SingleChildScrollView(
              child: WeightLossProjectionView(embedded: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dual-goal-switcher')), findsNothing);
      expect(find.byKey(const ValueKey('pill-maintain-health')), findsNothing);
      expect(
        find.byKey(const ValueKey('dual-goal-comparison-card')),
        findsNothing,
      );
      expect(find.text('Health Maintenance Outlook'), findsNothing);
      expect(
        projController.activeAnalysisGoal.value,
        MealPlannerHealthGoal.loseWeight,
      );
      expect(find.text('Weight Loss Forecast'), findsOneWidget);
    });
  });
}
