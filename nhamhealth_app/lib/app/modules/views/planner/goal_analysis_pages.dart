import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
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
        _controller.showAnalysisGoal();
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
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: _accent,
                        onRefresh:
                            () => _controller.showAnalysisGoal(
                              forceRefresh: true,
                            ),
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            pagePadding,
                            12,
                            pagePadding,
                            104,
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
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _fixedBottomAction(context),
          ),
        ],
      ),
    );
  }

  Widget _fixedBottomAction(BuildContext context) {
    final pagePadding = AppSpacing.pageHorizontalFor(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(pagePadding, 10, pagePadding, 12),
        decoration: BoxDecoration(
          color: context.appElevatedSurface,
          border: Border(
            top: BorderSide(color: context.appBorder.withValues(alpha: 0.8)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Obx(
              () => SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  key: const ValueKey('continue-with-weight-goal'),
                  onPressed:
                      _controller.forecast.value == null
                          ? null
                          : () => Get.back(),
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 19),
                  label: Text(
                    'planner.continue_to_meal_planner'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                                    .hasAnalyzedWeightLoss
                                    .value
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
