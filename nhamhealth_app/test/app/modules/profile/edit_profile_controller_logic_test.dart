import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/edit_profile_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/profile_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_person_profile.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(AuthService authService) : super(authService: authService);

  @override
  Future<int> getUnreadNotificationCount() async => 0;

  @override
  Future<ProfileDashboardModel> getDashboard({DateTime? date}) async =>
      const ProfileDashboardModel(
        userId: 1,
        email: 'test@example.com',
        fullName: 'Test User',
        heightCm: 175,
        weightKg: 70,
        age: 25,
      );

  @override
  Future<List<CommunityPost>> getMyPosts() async => const [];
}

class _FakeCommunityRepository extends CommunityRepository {
  _FakeCommunityRepository(AuthService authService) : super(authService: authService);

  @override
  Future<CommunityPersonProfile> getPersonProfile(int userId) async =>
      const CommunityPersonProfile(
        id: 1,
        name: 'Test User',
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

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    if (Get.isRegistered<EditProfileController>()) {
      Get.delete<EditProfileController>();
    }
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().onClose();
    }
    Get.reset();
  });

  EditProfileController createController({
    String fullName = 'Test User',
    String email = 'test@example.com',
    double height = 175,
    double weight = 70,
    int age = 25,
    DateTime? dob,
  }) {
    final auth = AuthService();
    final profileController = ProfileController(
      repository: _FakeProfileRepository(auth),
      communityRepository: _FakeCommunityRepository(auth),
    );
    profileController.name.value = fullName;
    profileController.email.value = email;
    profileController.height.value = height;
    profileController.weight.value = weight;
    profileController.age.value = age;
    profileController.dashboard.value = ProfileDashboardModel(
      userId: 1,
      fullName: fullName,
      email: email,
      heightCm: height,
      weightKg: weight,
      age: age,
      dateOfBirth: dob ?? DateTime(2000, 1, 1),
    );
    Get.put<ProfileController>(profileController);

    final editProfileController = EditProfileController(
      profileController: profileController,
    );
    Get.put<EditProfileController>(editProfileController);
    return editProfileController;
  }

  group('EditProfileController real-time logic tests', () {
    test('initializes all 6 TextEditingControllers with dashboard values', () {
      final controller = createController(
        fullName: 'Visal Dev',
        email: 'visal@nhamhealth.com',
        height: 180,
        weight: 75,
        age: 26,
      );

      expect(controller.nameController.text, 'Visal Dev');
      expect(controller.emailController.text, 'visal@nhamhealth.com');
      expect(controller.heightController.text, '180');
      expect(controller.weightController.text, '75');
      expect(controller.ageController.text, '26');
      expect(controller.fullName.value, 'Visal Dev');
      expect(controller.email.value, 'visal@nhamhealth.com');
      expect(controller.height.value, 180.0);
      expect(controller.weight.value, 75.0);
      expect(controller.age.value, 26);
    });

    test('real-time height & weight update triggers BMI recalculation', () {
      final controller = createController(height: 170, weight: 65);

      // BMI for 170cm, 65kg = 65 / (1.7 * 1.7) = 22.49...
      expect(controller.bmi.toStringAsFixed(1), '22.5');

      // Update height in real time
      controller.updateHeight('180');
      expect(controller.height.value, 180.0);
      // BMI for 180cm, 65kg = 65 / (1.8 * 1.8) = 20.06...
      expect(controller.bmi.toStringAsFixed(1), '20.1');

      // Update weight in real time
      controller.updateWeight('80');
      expect(controller.weight.value, 80.0);
      // BMI for 180cm, 80kg = 80 / (1.8 * 1.8) = 24.69...
      expect(controller.bmi.toStringAsFixed(1), '24.7');
    });

    test('updateAge immediately calculates corresponding dateOfBirth', () {
      final controller = createController(age: 20);

      controller.updateAge('30');
      expect(controller.age.value, 30);
      expect(controller.dateOfBirth.value, isNotNull);
      final expectedYear = DateTime.now().year - 30;
      expect(controller.dateOfBirth.value!.year, expectedYear);
    });

    test('updateFullName and updateEmail reflect immediately in reactive fields', () {
      final controller = createController();

      controller.updateFullName('Jane Doe');
      expect(controller.fullName.value, 'Jane Doe');

      controller.updateEmail('jane@nhamhealth.com');
      expect(controller.email.value, 'jane@nhamhealth.com');
    });

    test('genderDisplay handles Male, Female, and Prefer not to say correctly', () {
      final controller = createController();

      controller.gender.value = 'Male';
      expect(controller.genderDisplay, isNotEmpty);

      controller.gender.value = 'Female';
      expect(controller.genderDisplay, isNotEmpty);

      controller.gender.value = 'Prefer not to say';
      expect(controller.genderDisplay, isNotEmpty);
    });
  });
}
