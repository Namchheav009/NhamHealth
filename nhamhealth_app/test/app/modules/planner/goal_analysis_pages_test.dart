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
    WidgetTester tester,
  ) async {
    final controller = Get.put(WeightLossProjectionController());
    final forecast = WeightLossForecast.fallback(
      goal: MealPlannerHealthGoal.loseWeight,
    );
    controller.weightLossForecast.value = forecast;
    controller.forecast.value = forecast;
    controller.isLoading.value = false;

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const WeightLossAnalysisPage(),
      ),
    );
    await tester.pump();
  }

  testWidgets('weight loss has a dedicated focused page', (tester) async {
    await pumpAnalysisPage(tester);

    expect(
      find.byKey(const ValueKey('weight-loss-analysis-page')),
      findsOneWidget,
    );
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

}
