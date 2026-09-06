import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

const savedDashboard = ProfileDashboardModel(
  userId: 1,
  email: '',
  calories: ProfileProgressModel(current: 840, goal: 2000),
  protein: ProfileProgressModel(current: 30, goal: 120),
  carbs: ProfileProgressModel(current: 90, goal: 205),
  fat: ProfileProgressModel(current: 20, goal: 78),
  water: ProfileProgressModel(current: 3, goal: 8),
  fiber: ProfileProgressModel(current: 8, goal: 25),
  sugar: ProfileProgressModel(current: 12, goal: 50),
);

void main() {
  test(
    'saved nutrition selects today and shows server totals without adding twice',
    () {
      final controller = WellnessController();
      controller.selectedDate.value = DateTime(2024);
      final today = DateTime.now();
      controller.showSavedNutrition(savedDashboard, date: today);
      controller.showSavedNutrition(savedDashboard, date: today);

      expect(controller.isToday, isTrue);
      expect(controller.nutrients.map((item) => item.current), [
        '840',
        '30',
        '90',
        '20',
        '3',
        '8',
        '12',
      ]);
      expect(controller.nutrients.first.percentage, 42);
    },
  );

  test(
    'older dashboard response cannot overwrite a successful food save',
    () async {
      final repository = DelayedProfileRepository();
      final controller = WellnessController(profileRepository: repository);
      final loading = controller.loadDailyWellness();
      controller.showSavedNutrition(savedDashboard, date: DateTime.now());
      repository.response.complete(
        const ProfileDashboardModel(userId: 1, email: ''),
      );
      await loading;

      expect(controller.nutrients.first.current, '840');
      expect(controller.isLoading.value, isFalse);
    },
  );
}

class DelayedProfileRepository extends ProfileRepository {
  DelayedProfileRepository() : super(authService: AuthService());

  final response = Completer<ProfileDashboardModel>();

  @override
  Future<ProfileDashboardModel> getDashboard({DateTime? date}) =>
      response.future;
}
