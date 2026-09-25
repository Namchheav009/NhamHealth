import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../models/planner/weight_loss_forecast_model.dart';
import 'weight_loss_projection_view.dart';

class WeightLossAnalysisPage extends StatefulWidget {
  const WeightLossAnalysisPage({super.key});

  @override
  State<WeightLossAnalysisPage> createState() => _WeightLossAnalysisPageState();
}

class _WeightLossAnalysisPageState extends State<WeightLossAnalysisPage> {
  static const _accent = AppColors.primaryGreen;

  WeightLossProjectionController get _controller =>
      Get.find<WeightLossProjectionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.showGoalAnalysis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pagePadding = AppSpacing.pageHorizontalFor(context);
    return Scaffold(
      key: const ValueKey('weight-goal-analysis-page'),
      backgroundColor: context.appBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: AppBackground(
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        pagePadding,
                        8,
                        pagePadding,
                        0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: AppBackHeader(
                          title: 'planner.weight_goal_analysis'.tr,
                          onBack: () => Get.back(),
                          trailing: Obx(() {
                            final forecast = _controller.forecast.value;
                            return IconButton(
                              key: const ValueKey(
                                'gemini-analysis-topbar-button',
                              ),
                              tooltip: 'planner.plan_details'.tr,
                              onPressed:
                                  () => AppAlert.actionInfo(
                                    context: context,
                                    title: 'planner.plan_details',
                                    message:
                                        forecast == null
                                            ? 'planner.forecast_unavailable'
                                            : _planDetails(forecast),
                                  ),
                              icon: const Icon(Icons.insights_rounded),
                              color: const Color(0xFF0F62FE),
                            );
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: _accent,
                        onRefresh:
                            () => _controller.showGoalAnalysis(
                              forceRefresh: true,
                            ),
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            pagePadding,
                            12,
                            pagePadding,
                            28,
                          ),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppSpacing.maxContentWidth,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _analysisHero(context),
                                    const SizedBox(height: 14),
                                    const WeightLossProjectionView(
                                      embedded: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _planDetails(WeightLossForecast forecast) {
    final goal =
        forecast.shouldGainWeight
            ? 'planner.goal_gain_weight'.tr
            : forecast.shouldMaintainWeight
            ? 'planner.goal_maintain_health'.tr
            : 'planner.goal_lose_weight'.tr;
    final change = forecast.projectedEndWeightKg - forecast.currentWeightKg;
    final changeText =
        '${change > 0 ? '+' : change < 0 ? '−' : ''}${change.abs().toStringAsFixed(1)}';
    final calorieGap = forecast.dailyDeficitCalories;
    final balance =
        calorieGap < 0
            ? 'planner.balance_surplus'.trParams({
              'amount': calorieGap.abs().round().toString(),
            })
            : calorieGap > 0
            ? 'planner.balance_deficit'.trParams({
              'amount': calorieGap.round().toString(),
            })
            : 'planner.balance_even'.tr;
    final guidance =
        forecast.aiAnalysisSummary.trim().isNotEmpty
            ? forecast.aiAnalysisSummary.trim()
            : forecast.paceDescription.trim();

    return [
      'planner.detail_goal'.trParams({'goal': goal}),
      'planner.detail_projection'.trParams({
        'current': forecast.currentWeightKg.toStringAsFixed(1),
        'projected': forecast.projectedEndWeightKg.toStringAsFixed(1),
        'days': forecast.timeframeDays.toString(),
        'change': changeText,
      }),
      'planner.detail_energy'.trParams({
        'intake': forecast.dailyPlannedCalories.round().toString(),
        'burn': forecast.tdeeCalories.round().toString(),
        'balance': balance,
      }),
      if (guidance.isNotEmpty)
        'planner.detail_guidance'.trParams({'guidance': guidance}),
      'planner.forecast_disclaimer'.tr,
    ].join('\n\n');
  }

  Widget _analysisHero(BuildContext context) {
    return Container(
      key: const ValueKey('weight-goal-analysis-hero'),
      padding: const EdgeInsets.fromLTRB(20, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              context.appIsDark
                  ? [context.appElevatedSurface, context.appSoftGreen]
                  : const [Color(0xFFE9FFF2), Color(0xFFF5FFF2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: context.appIsDark ? 0.08 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -4,
            bottom: -18,
            child: Container(
              width: 150,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(110, 60),
                  topRight: Radius.elliptical(85, 50),
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: -4,
            child: SizedBox(
              width: 132,
              height: 94,
              child: Image.asset(
                'assets/images/planner/analysis.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder:
                    (_, _, _) => const Icon(
                      Icons.eco_rounded,
                      size: 55,
                      color: AppColors.primaryGreen,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 104),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primaryGreen,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      if (Get.isRegistered<MealPlannerController>())
                        Obx(
                          () => Text(
                            Get.find<MealPlannerController>()
                                    .hasAnalyzedCurrentGoal
                                ? 'planner.analysis_ready'.tr
                                : 'planner.analysis_preview'.tr,
                            style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Text(
                          'planner.analysis_preview'.tr,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'planner.weight_goal_analysis'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Obx(() {
                  final forecast = _controller.forecast.value;
                  final descriptionKey =
                      forecast?.shouldGainWeight == true
                          ? 'planner.analysis_gain_page_desc'
                          : forecast?.shouldMaintainWeight == true
                          ? 'planner.analysis_maintain_weight_page_desc'
                          : 'planner.analysis_loss_page_desc';
                  return Text(
                    descriptionKey.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
