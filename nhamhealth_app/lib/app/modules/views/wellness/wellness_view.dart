import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness/wellness_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/app_back_header.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/ai_meal_card.dart';
import 'widgets/wellness_daily_summary_card.dart';

class WellnessView extends GetView<WellnessController> {
  const WellnessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              context.appSoftPink,
              context.appBackground,
              context.appSoftGreen,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxWideContentWidth,
                  ),
                  child: Column(
                    children: [
                      // Header
                      _header(context),

                      // Scrollable content
                      Expanded(
                        child: Obx(
                          () => SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: AppSpacing.pagePaddingFor(context),
                            child: LoadingContentTransition(
                              isLoading: controller.isLoading.value,
                              loading: const PageSkeleton.wellness(),
                              content: const _WellnessDashboardContent(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final horizontal = AppSpacing.pageHorizontalFor(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 10),
      child: Row(
        children: [
          AppBackButton(
            buttonKey: const ValueKey<String>('wellness-back-button'),
            onPressed: Get.back,
          ),

          // Page title
          Expanded(
            child: Center(
              child: Text(
                'Daily Wellness'.tr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
            ),
          ),

          // Calendar / Today button
          Obx(
            () => Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  controller.selectDate(context);
                },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.appSoftGreen,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 17,
                        color: Color(0xFF00A651),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        controller.selectedDateText.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.appText,
                        ),
                      ),

                      const SizedBox(width: 3),

                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF00A651),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessDashboardContent extends StatelessWidget {
  const _WellnessDashboardContent();

  static const double _wideBreakpoint = 820;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _wideBreakpoint) {
          return const Column(
            children: [
              WellnessDailySummaryCard(),
              SizedBox(height: 14),
              AiMealCard(),
              SizedBox(height: 14),
              AiInsightCard(),
            ],
          );
        }

        return const Row(
          key: ValueKey<String>('wellness-tablet-layout'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: WellnessDailySummaryCard()),
            SizedBox(width: 20),
            Expanded(
              flex: 6,
              child: Column(
                children: [AiMealCard(), SizedBox(height: 14), AiInsightCard()],
              ),
            ),
          ],
        );
      },
    );
  }
}
