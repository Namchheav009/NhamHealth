import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/water_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/water_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('water page follows the responsive hydration layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);

    Get.put<WaterController>(
      WaterController(repository: _WaterViewRepository()),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const WaterView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('water-progress-hero')), findsOneWidget);
    expect(find.byKey(const ValueKey('water-quick-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('water-quick-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-water-button')), findsOneWidget);
    expect(find.text('Stay hydrated, stay healthy'), findsNothing);
    expect(find.text("Today's total"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WaterViewRepository extends ProfileRepository {
  _WaterViewRepository() : super(authService: AuthService());

  @override
  Future<ProfileDashboardModel> getDashboard({DateTime? date}) async =>
      const ProfileDashboardModel(
        userId: 1,
        email: 'water@example.com',
        water: ProfileProgressModel(current: 3, goal: 8),
      );
}
