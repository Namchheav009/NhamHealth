import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../models/wellness_summary_model.dart';

class WellnessController extends GetxController {
  // Selected date
  final selectedDate = DateTime.now().obs;

  final nutrients = <WellnessSummaryModel>[
    const WellnessSummaryModel(
      name: 'Calories',
      current: '1420',
      target: '2000',
      unit: 'kcal',
      percentage: 71,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFF641E),
    ),
    const WellnessSummaryModel(
      name: 'Protein',
      current: '82',
      target: '120',
      unit: 'g',
      percentage: 68,
      icon: Icons.bolt_rounded,
      color: Color(0xFF00A651),
    ),
    const WellnessSummaryModel(
      name: 'Water',
      current: '6',
      target: '8',
      unit: 'glasses',
      percentage: 75,
      icon: Icons.water_drop_rounded,
      color: Color(0xFF4FC3F7),
    ),
    const WellnessSummaryModel(
      name: 'Fiber',
      current: '12',
      target: '25',
      unit: 'g',
      percentage: 48,
      icon: Icons.air_rounded,
      color: Color(0xFF9747FF),
    ),
    const WellnessSummaryModel(
      name: 'Sugar',
      current: '25',
      target: '50',
      unit: 'g',
      percentage: 56,
      icon: Icons.hexagon_rounded,
      color: Color(0xFFFF5CB8),
    ),
  ].obs;

  // =========================
  // DATE / CALENDAR
  // =========================

  Future<void> selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,

      // User can select previous dates
      firstDate: DateTime(2024),

      // Allow future dates too
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),

      helpText: 'Select Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate != null) {
      selectedDate.value = pickedDate;

      // Later when API is ready:
      // await loadWellnessByDate(pickedDate);
    }
  }

  // Check if selected date is today
  bool get isToday {
    final DateTime today = DateTime.now();
    final DateTime date = selectedDate.value;

    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // Text displayed in the button
  String get selectedDateText {
    if (isToday) {
      return 'Today';
    }

    final DateTime date = selectedDate.value;

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =========================
  // NUTRIENT NAVIGATION
  // =========================

  void openNutrientDetail(int index) {
    switch (index) {
      case 0:
        Get.toNamed(AppRoutes.calories);
        break;

      case 1:
        Get.toNamed(AppRoutes.protein);
        break;

      case 2:
        Get.toNamed(AppRoutes.water);
        break;

      case 3:
        Get.toNamed(AppRoutes.fiber);
        break;

      case 4:
        Get.toNamed(AppRoutes.sugar);
        break;
    }
  }

  // =========================
  // AI MEAL
  // =========================

  void openAiMealAutoFill() {
    Get.toNamed(AppRoutes.aiMealAutoFill);
  }
}