import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';
import 'package:image_picker/image_picker.dart';

import '../models/food_nutrition_model.dart';
import '../models/food_prediction_model.dart';
import '../models/food_recommendation_model.dart';
import '../repositories/food_nutrition_repository.dart';
import '../services/food_ai_service.dart';
import '../services/food_recommendation_service.dart';
import 'calories_controller.dart';
import 'wellness_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/repositories/profile_repository.dart';

class AiFoodController extends GetxController {
  AiFoodController({
    required this.aiService,
    required this.nutritionRepository,
    required this.recommendationService,
    required this.caloriesController,
    required this.wellnessController,
    required this.profileRepository,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  static const double lowConfidenceThreshold = 0.80;
  final FoodAiService aiService;
  final FoodNutritionRepository nutritionRepository;
  final FoodRecommendationService recommendationService;
  final CaloriesController caloriesController;
  final WellnessController wellnessController;
  final ProfileRepository profileRepository;
  final ImagePicker _imagePicker;

  final isModelLoading = false.obs;
  final isAnalyzing = false.obs;
  final isNutritionLoading = false.obs;
  final isSaving = false.obs;
  final isLiveCameraStarting = false.obs;
  final isLiveAnalyzing = false.obs;
  final selectedImage = Rxn<File>();
  final prediction = Rxn<FoodPredictionModel>();
  final nutrition = Rxn<FoodNutritionModel>();
  final recommendation = Rxn<FoodRecommendationModel>();
  final errorMessage = RxnString();
  final wasAdded = false.obs;
  CameraController? liveCameraController;
  bool _processingFrame = false;
  DateTime? _lastFrameAt;
  String? _candidateLabel;
  int _candidateCount = 0;
  String? _lastNutritionLookup;
  int _scanGeneration = 0;

  bool get isLiveCameraReady =>
      isLiveAnalyzing.value &&
      (liveCameraController?.value.isInitialized ?? false);

  @override
  void onInit() {
    super.onInit();
    _loadModel();
  }

  Future<void> _loadModel() async {
    isModelLoading.value = true;
    try {
      await aiService.load();
    } on FoodAiException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isModelLoading.value = false;
    }
  }

  Future<void> takePhoto() => _pick(ImageSource.camera);
  Future<void> pickImageFromGallery() => _pick(ImageSource.gallery);

  Future<void> toggleLiveAnalysis() async {
    if (isLiveAnalyzing.value || isLiveCameraStarting.value) {
      await stopLiveAnalysis();
    } else {
      await startLiveAnalysis();
    }
  }

  Future<void> startLiveAnalysis() async {
    if (isLiveCameraStarting.value || isLiveAnalyzing.value) return;
    final generation = ++_scanGeneration;
    isLiveCameraStarting.value = true;
    errorMessage.value = null;
    try {
      await aiService.load();
      if (generation != _scanGeneration) return;
      final cameras = await availableCameras();
      if (generation != _scanGeneration) return;
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera is available.');
      }
      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final camera = CameraController(
        selected,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      liveCameraController = camera;
      await camera.initialize();
      if (generation != _scanGeneration) {
        await camera.dispose();
        if (identical(liveCameraController, camera)) {
          liveCameraController = null;
        }
        return;
      }
      selectedImage.value = null;
      clearResult();
      isLiveAnalyzing.value = true;
      await camera.startImageStream(_onCameraFrame);
    } on FoodAiException catch (error) {
      errorMessage.value = error.message;
    } on CameraException catch (error) {
      await liveCameraController?.dispose();
      liveCameraController = null;
      errorMessage.value =
          error.code == 'CameraAccessDenied'
              ? 'Camera permission is required for live food analysis.'
              : 'Live camera could not start. ${error.description ?? ''}'
                  .trim();
    } finally {
      isLiveCameraStarting.value = false;
    }
  }

  Future<void> stopLiveAnalysis() async {
    final camera = liveCameraController;
    _scanGeneration++;
    isLiveAnalyzing.value = false;
    liveCameraController = null;
    _processingFrame = false;
    _candidateLabel = null;
    _candidateCount = 0;
    if (camera != null) {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
      await camera.dispose();
    }
  }

  Future<void> _onCameraFrame(CameraImage frame) async {
    if (!isLiveAnalyzing.value || _processingFrame) return;
    final now = DateTime.now();
    if (_lastFrameAt != null &&
        now.difference(_lastFrameAt!) < const Duration(milliseconds: 1200)) {
      return;
    }
    _lastFrameAt = now;
    _processingFrame = true;
    final generation = _scanGeneration;
    try {
      final camera = liveCameraController;
      if (camera == null) return;
      final result = await aiService.analyzeCameraImage(
        frame,
        rotationDegrees: camera.description.sensorOrientation,
      );
      if (!isLiveAnalyzing.value || generation != _scanGeneration) return;
      prediction.value = result;
      if (result.foodName == _candidateLabel) {
        _candidateCount++;
      } else {
        _candidateLabel = result.foodName;
        _candidateCount = 1;
      }
      if (_candidateCount >= 2 &&
          result.confidence >= lowConfidenceThreshold &&
          result.foodName != _lastNutritionLookup) {
        _lastNutritionLookup = result.foodName;
        final bytes = aiService.cameraImageToJpeg(
          frame,
          rotationDegrees: camera.description.sensorOrientation,
        );
        await _analyzeWithCloud(bytes, generation: generation);
      }
    } on FoodAiException catch (error) {
      errorMessage.value = error.message;
    } finally {
      _processingFrame = false;
    }
  }

  Future<void> _pick(ImageSource source) async {
    try {
      if (isLiveAnalyzing.value || isLiveCameraStarting.value) {
        await stopLiveAnalysis();
      }
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null) {
        return;
      }
      selectedImage.value = File(image.path);
      clearResult();
    } catch (_) {
      errorMessage.value =
          source == ImageSource.camera
              ? 'Camera is unavailable or permission was denied.'
              : 'Gallery is unavailable or permission was denied.';
    }
  }

  Future<void> analyzeFood() async {
    final image = selectedImage.value;
    if (image == null || isAnalyzing.value) {
      return;
    }
    isAnalyzing.value = true;
    final generation = ++_scanGeneration;
    errorMessage.value = null;
    clearResult();
    try {
      await _analyzeWithCloud(
        await image.readAsBytes(),
        filename: image.path.split(Platform.pathSeparator).last,
        generation: generation,
      );
    } on FoodAiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Food analysis failed. Please try another photo.';
    } finally {
      isAnalyzing.value = false;
    }
  }

  Future<void> _analyzeWithCloud(
    List<int> bytes, {
    String filename = 'food.jpg',
    int? generation,
  }) async {
    isNutritionLoading.value = true;
    try {
      final food = await nutritionRepository.analyzeImage(
        Uint8List.fromList(bytes),
        filename: filename,
      );
      if (generation != null && generation != _scanGeneration) return;
      nutrition.value = food;
      prediction.value = FoodPredictionModel(
        foodName: food.name,
        confidence: food.confidence.clamp(0, 1),
        classIndex: -1,
      );
      recommendation.value = FoodRecommendationModel(
        title: food.recommendationTitle,
        message: food.recommendation,
        type:
            food.sugar >= 20 ||
                    food.calories >
                        (caloriesController.targetCalories.value -
                            caloriesController.currentCalories.value)
                ? FoodRecommendationType.warning
                : FoodRecommendationType.good,
      );
      errorMessage.value = null;
    } on FoodNutritionException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isNutritionLoading.value = false;
    }
  }

  Future<void> loadFoodNutrition() async {
    final result = prediction.value;
    if (result == null || isNutritionLoading.value) {
      return;
    }
    isNutritionLoading.value = true;
    nutrition.value = null;
    recommendation.value = null;
    try {
      nutrition.value = await nutritionRepository.searchFood(result.foodName);
      final food = nutrition.value;
      if (food == null) {
        errorMessage.value =
            'Food recognized, but nutrition was not found in the database.';
        return;
      }
      recommendation.value = recommendationService.create(
        food: food,
        currentCalories: caloriesController.currentCalories.value,
        targetCalories: caloriesController.targetCalories.value,
      );
    } on FoodNutritionException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isNutritionLoading.value = false;
    }
  }

  Future<void> addFoodToToday() async {
    final food = nutrition.value;
    if (food == null ||
        isSaving.value ||
        wasAdded.value ||
        (prediction.value?.confidence ?? 0) < lowConfidenceThreshold) {
      return;
    }
    isSaving.value = true;
    try {
      await profileRepository.addDailyNutrition(
        calories: food.calories,
        protein: food.protein,
        sugar: food.sugar,
        aiRecommendation:
            recommendation.value == null
                ? null
                : '${recommendation.value!.title}: ${recommendation.value!.message}',
      );
      caloriesController.addFoodSource(
        mealType: _mealTypeNow(),
        foodName: food.name,
        calories: food.calories.round(),
        closeSheet: false,
        showMessage: false,
      );
      wellnessController.addNutrition(
        calories: food.calories.round(),
        protein: food.protein,
        sugar: food.sugar,
      );
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().addNutritionToToday(
          calories: food.calories.round(),
          protein: food.protein,
        );
      }
      wasAdded.value = true;
      AppAlert.success(
        title: 'Food added',
        message: '${food.name} added successfully.',
      );
    } on Object {
      AppAlert.error(
        title: 'Could not save food',
        message:
            'Your nutrition was not stored. Please check the server and try again.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  String _mealTypeNow() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 16) return 'Lunch';
    return 'Dinner';
  }

  void clearImage() {
    _scanGeneration++;
    selectedImage.value = null;
    clearResult();
  }

  void clearResult() {
    prediction.value = null;
    nutrition.value = null;
    recommendation.value = null;
    errorMessage.value = null;
    wasAdded.value = false;
    _lastNutritionLookup = null;
  }

  @override
  void onClose() {
    final camera = liveCameraController;
    if (camera?.value.isStreamingImages ?? false) {
      camera?.stopImageStream();
    }
    camera?.dispose();
    aiService.dispose();
    super.onClose();
  }
}
