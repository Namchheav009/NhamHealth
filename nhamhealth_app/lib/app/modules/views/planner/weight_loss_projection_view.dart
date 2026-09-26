import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../models/planner/meal_plan.dart';
import '../../models/planner/weight_loss_forecast_model.dart';
import 'planner_shared.dart';

class WeightLossProjectionView extends GetView<WeightLossProjectionController> {
  const WeightLossProjectionView({super.key, this.embedded = false});

  final bool embedded;
  String get _pageTitle => 'planner.weight_loss_forecast'.tr;

  Color _positiveText(BuildContext context) =>
      context.appIsDark ? const Color(0xFF72DDA7) : AppColors.darkGreen;

  Color _secondaryAccent(BuildContext context) =>
      context.appIsDark ? const Color(0xFF78DCD0) : const Color(0xFF087F72);

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Obx(() => _forecastContent(context, embedded: true));
    }
    return Scaffold(
      backgroundColor: context.appBackground,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontalFor(context),
                  8,
                  AppSpacing.pageHorizontalFor(context),
                  0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: AppBackHeader(
                    title: _pageTitle,
                    onBack: () => Get.back(),
                    trailing: Obx(() {
                      final analysis =
                          controller.forecast.value?.aiAnalysisSummary.trim() ??
                          '';
                      if (analysis.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        key: const ValueKey('gemini-analysis-topbar-button'),
                        tooltip: 'planner.gemini_analysis'.tr,
                        onPressed:
                            () => showWeightGoalPlanDetailsAlert(
                              context,
                              forecast: controller.forecast.value,
                            ),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        color: const Color(0xFF0F62FE),
                      );
                    }),
                  ),
                ),
              ),
              Expanded(child: Obx(() => _forecastContent(context))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _forecastContent(BuildContext context, {bool embedded = false}) {
    if (controller.isLoading.value && controller.forecast.value == null) {
      return const PageSkeleton.plannerSlots();
    }

    final forecast = controller.forecast.value;
    if (forecast == null) {
      final error = controller.errorMessage.value.trim();
      final needsProfile = controller.requiresProfileReview.value;
      return Padding(
        key: embedded ? const ValueKey('embedded-weight-loss-forecast') : null,
        padding: const EdgeInsets.all(20),
        child: Container(
          key: ValueKey(
            needsProfile
                ? 'weight-goal-profile-review-state'
                : 'weight-goal-network-error-state',
          ),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.appBorder),
            boxShadow: context.appTileShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      needsProfile
                          ? context.appSoftGreen
                          : context.appSurfaceLow,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  needsProfile
                      ? Icons.manage_accounts_outlined
                      : Icons.cloud_off_outlined,
                  size: 29,
                  color:
                      needsProfile
                          ? AppColors.primaryGreen
                          : context.appMutedText,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                needsProfile ? 'planner.profile_review_needed'.tr : _pageTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                error.isEmpty ? 'planner.forecast_unavailable'.tr : error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              if (needsProfile) ...[
                FilledButton.icon(
                  onPressed: () => Get.toNamed<void>(AppRoutes.bmiAnalysis),
                  icon: const Icon(Icons.monitor_heart_outlined, size: 19),
                  label: Text('planner.review_health_profile'.tr),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: context.appColorScheme.primary,
                    foregroundColor: context.appColorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                TextButton.icon(
                  onPressed: () => controller.loadForecast(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text('planner.retry'.tr),
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: () => controller.loadForecast(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('planner.retry'.tr),
                ),
            ],
          ),
        ),
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _projectionHeroCard(context, forecast),
        if (controller.hasGoalRecommendation) ...[
          const SizedBox(height: 12),
          _goalRecommendationCard(context, forecast),
        ],
        const SizedBox(height: 12),
        _lifestyleGuidanceCard(context, forecast),
        const SizedBox(height: 12),
        _energyBalanceCard(context, forecast),
      ],
    );

    if (embedded) {
      return KeyedSubtree(
        key: const ValueKey('embedded-weight-loss-forecast'),
        child: content,
      );
    }
    return RefreshIndicator(
      onRefresh: () => controller.loadForecast(forceRefresh: true),
      color: AppColors.primaryGreen,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontalFor(context),
          14,
          AppSpacing.pageHorizontalFor(context),
          28,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  // Retained for a possible expanded analysis page.
  // ignore: unused_element
  Widget _geminiAnalysisCard(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    return Container(
      key: const ValueKey('gemini-weight-goal-analysis'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF0F62FE).withValues(alpha: 0.24),
        ),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F62FE).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF0F62FE),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.gemini_analysis'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'planner.gemini_analysis_subtitle'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            forecast.aiAnalysisSummary.trim(),
            style: TextStyle(
              color: context.appText,
              fontSize: 12.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'planner.forecast_disclaimer'.tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 9.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Kept as a reusable expanded presentation. The analysis page now uses the
  // compact direction summary inside the forecast card.
  // ignore: unused_element
  Widget _weightDirectionCard(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    final color =
        forecast.shouldGainWeight
            ? AppColors.accentOrange
            : forecast.shouldMaintainWeight
            ? _secondaryAccent(context)
            : AppColors.primaryGreen;
    final icon =
        forecast.shouldGainWeight
            ? Icons.trending_up_rounded
            : forecast.shouldMaintainWeight
            ? Icons.trending_flat_rounded
            : Icons.trending_down_rounded;

    return Container(
      key: ValueKey(
        'weight-direction-${forecast.resolvedWeightDirection.toLowerCase()}',
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: context.appCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 29),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'planner.your_weight_direction'.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  forecast.weightDirectionTitleKey.tr,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  forecast.weightDirectionMessageKey.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
                if (forecast.hasBmiContext) ...[
                  const SizedBox(height: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'BMI ${forecast.bmi!.toStringAsFixed(1)} • ${forecast.bmiStatusKey.tr}',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectionHeroCard(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    final change = forecast.projectedEndWeightKg - forecast.currentWeightKg;
    final absoluteChange = change.abs();
    final preciseChange =
        absoluteChange < 0.1 && absoluteChange > 0
            ? absoluteChange.toStringAsFixed(2)
            : absoluteChange.toStringAsFixed(1);
    final changeText =
        change == 0 ? '0.0 kg' : '${change > 0 ? '+' : '−'}$preciseChange kg';
    final accent =
        forecast.shouldGainWeight
            ? AppColors.accentOrange
            : forecast.shouldMaintainWeight
            ? _secondaryAccent(context)
            : AppColors.primaryGreen;
    final titleKey =
        forecast.shouldGainWeight
            ? 'planner.weight_gain_forecast'
            : forecast.shouldMaintainWeight
            ? 'planner.weight_maintenance_forecast'
            : 'planner.weight_loss_forecast';
    final directionKey = ValueKey(
      'weight-direction-${forecast.resolvedWeightDirection.toLowerCase()}',
    );

    return Container(
      key: const ValueKey('weight-goal-forecast-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                key: directionKey,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  forecast.shouldGainWeight
                      ? Icons.trending_up_rounded
                      : forecast.shouldMaintainWeight
                      ? Icons.balance_rounded
                      : Icons.bar_chart_rounded,
                  size: 23,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          forecast.weightDirectionTitleKey.tr,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (forecast.hasBmiContext)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              'BMI ${forecast.bmi!.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: accent,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big projected weight loss number
          Center(
            child: Column(
              children: [
                Text(
                  changeText,
                  style: TextStyle(
                    color: accent,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'planner.timeframe_days'.trParams({
                    'count': '${forecast.timeframeDays}',
                  }),
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _weightProgress(context, forecast, accent: accent),
          const SizedBox(height: 12),
          _weightShiftConfirmationBanner(context, forecast, change: change),
          const SizedBox(height: 16),

          // Timeframe Selection Chips
          _timeframeSelector(context),
        ],
      ),
    );
  }

  Widget _weightShiftConfirmationBanner(
    BuildContext context,
    WeightLossForecast forecast, {
    required double change,
  }) {
    final absChange = change.abs();
    final absAmount =
        absChange < 0.1 && absChange > 0
            ? absChange.toStringAsFixed(2)
            : absChange.toStringAsFixed(1);
    final isLoss = change < 0;
    final isGain = change > 0;

    final String titleText;
    final String noteText;
    final IconData iconData;
    final Color bannerColor;

    if (isLoss) {
      titleText = 'planner.weight_shift_loss'.trParams({'amount': absAmount});
      noteText =
          absChange < 0.5
              ? 'planner.weight_shift_small_loss_note'.trParams({
                'amount': absAmount,
              })
              : 'planner.weight_shift_steady_loss_note'.trParams({
                'amount': absAmount,
              });
      iconData = Icons.trending_down_rounded;
      bannerColor = AppColors.primaryGreen;
    } else if (isGain) {
      titleText = 'planner.weight_shift_gain'.trParams({'amount': absAmount});
      noteText =
          absChange < 0.5
              ? 'planner.weight_shift_small_gain_note'.trParams({
                'amount': absAmount,
              })
              : 'planner.weight_shift_steady_gain_note'.trParams({
                'amount': absAmount,
              });
      iconData = Icons.trending_up_rounded;
      bannerColor = AppColors.accentOrange;
    } else {
      titleText = 'planner.weight_shift_maintain'.tr;
      noteText = 'planner.weight_shift_maintain_note'.tr;
      iconData = Icons.balance_rounded;
      bannerColor = _secondaryAccent(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: bannerColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    color: bannerColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  noteText,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifestyleGuidanceCard(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    final isGain = forecast.shouldGainWeight;
    final isMaintain = forecast.shouldMaintainWeight;

    final String tip1Title =
        isGain
            ? 'planner.lifestyle_gain_tip1_title'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip1_title'.tr
                : 'planner.lifestyle_loss_tip1_title'.tr);
    final String tip1Desc =
        isGain
            ? 'planner.lifestyle_gain_tip1_desc'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip1_desc'.tr
                : 'planner.lifestyle_loss_tip1_desc'.tr);

    final String tip2Title =
        isGain
            ? 'planner.lifestyle_gain_tip2_title'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip2_title'.tr
                : 'planner.lifestyle_loss_tip2_title'.tr);
    final String tip2Desc =
        isGain
            ? 'planner.lifestyle_gain_tip2_desc'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip2_desc'.tr
                : 'planner.lifestyle_loss_tip2_desc'.tr);

    final String tip3Title =
        isGain
            ? 'planner.lifestyle_gain_tip3_title'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip3_title'.tr
                : 'planner.lifestyle_loss_tip3_title'.tr);
    final String tip3Desc =
        isGain
            ? 'planner.lifestyle_gain_tip3_desc'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip3_desc'.tr
                : 'planner.lifestyle_loss_tip3_desc'.tr);

    final String tip4Title =
        isGain
            ? 'planner.lifestyle_gain_tip4_title'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip4_title'.tr
                : 'planner.lifestyle_loss_tip4_title'.tr);
    final String tip4Desc =
        isGain
            ? 'planner.lifestyle_gain_tip4_desc'.tr
            : (isMaintain
                ? 'planner.lifestyle_maintain_tip4_desc'.tr
                : 'planner.lifestyle_loss_tip4_desc'.tr);

    final tips = [
      (Icons.water_drop_outlined, tip1Title, tip1Desc),
      (Icons.restaurant_rounded, tip2Title, tip2Desc),
      (Icons.timer_outlined, tip3Title, tip3Desc),
      (Icons.bedtime_outlined, tip4Title, tip4Desc),
    ];

    final accent =
        isGain
            ? AppColors.accentOrange
            : (isMaintain ? _secondaryAccent(context) : AppColors.primaryGreen);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.favorite_rounded, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.lifestyle_tips_title'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'planner.lifestyle_tips_subtitle'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(t.$1, size: 14, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.$2,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.$3,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightProgress(
    BuildContext context,
    WeightLossForecast forecast, {
    required Color accent,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'planner.current_weight'.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${forecast.currentWeightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'planner.projected_weight'.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${forecast.projectedEndWeightKg.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.65),
                      accent.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 14, height: 14),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.appElevatedSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
      ],
    );
  }

  Widget _timeframeSelector(BuildContext context) {
    return Row(
      children:
          WeightLossProjectionController.availableTimeframes.map((days) {
            final isSelected = controller.selectedTimeframeDays.value == days;
            final label = switch (days) {
              7 => 'planner.timeframe_one_week'.tr,
              30 => 'planner.timeframe_one_month'.tr,
              90 => 'planner.timeframe_three_months'.tr,
              _ => 'planner.timeframe_day_short'.trParams({'count': '$days'}),
            };
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  key: ValueKey('timeframe-chip-$days'),
                  onTap: () => controller.setTimeframeDays(days),
                  borderRadius: BorderRadius.circular(99),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 34,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryGreen
                              : context.appSurfaceLow,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primaryGreen
                                : context.appBorder.withValues(alpha: 0.35),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? context.appOnBrand
                                  : context.appMutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _goalRecommendationCard(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    final recommendation = controller.recommendedGoal;
    if (recommendation == null) return const SizedBox.shrink();
    final goalLabel = switch (recommendation) {
      MealPlannerHealthGoal.gainWeight => 'planner.goal_gain_weight'.tr,
      MealPlannerHealthGoal.maintainHealth => 'planner.goal_maintain_health'.tr,
      MealPlannerHealthGoal.loseWeight => 'planner.goal_lose_weight'.tr,
    };

    return Container(
      key: const ValueKey('weight-goal-recommendation-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSoftGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.recommended_goal'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      goalLabel,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      forecast.weightDirectionMessageKey.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('apply-recommended-weight-goal'),
            onPressed:
                controller.isLoading.value
                    ? null
                    : controller.applyRecommendedGoal,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text('planner.apply_recommended_goal'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _energyBalanceCard(BuildContext context, WeightLossForecast forecast) {
    final isGain = forecast.shouldGainWeight;
    final isMaintain = forecast.shouldMaintainWeight;
    final balanceValue = forecast.dailyDeficitCalories.abs().round();
    final hasDeficit = forecast.dailyDeficitCalories > 0;
    final hasSurplus = forecast.dailyDeficitCalories < 0;
    final titleKey =
        isMaintain || (!hasDeficit && !hasSurplus)
            ? 'planner.daily_balance'
            : hasSurplus
            ? 'planner.daily_surplus'
            : 'planner.daily_deficit';
    final descriptionKey =
        isMaintain || (!hasDeficit && !hasSurplus)
            ? 'planner.estimated_daily_balance'
            : hasSurplus
            ? 'planner.estimated_daily_surplus'
            : 'planner.estimated_daily_deficit';
    final accent = isGain ? AppColors.accentOrange : AppColors.primaryGreen;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 23,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descriptionKey.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isGain ? context.appWarningSurface : context.appSoftGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  '$balanceValue ${'planner.kcal_per_day'.tr}',
                  style: TextStyle(
                    color:
                        isGain
                            ? context.appOnWarningSurface
                            : _positiveText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comparison row: TDEE vs Planned
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  context,
                  title: 'planner.tdee_burn'.tr,
                  value: '${forecast.tdeeCalories.round()} kcal',
                  subtext:
                      '${'planner.bmr_baseline'.tr}: ${forecast.bmrCalories.round()}',
                  icon: Icons.bolt_rounded,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  context,
                  title: 'planner.planned_intake'.tr,
                  value: '${forecast.dailyPlannedCalories.round()} kcal',
                  subtext:
                      '${forecast.weeklyPaceKg.toStringAsFixed(2)} ${'planner.kg_per_week'.tr}',
                  icon: Icons.restaurant_rounded,
                  color: accent,
                ),
              ),
            ],
          ),

          if (forecast.calorieWarning) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.appWarningSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.appOnWarningSurface.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: context.appOnWarningSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'planner.safe_floor_alert'.tr,
                          style: TextStyle(
                            color: context.appOnWarningSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          forecast.calorieWarningMessage,
                          style: TextStyle(
                            color: context.appOnWarningSurface.withValues(
                              alpha: 0.85,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Retained only as an implementation reference while the compact BMI goal
  // summary remains in the forecast card.
  // ignore: unused_element
  Widget _profileContextCard(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    if (!forecast.hasBmiContext) {
      return Container(
        key: const ValueKey('weight-goal-profile-context-missing'),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              color: context.appColorScheme.primary,
              size: 30,
            ),
            const SizedBox(height: 9),
            Text(
              'planner.complete_health_profile'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'planner.complete_health_profile_help'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMutedText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Get.toNamed<void>(AppRoutes.bmiAnalysis),
              icon: const Icon(Icons.monitor_heart_outlined, size: 18),
              label: Text('planner.open_bmi_analysis'.tr),
            ),
          ],
        ),
      );
    }

    final bmi = forecast.bmi!;
    final projectedBmi = forecast.resolvedProjectedBmi;
    final healthyMin = forecast.resolvedHealthyWeightMinKg;
    final healthyMax = forecast.resolvedHealthyWeightMaxKg;
    final timeframeLabel =
        forecast.timeframeDays < 14
            ? 'planner.timeframe_days'.trParams({
              'count': '${forecast.timeframeDays}',
            })
            : 'planner.timeframe_weeks'.trParams({
              'count': '${forecast.timeframeDays ~/ 7}',
            });
    return Container(
      key: const ValueKey('weight-goal-bmi-context'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.appElevatedSurface, context.appSoftGreen],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.18),
        ),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'planner.your_health_context'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'planner.personalized_from_profile'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: AppColors.primaryGreen,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'planner.profile_connected'.tr,
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'planner.why_this_weight_goal'.tr,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        forecast.weightDirectionMessageKey.tr,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _bmiOutlookTile(
                  context,
                  label: 'planner.current_bmi'.tr,
                  value: bmi.toStringAsFixed(1),
                  supportingText: forecast.bmiStatusKey.tr,
                  emphasized: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 19,
                  color: context.appMutedText,
                ),
              ),
              Expanded(
                child: _bmiOutlookTile(
                  context,
                  label: 'planner.projected_bmi'.tr,
                  value:
                      projectedBmi == null
                          ? '—'
                          : projectedBmi.toStringAsFixed(1),
                  supportingText: 'planner.projected_bmi_timeframe'.trParams({
                    'timeframe': timeframeLabel,
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 3 : 2;
              const spacing = 9.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 10,
                children: [
                  _contextMetric(
                    context,
                    width: itemWidth,
                    icon: Icons.cake_outlined,
                    label: 'bmi.age'.tr,
                    value:
                        forecast.age == null
                            ? '—'
                            : '${forecast.age} ${'bmi.years'.tr}',
                  ),
                  _contextMetric(
                    context,
                    width: itemWidth,
                    icon: Icons.height_rounded,
                    label: 'bmi.height'.tr,
                    value:
                        forecast.heightCm == null
                            ? '—'
                            : '${_number(forecast.heightCm!)} cm',
                  ),
                  _contextMetric(
                    context,
                    width: itemWidth,
                    icon: Icons.monitor_weight_outlined,
                    label: 'bmi.weight'.tr,
                    value: '${_number(forecast.currentWeightKg)} kg',
                  ),
                  _contextMetric(
                    context,
                    width: itemWidth,
                    icon: Icons.monitor_heart_outlined,
                    label: 'planner.current_bmi'.tr,
                    value: bmi.toStringAsFixed(1),
                  ),
                  _contextMetric(
                    context,
                    width: itemWidth,
                    icon: Icons.directions_walk_rounded,
                    label: 'planner.activity'.tr,
                    value: forecast.activityLevelKey.tr,
                  ),
                  _contextMetric(
                    context,
                    width: itemWidth,
                    icon: Icons.track_changes_rounded,
                    label: 'planner.goal'.tr,
                    value:
                        forecast.shouldGainWeight
                            ? 'planner.goal_gain_weight'.tr
                            : forecast.shouldMaintainWeight
                            ? 'planner.goal_maintain_health'.tr
                            : 'planner.goal_lose_weight'.tr,
                  ),
                ],
              );
            },
          ),
          if (healthyMin != null && healthyMax != null) ...[
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: context.appSurfaceLow,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 19,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'planner.healthy_weight_reference'.tr,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_number(healthyMin)}–${_number(healthyMax)} kg',
                          style: TextStyle(
                            color: _positiveText(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'planner.healthy_weight_reference_help'.tr,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 9.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 92),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            forecast.isRapid
                                ? context.appWarningSurface
                                : context.appSoftGreen,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          forecast.paceStatusKey.tr,
                          maxLines: 1,
                          style: TextStyle(
                            color:
                                forecast.isRapid
                                    ? context.appOnWarningSurface
                                    : _positiveText(context),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (forecast.projectionBelowHealthyRange) ...[
            const SizedBox(height: 10),
            _contextNotice(
              context,
              icon: Icons.warning_amber_rounded,
              text:
                  forecast.shouldGainWeight
                      ? 'planner.current_bmi_below_range'.tr
                      : 'planner.projected_bmi_warning'.tr,
              warning: true,
            ),
          ],
          if (forecast.energyEstimateUsesDefaults) ...[
            const SizedBox(height: 10),
            _contextNotice(
              context,
              icon: Icons.calculate_outlined,
              text: 'planner.energy_estimate_defaults'.tr,
            ),
          ],
          const SizedBox(height: 10),
          _contextNotice(
            context,
            icon: Icons.info_outline_rounded,
            text: 'planner.bmi_supporting_context'.tr,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Get.toNamed<void>(AppRoutes.bmiAnalysis),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text('planner.open_bmi_analysis'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextMetric(
    BuildContext context, {
    required double width,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryGreen),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 10.5,
                    height: 1.2,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bmiOutlookTile(
    BuildContext context, {
    required String label,
    required String value,
    required String supportingText,
    bool emphasized = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              emphasized
                  ? AppColors.primaryGreen.withValues(alpha: 0.28)
                  : context.appBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasized ? _positiveText(context) : context.appText,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            supportingText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 9.5,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contextNotice(
    BuildContext context, {
    required IconData icon,
    required String text,
    bool warning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: warning ? context.appWarningSurface : context.appSurfaceLow,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: warning ? context.appOnWarningSurface : context.appMutedText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    warning
                        ? context.appOnWarningSurface
                        : context.appMutedText,
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _number(double value) {
    final text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  Widget _metricBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.appText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Kept for reuse in a dedicated recommendations page; intentionally hidden
  // from Weight Goal Analysis so this page stays focused on the forecast.
  // ignore: unused_element
  Widget _recommendationsSection(
    BuildContext context,
    WeightLossForecast forecast,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'planner.weight_loss_recommendations'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'planner.weight_loss_recommendations_help'.tr,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),

        // Segmented Tabs: Suitable Foods vs Healthy Beverages
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.appSurfaceLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _tabButton(
                  context,
                  key: const ValueKey('tab-suitable-foods'),
                  label: 'planner.tab_suitable_foods'.tr,
                  icon: Icons.restaurant_menu_rounded,
                  isSelected: controller.selectedTab.value == 0,
                  onTap: () => controller.setSelectedTab(0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _tabButton(
                  context,
                  key: const ValueKey('tab-healthy-beverages'),
                  label: 'planner.tab_healthy_beverages'.tr,
                  icon: Icons.local_drink_rounded,
                  isSelected: controller.selectedTab.value == 1,
                  onTap: () => controller.setSelectedTab(1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Recommendation cards list
        Builder(
          builder: (context) {
            final isFoods = controller.selectedTab.value == 0;
            final rawItems =
                isFoods
                    ? forecast.recommendedFoods
                    : forecast.recommendedBeverages;

            // Guarantee zero duplicates by name and source ID
            final seenNames = <String>{};
            final seenIds = <int>{};
            final items = <ForecastRecommendationItem>[];
            for (final item in rawItems) {
              final norm = item.name.trim().toLowerCase();
              if (seenNames.contains(norm)) {
                continue;
              }
              if (item.sourceId > 0 && seenIds.contains(item.sourceId)) {
                continue;
              }
              seenNames.add(norm);
              if (item.sourceId > 0) seenIds.add(item.sourceId);
              items.add(item);
              if (items.length == 2) break;
            }

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'planner.no_recommendations_found'.tr,
                    style: TextStyle(color: context.appMutedText, fontSize: 13),
                  ),
                ),
              );
            }

            return Column(
              children:
                  items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _recommendationCard(context, item),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _tabButton(
    BuildContext context, {
    Key? key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? context.appElevatedSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? context.appTileShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primaryGreen : context.appMutedText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? context.appText : context.appMutedText,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(
    BuildContext context,
    ForecastRecommendationItem item,
  ) {
    final imageUri = plannerImageUrl(item.imageUrl);
    final source = _extractSource(item.rationale);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Compact Image / Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      imageUri.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: imageUri,
                            fit: BoxFit.cover,
                            placeholder:
                                (_, _) => Container(
                                  color: context.appSurfaceLow,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            errorWidget:
                                (_, _, _) => _fallbackThumb(context, item),
                          )
                          : _fallbackThumb(context, item),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Rationale & Nutrients
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '${item.calories.round()} kcal',
                          style: TextStyle(
                            color: _positiveText(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.proteinGrams > 0) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${item.proteinGrams.toStringAsFixed(0)}g pro',
                            style: TextStyle(
                              color: _secondaryAccent(context),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // "Add to Plan" button
              ElevatedButton(
                key: ValueKey('add-recommendation-${item.sourceId}'),
                onPressed: () => _showAddToPlanSheet(context, item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 34),
                ),
                child: Text(
                  'planner.add_to_plan'.tr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final isBeverage = item.isBeverage;
              final analysisTitle =
                  isBeverage
                      ? 'planner.analysis_drink_loss'.tr
                      : 'planner.analysis_food_loss'.tr;
              final analysisIcon =
                  isBeverage
                      ? Icons.water_drop_outlined
                      : Icons.fitness_center_rounded;
              final analysisColor =
                  isBeverage
                      ? _secondaryAccent(context)
                      : _positiveText(context);

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: analysisColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: analysisColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(analysisIcon, size: 14, color: analysisColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            analysisTitle,
                            style: TextStyle(
                              color: analysisColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (source != null) _sourceBadge(context, source),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.rationale,
                      style: TextStyle(
                        color: context.appText.withValues(alpha: 0.85),
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String? _extractSource(String rationale) {
    if (rationale.contains('BBC Good Food')) return 'BBC Good Food';
    if (rationale.contains('EatingWell')) return 'EatingWell';
    if (rationale.contains('Healthline')) return 'Healthline';
    return null;
  }

  Widget _sourceBadge(BuildContext context, String source) {
    final accent = _secondaryAccent(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Text(
        source,
        style: TextStyle(
          color: accent,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _fallbackThumb(BuildContext context, ForecastRecommendationItem item) {
    return Container(
      color: (item.isBeverage
              ? _secondaryAccent(context)
              : AppColors.primaryGreen)
          .withValues(alpha: 0.12),
      child: Center(
        child: Icon(
          item.isBeverage
              ? Icons.local_drink_rounded
              : Icons.restaurant_rounded,
          size: 28,
          color:
              item.isBeverage
                  ? _secondaryAccent(context)
                  : AppColors.primaryGreen,
        ),
      ),
    );
  }

  /// Interactive Bottom Sheet to pick day, meal slot, and add the recommended item directly to plan
  Future<void> _showAddToPlanSheet(
    BuildContext context,
    ForecastRecommendationItem item,
  ) async {
    final plannerCtrl =
        Get.isRegistered<MealPlannerController>()
            ? Get.find<MealPlannerController>()
            : null;

    final planDays =
        plannerCtrl != null && plannerCtrl.planDays.isNotEmpty
            ? plannerCtrl.planDays
            : List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

    DateTime selectedDate = planDays.first;
    MealPlanSlot selectedSlot =
        item.isBeverage ? MealPlanSlot.snack : MealPlanSlot.lunch;
    double servings = 1.0;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.appSurfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.appBorder,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'planner.add_to_plan'.tr,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. Day selector
                    Text(
                      'planner.select_day'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            planDays.map((d) {
                              final isSelected =
                                  d.year == selectedDate.year &&
                                  d.month == selectedDate.month &&
                                  d.day == selectedDate.day;
                              final dayLabel = DateFormat(
                                'EEE, MMM d',
                              ).format(d);

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(dayLabel),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() => selectedDate = d);
                                    }
                                  },
                                  selectedColor: AppColors.primaryGreen,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : context.appText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Meal Slot selector
                    Text(
                      'planner.select_meal_slot'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children:
                          MealPlanSlot.values.map((slot) {
                            final isSelected = selectedSlot == slot;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: ChoiceChip(
                                  label: Text(
                                    slot.name.capitalizeFirst ?? slot.name,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : context.appText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() => selectedSlot = slot);
                                    }
                                  },
                                  selectedColor: AppColors.primaryGreen,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 3. Servings Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'planner.servings'.tr,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  servings > 0.5
                                      ? () =>
                                          setSheetState(() => servings -= 0.5)
                                      : null,
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                              color: AppColors.primaryGreen,
                            ),
                            Text(
                              servings.toStringAsFixed(1),
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  servings < 5.0
                                      ? () =>
                                          setSheetState(() => servings += 0.5)
                                      : null,
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              color: AppColors.primaryGreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 4. Confirm Button
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        await controller.addRecommendationToPlan(
                          context: context,
                          item: item,
                          targetDate: selectedDate,
                          slot: selectedSlot,
                          servings: servings,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'planner.confirm_add'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
