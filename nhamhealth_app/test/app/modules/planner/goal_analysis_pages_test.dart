import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/weight_loss_projection_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/weight_loss_forecast_model.dart';
import 'package:nhamhealth_flutter/app/modules/views/planner/goal_analysis_pages.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() => Get.reset());
  tearDown(() => Get.reset());

  Future<void> pumpAnalysisPage(
    WidgetTester tester, {
    Locale locale = const Locale('en', 'US'),
    ThemeData? theme,
    String direction = 'LOSE',
    double bmi = 26.2,
    String bmiStatus = 'OVERWEIGHT',
  }) async {
    final controller = Get.put(WeightLossProjectionController());
    final forecast = WeightLossForecast.fallback(
      goal: MealPlannerHealthGoal.loseWeight,
      hasPlannedMeals: true,
      age: 28,
      heightCm: 170,
      bmi: bmi,
      projectedBmi: direction == 'LOSE' ? 25.4 : bmi,
      healthyWeightMinKg: 53.5,
      healthyWeightMaxKg: 72.0,
      bmiStatus: bmiStatus,
      recommendedWeightDirection: direction,
      activityLevel: 'MODERATE',
      hasBiometricProfile: true,
    );
    controller.weightLossForecast.value = forecast;
    controller.forecast.value = forecast;
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        theme: theme ?? AppTheme.light,
        translations: AppTranslations(),
        locale: locale,
        home: const WeightLossAnalysisPage(),
      ),
    );
    await tester.pump();
  }

  testWidgets('weight goal analysis has a dedicated focused page', (
    tester,
  ) async {
    await pumpAnalysisPage(tester);

    expect(
      find.byKey(const ValueKey('weight-goal-analysis-page')),
      findsOneWidget,
    );
    expect(find.text('Weight Goal Analysis'), findsWidgets);
    expect(
      find.byKey(const ValueKey('weight-goal-analysis-hero')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('weight-goal-forecast-card')),
      findsOneWidget,
    );
    expect(find.text('Daily Deficit'), findsOneWidget);
    expect(find.text('BMI 26.2'), findsOneWidget);
    expect(find.text('Focus on gradual weight loss'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('weight-goal-bmi-context')),
      findsOneWidget,
    );
    expect(find.text('Why this goal is recommended'), findsOneWidget);
    expect(find.text('Focus on gradual weight loss'), findsOneWidget);
    expect(find.text('Calorie deficit'), findsNothing);
    expect(find.text('Protein focus'), findsNothing);
    expect(find.text('Safe pace'), findsNothing);
    expect(
      find.byKey(const ValueKey('maintain-health-analysis-page')),
      findsNothing,
    );
    expect(find.textContaining('Maintain Health'), findsNothing);
    expect(find.byKey(const ValueKey('dual-goal-switcher')), findsNothing);
  });

  testWidgets('low BMI shows a clear gain-weight direction instead of error', (
    tester,
  ) async {
    await pumpAnalysisPage(
      tester,
      direction: 'GAIN',
      bmi: 17.2,
      bmiStatus: 'UNDERWEIGHT',
    );

    expect(find.byKey(const ValueKey('weight-direction-gain')), findsOneWidget);
    expect(find.text('Focus on gaining weight'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('weight-goal-profile-review-state')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('weight-goal-forecast-card')),
      findsOneWidget,
    );
    expect(find.text('Weight Gain Forecast'), findsOneWidget);
  });

  testWidgets('healthy BMI shows a clear maintain-weight direction', (
    tester,
  ) async {
    await pumpAnalysisPage(
      tester,
      direction: 'MAINTAIN',
      bmi: 22.4,
      bmiStatus: 'HEALTHY',
    );

    expect(
      find.byKey(const ValueKey('weight-direction-maintain')),
      findsOneWidget,
    );
    expect(find.text('Maintain your current weight'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('weight-goal-forecast-card')),
      findsOneWidget,
    );
    expect(find.text('Weight Maintenance Forecast'), findsOneWidget);
  });

  testWidgets('weight goal analysis is responsive in Khmer dark mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpAnalysisPage(
      tester,
      locale: const Locale('km', 'KH'),
      theme: AppTheme.dark,
    );

    expect(find.text('ការវិភាគគោលដៅទម្ងន់'), findsWidgets);
    expect(
      find.byKey(const ValueKey('weight-goal-forecast-card')),
      findsOneWidget,
    );
    expect(find.text('BMI 26.2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('weight-goal-bmi-context')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
