import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/follow_connection_result.dart';
import 'package:nhamhealth_flutter/app/modules/providers/community/follow_connections_provider.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/follow_connections_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_page.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test(
    'Follow provider posts receiver only to the connection endpoint',
    () async {
      final sent = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent.add(options);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {
                  'id': 41,
                  'status': 'PENDING',
                  'relationshipStatus': 'OUTGOING_PENDING',
                },
              ),
            );
          },
        ),
      );

      final provider = FollowConnectionsProvider(
        authService: _FriendAuthService(),
        dio: dio,
      );
      await provider.create(2);
      await provider.accept(41);
      await provider.decline(41);

      expect(sent.map((request) => request.path), [
        '/api/follows/connections',
        '/api/follows/connections/41/accept',
        '/api/follows/connections/41/decline',
      ]);
      expect(sent.first.data, {'receiverId': 2});
      expect(sent.first.headers['Authorization'], 'Bearer test-token');
    },
  );

  test(
    'multiple requests keep failures selected and never resend successes',
    () async {
      final auth = _FriendAuthService();
      final requests = _FakeFollowConnectionsRepository(failingIds: {3});
      final community = _FriendCommunityRepository(auth, requests);
      final controller = CommunityController(
        repository: community,
        followConnectionsRepository: requests,
        authService: auth,
        homeProvider: _FriendHomeProvider(auth),
      );
      await controller.reload();
      controller.selectFriendsView(FriendsView.addFriends);
      controller.toggleMultiSelectMode();
      final people = controller.peopleFor(FriendsView.addFriends);
      controller.toggleFriendSelection(people.firstWhere((p) => p.id == '2'));
      controller.toggleFriendSelection(people.firstWhere((p) => p.id == '3'));

      final first = await controller.sendSelectedFollowConnections();

      expect(first.successfulIds, {'2'});
      expect(first.failures.keys, {'3'});
      expect(controller.friendshipStatuses['2'], 'OUTGOING_PENDING');
      expect(controller.selectedFriendIds, {'3'});

      await controller.sendSelectedFollowConnections();
      expect(requests.createCalls.where((id) => id == 2), hasLength(1));
      controller.onClose();
    },
  );

  test('429 sets a cooldown and is not automatically retried', () async {
    final auth = _FriendAuthService();
    final requests = _FakeFollowConnectionsRepository(rateLimitedIds: {4});
    final controller = CommunityController(
      repository: _FriendCommunityRepository(auth, requests),
      followConnectionsRepository: requests,
      authService: auth,
      homeProvider: _FriendHomeProvider(auth),
    );
    await controller.reload();
    controller.selectFriendsView(FriendsView.addFriends);
    controller.toggleMultiSelectMode();
    final person = controller
        .peopleFor(FriendsView.addFriends)
        .firstWhere((person) => person.id == '4');
    controller.toggleFriendSelection(person);

    await controller.sendSelectedFollowConnections();

    expect(requests.createCalls, [4]);
    expect(controller.followConnectionCooldownActive, isTrue);
    await controller.sendSelectedFollowConnections();
    expect(requests.createCalls, [4]);
    controller.onClose();
  });

  test('only NONE relationships are eligible for multi-select', () async {
    final auth = _FriendAuthService();
    final requests = _FakeFollowConnectionsRepository(
      statuses: {2: 'OUTGOING_PENDING', 3: 'INCOMING_PENDING', 4: 'FRIENDS'},
    );
    final controller = CommunityController(
      repository: _FriendCommunityRepository(auth, requests),
      followConnectionsRepository: requests,
      authService: auth,
      homeProvider: _FriendHomeProvider(auth),
    );
    await controller.reload();
    final people = controller.peopleFor(FriendsView.addFriends);

    expect(
      controller.canSelectFriend(people.firstWhere((p) => p.id == '2')),
      isFalse,
    );
    expect(
      controller.canSelectFriend(people.firstWhere((p) => p.id == '3')),
      isFalse,
    );
    expect(
      controller.canSelectFriend(people.firstWhere((p) => p.id == '4')),
      isFalse,
    );
    expect(FriendshipStatus.fromApi('NONE').canRequest, isTrue);
    controller.onClose();
  });

  test(
    'one-way follow remains eligible for a separate follow connection',
    () async {
      final auth = _FriendAuthService();
      final requests = _FakeFollowConnectionsRepository();
      final controller = CommunityController(
        repository: _FriendCommunityRepository(
          auth,
          requests,
          connectionStatuses: {2: 'FOLLOWING', 3: 'FOLLOWS_YOU'},
        ),
        followConnectionsRepository: requests,
        authService: auth,
        homeProvider: _FriendHomeProvider(auth),
      );
      await controller.reload();
      final discover = controller.peopleFor(FriendsView.addFriends);
      expect(discover.map((person) => person.id), containsAll(['2', '3']));
      expect(controller.canSelectFriend(discover.first), isTrue);
      controller.onClose();
    },
  );

  testWidgets('cancelling confirmation sends no requests', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final auth = _FriendAuthService();
    final requests = _FakeFollowConnectionsRepository();
    Get.put<AuthService>(auth);
    final controller = Get.put(
      CommunityController(
        repository: _FriendCommunityRepository(auth, requests),
        followConnectionsRepository: requests,
        authService: auth,
        homeProvider: _FriendHomeProvider(auth),
      ),
    );
    controller.selectSection(CommunitySection.people);
    controller.selectFriendsView(FriendsView.addFriends);

    await tester.pumpWidget(const GetMaterialApp(home: CommunityPage()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byKey(const ValueKey<String>('friend-action-2')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey<String>('confirm-follow-connections')),
      findsOneWidget,
    );
    expect(requests.createCalls, isEmpty);
    final cancel = find.byKey(
      const ValueKey<String>('cancel-follow-connections'),
    );
    tester.widget<OutlinedButton>(cancel).onPressed!();
    await tester.pump(const Duration(milliseconds: 500));
    expect(requests.createCalls, isEmpty);
  });
}

class _FakeFollowConnectionsRepository implements FollowConnectionsRepository {
  _FakeFollowConnectionsRepository({
    this.failingIds = const {},
    this.rateLimitedIds = const {},
    Map<int, String> statuses = const {},
  }) : statuses = Map<int, String>.from(statuses);

  final Set<int> failingIds;
  final Set<int> rateLimitedIds;
  final List<int> createCalls = [];
  final Map<int, String> statuses;

  @override
  Future<FollowConnectionResult> create(int receiverId) async {
    createCalls.add(receiverId);
    if (rateLimitedIds.contains(receiverId)) {
      throw const FollowConnectionApiException(
        'Slow down',
        statusCode: 429,
        retryAfter: Duration(seconds: 30),
      );
    }
    if (failingIds.contains(receiverId)) {
      throw const FollowConnectionApiException(
        'User is unavailable',
        statusCode: 403,
      );
    }
    statuses[receiverId] = 'OUTGOING_PENDING';
    return FollowConnectionResult(
      id: 100 + receiverId,
      status: 'PENDING',
      relationshipStatus: 'OUTGOING_PENDING',
    );
  }

  @override
  Future<FollowConnectionResult> accept(int requestId) async =>
      FollowConnectionResult(
        id: requestId,
        status: 'ACCEPTED',
        relationshipStatus: 'FRIENDS',
      );

  @override
  Future<FollowConnectionResult> decline(int requestId) async =>
      FollowConnectionResult(
        id: requestId,
        status: 'DECLINED',
        relationshipStatus: 'NONE',
      );
}

class _FriendCommunityRepository extends CommunityRepository {
  _FriendCommunityRepository(
    AuthService auth,
    this.requests, {
    this.connectionStatuses = const {},
  }) : super(authService: auth);

  final _FakeFollowConnectionsRepository requests;
  final Map<int, String> connectionStatuses;

  @override
  Future<List<CommunityPost>> getPosts({bool following = false}) async =>
      const [];

  @override
  Future<Map<FriendsView, List<CommunityPerson>>> getPeople() async {
    final people = [2, 3, 4]
        .map(
          (id) => CommunityPerson(
            id: '$id',
            name: 'Person $id',
            avatarUrl: '',
            connectionStatus: connectionStatuses[id] ?? 'NONE',
            friendshipStatus: requests.statuses[id] ?? 'NONE',
          ),
        )
        .toList(growable: false);
    return {for (final view in FriendsView.values) view: people};
  }
}

class _FriendAuthService extends AuthService {
  @override
  Future<String?> readAccessToken() async => 'test-token';

  @override
  Future<AuthenticatedUser?> restoreSession() async => const AuthenticatedUser(
    id: 1,
    email: 'viewer@example.com',
    role: 'USER',
    fullName: 'Viewer',
  );
}

class _FriendHomeProvider extends HomeProvider {
  _FriendHomeProvider(AuthService auth) : super(authService: auth);

  @override
  Future<int> getUnreadNotificationCount() async => 0;
}
