import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_alert.dart';
import '../../models/wellness/food_nutrition_model.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../repositories/wellness/food_nutrition_repository.dart';
import '../../services/wellness/meal_text_parser.dart';
import '../home/home_controller.dart';
import 'calories_controller.dart';
import 'wellness_controller.dart';

class AiMealAutoFillController extends GetxController {
  AiMealAutoFillController({
    required this.nutritionRepository,
    required this.profileRepository,
    required this.caloriesController,
    required this.wellnessController,
    MealTextParser parser = const MealTextParser(),
  }) : _parser = parser;

  final FoodNutritionRepository nutritionRepository;
  final ProfileRepository profileRepository;
  final CaloriesController caloriesController;
  final WellnessController wellnessController;
  final MealTextParser _parser;
  final inputController = TextEditingController();
  final foods = <FoodNutritionModel>[].obs;
  final unresolved = <String>[].obs;
  final isAnalyzing = false.obs;
  final isSaving = false.obs;

  double get totalCalories => foods.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => foods.fold(0, (sum, item) => sum + item.protein);
  double get totalFat => foods.fold(0, (sum, item) => sum + item.fat);
  double get totalSugar => foods.fold(0, (sum, item) => sum + item.sugar);

  Future<void> analyzeText() async {
    final parsed = _parser.parse(inputController.text);
    if (parsed.isEmpty || isAnalyzing.value) {
      AppAlert.error(
        title: 'Add your meal',
        message: 'Enter one or more foods first.',
      );
      return;
    }
    isAnalyzing.value = true;
    foods.clear();
    unresolved.clear();
    try {
      for (final item in parsed) {
        final match = await nutritionRepository.searchFood(item.searchName);
        if (match == null) {
          unresolved.add(item.searchName);
          continue;
        }
        if (item.amount != null &&
            item.unit != null &&
            item.unit!.toLowerCase() != match.servingUnit.toLowerCase()) {
          unresolved.add('${item.searchName} (use ${match.servingUnit})');
          continue;
        }
        foods.add(
          item.amount == null
              ? match
              : match.withServing(
                size: item.amount!,
                unit: item.unit ?? match.servingUnit,
              ),
        );
      }
      if (foods.isEmpty) {
        AppAlert.error(
          title: 'No catalog matches',
          message: 'Try simpler food names, separated by commas.',
        );
      }
    } on FoodNutritionException catch (error) {
      AppAlert.error(title: 'Could not analyze meal', message: error.message);
    } finally {
      isAnalyzing.value = false;
    }
  }

  void removeAt(int index) => foods.removeAt(index);

  Future<void> addAllToToday() async {
    if (foods.isEmpty || isSaving.value) return;
    isSaving.value = true;
    try {
      await profileRepository.addDailyNutrition(
        calories: totalCalories,
        protein: totalProtein,
        fat: totalFat,
        sugar: totalSugar,
        aiRecommendation:
            'Meal auto-fill: ${foods.map((food) => food.name).join(', ')}',
      );
      for (final food in foods) {
        caloriesController.addFoodSource(
          mealType: _mealTypeNow(),
          foodName: food.name,
          calories: food.calories.round(),
          closeSheet: false,
          showMessage: false,
        );
      }
      wellnessController.addNutrition(
        calories: totalCalories.round(),
        protein: totalProtein,
        fat: totalFat,
        sugar: totalSugar,
      );
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().addNutritionToToday(
          calories: totalCalories.round(),
          protein: totalProtein,
          fat: totalFat,
        );
      }
      AppAlert.success(
        title: 'Meal added',
        message:
            '${foods.length} food${foods.length == 1 ? '' : 's'} added to today.',
      );
      foods.clear();
      unresolved.clear();
      inputController.clear();
    } on Object {
      AppAlert.error(
        title: 'Could not save meal',
        message: 'Please try again.',
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

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }
}
