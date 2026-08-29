import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness/wellness_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
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
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      // Header
                      _header(context),

                      // Scrollable content
                      Expanded(
                        child: Obx(
                          () => SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: AppSpacing.pagePadding,
                            child: LoadingContentTransition(
                              isLoading: controller.isLoading.value,
                              loading: const PageSkeleton.wellness(),
                              content: const Column(
                                children: [
                                  WellnessDailySummaryCard(),

                                  SizedBox(height: 14),

                                  AiMealCard(),

                                  SizedBox(height: 14),

                                  AiInsightCard(),
                                ],
                              ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF00A651),
              size: 27,
            ),
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
