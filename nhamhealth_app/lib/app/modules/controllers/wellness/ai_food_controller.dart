import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../widgets/app_alert.dart';
import '../../models/wellness/food_detection_model.dart';
import '../../models/wellness/food_nutrition_model.dart';
import '../../models/wellness/food_prediction_model.dart';
import '../../models/wellness/food_recommendation_model.dart';
import '../../models/wellness/plate_item_model.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../repositories/wellness/food_nutrition_repository.dart';
import '../../services/wellness/food_ai_service.dart';
import '../../services/wellness/food_recommendation_service.dart';
import '../home/home_controller.dart';
import 'calories_controller.dart';
import 'wellness_controller.dart';

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
  final detection = Rxn<FoodDetectionModel>();
  final customFoodName = RxnString();
  final customCuisine = RxnString();
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
  final drinkSugarPercentage = 100.obs;
  final plateItems = <PlateItemState>[].obs;
  int _scanGeneration = 0;
  FoodNutritionModel? _baseNutrition;

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

  double get estimatedCalories {
    final currentNutrition = nutrition.value ?? _baseNutrition;
    if (currentNutrition != null) {
      return currentNutrition.calories;
    }
    if (inputKind.value == AiFoodInputKind.drink) {
      final sugarRatio = drinkSugarPercentage.value / 100.0;
      return (120.0 * (selectedAmount / 350.0) * (0.4 + 0.6 * sugarRatio));
    }
    return 400.0 * foodAmount.value;
  }

  int get estimatedGrams {
    final currentNutrition = nutrition.value ?? _baseNutrition;
    if (currentNutrition != null && currentNutrition.servingSize > 0) {
      return (currentNutrition.servingSize * foodAmount.value).round();
    }
    return (350.0 * foodAmount.value).round();
  }

  bool get canAnalyze =>
      selectedImage.value != null &&
      selectedAmount.isFinite &&
      selectedAmount > 0;

  bool get hasAnalyzedImage => _baseNutrition != null;
  bool get hasDetectedImage => detection.value?.foodDetected == true;

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

  void setDrinkSugarPercentage(int value) {
    drinkSugarPercentage.value = value.clamp(0, 200);
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
    if (image == null || !hasDetectedImage || isAnalyzing.value) {
      return;
    }
    isAnalyzing.value = true;
    analysisStage.value = 0;
    final stageTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (analysisStage.value < 3) analysisStage.value++;
    });
    final generation = ++_scanGeneration;
    errorMessage.value = null;
    _clearAnalysisResult();
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

  Future<bool> detectFood() async {
    final image = selectedImage.value;
    if (image == null || isAnalyzing.value) return false;
    isAnalyzing.value = true;
    analysisStage.value = 0;
    final generation = ++_scanGeneration;
    clearResult();
    try {
      final result = await nutritionRepository.detectImage(
        await image.readAsBytes(),
        filename: image.path.split(Platform.pathSeparator).last,
      );
      if (generation != _scanGeneration) return false;
      detection.value = result;
      if (!result.foodDetected) {
        errorMessage.value =
            result.reason.isEmpty
                ? "We couldn't detect food or drink in this photo. Try another clear photo."
                : result.reason;
        return false;
      }
      inputKind.value =
          result.isDrink ? AiFoodInputKind.drink : AiFoodInputKind.food;
      errorMessage.value = null;
      return true;
    } on FoodNutritionException catch (error) {
      errorMessage.value = error.message;
      return false;
    } on Object {
      errorMessage.value =
          'wellness.food_analysis_failed_please_try_another_photo';
      return false;
    } finally {
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
      _baseNutrition = food;
      _syncInputKindFrom(food);
      final adjustedFood = _applySelectedAmount(food);
      _publishPrediction(adjustedFood);
      _initPlateFrom(adjustedFood);
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
        _baseNutrition = localNutrition;
        _syncInputKindFrom(localNutrition);
        final adjustedFood = _applySelectedAmount(localNutrition);
        nutrition.value = adjustedFood;
        _initPlateFrom(adjustedFood);
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
        final activeItems = plateItems.where((i) => i.isSelected).toList();
        if (activeItems.length > 1) {
          for (final item in activeItems) {
            caloriesController.addFoodSource(
              mealType: _mealTypeNow(),
              foodName: item.name,
              calories: item.calories.round(),
              closeSheet: false,
              showMessage: false,
            );
          }
        } else {
          caloriesController.addFoodSource(
            mealType: _mealTypeNow(),
            foodName:
                activeItems.isNotEmpty ? activeItems.first.name : food.name,
            calories: food.calories.round(),
            closeSheet: false,
            showMessage: false,
          );
        }
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

  Future<void> confirmAndAddFoodToToday() async {
    final food = nutrition.value;
    if (food == null || isSaving.value || wasAdded.value) return;
    if (food.needsUserConfirmation && !isUserConfirmed.value) {
      await confirmFood();
    }
    await addFoodToToday();
  }

  bool get canAddFood =>
      nutrition.value != null &&
      nutrition.value!.hasCompleteNutrition &&
      (!nutrition.value!.needsUserConfirmation || isUserConfirmed.value);

  bool get hasCompleteResult =>
      nutrition.value != null && nutrition.value!.foodDetected;

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
      await AppAlert.actionError(
        title: 'wellness.could_not_save_feedback'.tr,
        message: error.message,
      );
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
      throw const FoodNutritionException(
        'Enter a food, a serving amount, and a serving unit.',
      );
    }
    if (current.analysisId == null) {
      throw const FoodNutritionException(
        'This result cannot be corrected because its analysis session has expired. Analyze the photo again.',
      );
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
    } on FoodNutritionException {
      rethrow;
    } catch (_) {
      throw const FoodNutritionException(
        'The correction could not be saved. Please try again.',
      );
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
    drinkSugarPercentage.value = 100;
  }

  void clearResult() {
    detection.value = null;
    customFoodName.value = null;
    customCuisine.value = null;
    _clearAnalysisResult();
  }

  void _clearAnalysisResult() {
    _baseNutrition = null;
    plateItems.clear();
    prediction.value = null;
    nutrition.value = null;
    recommendation.value = null;
    errorMessage.value = null;
    errorMessageParams.clear();
    wasAdded.value = false;
    isUserConfirmed.value = false;
  }

  void updateDetectedFood({
    required String name,
    String? cuisine,
    bool? isDrink,
  }) {
    final cleanName = name.trim();
    if (cleanName.isNotEmpty) {
      customFoodName.value = cleanName;
    }
    if (cuisine != null && cuisine.trim().isNotEmpty) {
      customCuisine.value = cuisine.trim();
    }
    if (isDrink != null) {
      inputKind.value = isDrink ? AiFoodInputKind.drink : AiFoodInputKind.food;
    }
    final det = detection.value;
    if (det != null) {
      detection.value = FoodDetectionModel(
        foodDetected: true,
        reason: det.reason,
        mealName: cleanName.isNotEmpty ? cleanName : det.mealName,
        type: (isDrink ?? det.isDrink) ? 'drink' : 'food',
        requiresDrinkDetails: isDrink ?? det.requiresDrinkDetails,
        confidence: det.confidence > 0 ? det.confidence : 1.0,
      );
    }
  }

  List<String> get foodTags {
    final food = nutrition.value ?? _baseNutrition;
    if (food == null) return const [];
    final tags = <String>{};
    if (food.cuisine != 'Unknown' && food.cuisine.trim().isNotEmpty) {
      tags.add(food.cuisine.trim());
    }
    if (food.mealType != 'food' && food.mealType.trim().isNotEmpty) {
      tags.add(food.mealType.capitalizeFirst ?? food.mealType);
    }
    for (final c in food.components) {
      final name = c.name.trim();
      if (name.isNotEmpty && !tags.contains(name)) {
        tags.add(name);
      }
    }
    for (final p in plateItems) {
      final name = p.name.trim();
      if (name.isNotEmpty && !tags.contains(name)) {
        tags.add(name);
      }
    }
    if (tags.isEmpty) {
      tags.addAll(['Healthy', 'Nutrition']);
    }
    return tags.take(5).toList();
  }

  String get detectedFoodName {
    if (customFoodName.value != null &&
        customFoodName.value!.trim().isNotEmpty) {
      return customFoodName.value!.trim();
    }
    final det = detection.value;
    if (det != null && det.mealName.isNotEmpty) {
      return det.mealName;
    }
    final nut = nutrition.value ?? _baseNutrition;
    if (nut != null) {
      return nut.mealName.isNotEmpty ? nut.mealName : nut.name;
    }
    return 'Shrimp Fettuccine Alfredo';
  }

  String get detectedCuisine {
    if (customCuisine.value != null && customCuisine.value!.trim().isNotEmpty) {
      final type = inputKind.value == AiFoodInputKind.drink ? 'Drink' : 'Dish';
      return '${customCuisine.value!.trim()} • $type';
    }
    final nut = nutrition.value ?? _baseNutrition;
    if (nut != null && nut.cuisine != 'Unknown' && nut.cuisine.isNotEmpty) {
      return '${nut.cuisine} • ${nut.mealType == 'drink' ? 'Drink' : 'Pasta'}';
    }
    final det = detection.value;
    if (det != null) {
      return det.isDrink ? 'Beverage • Drink' : 'Italian • Pasta';
    }
    return 'Italian • Pasta';
  }

  void selectCandidate(String candidateName) {
    if (nutrition.value == null) return;
    nutrition.value = nutrition.value!.copyWith(name: candidateName);
    isUserConfirmed.value = true;
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

  void updateAmountForCurrentResult() {
    final baseFood = _baseNutrition;
    if (baseFood == null) return;
    final adjustedFood = _applySelectedAmount(baseFood);
    _publishPrediction(adjustedFood);
    _initPlateFrom(adjustedFood);
    recommendation.value = recommendationService.create(
      food: adjustedFood,
      currentCalories: caloriesController.currentCalories.value,
      targetCalories: caloriesController.targetCalories.value,
    );
    wasAdded.value = false;
    errorMessage.value = null;
  }

  // ---- Multi-Item Plate Management -----------------------------------------

  void _initPlateFrom(FoodNutritionModel food) {
    plateItems.clear();
    if (food.components.isNotEmpty) {
      for (var i = 0; i < food.components.length; i++) {
        final c = food.components[i];
        plateItems.add(
          PlateItemState(
            id: 'comp_${i}_${DateTime.now().microsecondsSinceEpoch}',
            name: c.name,
            baseCalories: c.calories,
            baseProtein: c.protein,
            baseCarbs: c.carbohydrates,
            baseFat: c.fat,
            baseSugar: c.sugar,
            baseFiber: c.fiber,
            baseSodium: c.sodium,
            baseServingSize:
                c.estimatedAmount > 0
                    ? c.estimatedAmount
                    : (c.liquidVolumeMl > 0 ? c.liquidVolumeMl : 100),
            unit: c.liquidVolumeMl > 0 ? 'ml' : 'g',
            portionMultiplier: 1.0,
            isSelected: true,
            componentType: c.componentType,
            confidence: c.confidence,
            preparationMethod: c.preparationMethod,
            visibleEvidence: c.visibleEvidence,
          ),
        );
      }
    } else {
      plateItems.add(
        PlateItemState(
          id: 'comp_single_${DateTime.now().microsecondsSinceEpoch}',
          name: food.name,
          baseCalories: food.calories,
          baseProtein: food.protein,
          baseCarbs: food.carbs,
          baseFat: food.fat,
          baseSugar: food.sugar,
          baseFiber: food.fiber,
          baseSodium: food.sodium,
          baseServingSize: food.servingSize,
          unit: food.servingUnit,
          portionMultiplier: 1.0,
          isSelected: true,
          componentType: food.mealType,
          confidence: food.confidence,
        ),
      );
    }
  }

  void togglePlateItem(int index) {
    if (index >= 0 && index < plateItems.length) {
      plateItems[index].isSelected = !plateItems[index].isSelected;
      plateItems.refresh();
      _syncNutritionFromPlate();
    }
  }

  void updatePlateItemPortion(int index, double multiplier) {
    if (index >= 0 && index < plateItems.length) {
      plateItems[index].portionMultiplier = multiplier;
      plateItems.refresh();
      _syncNutritionFromPlate();
    }
  }

  void removePlateItem(int index) {
    if (index >= 0 && index < plateItems.length) {
      plateItems.removeAt(index);
      _syncNutritionFromPlate();
    }
  }

  void addPlateItem({
    required String name,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
  }) {
    plateItems.add(
      PlateItemState(
        id: 'comp_manual_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        baseCalories: calories,
        baseProtein: protein,
        baseCarbs: carbs,
        baseFat: fat,
        portionMultiplier: 1.0,
        isSelected: true,
      ),
    );
    _syncNutritionFromPlate();
  }

  void _syncNutritionFromPlate() {
    final current = nutrition.value;
    if (current == null) return;

    final selected = plateItems.where((i) => i.isSelected).toList();
    if (selected.isEmpty) {
      nutrition.value = current.copyWith(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        sugar: 0,
        fiber: 0,
        sodium: 0,
      );
      return;
    }

    final totalCalories = selected.fold<double>(
      0,
      (sum, i) => sum + i.calories,
    );
    final totalProtein = selected.fold<double>(0, (sum, i) => sum + i.protein);
    final totalCarbs = selected.fold<double>(0, (sum, i) => sum + i.carbs);
    final totalFat = selected.fold<double>(0, (sum, i) => sum + i.fat);
    final totalSugar = selected.fold<double>(0, (sum, i) => sum + i.sugar);
    final totalFiber = selected.fold<double>(0, (sum, i) => sum + i.fiber);
    final totalSodium = selected.fold<double>(0, (sum, i) => sum + i.sodium);

    final updated = current.copyWith(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      sugar: totalSugar,
      fiber: totalFiber,
      sodium: totalSodium,
    );

    nutrition.value = updated;
    recommendation.value = recommendationService.create(
      food: updated,
      currentCalories: caloriesController.currentCalories.value,
      targetCalories: caloriesController.targetCalories.value,
    );
  }

  void _syncInputKindFrom(FoodNutritionModel food) {
    final onlyDrinkComponents =
        food.components.isNotEmpty &&
        food.components.every(
          (component) => component.componentType == 'drink',
        );
    inputKind.value =
        food.mealType == 'drink' ||
                food.requiresDrinkDetails ||
                onlyDrinkComponents
            ? AiFoodInputKind.drink
            : AiFoodInputKind.food;
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
      sugarFactor: drinkSugarPercentage.value / 100.0,
    );
  }

  @override
  void onClose() {
    aiService.dispose();
    super.onClose();
  }
}
