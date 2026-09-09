import 'dart:async';
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

enum AiFoodInputKind { food, drink }

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
  final analysisStage = 0.obs;
  final isUserConfirmed = false.obs;
  final selectedImage = Rxn<File>();
  final prediction = Rxn<FoodPredictionModel>();
  final nutrition = Rxn<FoodNutritionModel>();
  final recommendation = Rxn<FoodRecommendationModel>();
  final errorMessage = RxnString();
  final errorMessageParams = <String, String>{}.obs;
  final wasAdded = false.obs;
  final inputKind = AiFoodInputKind.food.obs;
  final foodAmount = 1.0.obs;
  final foodUnit = 'plate'.obs;
  final drinkCupMl = 350.0.obs;
  final drinkConsumedFraction = 1.0.obs;
  int _scanGeneration = 0;

  double get selectedAmount =>
      inputKind.value == AiFoodInputKind.drink
          ? drinkCupMl.value * drinkConsumedFraction.value
          : foodAmount.value;

  String get selectedAmountUnit =>
      inputKind.value == AiFoodInputKind.drink ? 'ml' : foodUnit.value;

  String get selectedAmountLabel {
    final value = selectedAmount;
    final formatted =
        value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return '$formatted $selectedAmountUnit';
  }

  bool get canAnalyze =>
      selectedImage.value != null &&
      selectedAmount.isFinite &&
      selectedAmount > 0;

  void setInputKind(AiFoodInputKind value) => inputKind.value = value;

  void setFoodAmount(double value) {
    if (value.isFinite && value > 0) foodAmount.value = value;
  }

  void adjustFoodAmount(double delta) {
    final next = (foodAmount.value + delta).clamp(.25, 5.0);
    foodAmount.value = (next * 4).round() / 4;
  }

  void setFoodUnit(String value) {
    if (value.trim().isNotEmpty) foodUnit.value = value.trim();
  }

  void setDrinkCupMl(double value) {
    if (value.isFinite && value > 0) drinkCupMl.value = value;
  }

  void setDrinkConsumedFraction(double value) {
    drinkConsumedFraction.value = value.clamp(.25, 1.0);
  }

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
      resetAmountInput();
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
    analysisStage.value = 0;
    final stageTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (analysisStage.value < 3) analysisStage.value++;
    });
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
      errorMessage.value =
          'wellness.food_analysis_failed_please_try_another_photo';
    } finally {
      stageTimer.cancel();
      isAnalyzing.value = false;
      analysisStage.value = 0;
    }
  }

  String get analysisStageLabel => switch (analysisStage.value) {
    0 => 'wellness.checking_image_quality',
    1 => 'wellness.recognizing_food_and_drinks',
    2 => 'wellness.estimating_portions',
    _ => 'wellness.calculating_nutrition_and_sugar',
  };

  double get analysisProgress => switch (analysisStage.value) {
    0 => .18,
    1 => .42,
    2 => .68,
    _ => .88,
  };

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
      final adjustedFood = _applySelectedAmount(food);
      _publishPrediction(adjustedFood);
      final localGuidance = recommendationService.create(
        food: adjustedFood,
        currentCalories: caloriesController.currentCalories.value,
        targetCalories: caloriesController.targetCalories.value,
      );
      final useReviewGuidance = adjustedFood.needsUserConfirmation;
      final useLocalTitle = adjustedFood.recommendationTitle.isEmpty;
      final useLocalMessage = adjustedFood.recommendation.isEmpty;
      recommendation.value = FoodRecommendationModel(
        title:
            useReviewGuidance
                ? 'wellness.review_this_estimate'
                : useLocalTitle
                ? localGuidance.title
                : adjustedFood.recommendationTitle,
        message:
            useReviewGuidance
                ? 'wellness.review_estimate_help'
                : useLocalMessage
                ? localGuidance.message
                : adjustedFood.recommendation,
        type: localGuidance.type,
        titleParams:
            useReviewGuidance
                ? const {}
                : useLocalTitle
                ? localGuidance.titleParams
                : const {},
        messageParams:
            useReviewGuidance
                ? const {}
                : useLocalMessage
                ? localGuidance.messageParams
                : const {},
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
        final adjustedFood = _applySelectedAmount(localNutrition);
        nutrition.value = adjustedFood;
        prediction.value = FoodPredictionModel(
          foodName: adjustedFood.name,
          confidence: localPrediction.confidence.clamp(0, 1),
          classIndex: localPrediction.classIndex,
        );
        isUserConfirmed.value = false;
        recommendation.value = recommendationService.create(
          food: adjustedFood,
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
      final waterGlasses = food.plainWaterVolumeMl / 250;
      final today = DateTime.now();
      final savedDashboard = await profileRepository.addDailyNutrition(
        date: today,
        calories: food.calories,
        protein: food.protein,
        carbs: food.carbs,
        fat: food.fat,
        water: waterGlasses > 0 ? waterGlasses : null,
        fiber: food.fiber,
        sugar: food.sugar,
        aiRecommendation:
            recommendation.value == null
                ? null
                : '${recommendation.value!.title}: ${recommendation.value!.message}',
      );
      if (!food.isPlainWaterOnly) {
        caloriesController.addFoodSource(
          mealType: _mealTypeNow(),
          foodName: food.name,
          calories: food.calories.round(),
          closeSheet: false,
          showMessage: false,
        );
      }
      wellnessController.showSavedNutrition(savedDashboard, date: today);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().addNutritionToToday(
          calories: food.calories.round(),
          protein: food.protein,
          fat: food.fat,
          water: waterGlasses,
          fiber: food.fiber,
          sugar: food.sugar,
        );
      }
      wasAdded.value = true;
      await AppAlert.actionSuccess(
        title:
            food.isPlainWaterOnly
                ? 'wellness.water_added'
                : 'wellness.food_added',
        message: 'wellness.food_added_success'.trParams({'name': food.name}),
      );
    } on Object {
      await AppAlert.actionError(
        title: 'wellness.could_not_save_food',
        message:
            'wellness.your_nutrition_was_not_stored_please_check_the_server_and_try_again',
      );
    } finally {
      isSaving.value = false;
    }
  }

  bool get canAddFood =>
      nutrition.value != null &&
      nutrition.value!.hasCompleteNutrition &&
      (!nutrition.value!.needsUserConfirmation || isUserConfirmed.value);

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
        title: 'wellness.food_confirmed',
        message:
            'wellness.thanks_your_confirmation_helps_improve_future_results',
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
    if (current.analysisId == null) {
      errorMessage.value =
          'This result cannot be corrected because its analysis session has expired. Analyze the photo again.';
      return;
    }
    isFeedbackSaving.value = true;
    try {
      await nutritionRepository.submitFeedback(
        analysisId: current.analysisId!,
        confirmed: false,
        foodName: cleanName,
        servingSize: servingSize,
        servingUnit: cleanUnit,
      );
      FoodNutritionModel? databaseFood;
      try {
        databaseFood = await nutritionRepository.searchFood(cleanName);
      } on FoodNutritionException {
        // Feedback is already saved; catalog enrichment is optional.
      }
      if (databaseFood == null) {
        final corrected = current.withCorrection(
          correctedName: cleanName,
          size: servingSize,
          unit: cleanUnit,
        );
        nutrition.value = corrected;
        prediction.value = FoodPredictionModel(
          foodName: cleanName,
          confidence: 1,
          classIndex: -1,
        );
        isUserConfirmed.value = true;
        errorMessage.value = null;
        AppAlert.success(
          title: 'wellness.correction_saved',
          message: 'wellness.correction_review_estimate',
        );
        return;
      }
      if (cleanUnit.toLowerCase() !=
          databaseFood.servingUnit.trim().toLowerCase()) {
        isUserConfirmed.value = true;
        errorMessage.value = null;
        AppAlert.success(
          title: 'wellness.correction_saved',
          message: 'wellness.correction_review_unit'.trParams({
            'unit': databaseFood.servingUnit,
          }),
        );
        return;
      }
      final corrected = databaseFood
          .withAnalysisId(current.analysisId)
          .withServing(size: servingSize, unit: cleanUnit)
          .withCorrection(
            correctedName: cleanName,
            size: servingSize,
            unit: cleanUnit,
          );
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
        title: 'wellness.correction_saved',
        message: 'wellness.nutrition_was_recalculated_from_the_database',
      );
    } on FoodNutritionException catch (error) {
      errorMessage.value = error.message;
    } on Object {
      errorMessage.value =
          'The correction could not be saved. Please try again.';
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
    resetAmountInput();
  }

  void resetAmountInput() {
    inputKind.value = AiFoodInputKind.food;
    foodAmount.value = 1;
    foodUnit.value = 'plate';
    drinkCupMl.value = 350;
    drinkConsumedFraction.value = 1;
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

  FoodNutritionModel _applySelectedAmount(FoodNutritionModel food) {
    if (inputKind.value == AiFoodInputKind.food) {
      return food.withPortionScale(
        factor: foodAmount.value,
        size: foodAmount.value,
        unit: foodUnit.value,
      );
    }

    final requestedMl = selectedAmount;
    final detectedMl = food.drinkVolumeMl;
    final baselineMl = detectedMl > 0 ? detectedMl : 350.0;
    return food.withPortionScale(
      factor: requestedMl / baselineMl,
      size: requestedMl,
      unit: 'ml',
    );
  }

  @override
  void onClose() {
    aiService.dispose();
    super.onClose();
  }
}
