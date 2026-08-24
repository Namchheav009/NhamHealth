import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/wellness/food_nutrition_model.dart';
import '../../models/wellness/food_prediction_model.dart';
import '../../models/wellness/food_recommendation_model.dart';
import '../../repositories/wellness/food_nutrition_repository.dart';
import '../../services/wellness/food_ai_service.dart';
import '../../services/wellness/food_recommendation_service.dart';
import 'calories_controller.dart';
import 'wellness_controller.dart';
import '../home/home_controller.dart';
import '../../repositories/profile/profile_repository.dart';

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
  final isFeedbackSaving = false.obs;
  final isUserConfirmed = false.obs;
  final selectedImage = Rxn<File>();
  final prediction = Rxn<FoodPredictionModel>();
  final nutrition = Rxn<FoodNutritionModel>();
  final recommendation = Rxn<FoodRecommendationModel>();
  final errorMessage = RxnString();
  final errorMessageParams = <String, String>{}.obs;
  final wasAdded = false.obs;
  int _scanGeneration = 0;

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

  Future<void> _pick(ImageSource source) async {
    try {
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
      if (!food.foodDetected) {
        prediction.value = null;
        nutrition.value = null;
        recommendation.value = null;
        isUserConfirmed.value = false;
        errorMessage.value =
            food.reason.isEmpty
                ? "We couldn't detect food in this photo. Try another clear photo."
                : food.reason;
        return;
      }
      _publishPrediction(food);
      final localGuidance = recommendationService.create(
        food: food,
        currentCalories: caloriesController.currentCalories.value,
        targetCalories: caloriesController.targetCalories.value,
      );
      final useLocalTitle =
          food.needsUserConfirmation || food.recommendationTitle.isEmpty;
      final useLocalMessage =
          food.needsUserConfirmation || food.recommendation.isEmpty;
      recommendation.value = FoodRecommendationModel(
        title: useLocalTitle ? localGuidance.title : food.recommendationTitle,
        message: useLocalMessage ? localGuidance.message : food.recommendation,
        type: localGuidance.type,
        titleParams: useLocalTitle ? localGuidance.titleParams : const {},
        messageParams: useLocalMessage ? localGuidance.messageParams : const {},
      );
      errorMessage.value = null;
    } on FoodNutritionException catch (cloudError) {
      try {
        final localPrediction = await aiService.analyze(
          Uint8List.fromList(bytes),
        );
        if (generation != null && generation != _scanGeneration) return;
        final localNutrition = await nutritionRepository.searchFood(
          localPrediction.foodName,
        );
        if (localNutrition == null) {
          throw const FoodNutritionException(
            'Food recognized locally, but nutrition was not found.',
          );
        }
        if (generation != null && generation != _scanGeneration) return;
        nutrition.value = localNutrition;
        prediction.value = FoodPredictionModel(
          foodName: localNutrition.name,
          confidence: localPrediction.confidence.clamp(0, 1),
          classIndex: localPrediction.classIndex,
        );
        isUserConfirmed.value = false;
        recommendation.value = recommendationService.create(
          food: localNutrition,
          currentCalories: caloriesController.currentCalories.value,
          targetCalories: caloriesController.targetCalories.value,
        );
        errorMessage.value = null;
      } on Object {
        prediction.value = null;
        nutrition.value = null;
        recommendation.value = null;
        isUserConfirmed.value = false;
        errorMessage.value = cloudError.message;
      }
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
    if (food == null || isSaving.value || wasAdded.value || !canAddFood) {
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

  bool get canAddFood =>
      nutrition.value != null &&
      nutrition.value!.hasCompleteNutrition &&
      (isUserConfirmed.value ||
          (prediction.value?.confidence ?? 0) >= lowConfidenceThreshold);

  bool get hasCompleteResult =>
      prediction.value != null &&
      nutrition.value != null &&
      errorMessage.value == null;

  Future<void> confirmFood() async {
    final food = nutrition.value;
    if (food == null || isFeedbackSaving.value) return;
    isFeedbackSaving.value = true;
    try {
      if (food.analysisId != null) {
        await nutritionRepository.submitFeedback(
          analysisId: food.analysisId!,
          confirmed: true,
          foodName: food.name,
          servingSize: food.servingSize,
          servingUnit: food.servingUnit,
        );
      }
      isUserConfirmed.value = true;
      errorMessage.value = null;
      AppAlert.success(
        title: 'Food confirmed',
        message: 'Thanks—your confirmation helps improve future results.',
      );
    } on FoodNutritionException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isFeedbackSaving.value = false;
    }
  }

  Future<void> correctFood({
    required String foodName,
    required double servingSize,
    required String servingUnit,
  }) async {
    final current = nutrition.value;
    if (current == null || isFeedbackSaving.value) return;
    final cleanName = foodName.trim();
    final cleanUnit = servingUnit.trim();
    if (cleanName.isEmpty || cleanUnit.isEmpty || servingSize <= 0) {
      errorMessage.value =
          'Enter a food, a serving amount, and a serving unit.';
      return;
    }
    isFeedbackSaving.value = true;
    try {
      final databaseFood = await nutritionRepository.searchFood(cleanName);
      if (databaseFood == null) {
        throw const FoodNutritionException(
          'That food is not in the nutrition database yet. Try a more specific name.',
        );
      }
      if (cleanUnit.toLowerCase() !=
          databaseFood.servingUnit.trim().toLowerCase()) {
        errorMessageParams.assignAll({
          'unit': databaseFood.servingUnit,
          'food': databaseFood.name,
        });
        throw FoodNutritionException(
          'Use @unit for @food so nutrition can be scaled safely.',
        );
      }
      final corrected = databaseFood
          .withAnalysisId(current.analysisId)
          .withServing(size: servingSize, unit: cleanUnit);
      if (current.analysisId != null) {
        await nutritionRepository.submitFeedback(
          analysisId: current.analysisId!,
          confirmed: false,
          foodName: corrected.name,
          servingSize: corrected.servingSize,
          servingUnit: corrected.servingUnit,
        );
      }
      nutrition.value = corrected;
      prediction.value = FoodPredictionModel(
        foodName: corrected.name,
        confidence: 1,
        classIndex: -1,
      );
      recommendation.value = recommendationService.create(
        food: corrected,
        currentCalories: caloriesController.currentCalories.value,
        targetCalories: caloriesController.targetCalories.value,
      );
      isUserConfirmed.value = true;
      errorMessage.value = null;
      AppAlert.success(
        title: 'Correction saved',
        message: 'Nutrition was recalculated from the database.',
      );
    } on FoodNutritionException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isFeedbackSaving.value = false;
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
    errorMessageParams.clear();
    wasAdded.value = false;
    isUserConfirmed.value = false;
  }

  void _publishPrediction(FoodNutritionModel food) {
    nutrition.value = food;
    prediction.value = FoodPredictionModel(
      foodName: food.name,
      confidence: food.confidence.clamp(0, 1),
      classIndex: -1,
    );
    isUserConfirmed.value = !food.needsUserConfirmation;
  }

  @override
  void onClose() {
    aiService.dispose();
    super.onClose();
  }
}
