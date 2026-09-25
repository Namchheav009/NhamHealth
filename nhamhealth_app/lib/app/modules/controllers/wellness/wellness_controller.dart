import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_nutrient_theme.dart';
import '../../../widgets/app_alert.dart';
import '../../models/profile/profile_dashboard_model.dart';
import '../../models/wellness/wellness_summary_model.dart';
import '../../repositories/profile/profile_repository.dart';
import '../home/home_controller.dart';
import '../planner/meal_planner_controller.dart';

class WellnessController extends GetxController {
  WellnessController({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository;

  final ProfileRepository? _profileRepository;
  final isLoading = false.obs;
  int _loadVersion = 0;
  // Selected date
  final selectedDate = DateTime.now().obs;

  final nutrients =
      <WellnessSummaryModel>[
        const WellnessSummaryModel(
          name: 'Water',
          current: '0',
          target: '8',
          unit: 'glasses',
          percentage: 0,
          icon: AppNutrientTheme.waterIcon,
          color: AppNutrientTheme.waterColor,
        ),
        const WellnessSummaryModel(
          name: 'Calories',
          current: '0',
          target: '2000',
          unit: 'kcal',
          percentage: 0,
          icon: AppNutrientTheme.caloriesIcon,
          color: AppNutrientTheme.caloriesColor,
        ),
        const WellnessSummaryModel(
          name: 'Protein',
          current: '0',
          target: '120',
          unit: 'g',
          percentage: 0,
          icon: AppNutrientTheme.proteinIcon,
          color: AppNutrientTheme.proteinColor,
        ),
        const WellnessSummaryModel(
          name: 'Carbohydrates',
          current: '0',
          target: '205',
          unit: 'g',
          percentage: 0,
          icon: AppNutrientTheme.carbsIcon,
          color: AppNutrientTheme.carbsColor,
        ),
        const WellnessSummaryModel(
          name: 'Fat',
          current: '0',
          target: '78',
          unit: 'g',
          percentage: 0,
          icon: AppNutrientTheme.fatIcon,
          color: AppNutrientTheme.fatColor,
        ),
        const WellnessSummaryModel(
          name: 'Fiber',
          current: '0',
          target: '25',
          unit: 'g',
          percentage: 0,
          icon: AppNutrientTheme.fiberIcon,
          color: AppNutrientTheme.fiberColor,
        ),
        const WellnessSummaryModel(
          name: 'Sugar',
          current: '0',
          target: '50',
          unit: 'g',
          percentage: 0,
          icon: AppNutrientTheme.sugarIcon,
          color: AppNutrientTheme.sugarColor,
          isLimit: true,
        ),
      ].obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is DateTime) {
      selectedDate.value = Get.arguments as DateTime;
    }
    loadDailyWellness();
  }

  Future<void> loadDailyWellness() async {
    final repository = _profileRepository;
    if (repository == null) return;
    final version = ++_loadVersion;
    isLoading.value = true;
    try {
      final dashboard = await repository.getDashboard(date: selectedDate.value);
      if (version != _loadVersion) return;
      _applyDashboard(dashboard);
    } on Object {
      if (version != _loadVersion) return;
      AppAlert.error(
        title: 'wellness.wellness_unavailable',
        message: 'wellness.unable_to_load_your_daily_wellness_data',
      );
    } finally {
      if (version == _loadVersion) isLoading.value = false;
    }
  }

  void showSavedNutrition(
    ProfileDashboardModel dashboard, {
    required DateTime date,
  }) {
    // Ignore any dashboard request that started before this successful save.
    _loadVersion++;
    selectedDate.value = DateTime(date.year, date.month, date.day);
    isLoading.value = false;
    _applyDashboard(dashboard);
    _notifyCrossControllers(date);
  }

  void _notifyCrossControllers(DateTime date) {
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      if (_sameDay(home.selectedDay.value, date)) {
        unawaited(home.loadDashboard());
      }
    }
    if (Get.isRegistered<MealPlannerController>()) {
      final planner = Get.find<MealPlannerController>();
      unawaited(planner.loadDailyNutrition(date));
    }
  }

  /// Applies a temporary local nutrition change while the meal-status request
  /// is in flight. The next successful dashboard load replaces these values
  /// with the server totals, so retries cannot accumulate duplicate amounts.
  void applyMealNutritionDelta({
    required DateTime date,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) {
    if (!_sameDay(selectedDate.value, date)) return;
    _applyDelta('Calories', calories);
    _applyDelta('Protein', protein);
    _applyDelta('Carbohydrates', carbs);
    _applyDelta('Fat', fat);
  }

  void _applyDelta(String name, double delta) {
    final index = nutrients.indexWhere((item) => item.name == name);
    if (index < 0) return;
    final item = nutrients[index];
    final current = double.tryParse(item.current) ?? 0;
    final target = double.tryParse(item.target) ?? 0;
    final updated = (current + delta).clamp(0, double.infinity).toDouble();
    nutrients[index] = WellnessSummaryModel(
      name: item.name,
      current: _number(updated),
      target: item.target,
      unit: item.unit,
      percentage: target <= 0 ? 0 : ((updated / target) * 100).round(),
      icon: item.icon,
      color: item.color,
      isLimit: item.isLimit,
    );
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void _applyDashboard(ProfileDashboardModel dashboard) {
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
      'Carbohydrates',
      dashboard.carbs?.current ?? 0,
      dashboard.carbs?.goal ?? 205,
    );
    _setNutrient('Fat', dashboard.fat?.current ?? 0, dashboard.fat?.goal ?? 78);
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
      isLimit: item.isLimit,
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

      helpText: 'planner.select_date'.tr,
      cancelText: 'common.cancel'.tr,
      confirmText: 'planner.select'.tr,
    );

    if (pickedDate != null) {
      selectedDate.value = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      await loadDailyWellness();
    }
  }

  Future<void> goToToday() async {
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
    await loadDailyWellness();
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
      return 'common.today'.tr;
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
      'Carbohydrates' => AppRoutes.carbs,
      'Fat' => AppRoutes.fat,
      'Water' => AppRoutes.water,
      'Fiber' => AppRoutes.fiber,
      'Sugar' => AppRoutes.sugar,
      _ => null,
    };

    if (route == null) return;
    await Get.toNamed<void>(route, arguments: selectedDate.value);
    await loadDailyWellness();
    _notifyCrossControllers(selectedDate.value);
  }

  // =========================
  // AI MEAL
  // =========================

  Future<void> openMealAutoFill() async {
    await Get.toNamed<void>(AppRoutes.aiFood);
    await loadDailyWellness();
    _notifyCrossControllers(selectedDate.value);
  }

  void addNutrition({
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required double sugar,
    double water = 0,
    double fiber = 0,
  }) {
    _incrementNutrient('Calories', calories.toDouble());
    _incrementNutrient('Protein', protein);
    _incrementNutrient('Carbohydrates', carbs);
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
      isLimit: item.isLimit,
    );
  }
}
