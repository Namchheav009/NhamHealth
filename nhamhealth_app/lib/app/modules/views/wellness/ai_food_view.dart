import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../controllers/wellness/ai_food_controller.dart';
import '../../models/wellness/food_nutrition_model.dart';
import '../../models/wellness/food_recommendation_model.dart';
import 'widgets/animated_reveal_text.dart';

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
    backgroundColor: context.appBackground,
    body: SafeArea(
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
            child: Center(
              child: Text(
                'AI Food Check'.tr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
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
              action: controller.takePhoto,
              style: _ButtonStyle.outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _button(
              context: context,
              icon: Icons.photo_library_outlined,
              text: 'Gallery',
              action: controller.pickImageFromGallery,
              style: _ButtonStyle.outlined,
            ),
          ),
        ],
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child:
            controller.selectedImage.value != null
                ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _button(
                    context: context,
                    icon: Icons.auto_awesome,
                    text:
                        controller.isAnalyzing.value
                            ? 'Analyzing food or drink...'
                            : 'Analyze Food or Drink',
                    action:
                        controller.isAnalyzing.value
                            ? null
                            : controller.analyzeFood,
                    style: _ButtonStyle.primary,
                    loading: controller.isAnalyzing.value,
                  ),
                )
                : const SizedBox(width: double.infinity),
      ),
    ],
  );

  Widget _resultsPanel(BuildContext context, {bool wide = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (wide && !controller.hasCompleteResult)
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
              AnimatedRevealText(
                text: 'Know what you eat or drink'.tr,
                duration: const Duration(milliseconds: 700),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 5),
              AnimatedRevealText(
                text: 'Snap a clear photo for instant nutrition insights.'.tr,
                delay: const Duration(milliseconds: 220),
                duration: const Duration(milliseconds: 900),
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
        'Add a meal photo'.tr,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      const SizedBox(height: 4),
      Text(
        'Use camera or choose from gallery'.tr,
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
                Text(text.tr),
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
            label: child ?? Text(text.tr),
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
            label: Text(text.tr),
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
            label: Text(text.tr),
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
                          ? 'Food + drink'.tr
                          : food.mealType == 'drink'
                          ? 'Drink'
                          : 'Food'.tr,
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
                          component.name,
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
                  water > 0 ? 'Plain water detected'.tr : 'Drink volume'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  water > 0
                      ? '$water ml • ${glasses.toStringAsFixed(glasses % 1 == 0 ? 0 : 1)} × 250 ml glasses'
                      : total > 0
                      ? 'About $total ml, excluding visible ice and foam'
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
            'Confidence'.tr,
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
        const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: warn, size: 22),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Please review this result',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'The AI is not fully certain about the food or portion. Confirm it or correct the result before adding it to today.',
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
                label: Text('Correct'.tr),
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
                icon:
                    controller.isFeedbackSaving.value
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.check_rounded, size: 18),
                label: Text('Confirm'.tr),
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
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, updateDialog) => AlertDialog(
                  title: Text('Correct AI result'.tr),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Food name'.tr,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'Amount'.tr,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: unitController,
                                decoration: InputDecoration(
                                  labelText: 'Unit'.tr,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (validationError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            validationError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          saving
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                      child: Text('Cancel'.tr),
                    ),
                    FilledButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                final amount = double.tryParse(
                                  amountController.text.trim(),
                                );
                                if (nameController.text.trim().isEmpty ||
                                    unitController.text.trim().isEmpty ||
                                    amount == null ||
                                    amount <= 0) {
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
                                await controller.correctFood(
                                  foodName: nameController.text,
                                  servingSize: amount,
                                  servingUnit: unitController.text,
                                );
                                if (!dialogContext.mounted) return;
                                if (controller.isUserConfirmed.value) {
                                  Navigator.of(dialogContext).pop();
                                  return;
                                }
                                updateDialog(() {
                                  saving = false;
                                  validationError =
                                      controller.errorMessage.value ??
                                      'The correction could not be saved.';
                                });
                              },
                      child:
                          saving
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text('Save correction'.tr),
                    ),
                  ],
                ),
          ),
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
                'Nutrition estimate'.tr,
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
                food.nutritionSourceLabel.tr,
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
                  label.tr,
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
            'AI Recommendation'.tr,
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
                child: AnimatedRevealText(
                  key: ValueKey<String>(
                    'ai-recommendation-title-${item.title}-${item.titleParams}',
                  ),
                  text: item.title.trParams(item.titleParams),
                  duration: const Duration(milliseconds: 800),
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
          AnimatedRevealText(
            key: ValueKey<String>(
              'ai-recommendation-message-${item.message}-${item.messageParams}',
            ),
            text: item.message.trParams(item.messageParams),
            delay: const Duration(milliseconds: 180),
            duration: const Duration(milliseconds: 1500),
            style: const TextStyle(height: 1.45, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _legalNotice(BuildContext context, FoodNutritionModel? food) {
    const defaultDisclaimer =
        'AI nutrition results are estimates for general wellness only. They are not medical advice, a diagnosis, or an official nutrition label.';
    const defaultPrivacy =
        'Food photos are sent to the configured AI provider for analysis. Do not include faces, documents, or other personal information.';
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
                'Important information'.tr,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            food?.disclaimer.isNotEmpty == true
                ? food!.disclaimer.tr
                : defaultDisclaimer.tr,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: context.appOnWarningSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            food?.privacyNotice.isNotEmpty == true
                ? food!.privacyNotice.tr
                : defaultPrivacy.tr,
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
          'Your nutrition analysis will appear here'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 7),
        Text(
          'Choose a clear food or drink photo, then tap Analyze.'.tr,
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
