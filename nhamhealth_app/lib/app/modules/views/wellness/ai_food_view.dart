import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  static const bg = Color(0xFFF7FAF6);
  static const cardBorder = Color(0x0F004D26);
  static const warn = Color(0xFFFF7A45);
  static const textMuted = Color(0xFF6B7A70);
  static const double pageHorizontalPadding = 20;
  static const double sectionSpacing = 16;
  static const double imageAspectRatio = 16 / 9;
  static const double imageMinHeight = 190;
  static const double imageMaxHeight = 230;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: _appBar(),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.fromLTRB(
                pageHorizontalPadding,
                8,
                pageHorizontalPadding,
                40,
              ),
              children: [
                _intro(),
                const SizedBox(height: sectionSpacing),
                if (controller.isModelLoading.value) ...[
                  const _ModelLoadingBar(),
                  const SizedBox(height: 12),
                ],
                _imageCard(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _button(
                        icon: Icons.photo_camera_outlined,
                        text: 'Take Photo',
                        action: controller.takePhoto,
                        style: _ButtonStyle.outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _button(
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
                            padding: const EdgeInsets.only(top: 14),
                            child: Column(
                              children: [
                                _confidenceLine(),
                                const SizedBox(height: 14),
                                if (!controller.isUserConfirmed.value &&
                                    (controller.prediction.value?.confidence ??
                                            0) <
                                        AiFoodController
                                            .lowConfidenceThreshold) ...[
                                  _feedbackCard(context),
                                  const SizedBox(height: 14),
                                ],
                                _nutritionCard(controller.nutrition.value!),
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
                                  controller.recommendation.value!,
                                ),
                                const SizedBox(height: 14),
                                _button(
                                  icon:
                                      controller.wasAdded.value
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                  text:
                                      controller.wasAdded.value
                                          ? 'Added to Today'
                                          : controller.isSaving.value
                                          ? 'Adding...'
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
                _legalNotice(controller.nutrition.value),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  // ---- AppBar -------------------------------------------------------------

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: bg,
    surfaceTintColor: bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      onPressed: Get.back,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: cardBorder),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: green, size: 20),
      ),
    ),
    title: Text(
      'AI Food Check'.tr,
      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
    ),
    centerTitle: true,
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

  Widget _imageCard() => GestureDetector(
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  controller.selectedImage.value != null
                      ? green.withValues(alpha: .35)
                      : const Color(0xFFD9E7DA),
              width: controller.selectedImage.value != null ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child:
              controller.selectedImage.value == null
                  ? _emptyImageState()
                  : _selectedImagePreview(),
        );
      },
    ),
  );

  Widget _emptyImageState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE8F7EA),
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
        style: const TextStyle(color: textMuted, fontSize: 13),
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
    required IconData icon,
    required String text,
    required VoidCallback? action,
    _ButtonStyle style = _ButtonStyle.primary,
    bool loading = false,
  }) {
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
              backgroundColor: const Color(0xFFE8F7EA),
              foregroundColor: greenDark,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      case _ButtonStyle.outlined:
        return SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: action,
            icon: Icon(icon, size: 20),
            label: Text(text.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: green,
              side: const BorderSide(color: green),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
    }
  }

  // ---- Nutrition ---------------------------------------------------------

  Widget _confidenceLine() {
    final confidence = (controller.prediction.value?.confidence ?? 0).clamp(
      0.0,
      1.0,
    );
    final percentage = (confidence * 100).round();
    final low = confidence < AiFoodController.lowConfidenceThreshold;
    final color = low ? warn : green;

    return _card(
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
                backgroundColor: const Color(0xFFEFF3EE),
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

  Widget _nutritionCard(FoodNutritionModel food) => _card(
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
                  color: food.isDatabaseCalculated ? greenDark : warn,
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
              Icons.local_fire_department_rounded,
              const Color(0xFFFF7A45),
              food.hasNutritionEstimate
                  ? '${food.calories.round()} kcal'
                  : '--',
              'Calories',
            ),
            _metric(
              Icons.fitness_center_rounded,
              const Color(0xFF3B82F6),
              food.hasNutritionEstimate
                  ? '${food.protein.toStringAsFixed(1)}g'
                  : '--',
              'Protein',
            ),
            _metric(
              Icons.grain_rounded,
              const Color(0xFFC2A100),
              food.hasNutritionEstimate
                  ? '${food.carbs.toStringAsFixed(1)}g'
                  : '--',
              'Carbs',
            ),
            _metric(
              Icons.opacity_rounded,
              const Color(0xFFF43F5E),
              food.hasNutritionEstimate
                  ? '${food.fat.toStringAsFixed(1)}g'
                  : '--',
              'Fat',
            ),
            _metric(
              Icons.icecream_rounded,
              const Color(0xFFA855F7),
              food.hasNutritionEstimate
                  ? '${food.sugar.toStringAsFixed(1)}g'
                  : '--',
              'Sugar',
            ),
            _metric(
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

  Widget _feedbackCard(BuildContext context) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: warn),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please confirm before logging'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check the serving amount and nutrition estimate. Corrections are saved as quality feedback.'
                .tr,
            style: const TextStyle(color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      controller.isFeedbackSaving.value
                          ? null
                          : controller.confirmFood,
                  icon: const Icon(Icons.check_rounded),
                  label: Text('Looks right'.tr),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed:
                      controller.isFeedbackSaving.value
                          ? null
                          : () => _showCorrectionDialog(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text('Edit result'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCorrectionDialog(BuildContext context) async {
    final food = controller.nutrition.value;
    if (food == null) return;
    final nameController = TextEditingController(text: food.name);
    final sizeController = TextEditingController(
      text: food.servingSize.toString(),
    );
    final unitController = TextEditingController(text: food.servingUnit);
    final submit = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Correct food result'.tr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Food name'.tr,
                      prefixIcon: const Icon(Icons.restaurant_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sizeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(labelText: 'Amount'.tr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: 'Unit'.tr,
                            hintText: 'g, bowl, serving'.tr,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('Cancel'.tr),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('Save correction'.tr),
              ),
            ],
          ),
    );
    if (submit == true) {
      await controller.correctFood(
        foodName: nameController.text,
        servingSize: double.tryParse(sizeController.text) ?? 0,
        servingUnit: unitController.text,
      );
    }
    nameController.dispose();
    sizeController.dispose();
    unitController.dispose();
  }

  Widget _metric(IconData icon, Color color, String value, String label) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
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
                      style: const TextStyle(color: textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ---- Recommendation -----------------------------------------------

  Widget _recommendationCard(FoodRecommendationModel item) {
    final isWarning = item.type == FoodRecommendationType.warning;
    final color = isWarning ? warn : green;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Recommendation'.tr,
            style: const TextStyle(fontSize: 13, color: textMuted),
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

  Widget _legalNotice(FoodNutritionModel? food) {
    const defaultDisclaimer =
        'AI nutrition results are estimates for general wellness only. They are not medical advice, a diagnosis, or an official nutrition label.';
    const defaultPrivacy =
        'Food photos are sent to the configured AI provider for analysis. Do not include faces, documents, or other personal information.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3E4A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 17,
                color: Color(0xFF8A6500),
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
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF6E5A18),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            food?.privacyNotice.isNotEmpty == true
                ? food!.privacyNotice.tr
                : defaultPrivacy.tr,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF6E5A18),
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

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

enum _ButtonStyle { primary, outlined, success }

/// Slim animated loading bar shown while the on-device model loads.
class _ModelLoadingBar extends StatelessWidget {
  const _ModelLoadingBar();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: const LinearProgressIndicator(
      color: AiFoodView.green,
      backgroundColor: Color(0xFFE8F7EA),
      minHeight: 6,
    ),
  );
}
