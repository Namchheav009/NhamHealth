import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../providers/home/home_provider.dart';

class FeedController extends GetxController {
  FeedController({AuthService? authService, HomeProvider? homeProvider})
      : _authService = authService ?? Get.find<AuthService>(),
        _homeProvider = homeProvider ??
            HomeProvider(authService: authService ?? Get.find<AuthService>());

  final AuthService _authService;
  final HomeProvider _homeProvider;

  final RxInt selectedTab = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasLoaded = false.obs;
  final Rxn<AuthenticatedUser> authenticatedUser = Rxn<AuthenticatedUser>();
  final RxInt unreadNotificationCount = 0.obs;
  final RxList<bool> likedPosts = <bool>[false, false].obs;
  final RxList<int> postLikes = <int>[1000, 820].obs;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    await Future.wait<void>([
      loadTopBar(),
      Future<void>.delayed(const Duration(milliseconds: 350)),
    ]);
    hasLoaded.value = true;
    isLoading.value = false;
  }

  Future<void> loadTopBar() async {
    authenticatedUser.value = await _authService.restoreSession();
    try {
      unreadNotificationCount.value =
          await _homeProvider.getUnreadNotificationCount();
    } on Object {
      // Community content remains available when the badge cannot refresh.
    }
  }

  void selectTab(int index) => selectedTab.value = index;

  bool isPostLiked(int postIndex) => likedPosts[postIndex - 1];

  int likesForPost(int postIndex) => postLikes[postIndex - 1];

  void togglePostLike(int postIndex) {
    final index = postIndex - 1;
    likedPosts[index] = !likedPosts[index];
    postLikes[index] += likedPosts[index] ? 1 : -1;
  }

  Future<void> logout() async {
    await _authService.logout();
  }
}
