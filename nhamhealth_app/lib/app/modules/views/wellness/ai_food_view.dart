import 'dart:ui';

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
      child: AppBackHeader(
        title: 'wellness.ai_food_check',
        backButtonKey: const ValueKey<String>('ai-food-back-button'),
        onBack: () {
          if (controller.hasCompleteResult) {
            controller.clearResult();
          } else {
            Get.back();
          }
        },
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

    if (!detected && context.mounted) {
      await _showNoFoodDetectedDialog(context);
      return;
    }

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

  Future<void> _showNoFoodDetectedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.20),
      builder:
          (dialogContext) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 330,
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(28, 38, 28, 30),
                  decoration: BoxDecoration(
                    color: context.appElevatedSurface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: context.appElevatedSurface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.errorCoral,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'wellness.no_food_detected_title'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        controller.errorMessage.value?.trim().isNotEmpty ==
                                true
                            ? controller.errorMessage.value!.tr
                            : 'wellness.no_food_detected_message'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 14.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 224,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.clearImage();
                            Navigator.of(dialogContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: green.withValues(alpha: 0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'common.ok'.tr,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
