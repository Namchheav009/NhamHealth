import 'package:get/get.dart';

import '../../../widgets/app_alert.dart';
import '../../models/profile/profile_dashboard_model.dart';
import '../../repositories/profile/profile_repository.dart';

class WaterController extends GetxController {
  WaterController({
    required ProfileRepository repository,
    DateTime? initialDate,
  }) : _repository = repository,
       date = _dateOnly(initialDate ?? DateTime.now());

  static const int millilitersPerGlass = 250;
  static const int maximumGlassesPerEntry = 12;

  final ProfileRepository _repository;
  final DateTime date;

  final currentGlasses = 0.0.obs;
  final targetGlasses = 8.0.obs;
  final selectedGlasses = 1.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadWater();
  }

  double get progress =>
      targetGlasses.value <= 0
          ? 0
          : (currentGlasses.value / targetGlasses.value).clamp(0.0, 1.0);

  int get percentage => (progress * 100).round();

  double get remainingGlasses =>
      (targetGlasses.value - currentGlasses.value).clamp(0, double.infinity);

  int get selectedMilliliters => selectedGlasses.value * millilitersPerGlass;

  Future<void> loadWater() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      _applyDashboard(await _repository.getDashboard(date: date));
    } on Object catch (error) {
      errorMessage.value = _message(error, 'Unable to load water data.');
    } finally {
      isLoading.value = false;
    }
  }

  void selectGlasses(int value) {
    selectedGlasses.value = value.clamp(1, maximumGlassesPerEntry);
  }

  void decreaseSelection() => selectGlasses(selectedGlasses.value - 1);

  void increaseSelection() => selectGlasses(selectedGlasses.value + 1);

  Future<void> addSelectedWater() async {
    if (isSaving.value) return;
    isSaving.value = true;
    errorMessage.value = null;
    try {
      final amount = selectedGlasses.value.toDouble();
      final dashboard = await _repository.addDailyNutrition(
        water: amount,
        date: date,
      );
      _applyDashboard(dashboard);
      await AppAlert.success(
        title: 'wellness.water_added_today',
        message: (selectedGlasses.value == 1
                ? 'wellness.water_count_added_one'
                : 'wellness.water_count_added_many')
            .trParams({'count': '${selectedGlasses.value}'}),
      );
      selectedGlasses.value = 1;
    } on Object catch (error) {
      final message = _message(
        error,
        'wellness.unable_to_add_water_please_try_again',
      );
      errorMessage.value = message;
      await AppAlert.error(
        title: 'wellness.water_unavailable',
        message: message,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void _applyDashboard(ProfileDashboardModel dashboard) {
    currentGlasses.value = dashboard.water?.current ?? 0;
    final goal = dashboard.water?.goal ?? 8;
    targetGlasses.value = goal > 0 ? goal : 8;
  }

  String _message(Object error, String fallback) {
    if (error is ProfileException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    return fallback;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
