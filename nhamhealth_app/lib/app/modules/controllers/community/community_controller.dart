import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../models/community/community_person.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_types.dart';
import '../../providers/home/home_provider.dart';
import '../../repositories/community/community_repository.dart';

export '../../models/community/community_person.dart';
export '../../models/community/community_post.dart';
export '../../models/community/community_types.dart';

class CommunityController extends GetxController {
  CommunityController({
    required CommunityRepository repository,
    AuthService? authService,
    HomeProvider? homeProvider,
  }) : _repository = repository,
       _authService = authService ?? Get.find<AuthService>(),
       _homeProvider =
           homeProvider ??
           HomeProvider(authService: authService ?? Get.find<AuthService>());

  final CommunityRepository _repository;
  final AuthService _authService;
  final HomeProvider _homeProvider;
  final section = CommunitySection.feed.obs;
  final feedFilter = CommunityFeedFilter.forYou.obs;
  final friendsView = FriendsView.friends.obs;
  final peopleFilter = PeopleFilter.all.obs;
  final searchQuery = ''.obs;
  final isLoading = true.obs;
  final hasLoaded = false.obs;
  final Rxn<AuthenticatedUser> authenticatedUser = Rxn<AuthenticatedUser>();
  final unreadNotificationCount = 0.obs;
  final connectionStatuses = <String, String>{}.obs;
  final errorMessage = RxnString();

  final posts = <CommunityPost>[].obs;
  Map<FriendsView, List<CommunityPerson>> _people = const {};

  List<CommunityPost> get visiblePosts {
    switch (feedFilter.value) {
      case CommunityFeedFilter.forYou:
        return posts;
      case CommunityFeedFilter.following:
        return posts.where((post) => post.isFollowingAuthor).toList();
      case CommunityFeedFilter.latest:
        return posts.reversed.toList();
    }
  }

  List<CommunityPerson> get people => _people[friendsView.value] ?? const [];
  List<CommunityPerson> get filteredPeople {
    final query = searchQuery.value.trim().toLowerCase();
    return people.where((person) {
      final matchesQuery =
          query.isEmpty ||
          person.name.toLowerCase().contains(query) ||
          person.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesFilter =
          peopleFilter.value == PeopleFilter.all || person.mutualFriends > 0;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int countFor(FriendsView view) => _people[view]?.length ?? 0;

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait<dynamic>([
        _repository.getPosts(),
        _repository.getPeople(),
        loadTopBar(),
      ]);
      posts.assignAll(results[0] as List<CommunityPost>);
      _people = results[1] as Map<FriendsView, List<CommunityPerson>>;
      hasLoaded.value = true;
    } on Object catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTopBar() async {
    authenticatedUser.value = await _authService.restoreSession();
    try {
      unreadNotificationCount.value =
          await _homeProvider.getUnreadNotificationCount();
    } on Object {
      /* Stay available offline. */
    }
  }

  void selectSection(CommunitySection value) => section.value = value;
  void selectFeedFilter(CommunityFeedFilter value) => feedFilter.value = value;
  void selectFriendsView(FriendsView value) {
    friendsView.value = value;
    searchQuery.value = '';
    peopleFilter.value = PeopleFilter.all;
  }

  void selectPeopleFilter(PeopleFilter value) => peopleFilter.value = value;
  void updateSearch(String value) => searchQuery.value = value;
  Future<void> togglePostLike(CommunityPost post) async {
    final updated = await _repository.toggleLike(post.id);
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index >= 0) posts[index] = updated;
  }

  void togglePostSaved(CommunityPost post) {
    post.isSaved = !post.isSaved;
    posts.refresh();
  }

  Future<void> sharePost(CommunityPost post) async {
    await _repository.sharePost(post.id);
    post.shares += 1;
    posts.refresh();
  }

  Future<void> addPost({
    required String title,
    required String description,
    Uint8List? imageBytes,
  }) async {
    final post = await _repository.createPost(
      title: title,
      description: description,
      imageBytes: imageBytes,
    );
    posts.insert(0, post);
    section.value = CommunitySection.feed;
  }

  Future<void> updateConnection(
    CommunityPerson person,
    FriendsView view,
  ) async {
    if (view == FriendsView.friends) return;
    final status = await _repository.toggleFollow(person.id);
    connectionStatuses[person.id] =
        status == 'FOLLOWING' ? 'Following' : 'Follow';
    _people = await _repository.getPeople();
    update();
  }

  void declineFollower(CommunityPerson person) =>
      connectionStatuses[person.id] = 'Declined';
}
