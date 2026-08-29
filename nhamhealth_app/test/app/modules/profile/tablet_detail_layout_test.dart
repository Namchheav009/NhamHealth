import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/change_password_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/profile_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/ai_food_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/calories_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/wellness/food_nutrition_repository.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_ai_service.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/food_recommendation_service.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/change_password_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/profile_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/security_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/ai_food_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/wellness_view.dart';
import 'package:nhamhealth_flutter/core/services/app_security_service.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('profile uses overview and feed columns on a tablet', (
    tester,
  ) async {
    _setTabletSize(tester);
    final auth = AuthService();
    final controller = ProfileController(
      repository: _ProfileRepository(auth),
      communityRepository: CommunityRepository(authService: auth),
    );
    Get.put<ProfileController>(controller);

    await tester.pumpWidget(const GetMaterialApp(home: ProfileView()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('profile-tablet-layout')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.onClose();
    await tester.pump();
  });

  testWidgets('AI Food Check separates capture and results on a tablet', (
    tester,
  ) async {
    _setTabletSize(tester);
    final auth = AuthService();
    final profileRepository = ProfileRepository(authService: auth);
    final controller = AiFoodController(
      aiService: _FoodAiService(),
      nutritionRepository: FoodNutritionRepository(),
      recommendationService: FoodRecommendationService(),
      caloriesController: CaloriesController(),
      wellnessController: WellnessController(),
      profileRepository: profileRepository,
    );
    Get.put<AiFoodController>(controller);

    await tester.pumpWidget(const GetMaterialApp(home: AiFoodView()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('ai-food-tablet-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('ai-food-tablet-placeholder')),
      findsOneWidget,
    );
    final backButton = find.byKey(
      const ValueKey<String>('ai-food-back-button'),
    );
    expect(tester.getSize(backButton), const Size.square(44));
    expect(tester.getTopLeft(backButton), const Offset(68, 18));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily Wellness uses summary and AI columns on a tablet', (
    tester,
  ) async {
    _setTabletSize(tester);
    Get.put<WellnessController>(WellnessController());

    await tester.pumpWidget(const GetMaterialApp(home: WellnessView()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('wellness-tablet-layout')),
      findsOneWidget,
    );
    final backButton = find.byKey(
      const ValueKey<String>('wellness-back-button'),
    );
    expect(tester.getSize(backButton), const Size.square(44));
    expect(tester.getTopLeft(backButton), const Offset(68, 18));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password and Security uses two tablet columns', (tester) async {
    _setTabletSize(tester);
    Get.put<AppSecurityService>(_SecurityService());

    await tester.pumpWidget(const GetMaterialApp(home: SecurityView()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey<String>('security-tablet-layout')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('change password uses an intro and form tablet split', (
    tester,
  ) async {
    _setTabletSize(tester);
    Get.put<ChangePasswordController>(ChangePasswordController());

    await tester.pumpWidget(const GetMaterialApp(home: ChangePasswordView()));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('change-password-tablet-layout')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

void _setTabletSize(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1024, 768);
  addTearDown(tester.view.reset);
}

class _FoodAiService extends FoodAiService {
  @override
  Future<void> load() async {}
}

class _SecurityService extends AppSecurityService {
  @override
  Future<bool> get hasPin async => false;

  @override
  Future<bool> get biometricsEnabled async => false;

  @override
  Future<bool> canUseBiometrics() async => false;

  @override
  Future<AppBiometricKind> get biometricKind async => AppBiometricKind.generic;
}

class _ProfileRepository extends ProfileRepository {
  _ProfileRepository(AuthService authService) : super(authService: authService);

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<ProfileDashboardModel> getDashboard({DateTime? date}) async =>
      const ProfileDashboardModel(
        userId: 1,
        email: 'tablet@example.com',
        fullName: 'Tablet User',
      );

  @override
  Future<List<CommunityPost>> getMyPosts() async => const [];
}
