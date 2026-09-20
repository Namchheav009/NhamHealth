import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/edit_profile_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/profile_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_person_profile.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/edit_profile_view.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().onClose();
    }
    Get.reset();
  });

  void setDeviceDimensions(WidgetTester tester, {required double width, required double height}) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
  }

  ProfileController setupControllers() {
    final auth = AuthService();
    final profileController = ProfileController(
      repository: _ProfileRepository(auth),
      communityRepository: _CommunityRepository(auth),
    );
    Get.put<ProfileController>(profileController);
    final editProfileController = EditProfileController(
      profileController: profileController,
    );
    Get.put<EditProfileController>(editProfileController);
    return profileController;
  }

  testWidgets(
    'EditProfileView renders two-column layout on landscape tablet (1024x768)',
    (tester) async {
      setDeviceDimensions(tester, width: 1024, height: 768);
      final profileController = setupControllers();

      await tester.pumpWidget(const GetMaterialApp(home: EditProfileView()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('edit-profile-tablet-two-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('edit-profile-single-column')),
        findsNothing,
      );
      expect(find.byType(EditProfileView), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      profileController.onClose();
      await tester.pump();
    },
  );

  testWidgets(
    'EditProfileView renders centered single-column layout on Galaxy Tab portrait (800x1280)',
    (tester) async {
      setDeviceDimensions(tester, width: 800, height: 1280);
      final profileController = setupControllers();

      await tester.pumpWidget(const GetMaterialApp(home: EditProfileView()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('edit-profile-single-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('edit-profile-tablet-two-column')),
        findsNothing,
      );

      final singleColumnWidget = tester.firstWidget<ConstrainedBox>(
        find.ancestor(
          of: find.byKey(const ValueKey<String>('edit-profile-single-column')),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(singleColumnWidget.constraints.maxWidth, greaterThan(600.0));

      await tester.pumpWidget(const SizedBox.shrink());
      profileController.onClose();
      await tester.pump();
    },
  );

  testWidgets(
    'EditProfileView renders centered single-column layout on iPad portrait (768x1024)',
    (tester) async {
      setDeviceDimensions(tester, width: 768, height: 1024);
      final profileController = setupControllers();

      await tester.pumpWidget(const GetMaterialApp(home: EditProfileView()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('edit-profile-single-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('edit-profile-tablet-two-column')),
        findsNothing,
      );

      final singleColumnWidget = tester.firstWidget<ConstrainedBox>(
        find.ancestor(
          of: find.byKey(const ValueKey<String>('edit-profile-single-column')),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(singleColumnWidget.constraints.maxWidth, greaterThan(600.0));

      await tester.pumpWidget(const SizedBox.shrink());
      profileController.onClose();
      await tester.pump();
    },
  );

  testWidgets(
    'EditProfileView renders single-column layout on mobile phone (390x844)',
    (tester) async {
      setDeviceDimensions(tester, width: 390, height: 844);
      final profileController = setupControllers();

      await tester.pumpWidget(const GetMaterialApp(home: EditProfileView()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('edit-profile-single-column')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('edit-profile-tablet-two-column')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      profileController.onClose();
      await tester.pump();
    },
  );
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

class _CommunityRepository extends CommunityRepository {
  _CommunityRepository(AuthService authService) : super(authService: authService);

  @override
  Future<CommunityPersonProfile> getPersonProfile(int userId) async =>
      const CommunityPersonProfile(
        id: 1,
        name: 'Tablet User',
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
