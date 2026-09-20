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
  Widget build(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    final horizontalPadding = AppSpacing.pageHorizontalFor(context);
    final contentMaxWidth =
        isTablet
            ? AppSpacing.maxWideContentWidth
            : AppSpacing.maxContentWidth;
    final paddedMaxWidth = contentMaxWidth + (horizontalPadding * 2);

    return PopScope(
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
                constraints: BoxConstraints(maxWidth: paddedMaxWidth),
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
  }

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
}
