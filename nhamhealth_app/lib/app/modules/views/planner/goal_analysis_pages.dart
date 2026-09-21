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
  State<WeightLossAnalysisPage> createState() =>
      _WeightLossAnalysisPageState();
}

class _WeightLossAnalysisPageState extends State<WeightLossAnalysisPage> {
  static const _accent = Color(0xFF2563EB);

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
      key: const ValueKey('weight-loss-analysis-page'),
      backgroundColor: context.appBackground,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pagePadding, 8, pagePadding, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: AppBackHeader(
                    title: 'planner.view_weight_loss_analysis'.tr,
                    onBack: () => Get.back(),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: _accent,
                  onRefresh:
                      () => _controller.showAnalysisGoal(forceRefresh: true),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      pagePadding,
                      12,
                      pagePadding,
                      32,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSpacing.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _analysisHero(context),
                              const SizedBox(height: 14),
                              _goalFocusRow(context),
                              const SizedBox(height: 22),
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
    );
  }

  Widget _analysisHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
            child: const Icon(
              Icons.trending_down_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      if (Get.isRegistered<MealPlannerController>())
                        Obx(
                          () => Text(
                            Get.find<MealPlannerController>()
                                    .hasAnalyzedWeightLoss.value
                                ? 'planner.analysis_ready'.tr
                                : 'planner.analysis_preview'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Text(
                          'planner.analysis_preview'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'planner.view_weight_loss_analysis'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'planner.analysis_loss_page_desc'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalFocusRow(BuildContext context) {
    const items = [
      (Icons.local_fire_department_rounded, 'planner.focus_deficit'),
      (Icons.fitness_center_rounded, 'planner.focus_protein'),
      (Icons.monitor_heart_rounded, 'planner.focus_safe_pace'),
    ];

    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: context.appElevatedSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent.withValues(alpha: 0.18)),
              ),
              child: Column(
                children: [
                  Icon(items[index].$1, color: _accent, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    items[index].$2.tr,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 10.5,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
