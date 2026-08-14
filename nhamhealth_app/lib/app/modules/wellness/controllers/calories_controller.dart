import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../models/food_source_model.dart';

class CaloriesController extends GetxController {
  final targetCalories = 2000.obs;
  final currentCalories = 1420.obs;

  late final TextEditingController intakeController;

  final foodSources = <FoodSourceModel>[
    const FoodSourceModel(
      id: '1',
      mealType: 'Breakfast',
      foodName: 'Chicken rice',
      calories: 520,
      emoji: '🍛',
    ),
    const FoodSourceModel(
      id: '2',
      mealType: 'Drink',
      foodName: 'Milk tea',
      calories: 280,
      emoji: '🥤',
    ),
    const FoodSourceModel(
      id: '3',
      mealType: 'Dinner',
      foodName: 'Fried Chicken',
      calories: 620,
      emoji: '🍗',
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();

    intakeController = TextEditingController(
      text: currentCalories.value.toString(),
    );
  }

  double get progress {
    if (targetCalories.value == 0) {
      return 0;
    }

    return (currentCalories.value / targetCalories.value)
        .clamp(0.0, 1.0);
  }

  int get percentage {
    return (progress * 100).round();
  }

  void decreaseCalories() {
    if (currentCalories.value <= 0) {
      return;
    }

    currentCalories.value =
        (currentCalories.value - 100).clamp(
      0,
      targetCalories.value * 2,
    );

    _syncTextField();
  }

  void increaseCalories() {
    currentCalories.value += 100;
    _syncTextField();
  }

  void addCalories(int amount) {
    currentCalories.value += amount;
    _syncTextField();
  }

  void updateCaloriesFromInput(String value) {
    final parsed = int.tryParse(value);

    if (parsed != null && parsed >= 0) {
      currentCalories.value = parsed;
    }
  }

  void _syncTextField() {
    intakeController.text =
        currentCalories.value.toString();

    intakeController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset: intakeController.text.length,
      ),
    );
  }

  void openFoodSourceDetail(
    FoodSourceModel source,
  ) {
    Get.toNamed(
      AppRoutes.foodSourceDetail,
      arguments: source,
    );
  }

  void addFoodSource({
    required String mealType,
    required String foodName,
    required int calories,
  }) {
    foodSources.add(
      FoodSourceModel(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(),
        mealType: mealType,
        foodName: foodName,
        calories: calories,
        emoji: _emojiForMeal(mealType),
      ),
    );

    currentCalories.value += calories;

    _syncTextField();

    Get.back();

    Get.snackbar(
      'Food added',
      '$foodName added successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _emojiForMeal(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍚';
      case 'dinner':
        return '🍽️';
      case 'drink':
        return '🥤';
      case 'snack':
        return '🍎';
      default:
        return '🍴';
    }
  }

  void cancelChanges() {
    Get.back();
  }

  void saveChanges() {
    // Later:
    // await repository.saveCalories(...);

    Get.snackbar(
      'Saved',
      'Your calorie changes have been saved.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    intakeController.dispose();
    super.onClose();
  }
}