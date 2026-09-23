import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/current_user_service.dart';
import '../../../../core/services/notification_realtime_event.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_alert.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../models/community/community_comment.dart';
import '../../models/community/community_person.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_types.dart';
import '../../models/notifications/notification_item.dart';
import '../../providers/home/home_provider.dart';
import '../../repositories/community/community_repository.dart';
import '../../repositories/community/follow_connections_repository.dart';
import '../../repositories/notifications/notifications_repository.dart';
import '../../providers/community/follow_connections_provider.dart';

export '../../models/community/community_person.dart';
export '../../models/community/community_post.dart';
export '../../models/community/community_types.dart';

class CommunityController extends GetxController {
  CommunityController({
    required CommunityRepository repository,
    FollowConnectionsRepository? followConnectionsRepository,
    AuthService? authService,
    HomeProvider? homeProvider,
    NotificationsRepository? notificationsRepository,
    Stream<NotificationRealtimeEvent>? realtimeEvents,
  }) : _repository = repository,
       _followConnectionsRepository = followConnectionsRepository,
       _authService = authService ?? Get.find<AuthService>(),
       _notificationsRepository = notificationsRepository,
       _realtimeEvents = realtimeEvents,
       _homeProvider =
           homeProvider ??
           HomeProvider(authService: authService ?? Get.find<AuthService>());

  final CommunityRepository _repository;
  final FollowConnectionsRepository? _followConnectionsRepository;
  final AuthService _authService;
  final HomeProvider _homeProvider;
  final NotificationsRepository? _notificationsRepository;
  final Stream<NotificationRealtimeEvent>? _realtimeEvents;
  Timer? _notificationTimer;
  Timer? _feedRefreshTimer;
  StreamSubscription<NotificationRealtimeEvent>? _realtimeSubscription;
  Worker? _currentUserWorker;
  Set<int> _knownCommunityNotificationIds = const {};
  bool _notificationsInitialized = false;
  bool _notificationRequestInFlight = false;
  bool _feedRefreshInFlight = false;
  static const notificationRefreshInterval = Duration(seconds: 5);
  static const feedRefreshInterval = Duration(seconds: 3);
  final ScrollController feedScrollController = ScrollController();
  final ScrollController peopleScrollController = ScrollController();
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
  final updatingConnectionIds = <String>{}.obs;
  final isMultiSelectMode = false.obs;
  final selectedFriendIds = <String>{}.obs;
  final submittingFollowConnections = false.obs;
  final friendshipStatuses = <String, String>{}.obs;
  final followConnectionIds = <String, int>{}.obs;
  final followConnectionFailures = <String, String>{}.obs;
  final successfullyRequestedIds = <String>{}.obs;
  final Rxn<DateTime> followConnectionRetryAt = Rxn<DateTime>();
  final likingPostIds = <String>{}.obs;
  final likeUpdates = <String, int>{}.obs;
  final errorMessage = RxnString();

  final posts = <CommunityPost>[].obs;
  final commentsByPost = <String, List<CommunityComment>>{}.obs;
  Map<FriendsView, List<CommunityPerson>> _people = const {};

  final isLoadingMore = false.obs;
  final displayedPostCount = 10.obs;
  static const int pageSize = 10;

  List<CommunityPost> get _allFilteredPosts {
    late final List<CommunityPost> filteredByFeed;
    switch (feedFilter.value) {
      case CommunityFeedFilter.forYou:
        final ranked = posts.toList(growable: false);
        ranked.sort((a, b) {
          final engagement = _engagementScore(b).compareTo(_engagementScore(a));
          if (engagement != 0) return engagement;
          return _newestFirst(a, b);
        });
        filteredByFeed = ranked;
        break;
      case CommunityFeedFilter.following:
        final currentUserId = authenticatedUser.value?.id;
        filteredByFeed = posts
            .where(
              (post) =>
                  post.isFollowingAuthor && post.authorId != currentUserId,
            )
            .toList(growable: false);
        break;
      case CommunityFeedFilter.latest:
        final latest = posts.toList(growable: false);
        latest.sort(_newestFirst);
        filteredByFeed = latest;
        break;
    }

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return filteredByFeed;
    return filteredByFeed
        .where(
          (post) =>
              post.mealName.toLowerCase().contains(query) ||
              post.description.toLowerCase().contains(query) ||
              post.author.toLowerCase().contains(query) ||
              post.categoryName.toLowerCase().contains(query) ||
              post.tags.any((tag) => tag.toLowerCase().contains(query)) ||
              post.ingredients.any(
                (ingredient) =>
                    ingredient.ingredientName.toLowerCase().contains(query),
              ),
        )
        .toList(growable: false);
  }

  List<CommunityPost> get visiblePosts {
    final all = _allFilteredPosts;
    if (all.isEmpty) return const [];
    final count = displayedPostCount.value;
    if (count <= all.length) {
      return all.take(count).toList(growable: false);
    }
    // Keep the current page stable while varying each repeated pass.
    final result = all.toList(growable: true);
    var cycle = 1;
    while (result.length < count) {
      final next = all.toList(growable: true)..shuffle(Random(cycle));
      if (next.length > 1 && next.first.id == result.last.id) {
        final first = next.removeAt(0);
        next.add(first);
      }
      result.addAll(next.take(count - result.length));
      cycle++;
    }
    return result;
  }

  bool get hasMorePosts => _allFilteredPosts.isNotEmpty;

  int _engagementScore(CommunityPost post) =>
      post.likes + (post.comments * 2) + (post.shares * 3);

  int _newestFirst(CommunityPost a, CommunityPost b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate != null && bDate != null) return bDate.compareTo(aDate);
    if (aDate != null) return -1;
    if (bDate != null) return 1;
    return (int.tryParse(b.id) ?? 0).compareTo(int.tryParse(a.id) ?? 0);
  }

  List<CommunityPerson> get people => _people[friendsView.value] ?? const [];
  List<CommunityPerson> get friends => _people[FriendsView.friends] ?? const [];
  List<CommunityPerson> peopleFor(FriendsView view) =>
      _people[view] ?? const [];
  List<CommunityPerson> get filteredPeople {
    // Track the existing reactive relationship map so a real-time People
    // refresh rebuilds the view while `_people` remains hot-reload-safe.
    connectionStatuses.length;
    final query = searchQuery.value.trim().toLowerCase();
    return people.where((person) {
      final matchesQuery =
          query.isEmpty ||
          person.displayName.toLowerCase().contains(query) ||
          person.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesFilter =
          peopleFilter.value == PeopleFilter.all || person.mutualFriends > 0;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int countFor(FriendsView view) => _people[view]?.length ?? 0;

  int get selectedFriendCount => selectedFriendIds.length;

  List<CommunityPerson> get selectedFriends {
    final selected = selectedFriendIds.toSet();
    final unique = <String, CommunityPerson>{};
    for (final person in _people.values.expand((people) => people)) {
      if (selected.contains(person.id)) unique[person.id] = person;
    }
    return unique.values.toList(growable: false);
  }

  FriendshipStatus friendshipStatusFor(CommunityPerson person) =>
      FriendshipStatus.fromApi(
        friendshipStatuses[person.id] ?? person.friendshipStatus,
      );

  bool canSelectFriend(CommunityPerson person) =>
      friendshipStatusFor(person).canRequest &&
      !successfullyRequestedIds.contains(person.id);

  bool get followConnectionCooldownActive {
    final retryAt = followConnectionRetryAt.value;
    if (retryAt == null) return false;
    if (!DateTime.now().isBefore(retryAt)) {
      followConnectionRetryAt.value = null;
      return false;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    _bindCurrentUser();
    unawaited(reload());
    if (!Get.testMode) {
      _feedRefreshTimer = Timer.periodic(feedRefreshInterval, (_) {
        if (Get.currentRoute == AppRoutes.community &&
            hasLoaded.value &&
            !isLoading.value) {
          unawaited(_refreshPosts());
        }
      });
    }
    if (_notificationsRepository != null) {
      unawaited(_refreshCommunityNotifications(showAlert: false));
      if (!Get.testMode) {
        _notificationTimer = Timer.periodic(notificationRefreshInterval, (_) {
          if (Get.currentRoute == AppRoutes.community) {
            unawaited(_refreshCommunityNotifications(showAlert: true));
          }
        });
      }
    }
    _realtimeSubscription = _realtimeEvents?.listen((event) {
      unawaited(_refreshAfterRealtimeEvent(event));
    });
  }

  Future<void> _refreshAfterRealtimeEvent(
    NotificationRealtimeEvent event,
  ) async {
    await Future.wait<void>([
      _refreshUnreadNotificationCount(),
      _refreshCommunityNotifications(showAlert: false),
      if (event.referenceType == 'POST') _refreshPosts(),
      if (event.referenceType == 'USER') _refreshPeople(),
    ]);
  }

  Future<void> _refreshPeople() async {
    try {
      _replacePeople(await _repository.getPeople());
    } on Object {
      // Keep the current People view until a later refresh succeeds.
    }
  }

  Future<void> refreshPeople() => _refreshPeople();

  Future<void> _refreshCommunityNotifications({required bool showAlert}) async {
    final repository = _notificationsRepository;
    if (repository == null || _notificationRequestInFlight) return;
    _notificationRequestInFlight = true;
    try {
      final notifications = await repository.getNotifications();
      final communityNotifications = notifications
          .where((item) => item.kind == NotificationKind.social)
          .toList(growable: false);
      final newNotifications =
          _notificationsInitialized
              ? communityNotifications
                  .where(
                    (item) =>
                        item.isUnread &&
                        !_knownCommunityNotificationIds.contains(item.id),
                  )
                  .toList(growable: false)
              : const <NotificationItem>[];

      _knownCommunityNotificationIds =
          communityNotifications.map((item) => item.id).toSet();
      _notificationsInitialized = true;
      if (newNotifications.isNotEmpty) {
        unreadNotificationCount.value += newNotifications.length;
        if (showAlert) {
          final newest = newNotifications.first;
          unawaited(
            AppAlert.notification(title: newest.title, message: newest.message),
          );
        }
      }
    } on Object {
      /* Keep Community available if notification polling is offline. */
    } finally {
      _notificationRequestInFlight = false;
    }
  }

  Future<void> reload() async {
    isLoading.value = true;
    errorMessage.value = null;
    displayedPostCount.value = pageSize;

    // The feed is the only request that is required to render Community.
    // People and top-bar data are enhancements and must not turn a healthy
    // feed into a full-page error when one of their endpoints is unavailable.
    final peopleRequest = _refreshPeople();
    final topBarRequest = _loadTopBarSafely();
    try {
      final newPosts = await _repository.getPosts();
      posts.assignAll(newPosts);
      displayedPostCount.value =
          newPosts.length < pageSize && newPosts.isNotEmpty
              ? newPosts.length
              : pageSize;
      hasLoaded.value = true;
    } on Object catch (error) {
      errorMessage.value = error.toString();
    } finally {
      await Future.wait<void>([peopleRequest, topBarRequest]);
      isLoading.value = false;
    }
  }

  Future<void> _loadTopBarSafely() async {
    try {
      await loadTopBar();
    } on Object {
      // Community can still render when session/profile decoration is stale.
    }
  }

  Future<void> loadMorePosts() async {
    if (isLoadingMore.value || isLoading.value) return;

    if (hasMorePosts) {
      isLoadingMore.value = true;
      final increment =
          _allFilteredPosts.length < pageSize && _allFilteredPosts.isNotEmpty
              ? _allFilteredPosts.length
              : pageSize;
      displayedPostCount.value += increment;
      isLoadingMore.value = false;
      return;
    }

    // Try fetching newer or additional posts from repository
    isLoadingMore.value = true;
    try {
      final latest = await _repository.getPosts();
      final currentIds = posts.map((p) => p.id).toSet();
      final newPosts = latest.where((p) => !currentIds.contains(p.id)).toList();
      if (newPosts.isNotEmpty) {
        posts.addAll(newPosts);
        displayedPostCount.value += pageSize;
      }
    } on Object {
      // Keep existing posts
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadTopBar() async {
    final user = await _authService.restoreSession();
    authenticatedUser.value = user;
    if (Get.isRegistered<CurrentUserService>()) {
      Get.find<CurrentUserService>().setUser(user);
    }
    await _refreshUnreadNotificationCount();
  }

  void _bindCurrentUser() {
    if (!Get.isRegistered<CurrentUserService>()) return;
    final currentUser = Get.find<CurrentUserService>();
    authenticatedUser.value = currentUser.user.value ?? authenticatedUser.value;
    _currentUserWorker = ever<AuthenticatedUser?>(
      currentUser.user,
      (user) => authenticatedUser.value = user,
    );
  }

  Future<void> _refreshUnreadNotificationCount() async {
    try {
      unreadNotificationCount.value =
          await _homeProvider.getUnreadNotificationCount();
    } on Object {
      /* Stay available offline. */
    }
  }

  /// Keeps the Community feed current when another signed-in user publishes a
  /// meal through the Spring Boot recipe endpoint.
  Future<void> _refreshPosts() async {
    if (_feedRefreshInFlight) return;
    _feedRefreshInFlight = true;
    try {
      posts.assignAll(await _repository.getPosts());
    } on Object {
      // Keep the existing feed visible until the next successful refresh.
    } finally {
      _feedRefreshInFlight = false;
    }
  }

  void selectSection(CommunitySection value) {
    if (section.value == value) {
      // Tap on the active tab: scroll to the top and refresh content
      _scrollToTopAndRefresh(value);
      return;
    }
    section.value = value;
    searchQuery.value = '';
    displayedPostCount.value = pageSize;
    _scrollToTop(value);
  }

  void _scrollToTop(CommunitySection targetSection) {
    final controller = switch (targetSection) {
      CommunitySection.feed => feedScrollController,
      CommunitySection.people => peopleScrollController,
    };
    if (controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToTopAndRefresh(CommunitySection targetSection) {
    _scrollToTop(targetSection);
    switch (targetSection) {
      case CommunitySection.feed:
        unawaited(reload());
      case CommunitySection.people:
        unawaited(_refreshPeople());
    }
  }

  void selectFeedFilter(CommunityFeedFilter value) {
    if (feedFilter.value == value) return;
    feedFilter.value = value;
    displayedPostCount.value = pageSize;
  }

  void selectFriendsView(FriendsView value) {
    friendsView.value = value;
    searchQuery.value = '';
    peopleFilter.value = PeopleFilter.all;
    if (value != FriendsView.addFriends) exitMultiSelectMode();
  }

  void selectPeopleFilter(PeopleFilter value) => peopleFilter.value = value;

  void toggleMultiSelectMode() {
    if (isMultiSelectMode.value) {
      exitMultiSelectMode();
    } else {
      isMultiSelectMode.value = true;
      followConnectionFailures.clear();
    }
  }

  void exitMultiSelectMode() {
    isMultiSelectMode.value = false;
    selectedFriendIds.clear();
    followConnectionFailures.clear();
  }

  void toggleFriendSelection(CommunityPerson person) {
    if (!canSelectFriend(person) || submittingFollowConnections.value) return;
    if (!selectedFriendIds.remove(person.id)) selectedFriendIds.add(person.id);
  }

  void selectSingleFriend(CommunityPerson person) {
    if (!canSelectFriend(person) || submittingFollowConnections.value) return;
    selectedFriendIds
      ..clear()
      ..add(person.id);
    followConnectionFailures.clear();
  }

  Future<FollowConnectionBatchSummary> sendSelectedFollowConnections() async {
    final repository = _followConnectionsRepository;
    if (repository == null) {
      return const FollowConnectionBatchSummary(
        successfulIds: {},
        failures: {'request': 'Invitations are unavailable.'},
      );
    }
    if (submittingFollowConnections.value || followConnectionCooldownActive) {
      return FollowConnectionBatchSummary(
        successfulIds: const {},
        failures: Map<String, String>.from(followConnectionFailures),
      );
    }
    final pending = selectedFriendIds
        .where(
          (id) =>
              !successfullyRequestedIds.contains(id) &&
              FriendshipStatus.fromApi(friendshipStatuses[id]).canRequest,
        )
        .toList(growable: false);
    if (pending.isEmpty) {
      return const FollowConnectionBatchSummary(
        successfulIds: {},
        failures: {},
      );
    }

    submittingFollowConnections.value = true;
    followConnectionFailures.clear();
    final successes = <String>{};
    final failures = <String, String>{};
    var nextIndex = 0;

    Future<void> worker() async {
      while (nextIndex < pending.length) {
        final id = pending[nextIndex++];
        if (followConnectionCooldownActive) {
          failures[id] = 'Rate limit active. Try again after the cooldown.';
          continue;
        }
        try {
          final result = await repository.create(int.parse(id));
          final relationship = FriendshipStatus.fromApi(
            result.relationshipStatus == 'FRIENDS'
                ? 'FRIENDS'
                : 'OUTGOING_PENDING',
          );
          friendshipStatuses[id] = relationship.apiValue;
          if (result.id > 0) followConnectionIds[id] = result.id;
          successfullyRequestedIds.add(id);
          selectedFriendIds.remove(id);
          successes.add(id);
        } on FollowConnectionApiException catch (error) {
          failures[id] = error.message;
          if (error.isRateLimited) {
            followConnectionRetryAt.value = DateTime.now().add(
              error.retryAfter ?? const Duration(seconds: 60),
            );
          }
        } on Object catch (error) {
          failures[id] = error.toString();
        }
      }
    }

    try {
      final workers = List.generate(
        pending.length < 3 ? pending.length : 3,
        (_) => worker(),
      );
      await Future.wait(workers);
      followConnectionFailures.assignAll(failures);
      await _refreshPeople();
      if (failures.isEmpty) exitMultiSelectMode();
      return FollowConnectionBatchSummary(
        successfulIds: successes,
        failures: failures,
      );
    } finally {
      submittingFollowConnections.value = false;
    }
  }

  Future<void> acceptFollowConnection(CommunityPerson person) async {
    await _respondToFollowConnection(person, accept: true);
  }

  Future<void> declineFollowConnection(CommunityPerson person) async {
    await _respondToFollowConnection(person, accept: false);
  }

  Future<void> _respondToFollowConnection(
    CommunityPerson person, {
    required bool accept,
  }) async {
    final repository = _followConnectionsRepository;
    final requestId =
        followConnectionIds[person.id] ?? person.followConnectionId;
    if (repository == null || requestId == null) return;
    if (!updatingConnectionIds.add(person.id)) return;
    try {
      if (accept) {
        await repository.accept(requestId);
        friendshipStatuses[person.id] = FriendshipStatus.friends.apiValue;
      } else {
        await repository.decline(requestId);
        friendshipStatuses[person.id] = FriendshipStatus.none.apiValue;
      }
      await _refreshPeople();
    } finally {
      updatingConnectionIds.remove(person.id);
    }
  }

  void synchronizeFollowState({
    required int userId,
    required bool isFollowing,
    required bool followsViewer,
  }) {
    final key = '$userId';
    connectionStatuses[key] =
        CommunityConnectionStatus.fromDirections(
          isFollowing: isFollowing,
          followsViewer: followsViewer,
        ).apiValue;
    _updatePostAuthorFollowState(key, isFollowing);
  }

  CommunityConnectionStatus? connectionStatusFor(int userId) {
    final value = connectionStatuses['$userId'];
    return value == null ? null : CommunityConnectionStatus.fromApi(value);
  }

  void updateSearch(String value) {
    searchQuery.value = value;
    displayedPostCount.value = pageSize;
  }

  Future<void> togglePostLike(CommunityPost post) async {
    if (!likingPostIds.add(post.id)) return;
    post = posts.firstWhereOrNull((item) => item.id == post.id) ?? post;
    final previousLiked = post.isLiked;
    final previousLikes = post.likes;
    post.isLiked = !previousLiked;
    post.likes = (previousLikes + (previousLiked ? -1 : 1)).clamp(0, 1 << 31);
    likeUpdates[post.id] = (likeUpdates[post.id] ?? 0) + 1;
    try {
      final updated = await _repository.toggleLike(post.id);
      final current = posts.firstWhereOrNull((item) => item.id == post.id);
      if (current != null) {
        current.isLiked = updated.isLiked;
        current.likes = updated.likes;
        likeUpdates[post.id] = (likeUpdates[post.id] ?? 0) + 1;
      }
    } on Object catch (error) {
      final current = posts.firstWhereOrNull((item) => item.id == post.id);
      if (current != null) {
        current.isLiked = previousLiked;
        current.likes = previousLikes;
        likeUpdates[post.id] = (likeUpdates[post.id] ?? 0) + 1;
      }
      Get.snackbar('community.could_not_update_like'.tr, error.toString());
    } finally {
      likingPostIds.remove(post.id);
    }
  }

  Future<void> togglePostSaved(CommunityPost post) async {
    final currentUserId = authenticatedUser.value?.id;
    if (currentUserId != null && post.authorId == currentUserId) {
      return;
    }
    final recipeId = post.mealId;
    if (recipeId == null) {
      Get.snackbar(
        'common.favorites_unavailable'.tr,
        'This post cannot be saved right now.',
      );
      return;
    }
    final updated = await _repository.toggleSaved(post.id, recipeId: recipeId);
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index >= 0) posts[index] = updated;
  }

  Future<void> sharePost(
    CommunityPost post, {
    List<String> recipientIds = const [],
  }) async {
    await _repository.sharePost(post.id, recipientIds: recipientIds);
    post.shares += recipientIds.isEmpty ? 1 : recipientIds.length;
    posts.refresh();
  }

  Future<CommunityPost> sharePostToFeed(
    CommunityPost post, {
    String message = '',
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
  }) async {
    final shared = await _repository.sharePostToFeed(
      post.id,
      message: message,
      visibility: visibility,
    );
    post.shares += 1;
    posts.insert(0, shared);
    section.value = CommunitySection.feed;
    return shared;
  }

  List<CommunityComment> commentsFor(String postId) =>
      commentsByPost[postId] ?? const [];

  Future<void> loadComments(CommunityPost post) async {
    commentsByPost[post.id] = await _repository.getComments(post.id);
  }

  Future<void> addComment(
    CommunityPost post,
    String text, {
    String? parentCommentId,
  }) async {
    final comment = await _repository.addComment(
      post.id,
      text,
      parentCommentId: parentCommentId,
    );
    commentsByPost[post.id] = [...commentsFor(post.id), comment];
    post.comments += 1;
    posts.refresh();
  }

  Future<void> addPost({
    String mealName = '',
    required String description,
    int cookingTimeMinutes = 0,
    int servings = 0,
    String difficulty = 'EASY',
    List<MealPostIngredient> ingredients = const [],
    List<MealPostStep> steps = const [],
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    List<int> tagIds = const [],
    int? categoryId,
  }) async {
    final post = await _repository.createPost(
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
      categoryId: categoryId,
    );
    posts.insert(0, post);
    section.value = CommunitySection.feed;
  }

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
    int? categoryId,
  }) async {
    final updated = await _repository.updatePost(
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
      categoryId: categoryId,
    );
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index >= 0) posts[index] = updated;
    return updated;
  }

  Future<void> deletePost(CommunityPost post) async {
    final recipeId = post.mealId;
    if (recipeId == null) {
      throw CommunityException('community.post_delete_unavailable'.tr);
    }
    await _repository.deletePost(recipeId);
    posts.removeWhere((item) => item.id == post.id);
    commentsByPost.remove(post.id);
  }

  Future<void> updateConnection(
    CommunityPerson person,
    FriendsView view,
  ) async {
    if (updatingConnectionIds.contains(person.id)) {
      return;
    }

    final previousLocalStatus = connectionStatuses[person.id];
    final previousStatus = CommunityConnectionStatus.fromApi(
      previousLocalStatus ?? person.connectionStatus,
    );
    final wasFollowing = previousStatus.isFollowing;
    final optimisticFollowing = !wasFollowing;
    // When unfollowing, both follow directions are severed so they must add each other back to be friends.
    final followsViewer = wasFollowing ? false : previousStatus.followsViewer;

    connectionStatuses[person.id] =
        CommunityConnectionStatus.fromDirections(
          isFollowing: optimisticFollowing,
          followsViewer: followsViewer,
        ).apiValue;
    _updatePostAuthorFollowState(person.id, optimisticFollowing);
    updatingConnectionIds.add(person.id);

    try {
      final responseStatus = CommunityConnectionStatus.fromApi(
        await _repository.toggleFollow(person.id),
      );
      final status = _withKnownFollowerDirection(responseStatus, followsViewer);
      final isFollowing = status.isFollowing;
      connectionStatuses[person.id] = status.apiValue;
      _updatePostAuthorFollowState(person.id, isFollowing);

      try {
        _replacePeople(await _repository.getPeople());
      } on Object {
        // The confirmed relationship is already visible. Refresh later.
      }
    } on Object catch (error) {
      if (previousLocalStatus == null) {
        connectionStatuses.remove(person.id);
      } else {
        connectionStatuses[person.id] = previousLocalStatus;
      }
      _updatePostAuthorFollowState(person.id, wasFollowing);
      unawaited(
        AppAlert.error(
          title: 'community.could_not_update_follow',
          message: error.toString(),
        ),
      );
    } finally {
      updatingConnectionIds.remove(person.id);
    }
  }

  Future<void> removeFollower(CommunityPerson person) async {
    if (updatingConnectionIds.contains(person.id)) return;
    updatingConnectionIds.add(person.id);
    try {
      await _repository.removeFollower(person.id);
      final currentStatus = CommunityConnectionStatus.fromApi(
        connectionStatuses[person.id] ?? person.connectionStatus,
      );
      final updatedStatus = CommunityConnectionStatus.fromDirections(
        isFollowing: currentStatus.isFollowing,
        followsViewer: false,
      );
      connectionStatuses[person.id] = updatedStatus.apiValue;
      await _refreshPeople();
    } on Object catch (error) {
      unawaited(
        AppAlert.error(
          title: 'community.could_not_update_follow',
          message: error.toString(),
        ),
      );
    } finally {
      updatingConnectionIds.remove(person.id);
    }
  }

  Future<void> togglePostAuthorFollow(CommunityPost post) async {
    if (post.authorId <= 0) return;

    final currentUserId = authenticatedUser.value?.id;
    if (currentUserId != null && post.authorId == currentUserId) return;

    final authorIdKey = post.authorId.toString();
    if (updatingConnectionIds.contains(authorIdKey)) return;

    final previousStatusValue = connectionStatuses[authorIdKey];
    final previousStatus = CommunityConnectionStatus.fromApi(
      previousStatusValue,
    );
    final wasFollowing = previousStatus.isFollowing || post.isFollowingAuthor;
    final optimisticFollowing = !wasFollowing;
    // When unfollowing, both follow directions are severed so they must add each other back to be friends.
    final followsViewer = wasFollowing ? false : previousStatus.followsViewer;

    connectionStatuses[authorIdKey] =
        CommunityConnectionStatus.fromDirections(
          isFollowing: optimisticFollowing,
          followsViewer: followsViewer,
        ).apiValue;
    _updatePostAuthorFollowState(authorIdKey, optimisticFollowing);
    updatingConnectionIds.add(authorIdKey);

    try {
      final responseStatus = CommunityConnectionStatus.fromApi(
        await _repository.toggleFollow(authorIdKey),
      );
      final status = _withKnownFollowerDirection(responseStatus, followsViewer);
      final isFollowing = status.isFollowing;

      connectionStatuses[authorIdKey] = status.apiValue;
      _updatePostAuthorFollowState(authorIdKey, isFollowing);
      unawaited(_refreshPeople());
    } on Object catch (error) {
      if (previousStatusValue == null) {
        connectionStatuses.remove(authorIdKey);
      } else {
        connectionStatuses[authorIdKey] = previousStatusValue;
      }
      _updatePostAuthorFollowState(authorIdKey, wasFollowing);
      unawaited(
        AppAlert.error(
          title: 'community.could_not_update_follow',
          message: error.toString(),
        ),
      );
    } finally {
      updatingConnectionIds.remove(authorIdKey);
    }
  }

  void _updatePostAuthorFollowState(String personIdValue, bool isFollowing) {
    final personId = int.tryParse(personIdValue);
    if (personId == null) return;
    for (final post in posts) {
      if (post.authorId == personId) {
        post.isFollowingAuthor = isFollowing;
      }
      if (post.sharedPost?.authorId == personId) {
        post.sharedPost?.isFollowingAuthor = isFollowing;
      }
    }
    posts.refresh();
  }

  void _replacePeople(Map<FriendsView, List<CommunityPerson>> value) {
    final peopleById = <String, CommunityPerson>{};
    for (final people in value.values) {
      for (final person in people) {
        peopleById[person.id] = person;
      }
    }

    _people = {
      FriendsView.friends: peopleById.values
          .where(
            (person) => person.connection == CommunityConnectionStatus.friend,
          )
          .toList(growable: false),
      FriendsView.followers: peopleById.values
          .where(
            (person) =>
                person.connection == CommunityConnectionStatus.followsYou,
          )
          .toList(growable: false),
      FriendsView.following: peopleById.values
          .where(
            (person) =>
                person.connection == CommunityConnectionStatus.following,
          )
          .toList(growable: false),
      FriendsView.addFriends: value[FriendsView.addFriends] ??
          peopleById.values.toList(growable: false),
    };
    final statuses = <String, String>{};
    final friendStatuses = <String, String>{};
    final requestIds = <String, int>{};
    for (final person in peopleById.values) {
      statuses[person.id] = person.connection.apiValue;
      friendStatuses[person.id] = person.friendship.apiValue;
      if (person.followConnectionId != null) {
        requestIds[person.id] = person.followConnectionId!;
      }
    }
    connectionStatuses.assignAll(statuses);
    friendshipStatuses.assignAll(friendStatuses);
    followConnectionIds.assignAll(requestIds);
  }

  CommunityConnectionStatus _withKnownFollowerDirection(
    CommunityConnectionStatus status,
    bool followsViewer,
  ) {
    // When not following (unfollowed), relationship is completely severed to NONE.
    if (!status.isFollowing) return status;
    // Older API versions returned only FOLLOWING/NONE. Preserve the inbound
    // direction so a follow-back still becomes a friend during a rolling
    // client/server update.
    if (!followsViewer || status.followsViewer) return status;
    return CommunityConnectionStatus.fromDirections(
      isFollowing: status.isFollowing,
      followsViewer: true,
    );
  }

  @override
  void onClose() {
    _notificationTimer?.cancel();
    _feedRefreshTimer?.cancel();
    _realtimeSubscription?.cancel();
    _currentUserWorker?.dispose();
    feedScrollController.dispose();
    peopleScrollController.dispose();
    super.onClose();
  }
}

class FollowConnectionBatchSummary {
  const FollowConnectionBatchSummary({
    required this.successfulIds,
    required this.failures,
  });

  final Set<String> successfulIds;
  final Map<String, String> failures;
  bool get isCompleteSuccess => successfulIds.isNotEmpty && failures.isEmpty;
  bool get isPartialSuccess => successfulIds.isNotEmpty && failures.isNotEmpty;
}
