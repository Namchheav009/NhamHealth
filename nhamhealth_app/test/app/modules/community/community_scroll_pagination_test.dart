import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test(
    'CommunityController starts with page size posts and loads more on scroll',
    () async {
      final authService = _TestAuthService();
      Get.put<AuthService>(authService);

      // Create 25 mock posts
      final mockPosts = List.generate(
        25,
        (index) => CommunityPost(
          id: '${index + 1}',
          description: 'Post description $index',
          mealName: 'Meal $index',
          imageUrl: '',
          author: 'User $index',
          role: 'USER',
          createdAt: DateTime(2026, 9, 1, 12, index),
        ),
      );

      final repository = _PaginationPostRepository(authService, mockPosts);
      final controller = CommunityController(
        repository: repository,
        authService: authService,
        homeProvider: _TestHomeProvider(authService),
      );

      await controller.reload();

      // Initially loads all 25 posts into posts collection
      expect(controller.posts.length, 25);
      // But visiblePosts is paged to pageSize (10)
      expect(controller.visiblePosts.length, 10);
      expect(controller.hasMorePosts, isTrue);

      // User scrolls down -> loads next batch
      await controller.loadMorePosts();
      expect(controller.visiblePosts.length, 20);
      expect(controller.hasMorePosts, isTrue);

      // User scrolls down again -> loops posts continuously
      await controller.loadMorePosts();
      expect(controller.visiblePosts.length, 30);
      expect(controller.visiblePosts[25].id, controller.visiblePosts[0].id);
      expect(controller.hasMorePosts, isTrue);

      // Reload resets pagination back to pageSize
      await controller.reload();
      expect(controller.visiblePosts.length, 10);
      expect(controller.hasMorePosts, isTrue);
    },
  );

  test(
    'CommunityController resets displayed posts when feed filter or search changes',
    () async {
      final authService = _TestAuthService();
      Get.put<AuthService>(authService);

      final mockPosts = List.generate(
        15,
        (index) => CommunityPost(
          id: '${index + 1}',
          description: 'Post $index',
          mealName: 'Healthy Salad $index',
          imageUrl: '',
          author: 'User $index',
          role: 'USER',
        ),
      );

      final repository = _PaginationPostRepository(authService, mockPosts);
      final controller = CommunityController(
        repository: repository,
        authService: authService,
        homeProvider: _TestHomeProvider(authService),
      );

      await controller.reload();
      await controller.loadMorePosts();
      expect(controller.visiblePosts.length, 20);
      expect(controller.visiblePosts[15].id, controller.visiblePosts[0].id);

      // Changing feed filter resets to page size
      controller.selectFeedFilter(CommunityFeedFilter.latest);
      expect(controller.visiblePosts.length, 10);

      // Updating search resets to page size
      controller.updateSearch('Salad');
      expect(controller.visiblePosts.length, 10);
    },
  );
}

class _TestAuthService extends AuthService {
  @override
  Future<AuthenticatedUser?> restoreSession() async => const AuthenticatedUser(
    id: 1,
    email: 'test@example.com',
    role: 'USER',
    fullName: 'Test User',
  );

  @override
  Future<String?> readAccessToken() async => null;
}

class _TestHomeProvider extends HomeProvider {
  _TestHomeProvider(AuthService authService) : super(authService: authService);

  @override
  Future<int> getUnreadNotificationCount() async => 0;
}

class _PaginationPostRepository extends CommunityRepository {
  _PaginationPostRepository(AuthService authService, this._posts)
    : super(authService: authService);

  final List<CommunityPost> _posts;

  @override
  Future<List<CommunityPost>> getPosts({bool following = false}) async =>
      _posts;

  @override
  Future<Map<FriendsView, List<CommunityPerson>>> getPeople() async => {
    for (final view in FriendsView.values) view: const <CommunityPerson>[],
  };
}
