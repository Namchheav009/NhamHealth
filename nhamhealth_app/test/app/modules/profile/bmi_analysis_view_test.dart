import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/profile_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_person_profile.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/bmi_analysis_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> pumpPage(
    WidgetTester tester, {
    required int age,
    Locale locale = const Locale('en', 'US'),
  }) async {
    final auth = AuthService();
    Get.put<ProfileController>(
      ProfileController(
        repository: _ProfileRepository(auth, age: age),
        communityRepository: _CommunityRepository(auth),
      ),
    );
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        home: const BmiAnalysisView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await Get.delete<ProfileController>(force: true);
    await tester.pump();
  }

  testWidgets('shows adult BMI analysis and nutrition action', (tester) async {
    await pumpPage(tester, age: 28);

    expect(find.byKey(const ValueKey('bmi-result-card')), findsOneWidget);
    expect(find.text('22.5'), findsOneWidget);
    expect(find.text('Healthy weight range'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('bmi-nutrition-summary-button')),
      findsOneWidget,
    );
    await disposePage(tester);
  });

  testWidgets('uses neutral guidance for a user below 18', (tester) async {
    await pumpPage(tester, age: 16);

    expect(find.text('Use a growth reference'), findsOneWidget);
    expect(find.textContaining('age- and sex-specific'), findsOneWidget);
    expect(find.text('Foods that support healthy growth'), findsOneWidget);
    await disposePage(tester);
  });

  testWidgets('renders Khmer BMI content', (tester) async {
    await pumpPage(tester, age: 28, locale: const Locale('km', 'KH'));

    expect(find.text('ការវិភាគ BMI'), findsOneWidget);
    expect(find.text('កម្រិតទម្ងន់សមស្រប'), findsOneWidget);
    await disposePage(tester);
  });
}

class _ProfileRepository extends ProfileRepository {
  _ProfileRepository(AuthService authService, {required this.age})
    : super(authService: authService);

  final int age;

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<ProfileDashboardModel> getDashboard({DateTime? date}) async =>
      ProfileDashboardModel(
        userId: 1,
        email: 'bmi@example.com',
        fullName: 'BMI User',
        age: age,
        heightCm: 170,
        weightKg: 65,
      );

  @override
  Future<List<CommunityPost>> getMyPosts() async => const [];
}

class _CommunityRepository extends CommunityRepository {
  _CommunityRepository(AuthService authService)
    : super(authService: authService);

  @override
  Future<CommunityPersonProfile> getPersonProfile(int userId) async =>
      const CommunityPersonProfile(
        id: 1,
        name: 'BMI User',
        avatarUrl: '',
        role: 'Member',
        headline: '',
        joinedLabel: 'Jan 2025',
        verified: false,
        posts: 0,
        followers: 0,
        following: 0,
        isFollowing: false,
        followsViewer: false,
      );
}
