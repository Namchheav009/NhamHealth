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

  test('relationship status preserves both follow directions', () {
    expect(
      CommunityConnectionStatus.fromApi('follow_back'),
      CommunityConnectionStatus.followsYou,
    );
    expect(CommunityConnectionStatus.friend.isFollowing, isTrue);
    expect(CommunityConnectionStatus.friend.followsViewer, isTrue);
    expect(CommunityConnectionStatus.following.followsViewer, isFalse);
  });

  test('follow-back moves the user into the friends list only', () async {
    final authService = _FollowAuthService();
    final repository = _FollowRepository(authService);
    final controller = CommunityController(
      repository: repository,
      authService: authService,
      homeProvider: _FollowHomeProvider(authService),
    );
    await controller.reload();

    final follower = controller.peopleFor(FriendsView.followers).single;
    await controller.updateConnection(follower, FriendsView.followers);

    expect(controller.connectionStatusFor(2), CommunityConnectionStatus.friend);
    expect(controller.peopleFor(FriendsView.friends), hasLength(1));
    expect(controller.peopleFor(FriendsView.following), isEmpty);
    expect(controller.peopleFor(FriendsView.followers), isEmpty);
    expect(controller.peopleFor(FriendsView.addFriends), isEmpty);

    controller.onClose();
  });
}

class _FollowRepository extends CommunityRepository {
  _FollowRepository(AuthService authService) : super(authService: authService);

  bool isFollowing = false;
  final bool followsViewer = true;

  CommunityConnectionStatus get status =>
      CommunityConnectionStatus.fromDirections(
        isFollowing: isFollowing,
        followsViewer: followsViewer,
      );

  @override
  Future<List<CommunityPost>> getPosts({bool following = false}) async =>
      const [];

  @override
  Future<String> toggleFollow(String userId) async {
    isFollowing = !isFollowing;
    return status.apiValue;
  }

  @override
  Future<Map<FriendsView, List<CommunityPerson>>> getPeople() async {
    final person = CommunityPerson(
      id: '2',
      name: 'Follower',
      avatarUrl: '',
      connectionStatus: status.apiValue,
    );
    return {
      for (final view in FriendsView.values) view: [person],
    };
  }
}

class _FollowAuthService extends AuthService {
  @override
  Future<AuthenticatedUser?> restoreSession() async => const AuthenticatedUser(
    id: 1,
    email: 'viewer@example.com',
    role: 'USER',
    fullName: 'Viewer',
  );
}

class _FollowHomeProvider extends HomeProvider {
  _FollowHomeProvider(AuthService authService)
    : super(authService: authService);

  @override
  Future<int> getUnreadNotificationCount() async => 0;
}
