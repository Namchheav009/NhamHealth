import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/wellness/ai_food_controller.dart';
import '../../models/wellness/food_nutrition_model.dart';
import '../../models/wellness/food_recommendation_model.dart';
import '../../repositories/wellness/food_nutrition_repository.dart';
import 'widgets/ai_food_amount_sheet.dart';

/// -----------------------------------------------------------------------
/// AiFoodView — restyled
/// Same controller contract as before (AiFoodController via GetView), only
/// the presentation layer changed:
///   - Consistent color/spacing system
///   - Animated appearance for cards (AnimatedSwitcher / AnimatedSize)
///   - Icon-coded nutrition metrics
///   - Real confidence meter instead of plain text
///   - Clear empty and selected-image states
/// -----------------------------------------------------------------------
class AiFoodView extends GetView<AiFoodController> {
  const AiFoodView({super.key});

  // ---- Design tokens ----------------------------------------------------
  static const green = Color(0xFF00A651);
  static const greenDark = Color(0xFF087A48);
  static const warn = Color(0xFFFF7A45);
  static const double pageHorizontalPadding = 20;
  static const double sectionSpacing = 16;
  static const double imageAspectRatio = 16 / 9;
  static const double imageMinHeight = 190;
  static const double imageMaxHeight = 230;

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 820;
                      return Obx(
                        () => ListView(
                          padding: EdgeInsets.fromLTRB(
                            wide
                                ? AppSpacing.tabletPageHorizontal
                                : pageHorizontalPadding,
                            8,
                            wide
                                ? AppSpacing.tabletPageHorizontal
                                : pageHorizontalPadding,
                            40,
                          ),
                          children: [
                            if (wide)
                              Row(
                                key: const ValueKey<String>(
                                  'ai-food-tablet-layout',
                                ),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _capturePanel(context)),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _resultsPanel(context, wide: true),
                                  ),
                                ],
                              )
                            else ...[
                              _capturePanel(context),
                              _resultsPanel(context),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
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
            onPressed: Get.back,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'wellness.ai_food_check'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: context.appText,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppBackButton.layoutSize),
        ],
      ),
    );
  }

  Widget _capturePanel(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _intro(),
      const SizedBox(height: sectionSpacing),
      if (controller.isModelLoading.value) ...[
        const _ModelLoadingBar(),
        const SizedBox(height: 12),
      ],
      _imageCard(context),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _button(
              context: context,
              icon: Icons.photo_camera_outlined,
              text: 'Take Photo',
              action: () => _pickImage(context, camera: true),
              style: _ButtonStyle.outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _button(
              context: context,
              icon: Icons.photo_library_outlined,
              text: 'Gallery',
              action: () => _pickImage(context, camera: false),
              style: _ButtonStyle.outlined,
            ),
          ),
        ],
      ),
      if (controller.selectedImage.value != null &&
          controller.hasDetectedImage) ...[
        const SizedBox(height: 14),
        _amountInputCard(context),
      ],
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child:
            controller.selectedImage.value != null &&
                    !controller.hasDetectedImage
                ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _button(
                    context: context,
                    icon: Icons.auto_awesome,
                    text: 'Analyze Food or Drink',
                    action:
                        controller.isAnalyzing.value
                            ? null
                            : !controller.canAnalyze
                            ? null
                            : () => _detectAndEditAmount(context),
                    style: _ButtonStyle.primary,
                  ),
                )
                : const SizedBox(width: double.infinity),
      ),
    ],
  );

  Widget _amountInputCard(BuildContext context) {
    final isDrink = controller.inputKind.value == AiFoodInputKind.drink;
    return Container(
      key: const ValueKey<String>('ai-food-amount-input'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDrink ? Icons.local_drink_rounded : Icons.restaurant_rounded,
              color: green,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'wellness.amount'.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.selectedAmountLabel,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showAmountSheet(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text('wellness.edit_amount'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: greenDark,
              side: const BorderSide(color: green),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
    if (context.mounted &&
        selectedPath != null &&
        selectedPath != previousPath) {
      await _detectAndEditAmount(context);
    }
  }

  Future<void> _detectAndEditAmount(BuildContext context) async {
    final detected = await controller.detectFood();
    if (context.mounted && detected) {
      await _showAmountSheet(context);
    }
  }

  Future<void> _showAmountSheet(BuildContext context) async {
    if (controller.selectedImage.value == null ||
        !controller.hasDetectedImage) {
      return;
    }
    final shouldAnalyze = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .55),
      builder: (sheetContext) => AiFoodAmountSheet(controller: controller),
    );
    if (shouldAnalyze == true && context.mounted) {
      if (controller.hasCompleteResult) {
        controller.updateAmountForCurrentResult();
      } else {
        await controller.analyzeFood();
      }
    }
  }

  Widget _resultsPanel(BuildContext context, {bool wide = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (controller.isAnalyzing.value)
        Padding(
          padding: EdgeInsets.only(top: wide ? 0 : 14),
          child: Column(
            children: [
              _liveAnalysisCard(context),
              const SizedBox(height: 12),
              const PageSkeleton.aiFoodAnalysis(),
            ],
          ),
        )
      else if (wide && !controller.hasCompleteResult)
        const _TabletAnalysisPlaceholder(),
      if (controller.errorMessage.value != null)
        _message(
          controller.errorMessage.value!,
          Colors.red.shade700,
          Icons.error_outline_rounded,
          params: controller.errorMessageParams,
        ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child:
            controller.hasCompleteResult
                ? Padding(
                  key: const ValueKey('nutrition'),
                  padding: EdgeInsets.only(top: wide ? 0 : 14),
                  child: Column(
                    children: [
                      _confidenceLine(context),
                      const SizedBox(height: 14),
                      _analysisCard(context, controller.nutrition.value!),
                      if (controller.nutrition.value!.needsUserConfirmation &&
                          !controller.isUserConfirmed.value) ...[
                        const SizedBox(height: 14),
                        _reviewCard(context, controller.nutrition.value!),
                      ],
                      const SizedBox(height: 14),
                      _nutritionCard(context, controller.nutrition.value!),
                      if (controller.nutrition.value!.hasNutritionEstimate) ...[
                        const SizedBox(height: 14),
                        _sugarAnalysisCard(
                          context,
                          controller.nutrition.value!,
                        ),
                      ],
                      if (controller.nutrition.value!.hasDrink) ...[
                        const SizedBox(height: 14),
                        _hydrationCard(context, controller.nutrition.value!),
                      ],
                    ],
                  ),
                )
                : const SizedBox.shrink(),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child:
            controller.recommendation.value != null
                ? Padding(
                  key: const ValueKey('recommendation'),
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      _recommendationCard(
                        context,
                        controller.recommendation.value!,
                      ),
                      const SizedBox(height: 14),
                      _button(
                        context: context,
                        icon:
                            controller.wasAdded.value
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                        text:
                            controller.wasAdded.value
                                ? controller.nutrition.value!.isPlainWaterOnly
                                    ? 'Water Added Today'
                                    : 'Added to Today'
                                : controller.isSaving.value
                                ? 'Adding...'
                                : controller.nutrition.value!.isPlainWaterOnly
                                ? "Add to Today's Water"
                                : "Add to Today's Food",
                        action:
                            controller.isSaving.value ||
                                    controller.wasAdded.value ||
                                    !controller.canAddFood
                                ? null
                                : controller.addFoodToToday,
                        style:
                            controller.wasAdded.value
                                ? _ButtonStyle.success
                                : _ButtonStyle.primary,
                        loading: controller.isSaving.value,
                      ),
                    ],
                  ),
                )
                : const SizedBox.shrink(),
      ),
      const SizedBox(height: 14),
      _legalNotice(context, controller.nutrition.value),
    ],
  );

  // ---- Hero / intro ---------------------------------------------------

  Widget _intro() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [greenDark, green],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2600A651),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0x2FFFFFFF),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(13),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'wellness.know_what_you_eat_or_drink'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'wellness.snap_a_clear_photo_for_instant_nutrition_insights'.tr,
                style: const TextStyle(color: Color(0xDFFFFFFF), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ---- Image / camera card ---------------------------------------------

  Widget _imageCard(BuildContext context) => GestureDetector(
    onTap: controller.pickImageFromGallery,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxWidth / imageAspectRatio).clamp(
          imageMinHeight,
          imageMaxHeight,
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: previewHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.appSurfaceLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  controller.selectedImage.value != null
                      ? green.withValues(alpha: .35)
                      : context.appBorder,
              width: controller.selectedImage.value != null ? 1.5 : 1,
            ),
            boxShadow: context.appTileShadow,
          ),
          child:
              controller.selectedImage.value == null
                  ? _emptyImageState(context)
                  : _selectedImagePreview(),
        );
      },
    ),
  );

  Widget _emptyImageState(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        decoration: BoxDecoration(
          color: context.appSoftGreen,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(18),
        child: const Icon(Icons.add_a_photo_outlined, size: 32, color: green),
      ),
      const SizedBox(height: 12),
      Text(
        'common.add_a_meal_photo'.tr,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      const SizedBox(height: 4),
      Text(
        'wellness.use_camera_or_choose_from_gallery'.tr,
        style: TextStyle(color: context.appMutedText, fontSize: 13),
      ),
    ],
  );

  Widget _selectedImagePreview() => Stack(
    fit: StackFit.expand,
    children: [
      Image.file(
        controller.selectedImage.value!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      ),
      // gradient scrim so the close button stays legible on bright photos
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: .35), Colors.transparent],
            ),
          ),
        ),
      ),
      Positioned(
        top: 10,
        right: 10,
        child: Material(
          color: Colors.black.withValues(alpha: .45),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: controller.clearImage,
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
      ),
    ],
  );

  // ---- Buttons -----------------------------------------------------------

  Widget _button({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback? action,
    _ButtonStyle style = _ButtonStyle.primary,
    bool loading = false,
  }) {
    final isDark = context.appIsDark;
    final child =
        loading
            ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: style == _ButtonStyle.primary ? Colors.white : green,
                  ),
                ),
                const SizedBox(width: 10),
                Text(text.trOrSelf),
              ],
            )
            : null;

    switch (style) {
      case _ButtonStyle.primary:
        return SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: action,
            icon: loading ? const SizedBox.shrink() : Icon(icon),
            label: child ?? Text(text.trOrSelf),
            style: FilledButton.styleFrom(
              backgroundColor: green,
              disabledBackgroundColor: green.withValues(alpha: .5),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      case _ButtonStyle.success:
        return SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: action,
            icon: Icon(icon),
            label: Text(text.trOrSelf),
            style: FilledButton.styleFrom(
              backgroundColor:
                  isDark
                      ? context.appColorScheme.primaryContainer
                      : const Color(0xFFE8F7EA),
              foregroundColor:
                  isDark
                      ? context.appColorScheme.onPrimaryContainer
                      : greenDark,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      case _ButtonStyle.outlined:
        final outlineColor = isDark ? context.appColorScheme.primary : green;
        return SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: action,
            icon: Icon(icon, size: 20),
            label: Text(text.trOrSelf),
            style: OutlinedButton.styleFrom(
              foregroundColor: outlineColor,
              side: BorderSide(color: outlineColor),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }

  // ---- Nutrition ---------------------------------------------------------

  Widget _liveAnalysisCard(BuildContext context) => _card(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.analysisStageLabel.trOrSelf,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
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
  );

  Widget _analysisCard(BuildContext context, FoodNutritionModel food) => _card(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: green.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                food.mealType == 'drink'
                    ? Icons.local_drink_outlined
                    : food.mealType == 'mixed'
                    ? Icons.brunch_dining_outlined
                    : Icons.restaurant_outlined,
                color: greenDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.mealName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      food.mealType == 'mixed'
                          ? 'wellness.food_and_drink'.tr
                          : food.mealType == 'drink'
                          ? 'Drink'
                          : 'wellness.food'.tr,
                      if (food.cuisine != 'Unknown') food.cuisine,
                    ].join(' • '),
                    style: TextStyle(color: context.appMutedText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (food.components.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...food.components.map(
            (component) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    component.componentType == 'drink'
                        ? Icons.water_drop_outlined
                        : Icons.check_circle_outline,
                    color: green,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.components.length == 1
                              ? food.mealName
                              : component.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_amount(component.estimatedAmount)} ${component.unit}'
                          '${component.preparationMethod == 'unknown' ? '' : ' • ${component.preparationMethod}'}'
                          ' • ${(component.confidence * 100).round()}%',
                          style: TextStyle(
                            color: context.appMutedText,
                            fontSize: 12,
                          ),
                        ),
                        if (component.visibleEvidence.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            component.visibleEvidence,
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _hydrationCard(BuildContext context, FoodNutritionModel food) {
    final isDark = context.appIsDark;
    final total = food.drinkVolumeMl.round();
    final water = food.plainWaterVolumeMl.round();
    final glasses = water / 250;
    return _card(
      context,
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E2738) : const Color(0xFFE7F7FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_rounded,
              color: isDark ? const Color(0xFF5EC5FF) : const Color(0xFF1689C9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  water > 0
                      ? 'wellness.plain_water_detected'.tr
                      : 'wellness.drink_volume'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  water > 0
                      ? 'wellness.water_glass_summary'.trParams({
                        'water': '$water',
                        'glasses': glasses.toStringAsFixed(
                          glasses % 1 == 0 ? 0 : 1,
                        ),
                      })
                      : total > 0
                      ? 'wellness.about_total_ml'.trParams({'total': '$total'})
                      : 'Volume could not be estimated reliably',
                  style: TextStyle(color: context.appMutedText, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _amount(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

  Widget _confidenceLine(BuildContext context) {
    final isDark = context.appIsDark;
    final confidence = (controller.prediction.value?.confidence ?? 0).clamp(
      0.0,
      1.0,
    );
    final percentage = (confidence * 100).round();
    final low = confidence < AiFoodController.lowConfidenceThreshold;
    final color =
        low ? warn : (isDark ? context.appColorScheme.primary : green);

    return _card(
      context,
      Row(
        children: [
          Text(
            'wellness.confidence'.tr,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 7,
                backgroundColor:
                    isDark
                        ? context.appColorScheme.surfaceContainerHighest
                        : const Color(0xFFEFF3EE),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text(
              '$percentage%',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(BuildContext context, FoodNutritionModel food) => _card(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: warn, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'wellness.review_result'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'wellness.uncertain_result_help'.tr,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        if (food.candidates.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: food.candidates
                .map(
                  (candidate) => ActionChip(
                    onPressed:
                        controller.isFeedbackSaving.value
                            ? null
                            : () => _showCorrectionDialog(
                              context,
                              food,
                              initialName: candidate.name,
                            ),
                    backgroundColor: warn.withValues(
                      alpha: context.appIsDark ? .18 : .08,
                    ),
                    side: BorderSide(
                      color: warn.withValues(
                        alpha: context.appIsDark ? .42 : .22,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '${candidate.name} ${(candidate.confidence * 100).round()}%',
                      style: TextStyle(
                        color:
                            context.appIsDark
                                ? const Color(0xFFFFB388)
                                : const Color(0xFFA94A20),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    controller.isFeedbackSaving.value
                        ? null
                        : () => _showCorrectionDialog(context, food),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text('wellness.correct'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      context.appIsDark
                          ? context.appColorScheme.primary
                          : greenDark,
                  side: BorderSide(
                    color:
                        context.appIsDark
                            ? context.appColorScheme.primary
                            : green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    controller.isFeedbackSaving.value
                        ? null
                        : controller.confirmFood,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('common.confirm'.tr),
                style: FilledButton.styleFrom(backgroundColor: green),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Future<void> _showCorrectionDialog(
    BuildContext context,
    FoodNutritionModel food, {
    String? initialName,
  }) async {
    final nameController = TextEditingController(
      text: initialName?.trim().isNotEmpty == true ? initialName : food.name,
    );
    final amountController = TextEditingController(
      text: _amount(food.servingSize),
    );
    final unitController = TextEditingController(text: food.servingUnit);
    String? validationError;
    var saving = false;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'wellness.correct_ai_result'.tr,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder:
              (context, updateDialog) => PopScope(
                canPop: !saving,
                child: Material(
                  type: MaterialType.transparency,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: const SizedBox.expand(),
                      ),
                      SafeArea(
                        minimum: const EdgeInsets.all(22),
                        child: Center(
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 424),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                  26,
                                  28,
                                  26,
                                  26,
                                ),
                                decoration: BoxDecoration(
                                  color: context.appElevatedSurface,
                                  borderRadius: BorderRadius.circular(26),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 32,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: context.appElevatedSurface,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.16,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.edit_note_rounded,
                                          color: green,
                                          size: 34,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'wellness.correct_ai_result'.tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: context.appText,
                                        fontSize: 20,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'wellness.correction_description'.tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: context.appMutedText,
                                        fontSize: 14,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    TextField(
                                      controller: nameController,
                                      enabled: !saving,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      maxLength: 150,
                                      decoration: InputDecoration(
                                        labelText: 'wellness.food_name'.tr,
                                        prefixIcon: const Icon(
                                          Icons.restaurant_rounded,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide(
                                            color: context.appBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: const BorderSide(
                                            color: green,
                                            width: 1.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'wellness.serving_details'.tr,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: amountController,
                                            enabled: !saving,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: InputDecoration(
                                              labelText: 'wellness.amount'.tr,
                                              prefixIcon: const Icon(
                                                Icons.scale_outlined,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color: context.appBorder,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: green,
                                                  width: 1.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: unitController,
                                            enabled: !saving,
                                            maxLength: 40,
                                            decoration: InputDecoration(
                                              labelText: 'wellness.unit'.tr,
                                              prefixIcon: const Icon(
                                                Icons.straighten_rounded,
                                              ),
                                              counterText: '',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color: context.appBorder,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: const BorderSide(
                                                  color: green,
                                                  width: 1.8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'wellness.unit_examples'.tr,
                                      style: TextStyle(
                                        color: context.appMutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (validationError != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.appDangerSurface,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          validationError!,
                                          style: TextStyle(
                                            color: context.appOnDangerSurface,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed:
                                                saving
                                                    ? null
                                                    : () =>
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(),
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 50),
                                              side: BorderSide(
                                                color: context.appBorder,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(21),
                                              ),
                                            ),
                                            child: Text(
                                              'common.cancel'.tr,
                                              style: TextStyle(
                                                color: context.appText,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: FilledButton(
                                            onPressed:
                                                saving
                                                    ? null
                                                    : () async {
                                                      final amount =
                                                          double.tryParse(
                                                            amountController
                                                                .text
                                                                .trim(),
                                                          );
                                                      if (nameController.text
                                                              .trim()
                                                              .isEmpty ||
                                                          nameController.text
                                                                  .trim()
                                                                  .length >
                                                              150 ||
                                                          unitController.text
                                                              .trim()
                                                              .isEmpty ||
                                                          unitController.text
                                                                  .trim()
                                                                  .length >
                                                              40 ||
                                                          amount == null ||
                                                          amount <= 0 ||
                                                          amount > 10000) {
                                                        updateDialog(
                                                          () =>
                                                              validationError =
                                                                  'Enter a valid food, amount, and unit.',
                                                        );
                                                        return;
                                                      }
                                                      updateDialog(() {
                                                        saving = true;
                                                        validationError = null;
                                                      });
                                                      try {
                                                        await controller
                                                            .correctFood(
                                                              foodName:
                                                                  nameController
                                                                      .text,
                                                              servingSize:
                                                                  amount,
                                                              servingUnit:
                                                                  unitController
                                                                      .text,
                                                            );
                                                        if (!dialogContext
                                                            .mounted) {
                                                          return;
                                                        }
                                                        if (controller
                                                            .isUserConfirmed
                                                            .value) {
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop();
                                                          return;
                                                        }
                                                      } on FoodNutritionException catch (
                                                        error
                                                      ) {
                                                        if (!dialogContext
                                                            .mounted) {
                                                          return;
                                                        }
                                                        updateDialog(() {
                                                          saving = false;
                                                          validationError =
                                                              error.message;
                                                        });
                                                        AppAlert.actionError(
                                                          title:
                                                              'wellness.could_not_save_correction'
                                                                  .tr,
                                                          message:
                                                              error.message,
                                                        );
                                                        return;
                                                      } catch (_) {
                                                        if (!dialogContext
                                                            .mounted) {
                                                          return;
                                                        }
                                                        updateDialog(() {
                                                          saving = false;
                                                          validationError =
                                                              'wellness.could_not_save_correction'
                                                                  .tr;
                                                        });
                                                        AppAlert.actionError(
                                                          title:
                                                              'wellness.could_not_save_correction'
                                                                  .tr,
                                                          message:
                                                              'wellness.could_not_save_correction'
                                                                  .tr,
                                                        );
                                                        return;
                                                      }
                                                      updateDialog(() {
                                                        saving = false;
                                                      });
                                                    },
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 50),
                                              backgroundColor:
                                                  context
                                                      .appColorScheme
                                                      .primary,
                                              foregroundColor:
                                                  context.appOnBrand,
                                              disabledBackgroundColor: context
                                                  .appColorScheme
                                                  .primary
                                                  .withValues(alpha: .55),
                                              disabledForegroundColor:
                                                  context.appOnBrand,
                                              elevation: 5,
                                              shadowColor: context
                                                  .appColorScheme
                                                  .primary
                                                  .withValues(alpha: 0.38),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(21),
                                              ),
                                            ),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              child:
                                                  saving
                                                      ? Row(
                                                        key: const ValueKey(
                                                          'saving-correction',
                                                        ),
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  context
                                                                      .appOnBrand,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 9,
                                                          ),
                                                          Text(
                                                            'common.saving'.tr,
                                                          ),
                                                        ],
                                                      )
                                                      : Text(
                                                        'wellness.save_correction'
                                                            .tr,
                                                        key: const ValueKey(
                                                          'save-correction',
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
    unitController.dispose();
  }

  Widget _nutritionCard(BuildContext context, FoodNutritionModel food) => _card(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'wellness.nutrition_estimate'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (food.isDatabaseCalculated ? green : warn).withValues(
                  alpha: .1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                food.nutritionSourceLabel.trOrSelf,
                style: TextStyle(
                  color:
                      food.isDatabaseCalculated
                          ? (context.appIsDark
                              ? context.appColorScheme.primary
                              : greenDark)
                          : (context.appIsDark
                              ? const Color(0xFFFFB388)
                              : warn),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.35,
          children: [
            _metric(
              context,
              Icons.local_fire_department_rounded,
              const Color(0xFFFF7A45),
              food.hasNutritionEstimate
                  ? '${food.calories.round()} kcal'
                  : '--',
              'Calories',
            ),
            _metric(
              context,
              Icons.fitness_center_rounded,
              const Color(0xFF3B82F6),
              food.hasNutritionEstimate
                  ? '${food.protein.toStringAsFixed(1)}g'
                  : '--',
              'Protein',
            ),
            _metric(
              context,
              Icons.grain_rounded,
              const Color(0xFFC2A100),
              food.hasNutritionEstimate
                  ? '${food.carbs.toStringAsFixed(1)}g'
                  : '--',
              'Carbs',
            ),
            _metric(
              context,
              Icons.opacity_rounded,
              const Color(0xFFF43F5E),
              food.hasNutritionEstimate
                  ? '${food.fat.toStringAsFixed(1)}g'
                  : '--',
              'Fat',
            ),
            _metric(
              context,
              Icons.icecream_rounded,
              const Color(0xFFA855F7),
              food.hasNutritionEstimate
                  ? '${food.sugar.toStringAsFixed(1)}g'
                  : '--',
              'Sugar',
            ),
            _metric(
              context,
              Icons.eco_rounded,
              const Color(0xFF16A34A),
              food.hasNutritionEstimate
                  ? '${food.fiber.toStringAsFixed(1)}g'
                  : '--',
              'Fiber',
            ),
            _metric(
              context,
              Icons.water_drop_rounded,
              const Color(0xFF1689C9),
              food.plainWaterVolumeMl > 0
                  ? '${food.plainWaterVolumeMl.round()} ml'
                  : '--',
              'Water',
            ),
            _metric(
              context,
              Icons.restaurant_menu_rounded,
              green,
              '${food.servingSize.toStringAsFixed(food.servingSize % 1 == 0 ? 0 : 1)} ${food.servingUnit}',
              'Serving',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _sugarAnalysisCard(BuildContext context, FoodNutritionModel food) {
    const color = Color(0xFFA855F7);
    final sugarShare = food.sugarShareOfCarbs;
    return _card(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.icecream_rounded, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'wellness.sugar_analysis'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'wellness.estimate'.tr,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _sugarValue(
                  context,
                  '${food.sugar.toStringAsFixed(1)} g',
                  'Estimated total sugar',
                ),
              ),
              Expanded(
                child: _sugarValue(
                  context,
                  '${food.sugarTeaspoons.toStringAsFixed(1)} tsp',
                  'About teaspoons',
                ),
              ),
              Expanded(
                child: _sugarValue(
                  context,
                  '${sugarShare.round()}%',
                  'Sugar share of carbs',
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: sugarShare / 100,
              minHeight: 8,
              backgroundColor: context.appSubtleSurface,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'wellness.this_is_estimated_total_sugar_a_photo_cannot_reliably_separate_added_sugar_from_naturally_occurring_sugar_so_it_is_not_a_daily_value_percentage_check_the_package_label_or_recipe_when_available'
                .tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sugarValue(BuildContext context, String value, String label) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label.trOrSelf,
            style: TextStyle(color: context.appMutedText, fontSize: 10.5),
          ),
        ],
      );

  Widget _metric(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
  ) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.appSubtleSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.appBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  label.trOrSelf,
                  style: TextStyle(color: context.appMutedText, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  // ---- Recommendation -----------------------------------------------

  Widget _recommendationCard(
    BuildContext context,
    FoodRecommendationModel item,
  ) {
    final isWarning = item.type == FoodRecommendationType.warning;
    final color = isWarning ? warn : green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(22),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'common.ai_recommendation'.tr,
            style: TextStyle(fontSize: 13, color: context.appMutedText),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWarning ? Icons.priority_high_rounded : Icons.check_rounded,
                  color: color,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title.trParams(item.titleParams),
                  style: TextStyle(
                    fontSize: 17,
                    color: color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.message.trParams(item.messageParams),
            style: const TextStyle(height: 1.45, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _legalNotice(BuildContext context, FoodNutritionModel? food) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appWarningSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.appOnWarningSurface.withValues(alpha: .35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 17,
                color: context.appOnWarningSurface,
              ),
              const SizedBox(width: 7),
              Text(
                'wellness.important_information'.tr,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            food?.disclaimer.isNotEmpty == true
                ? food!.disclaimer
                : 'wellness.ai_nutrition_results_are_estimates_for_general_wellness_only_they_are_not_medical_advice_a_diagnosis_or_an_official_nutrition_label'
                    .tr,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: context.appOnWarningSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            food?.privacyNotice.isNotEmpty == true
                ? food!.privacyNotice
                : 'wellness.food_photos_are_sent_to_the_configured_ai_provider_for_analysis_do_not_include_faces_documents_or_other_personal_information'
                    .tr,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: context.appOnWarningSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Misc ----------------------------------------------------------

  Widget _message(
    String text,
    Color color,
    IconData icon, {
    Map<String, String> params = const {},
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.trParams(params),
              style: TextStyle(color: color, fontSize: 13.5),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _card(BuildContext context, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.appSurfaceLow,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appTileShadow,
    ),
    child: child,
  );
}

class _TabletAnalysisPlaceholder extends StatelessWidget {
  const _TabletAnalysisPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('ai-food-tablet-placeholder'),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: context.appSurfaceLow,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.appBorder),
    ),
    child: Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.analytics_outlined,
            color: AiFoodView.green,
            size: 31,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'wellness.analysis_empty'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          'wellness.choose_photo_to_analyze'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

enum _ButtonStyle { primary, outlined, success }

/// Slim animated loading bar shown while the on-device model loads.
class _ModelLoadingBar extends StatelessWidget {
  const _ModelLoadingBar();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: LinearProgressIndicator(
      color:
          context.appIsDark ? context.appColorScheme.primary : AiFoodView.green,
      backgroundColor:
          context.appIsDark
              ? context.appColorScheme.surfaceContainerHighest
              : const Color(0xFFE8F7EA),
      minHeight: 6,
    ),
  );
}
