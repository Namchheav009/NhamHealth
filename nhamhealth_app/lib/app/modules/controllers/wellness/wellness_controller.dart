import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';

import '../../../routes/app_routes.dart';
import '../../models/wellness/wellness_summary_model.dart';
import '../../repositories/profile/profile_repository.dart';

class WellnessController extends GetxController {
  WellnessController({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository;

  final ProfileRepository? _profileRepository;
  final isLoading = false.obs;
  // Selected date
  final selectedDate = DateTime.now().obs;

  final nutrients =
      <WellnessSummaryModel>[
        const WellnessSummaryModel(
          name: 'Calories',
          current: '0',
          target: '2000',
          unit: 'kcal',
          percentage: 0,
          icon: Icons.local_fire_department_rounded,
          color: Color(0xFFFF641E),
        ),
        const WellnessSummaryModel(
          name: 'Protein',
          current: '0',
          target: '120',
          unit: 'g',
          percentage: 0,
          icon: Icons.bolt_rounded,
          color: Color(0xFF00A651),
        ),
        const WellnessSummaryModel(
          name: 'Fat',
          current: '0',
          target: '78',
          unit: 'g',
          percentage: 0,
          icon: Icons.opacity_rounded,
          color: Color(0xFFF43F5E),
        ),
        const WellnessSummaryModel(
          name: 'Water',
          current: '0',
          target: '8',
          unit: 'glasses',
          percentage: 0,
          icon: Icons.water_drop_rounded,
          color: Color(0xFF4FC3F7),
        ),
        const WellnessSummaryModel(
          name: 'Fiber',
          current: '0',
          target: '25',
          unit: 'g',
          percentage: 0,
          icon: Icons.air_rounded,
          color: Color(0xFF9747FF),
        ),
        const WellnessSummaryModel(
          name: 'Sugar',
          current: '0',
          target: '50',
          unit: 'g',
          percentage: 0,
          icon: Icons.hexagon_rounded,
          color: Color(0xFFFF5CB8),
        ),
      ].obs;

  @override
  void onInit() {
    super.onInit();
    loadDailyWellness();
  }

  Future<void> loadDailyWellness() async {
    final repository = _profileRepository;
    if (repository == null || isLoading.value) return;
    isLoading.value = true;
    try {
      final dashboard = await repository.getDashboard(date: selectedDate.value);
      _setNutrient(
        'Calories',
        dashboard.calories?.current ?? 0,
        dashboard.calories?.goal ?? 2000,
      );
      _setNutrient(
        'Protein',
        dashboard.protein?.current ?? 0,
        dashboard.protein?.goal ?? 120,
      );
      _setNutrient(
        'Fat',
        dashboard.fat?.current ?? 0,
        dashboard.fat?.goal ?? 78,
      );
      _setNutrient(
        'Water',
        dashboard.water?.current ?? 0,
        dashboard.water?.goal ?? 8,
      );
      _setNutrient(
        'Fiber',
        dashboard.fiber?.current ?? 0,
        dashboard.fiber?.goal ?? 25,
      );
      _setNutrient(
        'Sugar',
        dashboard.sugar?.current ?? 0,
        dashboard.sugar?.goal ?? 50,
      );
    } on Object {
      AppAlert.error(
        title: 'Wellness unavailable',
        message: 'Unable to load your daily wellness data.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _setNutrient(String name, double current, double target) {
    final index = nutrients.indexWhere((item) => item.name == name);
    if (index < 0) return;
    final item = nutrients[index];
    nutrients[index] = WellnessSummaryModel(
      name: item.name,
      current: _number(current),
      target: _number(target),
      unit: item.unit,
      percentage: target <= 0 ? 0 : ((current / target) * 100).round(),
      icon: item.icon,
      color: item.color,
    );
  }

  String _number(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

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
      lastDate: DateTime.now().add(const Duration(days: 365)),

      helpText: 'Select Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (pickedDate != null) {
      selectedDate.value = pickedDate;
      await loadDailyWellness();
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

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =========================
  // NUTRIENT NAVIGATION
  // =========================

  Future<void> openNutrientDetails(String nutrientName) async {
    final route = switch (nutrientName) {
      'Calories' => AppRoutes.calories,
      'Protein' => AppRoutes.protein,
      'Water' => AppRoutes.water,
      'Fiber' => AppRoutes.fiber,
      'Sugar' => AppRoutes.sugar,
      _ => null,
    };

    if (route == null) return;
    await Get.toNamed<void>(route);
    await loadDailyWellness();
  }

  // =========================
  // AI MEAL
  // =========================

  Future<void> openMealAutoFill() async {
    await Get.toNamed<void>(AppRoutes.aiFood);
  }

  void addNutrition({
    required int calories,
    required double protein,
    required double fat,
    required double sugar,
    double water = 0,
    double fiber = 0,
  }) {
    _incrementNutrient('Calories', calories.toDouble());
    _incrementNutrient('Protein', protein);
    _incrementNutrient('Fat', fat);
    _incrementNutrient('Sugar', sugar);
    _incrementNutrient('Water', water);
    _incrementNutrient('Fiber', fiber);
  }

  void _incrementNutrient(String name, double amount) {
    final index = nutrients.indexWhere((item) => item.name == name);
    if (index < 0) return;
    final item = nutrients[index];
    final current = (double.tryParse(item.current) ?? 0) + amount;
    final target = double.tryParse(item.target) ?? 1;
    nutrients[index] = WellnessSummaryModel(
      name: item.name,
      current:
          current % 1 == 0
              ? current.toInt().toString()
              : current.toStringAsFixed(1),
      target: item.target,
      unit: item.unit,
      percentage: ((current / target) * 100).round(),
      icon: item.icon,
      color: item.color,
    );
  }
}
