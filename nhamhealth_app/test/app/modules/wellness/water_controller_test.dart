import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/water_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  test('loads and adds water for the selected wellness date', () async {
    final repository = _WaterProfileRepository();
    final controller = WaterController(
      repository: repository,
      initialDate: DateTime(2026, 9, 6, 17, 30),
    );

    await controller.loadWater();
    expect(controller.currentGlasses.value, 3);
    expect(controller.targetGlasses.value, 8);
    expect(controller.percentage, 38);

    controller.selectGlasses(2);
    await controller.addSelectedWater();

    expect(repository.addedWater, 2);
    expect(repository.requestedDate, DateTime(2026, 9, 6));
    expect(controller.currentGlasses.value, 5);
    expect(controller.selectedGlasses.value, 1);
  });

  test('keeps a water entry inside the supported range', () {
    final controller = WaterController(repository: _WaterProfileRepository());

    controller.selectGlasses(0);
    expect(controller.selectedGlasses.value, 1);
    controller.selectGlasses(99);
    expect(
      controller.selectedGlasses.value,
      WaterController.maximumGlassesPerEntry,
    );
  });
}

class _WaterProfileRepository extends ProfileRepository {
  _WaterProfileRepository() : super(authService: AuthService());

  double? addedWater;
  DateTime? requestedDate;

  @override
  Future<ProfileDashboardModel> getDashboard({DateTime? date}) async {
    requestedDate = date;
    return _dashboard(3);
  }

  @override
  Future<ProfileDashboardModel> addDailyNutrition({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? water,
    double? fiber,
    double? sugar,
    String? aiRecommendation,
    DateTime? date,
  }) async {
    addedWater = water;
    requestedDate = date;
    return _dashboard(3 + (water ?? 0));
  }

  ProfileDashboardModel _dashboard(double water) => ProfileDashboardModel(
    userId: 1,
    email: 'water@example.com',
    water: ProfileProgressModel(current: water, goal: 8),
  );
}
