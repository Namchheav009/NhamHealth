import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../widgets/page_skeleton.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import 'ai_food_amount_sheet.dart';
import 'ai_food_detected_food_sheet.dart';
import 'ai_food_tips_sheet.dart';

class AiFoodScanContent extends StatelessWidget {
  const AiFoodScanContent({
    super.key,
    required this.controller,
    required this.onPickImage,
    this.onAnalyze,
  });

  final AiFoodController controller;
  final Future<void> Function(BuildContext context, {required bool camera})
  onPickImage;
  final Future<void> Function()? onAnalyze;

  static const Color green = Color(0xFF00A651);
  static const Color greenDark = Color(0xFF087A48);
  static const Color greenLightBg = Color(0xFFEAF7EE);
  static const Color greenPillBg = Color(0xFFDCFCE7);
  static const Color greenPillText = Color(0xFF15803D);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final horizontalPadding =
            AppSpacing.isTabletFor(context)
                ? AppSpacing.tabletPageHorizontal
                : 16.0;
        // Wrap in Obx so the list rebuilds whenever any observable changes
        // (isAnalyzing, selectedImage, errorMessage, analysisStage, etc.)
        return Obx(() {
          final hasImage = controller.selectedImage.value != null;
          final hasDetectedFood = controller.hasDetectedImage;
          final isAnalyzing = controller.isAnalyzing.value;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              40,
            ),
            children: [
              // 1. Top "Snap your food" Banner
              _buildSnapBanner(context),
              const SizedBox(height: 14),

              // 2. Food Image Card
              _buildImageCard(context),
              const SizedBox(height: 12),

              // 3. Action Buttons (Take Photo / Gallery)
              _buildActionButtons(context),

              // Error message if any
              if (controller.errorMessage.value != null)
                _buildErrorMessage(context),

              // If analyzing, show the live 4-stage analysis
              if (isAnalyzing) ...[
                const SizedBox(height: 14),
                _buildLiveAnalysisCard(context),
                const SizedBox(height: 12),
                const PageSkeleton.aiFoodAnalysis(),
              ] else if (hasImage && hasDetectedFood) ...[
                // 4. Amount / Portion Card
                const SizedBox(height: 14),
                _buildAmountCard(context),

                // 5. Detected Food Card
                const SizedBox(height: 14),
                _buildDetectedFoodCard(context),

                // 6. Tip Card
                const SizedBox(height: 14),
                _buildTipCard(context),

                // 7. Big "Analyze Nutrition ->" Button
                const SizedBox(height: 20),
                _buildAnalyzeButton(context),
              ],
            ],
          );
        });
      },
    );
  }

  // ---- 1. Snap Banner -------------------------------------------------------
  Widget _buildSnapBanner(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDark
                  ? [const Color(0xFF133222), const Color(0xFF0D2619)]
                  : [const Color(0xFFEAF8ED), const Color(0xFFDEF7E5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDark
                  ? const Color(0xFF1E4630)
                  : const Color(0xFFBBEFCC).withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // Salad bowl illustration bleeding into the right edge
          Positioned(
            right: -35,
            top: -6,
            bottom: -10,
            width: 165,
            child: Image.asset(
              'assets/images/homepage/AI-Food.png',
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
              errorBuilder:
                  (_, _, _) => Image.asset(
                    'assets/images/homepage/AI-Food.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ),
            ),
          ),
          // Left text and feature badges
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 100, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Snap your food',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : const Color(0xFF0F5132),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Get instant nutrition insights with AI',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color:
                        isDark
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFF4A7264),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildMiniBadge(Icons.bolt_rounded, 'Fast', isDark: isDark),
                    _buildMiniBadge(
                      Icons.verified_user_rounded,
                      'Accurate',
                      isDark: isDark,
                    ),
                    _buildMiniBadge(
                      Icons.bar_chart_rounded,
                      'Healthier choices',
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label, {required bool isDark}) {
    const darkGreen = Color(0xFF0F5132);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark
                  ? Colors.white24
                  : const Color(0xFFB7EAC5).withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.5,
            color: isDark ? const Color(0xFF86EFAC) : darkGreen,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF86EFAC) : darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 2. Food Image Card ---------------------------------------------------
  Widget _buildImageCard(BuildContext context) {
    final imageFile = controller.selectedImage.value;
    final foodName = controller.detectedFoodName;
    final cuisine = controller.detectedCuisine;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 235,
        width: double.infinity,
        color: Colors.black87,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageFile != null)
              Image.file(
                imageFile,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildEmptyViewfinder(context),
              )
            else
              _buildEmptyViewfinder(context),

            if (imageFile != null) ...[
              // Gradient shadow overlay - only show full bottom gradient when title is displayed
              if (controller.hasCompleteResult)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.35, 0.65, 1.0],
                    ),
                  ),
                )
              else
                // Subtle top gradient for close button readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

              // Top-right close button (X)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    controller.selectedImage.value = null;
                    controller.clearResult();
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.black87,
                      size: 18,
                    ),
                  ),
                ),
              ),

              // Bottom food name & cuisine - only show when analysis succeeds
              if (controller.hasCompleteResult)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        foodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cuisine,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyViewfinder(BuildContext context) {
    return Container(
      color:
          context.appIsDark ? context.appSurfaceLow : const Color(0xFFF3F4F6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: green,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'wellness.take_or_choose_food_photo'.trOrSelf,
              style: TextStyle(
                color: context.appText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'wellness.point_camera_at_meal'.trOrSelf,
              style: TextStyle(color: context.appMutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 3. Action Buttons ----------------------------------------------------
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onPickImage(context, camera: true),
            icon: const Icon(Icons.photo_camera_outlined, size: 20),
            label: const Text('Take Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: greenDark,
              side: const BorderSide(color: green, width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => onPickImage(context, camera: false),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('Choose from Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: greenDark,
              side: const BorderSide(color: green, width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  // ---- 4. Amount / Portion Card ---------------------------------------------
  Widget _buildAmountCard(BuildContext context) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF143021) : greenLightBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              controller.inputKind.value == AiFoodInputKind.drink
                  ? Icons.local_drink_rounded
                  : Icons.restaurant_rounded,
              color: green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'wellness.amount'.trOrSelf,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  controller.selectedAmountLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  controller.inputKind.value == AiFoodInputKind.drink
                      ? 'About ${controller.selectedAmount.round()} ml'
                      : 'About ${controller.estimatedGrams} g',
                  style: TextStyle(color: context.appMutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final updated = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withValues(alpha: .55),
                builder: (_) => AiFoodAmountSheet(controller: controller),
              );
              if (updated == true && controller.hasCompleteResult) {
                controller.updateAmountForCurrentResult();
              }
            },
            icon: const Icon(Icons.edit_outlined, size: 15, color: green),
            label: Text(
              'common.edit'.trOrSelf,
              style: const TextStyle(
                color: green,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: green, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // ---- 5. Detected Food Card ------------------------------------------------
  Widget _buildDetectedFoodCard(BuildContext context) {
    final isDark = context.appIsDark;
    final foodName = controller.detectedFoodName;
    final cuisine = controller.detectedCuisine;
    final tags = controller.foodTags;
    final isDrink = controller.inputKind.value == AiFoodInputKind.drink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.55),
            builder: (_) => AiFoodDetectedFoodSheet(controller: controller),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appBorder),
            boxShadow: context.appCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF143021) : greenLightBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isDrink
                          ? Icons.local_drink_rounded
                          : Icons.lunch_dining_rounded,
                      color: green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDrink
                              ? 'wellness.detected_drink'.trOrSelf
                              : 'wellness.detected_food'.trOrSelf,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          foodName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.appText,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          cuisine,
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.appMutedText,
                    size: 22,
                  ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children:
                        tags.map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF193D2A)
                                        : greenPillBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? const Color(0xFF2E6346)
                                          : const Color(0xFFBBF7D0),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? const Color(0xFF86EFAC)
                                          : greenPillText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---- 6. Tip Card ----------------------------------------------------------
  Widget _buildTipCard(BuildContext context) {
    final isDark = context.appIsDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: 0.55),
            builder: (_) => const AiFoodTipsSheet(),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2211) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF634A1B) : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF423218)
                          : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tip',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'For more accurate results, use a clear photo with good lighting.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? const Color(0xFFFDE68A).withValues(alpha: 0.8)
                                : const Color(0xFFB45309),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 7. Big Analyze Button ------------------------------------------------
  Widget _buildAnalyzeButton(BuildContext context) {
    return ElevatedButton(
      onPressed:
          controller.isAnalyzing.value
              ? null
              : (onAnalyze ?? controller.analyzeFood),
      style: ElevatedButton.styleFrom(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          const SizedBox(width: 10),
          const Text(
            'Analyze Nutrition',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 20,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // ---- Live analysis / Error --------------------------------

  Widget _buildLiveAnalysisCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      // Obx needed so stage label and progress bar update as analysisStage ticks
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.analysisStageLabel.trOrSelf,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${controller.analysisProgressPercent}%',
                  key: const ValueKey<String>('ai-analysis-progress-percent'),
                  style: const TextStyle(
                    color: green,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const ValueKey<String>('ai-analysis-progress-line'),
                value: controller.analysisProgress,
                minHeight: 7,
                backgroundColor: context.appSubtleSurface,
                color: green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'wellness.results_update_when_the_full_food_and_drink_check_is_complete'
                  .tr,
              style: TextStyle(color: context.appMutedText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade700.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.errorMessage.value!.trParams(
                  controller.errorMessageParams,
                ),
                style: TextStyle(color: Colors.red.shade700, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
