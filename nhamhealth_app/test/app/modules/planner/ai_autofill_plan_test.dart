import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/ai_autofill_response_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/providers/planner/meal_planner_provider.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AiAutoFillPlanResponse', () {
    test('parses JSON response correctly', () {
      final json = {
        'filledCount': 14,
        'dailyPlannedCalories': 1450.0,
        'dailyDeficit': 480.0,
        'tdee': 1930.0,
        'bmr': 1420.0,
        'projectedWeeklyLossKg': 0.43,
        'timeframeDays': 28,
        'totalProjectedLossKg': 1.72,
        'aiRationale':
            'Clinical caloric deficit of 480 kcal/day maintained safely above BMR.',
        'goal': 'LOSE_WEIGHT',
        'modelName': 'Google Gemini / gemini-test',
        'createdPlans': [
          {
            'planId': 101,
            'planDate': '2026-09-22',
            'mealType': 'BREAKFAST',
            'plannerMealId': 1,
            'mealName': 'Healthy Oatmeal',
            'calories': 350,
            'servings': 1.0,
          },
          {
            'planId': 102,
            'planDate': '2026-09-22',
            'mealType': 'LUNCH',
            'plannerMealId': 2,
            'mealName': 'Grilled Chicken Bowl',
            'calories': 500,
            'servings': 1.0,
          },
        ],
      };

      final response = AiAutoFillPlanResponse.fromJson(json);

      expect(response.filledCount, 14);
      expect(response.dailyPlannedCalories, 1450.0);
      expect(response.dailyDeficit, 480.0);
      expect(response.tdee, 1930.0);
      expect(response.bmr, 1420.0);
      expect(response.projectedWeeklyLossKg, 0.43);
      expect(response.timeframeDays, 28);
      expect(response.totalProjectedLossKg, 1.72);
      expect(response.aiRationale, contains('Clinical caloric deficit'));
      expect(response.goal, 'LOSE_WEIGHT');
      expect(response.modelName, 'Google Gemini / gemini-test');
      expect(response.createdPlans.length, 2);
      expect(response.createdPlans.first.name, 'Healthy Oatmeal');
    });
  });

  group('MealPlannerProvider.aiAutoFillPlan', () {
    test(
      'sends POST to /api/v1/meal-planner/ai-autofill and returns parsed response',
      () async {
        late Uri capturedUri;
        late Map<String, dynamic> capturedBody;
        late Map<String, String> capturedHeaders;

        final client = MockClient((request) async {
          if (request.url.path == '/api/v1/meal-planner/ai-autofill') {
            capturedUri = request.url;
            capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
            capturedHeaders = request.headers;

            return http.Response(
              jsonEncode({
                'filledCount': 2,
                'dailyPlannedCalories': 1500.0,
                'dailyDeficit': 500.0,
                'tdee': 2000.0,
                'bmr': 1400.0,
                'projectedWeeklyLossKg': 0.45,
                'timeframeDays': 28,
                'totalProjectedLossKg': 1.8,
                'aiRationale': 'Optimized by Gemini.',
                'goal': 'LOSE_WEIGHT',
                'modelName': 'Google Gemini / gemini-test',
                'createdPlans': [
                  {
                    'planId': 201,
                    'planDate': '2026-09-22',
                    'mealType': 'BREAKFAST',
                    'plannerMealId': 5,
                    'mealName': 'Avocado Toast',
                    'calories': 380,
                    'servings': 1.0,
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final provider = MealPlannerProvider(
          authService: _FakeAuthService(),
          client: client,
        );

        final result = await provider.aiAutoFillPlan(
          startDate: DateTime(2026, 9, 22),
          days: 7,
          goal: MealPlannerHealthGoal.loseWeight,
          targetTimeframeDays: 28,
          fillEmptyOnly: true,
          preferences: const MealPlannerDietaryPreferences(
            diet: MealPlannerDiet.vegan,
            allergens: ['peanut'],
            excludedIngredients: ['mushroom'],
            medicalFlags: ['DIABETES'],
          ),
        );

        expect(capturedUri.path, '/api/v1/meal-planner/ai-autofill');
        expect(capturedHeaders['Authorization'], 'Bearer test-token');
        expect(capturedBody['startDate'], '2026-09-22');
        expect(capturedBody['days'], 7);
        expect(capturedBody['goal'], 'LOSE_WEIGHT');
        expect(capturedBody['targetTimeframeDays'], 28);
        expect(capturedBody['fillEmptyOnly'], true);
        expect(capturedBody['diet'], 'VEGAN');
        expect(capturedBody['allergens'], ['peanut']);
        expect(capturedBody['excludedIngredients'], ['mushroom']);
        expect(capturedBody['medicalFlags'], ['DIABETES']);
        expect(result.filledCount, 2);
        expect(result.createdPlans.length, 1);
        expect(result.createdPlans.first.name, 'Avocado Toast');
      },
    );
  });

  group('MealPlannerController with AI Auto-Fill', () {
    test('applyAiAutoFillResult tracks the returned goal', () {
      final controller = MealPlannerController();
      const response = AiAutoFillPlanResponse(
        createdPlans: [],
        filledCount: 0,
        dailyPlannedCalories: 1900,
        dailyDeficit: 0,
        tdee: 1900,
        bmr: 1400,
        projectedWeeklyLossKg: 0,
        timeframeDays: 28,
        totalProjectedLossKg: 0,
        aiRationale: 'Balanced maintenance plan.',
        goal: 'MAINTAIN_HEALTH',
        modelName: 'clinical-rule-fallback',
      );

      controller.applyAiAutoFillResult(response);

      expect(controller.hasAnalyzedMaintainHealth.value, isTrue);
      expect(controller.hasAnalyzedWeightLoss.value, isFalse);
      expect(controller.lastMaintainHealthResult.value, same(response));
      expect(controller.lastWeightLossResult.value, isNull);
    });

    test('gain analysis is tracked independently from maintenance', () {
      final controller = MealPlannerController();
      const response = AiAutoFillPlanResponse(
        createdPlans: [],
        filledCount: 0,
        dailyPlannedCalories: 2400,
        dailyDeficit: -300,
        tdee: 2100,
        bmr: 1500,
        projectedWeeklyLossKg: 0.27,
        timeframeDays: 30,
        totalProjectedLossKg: 1.2,
        aiRationale: 'Balanced surplus for gradual gain.',
        goal: 'GAIN_WEIGHT',
        modelName: 'clinical-rule-fallback',
      );

      controller.applyAiAutoFillResult(response);

      expect(controller.hasAnalyzedGainWeight.value, isTrue);
      expect(controller.hasAnalyzedMaintainHealth.value, isFalse);
      expect(controller.hasAnalyzedWeightLoss.value, isFalse);
      expect(controller.lastGainWeightResult.value, same(response));
    });

    test(
      'autoFillPlan calls provider.aiAutoFillPlan and updates plans and lastAiAutoFillResult',
      () async {
        final client = MockClient((request) async {
          if (request.url.path == '/api/v1/meal-planner/ai-autofill') {
            return http.Response(
              jsonEncode({
                'filledCount': 1,
                'dailyPlannedCalories': 1400.0,
                'dailyDeficit': 500.0,
                'tdee': 1900.0,
                'bmr': 1350.0,
                'projectedWeeklyLossKg': 0.45,
                'timeframeDays': 28,
                'totalProjectedLossKg': 1.8,
                'aiRationale': 'Safe deficit established by Gemini.',
                'goal': 'LOSE_WEIGHT',
                'modelName': 'Google Gemini / gemini-test',
                'createdPlans': [
                  {
                    'planId': 301,
                    'planDate': '2026-09-21',
                    'mealType': 'DINNER',
                    'plannerMealId': 10,
                    'mealName': 'Khmer Steamed Fish',
                    'calories': 420,
                    'servings': 1.0,
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('[]', 200);
        });

        final provider = MealPlannerProvider(
          authService: _FakeAuthService(),
          client: client,
        );

        final controller = MealPlannerController(provider: provider);
        controller.setPlanDaysCount(7);

        final filled = await controller.autoFillPlan();

        expect(filled, 1);
        expect(controller.lastAiAutoFillResult.value, isNotNull);
        expect(
          controller.lastAiAutoFillResult.value!.modelName,
          'Google Gemini / gemini-test',
        );
        expect(
          controller.lastAiAutoFillResult.value!.totalProjectedLossKg,
          1.8,
        );
        expect(
          controller.selectedMeals.any((m) => m.name == 'Khmer Steamed Fish'),
          isTrue,
        );
      },
    );
  });
}
