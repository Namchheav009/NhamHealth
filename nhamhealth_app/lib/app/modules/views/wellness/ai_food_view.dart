import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness/ai_food_controller.dart';
import '../../models/wellness/food_nutrition_model.dart';
import '../../models/wellness/food_recommendation_model.dart';

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _intro(),
                const SizedBox(height: 18),
                if (controller.isModelLoading.value) ...[
                  const _ModelLoadingBar(),
                  const SizedBox(height: 12),
                ],
                _imageCard(),
                const SizedBox(height: 14),
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
                    const SizedBox(width: 10),
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
                            padding: const EdgeInsets.only(top: 12),
                            child: _button(
                              icon: Icons.auto_awesome,
                              text:
                                  controller.isAnalyzing.value
                                      ? 'Analyzing your food...'
                                      : 'Analyze Food',
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
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child:
                      controller.prediction.value != null
                          ? Padding(
                            key: const ValueKey('prediction'),
                            padding: const EdgeInsets.only(top: 16),
                            child: _predictionCard(),
                          )
                          : const SizedBox.shrink(),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child:
                      controller.nutrition.value != null
                          ? Padding(
                            key: const ValueKey('nutrition'),
                            padding: const EdgeInsets.only(top: 14),
                            child: _nutritionCard(controller.nutrition.value!),
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
                                              (controller
                                                          .prediction
                                                          .value
                                                          ?.confidence ??
                                                      0) <
                                                  AiFoodController
                                                      .lowConfidenceThreshold
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
    title: const Text(
      'AI Food Check',
      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Know what is on your plate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Snap a clear photo for instant nutrition insights.',
                style: TextStyle(color: Color(0xDFFFFFFF), height: 1.35),
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
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
      const Text(
        'Add a meal photo',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      const SizedBox(height: 4),
      const Text(
        'Use camera or choose from gallery',
        style: TextStyle(color: textMuted, fontSize: 13),
      ),
    ],
  );

  Widget _selectedImagePreview() => Stack(
    fit: StackFit.expand,
    children: [
      Image.file(controller.selectedImage.value!, fit: BoxFit.cover),
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
                Text(text),
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
            label: child ?? Text(text),
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
            label: Text(text),
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
            label: Text(text),
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

  // ---- Prediction ----------------------------------------------------

  Widget _predictionCard() {
    final value = controller.prediction.value!;
    final low = value.confidence < AiFoodController.lowConfidenceThreshold;
    final pct = (value.confidence * 100).round();
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                low ? Icons.help_outline_rounded : Icons.restaurant_rounded,
                size: 16,
                color: low ? warn : green,
              ),
              const SizedBox(width: 6),
              Text(
                low ? 'Not sure about this food' : 'Detected Food',
                style: const TextStyle(fontSize: 13, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.foodName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: value.confidence.clamp(0, 1),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFEFF3EE),
                    valueColor: AlwaysStoppedAnimation(low ? warn : green),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$pct%',
                style: TextStyle(
                  color: low ? warn : green,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (low)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: warn.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Try another photo with better lighting, the food centered, and fewer objects around it.',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Nutrition ---------------------------------------------------------

  Widget _nutritionCard(FoodNutritionModel food) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Nutrition estimate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (food.databaseMatched ? green : warn).withValues(
                  alpha: .1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                food.databaseMatched ? 'Database matched' : 'AI estimate',
                style: TextStyle(
                  color: food.databaseMatched ? greenDark : warn,
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
              '${food.calories.round()} kcal',
              'Calories',
            ),
            _metric(
              Icons.fitness_center_rounded,
              const Color(0xFF3B82F6),
              '${food.protein.toStringAsFixed(1)}g',
              'Protein',
            ),
            _metric(
              Icons.grain_rounded,
              const Color(0xFFC2A100),
              '${food.carbs.toStringAsFixed(1)}g',
              'Carbs',
            ),
            _metric(
              Icons.opacity_rounded,
              const Color(0xFFF43F5E),
              '${food.fat.toStringAsFixed(1)}g',
              'Fat',
            ),
            _metric(
              Icons.icecream_rounded,
              const Color(0xFFA855F7),
              '${food.sugar.toStringAsFixed(1)}g',
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
                      label,
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
          const Text(
            'AI Recommendation',
            style: TextStyle(fontSize: 13, color: textMuted),
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
                  item.title,
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
            item.message,
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
          const Row(
            children: [
              Icon(Icons.info_outline, size: 17, color: Color(0xFF8A6500)),
              SizedBox(width: 7),
              Text(
                'Important information',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          if (controller.nutrition.value?.analysis.isNotEmpty == true) ...[
            const SizedBox(height: 7),
            Text(
              controller.nutrition.value!.analysis,
              style: const TextStyle(
                color: textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 7),
          Text(
            food?.disclaimer.isNotEmpty == true
                ? food!.disclaimer
                : defaultDisclaimer,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Color(0xFF6E5A18),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            food?.privacyNotice.isNotEmpty == true
                ? food!.privacyNotice
                : defaultPrivacy,
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

  Widget _message(String text, Color color, IconData icon) => Padding(
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
            child: Text(text, style: TextStyle(color: color, fontSize: 13.5)),
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
