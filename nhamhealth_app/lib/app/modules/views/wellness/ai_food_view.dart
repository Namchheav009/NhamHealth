import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/wellness/ai_food_controller.dart';
import 'widgets/ai_food_amount_sheet.dart';
import 'widgets/ai_food_nutrition_result_content.dart';
import 'widgets/ai_food_scan_content.dart';

class AiFoodView extends GetView<AiFoodController> {
  const AiFoodView({super.key});

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !controller.hasCompleteResult,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      if (controller.hasCompleteResult) {
        controller.clearResult();
      }
    },
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        lightDecoration: BoxDecoration(color: context.appBackground),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxWideContentWidth,
              ),
              child: Column(
                children: [
                  _header(context),
                  Expanded(
                    child: Obx(() {
                      if (controller.hasCompleteResult &&
                          controller.nutrition.value != null) {
                        return AiFoodNutritionResultContent(
                          controller: controller,
                        );
                      }
                      return LoadingContentTransition(
                        isLoading: controller.isModelLoading.value,
                        loading: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.pageHorizontalFor(context),
                            8,
                            AppSpacing.pageHorizontalFor(context),
                            40,
                          ),
                          child: const PageSkeleton.aiFood(),
                        ),
                        content: AiFoodScanContent(
                          controller: controller,
                          onPickImage:
                              (ctx, {required camera}) =>
                                  _pickImage(ctx, camera: camera),
                          onAnalyze: controller.analyzeFood,
                        ),
                      );
                    }),
                  ),
                  Obx(() {
                    if (controller.hasCompleteResult &&
                        controller.nutrition.value != null) {
                      return AiFoodNutritionResultBottomBar(
                        controller: controller,
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) {
    final horizontal = AppSpacing.pageHorizontalFor(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 10),
      child: Row(
        children: [
          AppBackButton(
            buttonKey: const ValueKey<String>('ai-food-back-button'),
            onPressed: () {
              if (controller.hasCompleteResult) {
                controller.clearResult();
              } else {
                Get.back();
              }
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'wellness.ai_food_check'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, {required bool camera}) async {
    final previousPath = controller.selectedImage.value?.path;
    if (camera) {
      await controller.takePhoto();
    } else {
      await controller.pickImageFromGallery();
    }
    final selectedPath = controller.selectedImage.value?.path;
    if (!context.mounted ||
        selectedPath == null ||
        selectedPath == previousPath) {
      return;
    }

    // Run food detection
    final detected = await controller.detectFood();

    // If food was detected, automatically show the amount / portion sheet
    // so the user can adjust portion size before analysing
    if (detected && context.mounted && controller.hasDetectedImage) {
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: .55),
        builder: (_) => AiFoodAmountSheet(controller: controller),
      );
    }
  }

  void _showHelpInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ctx.appElevatedSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: green, size: 22),
                const SizedBox(width: 8),
                Text(
                  'wellness.important_information'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: ctx.appText,
                  ),
                ),
              ],
            ),
            content: Text(
              'wellness.ai_nutrition_results_are_estimates_for_general_wellness_only_they_are_not_medical_advice_a_diagnosis_or_an_official_nutrition_label'
                  .tr,
              style: TextStyle(
                fontSize: 13,
                color: ctx.appMutedText,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: green, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
    );
  }
}
