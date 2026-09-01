import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';

import '../../models/wellness/food_source_model.dart';
import '../../../routes/app_routes.dart';

class FoodSourceDetailController extends GetxController {
  late final FoodSourceModel source;

  final selectedSize = 'Medium'.obs;
  final showManualEditor = false.obs;

  final amountController = TextEditingController();

  // base amount for current item
  final baseAmount = 350.obs; // ml for drink example
  final currentAmount = 350.obs;
  final currentCalories = 280.obs;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments;

    if (arguments is FoodSourceModel) {
      source = arguments;

      currentCalories.value = arguments.calories;

      amountController.text = currentAmount.value.toString();
    } else {
      // This can happen after a web hot restart / refresh.
      Future.microtask(() {
        Get.offNamed(AppRoutes.calories);

        AppAlert.error(
          title: 'Food not found',
          message: 'Please select a food source again.',
        );
      });
    }

    // source = Get.arguments as FoodSourceModel;

    // currentCalories.value = source.calories;
    // amountController.text = currentAmount.value.toString();
  }

  double get progress => (currentCalories.value / 1400).clamp(0.0, 1.0);

  int get percentOfTodayCalories {
    return ((currentCalories.value / 1400) * 100).round();
  }

  // estimated values
  int get estimatedProtein => (currentCalories.value * 0.085).round();
  int get estimatedFiber => (currentCalories.value * 0.01).round();
  int get estimatedSugar => (currentCalories.value * 0.10).round();

  String get hydrationTip {
    return currentAmount.value >= 350
        ? 'Drink 1 glass water'
        : 'Drink 1/2 glass water';
  }

  void selectSize(String size) {
    selectedSize.value = size;
    showManualEditor.value = false;

    switch (size) {
      case 'Small':
        _applyCaloriesAndAmount(
          calories: (source.calories * 0.8).round(),
          amount: (baseAmount.value * 0.8).round(),
        );
        break;

      case 'Medium':
        _applyCaloriesAndAmount(
          calories: source.calories,
          amount: baseAmount.value,
        );
        break;

      case 'Large':
        _applyCaloriesAndAmount(
          calories: (source.calories * 1.25).round(),
          amount: (baseAmount.value * 1.25).round(),
        );
        break;

      case 'Not sure':
        _applyCaloriesAndAmount(
          calories: source.calories,
          amount: baseAmount.value,
        );
        break;
    }
  }

  void toggleManualEditor() {
    showManualEditor.value = !showManualEditor.value;
  }

  void decreaseAmount() {
    if (currentAmount.value <= 50) return;

    currentAmount.value -= 50;
    _syncManualAmount();
  }

  void increaseAmount() {
    currentAmount.value += 50;
    _syncManualAmount();
  }

  void addAmount(int amount) {
    currentAmount.value += amount;
    _syncManualAmount();
  }

  void updateAmountFromInput(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      currentAmount.value = parsed;
      _recalculateCaloriesFromAmount();
    }
  }

  void _syncManualAmount() {
    amountController.text = currentAmount.value.toString();
    amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: amountController.text.length),
    );
    _recalculateCaloriesFromAmount();
  }

  void _recalculateCaloriesFromAmount() {
    final ratio = currentAmount.value / baseAmount.value;
    currentCalories.value = (source.calories * ratio).round();
  }

  void _applyCaloriesAndAmount({required int calories, required int amount}) {
    currentCalories.value = calories;
    currentAmount.value = amount;
    amountController.text = amount.toString();
  }

  void reanalyzeWithAi() {
    AppAlert.success(
      title: 'AI Re-analysis',
      message: 'Re-analyzing your food amount...',
    );
  }

  void saveChanges() {
    AppAlert.success(
      title: 'Saved',
      message: 'Food detail changes saved successfully.',
    );
  }

  void cancelChanges() {
    Get.back();
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }
}
