import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_comment.dart';
import '../../models/community/community_person.dart';
import '../../models/community/community_types.dart';
import '../../models/profile/profile_dashboard_model.dart';
import '../../repositories/community/community_repository.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../views/profile/edit_profile_view.dart';
import 'edit_profile_controller.dart';
import 'setting_controller.dart';
import '../../../widgets/privacy_auth_dialog.dart';

class ProfileController extends GetxController {
  ProfileController({
    required ProfileRepository repository,
    required CommunityRepository communityRepository,
  }) : _repository = repository,
       _communityRepository = communityRepository;

  final ProfileRepository _repository;
  final CommunityRepository _communityRepository;
  String? _uploadedProfileImagePath;
  final selectedNavIndex = 4.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final Rxn<AuthenticatedUser> authenticatedUser = Rxn<AuthenticatedUser>();
  final Rxn<ProfileDashboardModel> dashboard = Rxn<ProfileDashboardModel>();
  final posts = <CommunityPost>[].obs;
  final likingPostIds = <String>{}.obs;
  final commentsByPost = <String, List<CommunityComment>>{}.obs;
  final friends = <CommunityPerson>[].obs;
  final unreadNotificationCount = 0.obs;
  Timer? _notificationCountTimer;

  final name = 'My Profile'.obs;
  final email = ''.obs;
  final membership = 'WellBite Member'.obs;
  final profileImagePath = ''.obs;
  final insight = "Start logging meals to build today's progress.".obs;

  final age = 0.obs;
  final height = 0.obs;
  final weight = 0.obs;

  double get bmi {
    final heightInMeters = height.value / 100;
    if (heightInMeters <= 0) return 0;
    return weight.value / (heightInMeters * heightInMeters);
  }

  String get bmiStatus {
    if (height.value <= 0 || weight.value <= 0) return 'Not set';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  final calories = 0.obs;
  final caloriesGoal = 2000.obs;

  final protein = 0.obs;
  final proteinGoal = 120.obs;

  final water = 0.obs;
  final waterGoal = 8.obs;

  double get caloriesProgress =>
      caloriesGoal.value <= 0 ? 0 : calories.value / caloriesGoal.value;

  double get proteinProgress =>
      proteinGoal.value <= 0 ? 0 : protein.value / proteinGoal.value;

  double get waterProgress =>
      waterGoal.value <= 0 ? 0 : water.value / waterGoal.value;

  @override
  void onInit() {
    super.onInit();
    final routeUser = Get.arguments;
    if (routeUser is AuthenticatedUser) {
      _applyUser(routeUser);
    }
    loadProfile();
    loadUnreadNotificationCount();
    _notificationCountTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadUnreadNotificationCount(),
    );
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      unreadNotificationCount.value =
          await _repository.getUnreadNotificationCount();
    } on Object {
      // Preserve the last count if the network is temporarily unavailable.
    }
  }

  Future<void> loadProfile() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait<dynamic>([
        _repository.getDashboard(),
        _repository.getMyPosts(),
      ]);
      _applyDashboard(results[0] as ProfileDashboardModel);
      posts.assignAll(results[1] as List<CommunityPost>);
    } on ProfileException catch (error) {
      errorMessage.value = error.message;
    } on Object {
      errorMessage.value = 'Unable to load your profile. Pull down to retry.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() => loadProfile();

  Future<CommunityPost> updatePost({
    required CommunityPost post,
    String? mealName,
    required String description,
    int? cookingTimeMinutes,
    int? servings,
    String? difficulty,
    List<MealPostIngredient>? ingredients,
    List<MealPostStep>? steps,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    bool removeImage = false,
    List<int> tagIds = const [],
  }) async {
    final updated = await _communityRepository.updatePost(
      postId: post.id,
      mealName: mealName ?? post.mealName,
      description: description,
      cookingTimeMinutes: cookingTimeMinutes ?? post.cookingTimeMinutes ?? 0,
      servings: servings ?? post.servings ?? 0,
      difficulty: difficulty ?? post.difficulty,
      ingredients: ingredients ?? post.ingredients,
      steps: steps ?? post.steps,
      imageBytes: imageBytes,
      visibility: visibility,
      allowComments: allowComments,
      allowReplies: allowReplies,
      removeImage: removeImage,
      tagIds: tagIds,
    );
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index >= 0) posts[index] = updated;
    return updated;
  }

  Future<void> deletePost(CommunityPost post) async {
    await _repository.deletePost(post.id);
    posts.removeWhere((item) => item.id == post.id);
  }

  Future<void> togglePostLike(CommunityPost post) async {
    if (!likingPostIds.add(post.id)) return;
    try {
      // Profile posts and Community feed posts share this endpoint, so their
      // like totals and current-user state always come from one source.
      final updated = await _communityRepository.toggleLike(post.id);
      _replacePost(updated);
      posts.refresh();
    } on Object catch (error) {
      Get.snackbar('Could not update like', error.toString());
    } finally {
      likingPostIds.remove(post.id);
    }
  }

  List<CommunityComment> commentsFor(String postId) =>
      commentsByPost[postId] ?? const [];

  Future<void> loadComments(CommunityPost post) async {
    commentsByPost[post.id] = await _communityRepository.getComments(post.id);
  }

  Future<void> addComment(
    CommunityPost post,
    String text, {
    String? parentCommentId,
  }) async {
    final comment = await _communityRepository.addComment(
      post.id,
      text,
      parentCommentId: parentCommentId,
    );
    commentsByPost[post.id] = [...commentsFor(post.id), comment];
    post.comments += 1;
    posts.refresh();
  }

  Future<void> loadFriends() async {
    final people = await _communityRepository.getPeople();
    friends.assignAll(people[FriendsView.friends] ?? const []);
  }

  Future<void> sharePost(
    CommunityPost post, {
    List<String> recipientIds = const [],
  }) async {
    await _communityRepository.sharePost(post.id, recipientIds: recipientIds);
    post.shares += recipientIds.isEmpty ? 1 : recipientIds.length;
    posts.refresh();
  }

  /// Creates a shared post for the signed-in user. It belongs in the profile
  /// list immediately, just as it does in the Community feed.
  Future<CommunityPost> sharePostToFeed(
    CommunityPost post, {
    String message = '',
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
  }) async {
    final shared = await _communityRepository.sharePostToFeed(
      post.id,
      message: message,
      visibility: visibility,
    );
    post.shares += 1;
    posts.insert(0, shared);
    return shared;
  }

  Future<void> addPost({
    required String mealName,
    required String description,
    required int cookingTimeMinutes,
    required int servings,
    required String difficulty,
    required List<MealPostIngredient> ingredients,
    required List<MealPostStep> steps,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    List<int> tagIds = const [],
  }) async {
    final post = await _communityRepository.createPost(
      mealName: mealName,
      description: description,
      cookingTimeMinutes: cookingTimeMinutes,
      servings: servings,
      difficulty: difficulty,
      ingredients: ingredients,
      steps: steps,
      imageBytes: imageBytes,
      visibility: visibility,
      allowComments: allowComments,
      allowReplies: allowReplies,
      tagIds: tagIds,
    );
    posts.insert(0, post);
  }

  void _replacePost(CommunityPost updated) {
    final index = posts.indexWhere((item) => item.id == updated.id);
    if (index >= 0) posts[index] = updated;
  }

  void _applyUser(AuthenticatedUser user) {
    authenticatedUser.value = user;
    name.value = user.displayName;
    email.value = user.email;
    errorMessage.value = null;
  }

  void _applyDashboard(ProfileDashboardModel dashboard) {
    this.dashboard.value = dashboard;
    final fullName = dashboard.fullName?.trim();
    name.value =
        fullName == null || fullName.isEmpty
            ? dashboard.email.split('@').first
            : fullName;
    email.value = dashboard.email;
    membership.value =
        dashboard.membership?.trim().isNotEmpty == true
            ? dashboard.membership!.trim()
            : 'WellBite Member';
    if (dashboard.age != null) age.value = dashboard.age!;
    if (dashboard.heightCm != null) height.value = dashboard.heightCm!.round();
    if (dashboard.weightKg != null) weight.value = dashboard.weightKg!.round();
    if (dashboard.calories != null) {
      calories.value = dashboard.calories!.current.round();
      caloriesGoal.value = dashboard.calories!.goal.round();
    }
    if (dashboard.protein != null) {
      protein.value = dashboard.protein!.current.round();
      proteinGoal.value = dashboard.protein!.goal.round();
    }
    if (dashboard.water != null) {
      water.value = dashboard.water!.current.round();
      waterGoal.value = dashboard.water!.goal.round();
    }
    final dashboardInsight = dashboard.insight?.trim();
    if (dashboardInsight != null && dashboardInsight.isNotEmpty) {
      insight.value = dashboardInsight;
    } else if (caloriesGoal.value > 0) {
      final percent = (caloriesProgress * 100).clamp(0, 999).round();
      insight.value = "You've hit $percent% of your calories goal today.";
    }
    authenticatedUser.value = AuthenticatedUser(
      id: dashboard.userId,
      email: dashboard.email,
      role: authenticatedUser.value?.role ?? 'USER',
      fullName: dashboard.fullName,
      profileImageUrl: dashboard.profileImageUrl,
      hasPin: authenticatedUser.value?.hasPin ?? false,
    );
    errorMessage.value = null;
  }

  Future<void> saveProfile({
    required String fullName,
    required String email,
    required String phone,
    DateTime? dateOfBirth,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? imagePath,
  }) async {
    final selectedImagePath = imagePath?.trim();
    final hasSelectedImage =
        selectedImagePath != null && selectedImagePath.isNotEmpty;
    if (hasSelectedImage && _uploadedProfileImagePath != selectedImagePath) {
      await _repository.uploadProfileImage(selectedImagePath);
      _uploadedProfileImagePath = selectedImagePath;
    }
    try {
      _applyDashboard(
        await _repository.updateProfile(
          fullName: fullName,
          email: email,
          phone: phone,
          dateOfBirth: dateOfBirth,
          gender: gender,
          heightCm: heightCm,
          weightKg: weightKg,
        ),
      );
      profileImagePath.value = '';
      _uploadedProfileImagePath = null;
    } on Object {
      // The image endpoint commits before the profile-details request. If the
      // second request fails (for example, because an email is already used),
      // refresh so the stored photo is still reflected in the dashboard.
      if (hasSelectedImage && _uploadedProfileImagePath == selectedImagePath) {
        try {
          _applyDashboard(await _repository.getDashboard());
        } on Object {
          // Preserve the original, more useful save error.
        }
      }
      rethrow;
    }
  }

  void changeNavigation(int index) {
    if (index == 4) {
      openSettings();
      return;
    }
    if (index == selectedNavIndex.value) return;
    selectedNavIndex.value = index;

    switch (index) {
      case 0:
        Get.offNamed<void>(AppRoutes.home);
        break;
      case 1:
        Get.offNamed<void>(AppRoutes.meals);
        break;
      case 2:
        // Create post
        break;
      case 3:
        Get.offNamed<void>(AppRoutes.community);
        break;
      case 4:
        break;
    }
  }

  Future<void> editProfile() async {
    if (!await PrivacyAuth.require(
      reason: 'Unlock to edit your personal profile.',
    )) {
      return;
    }
    Get.to(
      () => const EditProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EditProfileController>(
          () => EditProfileController(profileController: this),
        );
      }),
    );
  }

  void openProfile() {
    if (Get.currentRoute == AppRoutes.profile) return;
    Get.offNamed<void>(AppRoutes.profile, arguments: authenticatedUser.value);
  }

  Future<void> openNotifications() async {
    await Get.toNamed<void>(AppRoutes.notifications);
    await loadUnreadNotificationCount();
  }

  void openSettings() {
    Get.offNamed<void>(AppRoutes.settings);
  }

  void requestLogout() {
    final settings =
        Get.isRegistered<SettingsController>()
            ? Get.find<SettingsController>()
            : Get.put(SettingsController());
    settings.logout();
  }

  void openProgressDetails() {
    // Get.toNamed(AppRoutes.progress);
  }

  void openInsights() {
    // Get.toNamed(AppRoutes.insights);
  }

  void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    } else {
      Get.offAllNamed<void>(AppRoutes.home);
    }
  }

  @override
  void onClose() {
    _notificationCountTimer?.cancel();
    super.onClose();
  }
}
