import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_page.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.addTranslations(AppTranslations().keys);
  });
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

  test('follow-back turns connection into friend and updates lists', () async {
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
    expect(controller.peopleFor(FriendsView.addFriends), hasLength(1));

    controller.onClose();
  });

  test('removing follower updates relationship and removes from followers', () async {
    final authService = _FollowAuthService();
    final repository = _FollowRepository(authService)..isFollowing = true;
    final controller = CommunityController(
      repository: repository,
      authService: authService,
      homeProvider: _FollowHomeProvider(authService),
    );
    await controller.reload();

    final friend = controller.peopleFor(FriendsView.friends).single;
    await controller.removeFollower(friend);

    expect(
      controller.connectionStatusFor(2),
      CommunityConnectionStatus.following,
    );

    controller.onClose();
  });

  test('unfollowing friend severs both directions so they must add each other back to be friend', () async {
    final authService = _FollowAuthService();
    final repository = _FollowRepository(authService)
      ..isFollowing = true
      ..followsViewer = true;
    final controller = CommunityController(
      repository: repository,
      authService: authService,
      homeProvider: _FollowHomeProvider(authService),
    );
    await controller.reload();

    expect(controller.connectionStatusFor(2), CommunityConnectionStatus.friend);
    final friend = controller.peopleFor(FriendsView.friends).single;

    // Unfollow
    await controller.updateConnection(friend, FriendsView.friends);
    expect(controller.connectionStatusFor(2), CommunityConnectionStatus.none);
    expect(controller.peopleFor(FriendsView.friends), isEmpty);

    // Follow again (only viewer follows target now)
    final unfollowedPerson = controller.peopleFor(FriendsView.addFriends).single;
    await controller.updateConnection(unfollowedPerson, FriendsView.addFriends);
    expect(controller.connectionStatusFor(2), CommunityConnectionStatus.following);
    expect(controller.peopleFor(FriendsView.friends), isEmpty);

    controller.onClose();
  });

  testWidgets('clicking friends button shows confirmation dialog before unfollowing', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final authService = _FollowAuthService();
    final repository = _FollowRepository(authService)
      ..isFollowing = true
      ..followsViewer = true;
    Get.put<AuthService>(authService);
    final controller = Get.put(
      CommunityController(
        repository: repository,
        authService: authService,
        homeProvider: _FollowHomeProvider(authService),
      ),
    );
    controller.selectSection(CommunitySection.people);
    controller.selectFriendsView(FriendsView.friends);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const CommunityPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    // Tap Friends button
    await tester.tap(find.byKey(const ValueKey<String>('people-action-2')));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify branded AppAlert confirmation dialog is shown
    expect(find.byKey(const ValueKey<String>('app-confirm-alert-confirm')), findsOneWidget);
    expect(find.text('Unfollow this member?'), findsOneWidget);
    expect(controller.connectionStatusFor(2), CommunityConnectionStatus.friend);

    // Tap Cancel
    await tester.tap(find.byKey(const ValueKey<String>('app-confirm-alert-cancel')));
    await tester.pump(const Duration(milliseconds: 500));

    // Still friend
    expect(find.byKey(const ValueKey<String>('app-confirm-alert-confirm')), findsNothing);
    expect(controller.connectionStatusFor(2), CommunityConnectionStatus.friend);

    // Tap Friends button again
    await tester.tap(find.byKey(const ValueKey<String>('people-action-2')));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Unfollow
    await tester.tap(find.byKey(const ValueKey<String>('app-confirm-alert-confirm')));
    await tester.pump(const Duration(milliseconds: 500));

    // Now unfollowed
    expect(controller.connectionStatusFor(2), CommunityConnectionStatus.none);

    // Verify success alert is shown (AppAlert.actionSuccess)
    expect(find.text('Unfollowed'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('app-action-alert-confirm')));
    await tester.pump(const Duration(milliseconds: 500));
  });
}

class _FollowRepository extends CommunityRepository {
  _FollowRepository(AuthService authService) : super(authService: authService);

  bool isFollowing = false;
  bool followsViewer = true;

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
    if (isFollowing) {
      isFollowing = false;
      if (followsViewer) {
        followsViewer = false;
      }
    } else {
      isFollowing = true;
    }
    return status.apiValue;
  }

  @override
  Future<void> removeFollower(String followerId) async {
    followsViewer = false;
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
