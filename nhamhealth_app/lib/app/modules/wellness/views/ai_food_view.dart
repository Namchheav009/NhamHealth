import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ai_food_controller.dart';
import '../models/food_nutrition_model.dart';
import '../models/food_recommendation_model.dart';

class AiFoodView extends GetView<AiFoodController> {
  const AiFoodView({super.key});
  static const green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAF6),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7FAF6),
      elevation: 0,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back_rounded, color: green),
      ),
      title: const Text(
        'AI Food Check',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      centerTitle: true,
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              _intro(),
              const SizedBox(height: 16),
              if (controller.isModelLoading.value)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(color: green),
                ),
              _imageCard(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _button(
                      Icons.photo_camera_outlined,
                      'Take Photo',
                      controller.takePhoto,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _button(
                      Icons.photo_library_outlined,
                      'Gallery',
                      controller.pickImageFromGallery,
                      outlined: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _button(
                controller.isLiveAnalyzing.value
                    ? Icons.stop_circle_outlined
                    : Icons.center_focus_strong,
                controller.isLiveCameraStarting.value
                    ? 'Starting camera...'
                    : controller.isLiveAnalyzing.value
                    ? 'Stop live scan'
                    : 'Scan food live',
                controller.isLiveCameraStarting.value
                    ? null
                    : controller.toggleLiveAnalysis,
                subtle: true,
              ),
              if (controller.selectedImage.value != null) ...[
                const SizedBox(height: 12),
                _button(
                  Icons.auto_awesome,
                  controller.isAnalyzing.value
                      ? 'Analyzing your food...'
                      : 'Analyze Food',
                  controller.isAnalyzing.value ? null : controller.analyzeFood,
                ),
              ],
              if (controller.errorMessage.value != null)
                _message(controller.errorMessage.value!, Colors.red.shade700),
              if (controller.prediction.value != null) ...[
                const SizedBox(height: 16),
                _predictionCard(),
              ],
              if (controller.isNutritionLoading.value)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: green)),
                ),
              if (controller.nutrition.value != null) ...[
                const SizedBox(height: 14),
                _nutritionCard(controller.nutrition.value!),
              ],
              if (controller.recommendation.value != null) ...[
                const SizedBox(height: 14),
                _recommendationCard(controller.recommendation.value!),
                const SizedBox(height: 14),
                _button(
                  Icons.add_circle_outline,
                  controller.wasAdded.value
                      ? 'Added to Today'
                      : controller.isSaving.value
                      ? 'Adding...'
                      : "Add to Today's Food",
                  controller.isSaving.value || controller.wasAdded.value
                      ? null
                      : controller.addFoodToToday,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _intro() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF087A48), Color(0xFF00A651)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: Color(0x2FFFFFFF), shape: BoxShape.circle),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Know what is on your plate', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 5),
              Text('Snap a clear photo for instant nutrition insights.', style: TextStyle(color: Color(0xDFFFFFFF), height: 1.35)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _imageCard() => GestureDetector(
    onTap:
        controller.isLiveAnalyzing.value
            ? null
            : controller.pickImageFromGallery,
    child: Container(
      height: 236,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD9E7DA)),
      ),
      child:
          controller.isLiveCameraReady
              ? Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width:
                          controller
                              .liveCameraController!
                              .value
                              .previewSize!
                              .height,
                      height:
                          controller
                              .liveCameraController!
                              .value
                              .previewSize!
                              .width,
                      child: CameraPreview(controller.liveCameraController!),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 7),
                          Text(
                            'LIVE AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : controller.selectedImage.value == null
              ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFFE8F7EA), shape: BoxShape.circle),
                    child: Padding(padding: EdgeInsets.all(16), child: Icon(Icons.add_a_photo_outlined, size: 34, color: green)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Add a meal photo',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Use camera or choose from gallery',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
              : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    controller.selectedImage.value!,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: controller.clearImage,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
    ),
  );

  Widget _button(
    IconData icon,
    String text,
    VoidCallback? action, {
    bool outlined = false,
    bool subtle = false,
  }) => SizedBox(
    height: 48,
    child:
        outlined || subtle
            ? OutlinedButton.icon(
              onPressed: action,
              icon: Icon(icon),
              label: Text(text),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: BorderSide(color: subtle ? const Color(0xFFCDE2D1) : green),
                backgroundColor: subtle ? Colors.white : null,
                shape: const StadiumBorder(),
              ),
            )
            : FilledButton.icon(
              onPressed: action,
              icon: Icon(icon),
              label: Text(text),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                shape: const StadiumBorder(),
              ),
            ),
  );

  Widget _predictionCard() {
    final value = controller.prediction.value!;
    final low = value.confidence < AiFoodController.lowConfidenceThreshold;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            low ? 'Not sure about this food' : 'Detected Food',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value.foodName,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          Text(
            '${(value.confidence * 100).round()}% confidence',
            style: TextStyle(
              color: low ? Colors.orange : green,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (low)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Try another photo with better lighting, the food centered, and fewer objects around it.',
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
        const Text(
          'Nutrition',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.25,
          children: [
            _metric('${food.calories.round()} kcal', 'Calories'),
            _metric('${food.protein.toStringAsFixed(1)}g', 'Protein'),
            _metric('${food.carbs.toStringAsFixed(1)}g', 'Carbs'),
            _metric('${food.fat.toStringAsFixed(1)}g', 'Fat'),
            _metric('${food.sugar.toStringAsFixed(1)}g', 'Sugar'),
            _metric(
              '${food.servingSize.toStringAsFixed(food.servingSize % 1 == 0 ? 0 : 1)} ${food.servingUnit}',
              'Serving',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _metric(String value, String label) => Padding(
    padding: const EdgeInsets.all(6),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _recommendationCard(FoodRecommendationModel item) {
    final color =
        item.type == FoodRecommendationType.warning
            ? const Color(0xFFFF7A45)
            : green;
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Recommendation',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check_circle, color: color),
              const SizedBox(width: 7),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 18,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(item.message, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  Widget _message(String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color)),
    ),
  );
  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x0F004D26)),
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
