import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_page.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_composer_card.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  for (final size in <Size>[const Size(320, 700), const Size(381, 856)]) {
    testWidgets(
      'community image carousel is constrained at ${size.width.toInt()} px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);

        final authService = _CommunityAuthService();
        Get.put<AuthService>(authService);
        Get.put<CommunityController>(
          CommunityController(
            repository: _ImagePostRepository(authService),
            authService: authService,
            homeProvider: _CommunityHomeProvider(authService),
          ),
        );

        await tester.pumpWidget(const GetMaterialApp(home: CommunityPage()));
        await tester.pump(const Duration(milliseconds: 500));

        final carousel = find.byType(PageView);
        expect(carousel, findsOneWidget);
        final carouselSize = tester.getSize(carousel);
        expect(carouselSize.height, carouselSize.width / (5 / 4));
        expect(carouselSize.height, lessThanOrEqualTo(360));
        expect(find.byType(CommunityComposerCard), findsOneWidget);
        expect(find.text('Like'), findsOneWidget);
        expect(find.text('Comment'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('community-feed-filter-forYou')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('community uses a sidebar feed on a landscape tablet', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.reset);

    final authService = _CommunityAuthService();
    Get.put<AuthService>(authService);
    Get.put<CommunityController>(
      CommunityController(
        repository: _ImagePostRepository(authService),
        authService: authService,
        homeProvider: _CommunityHomeProvider(authService),
      ),
    );

    await tester.pumpWidget(const GetMaterialApp(home: CommunityPage()));
    await tester.pump(const Duration(milliseconds: 500));

    final tabletLayout = find.byKey(
      const ValueKey<String>('community-tablet-layout'),
    );
    expect(tabletLayout, findsOneWidget);
    expect(find.byType(CommunityComposerCard), findsOneWidget);
    expect(tester.getSize(tabletLayout).width, lessThanOrEqualTo(960));
    expect(tester.takeException(), isNull);
  });

  testWidgets('community feed filters respond to taps', (tester) async {
    final authService = _CommunityAuthService();
    Get.put<AuthService>(authService);
    final controller = Get.put<CommunityController>(
      CommunityController(
        repository: _ImagePostRepository(authService),
        authService: authService,
        homeProvider: _CommunityHomeProvider(authService),
      ),
    );

    await tester.pumpWidget(const GetMaterialApp(home: CommunityPage()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(
      find.byKey(const ValueKey<String>('community-feed-filter-following')),
    );
    await tester.pump();
    expect(controller.feedFilter.value, CommunityFeedFilter.following);

    await tester.tap(
      find.byKey(const ValueKey<String>('community-feed-filter-latest')),
    );
    await tester.pump();
    expect(controller.feedFilter.value, CommunityFeedFilter.latest);
  });
}

class _ImagePostRepository extends CommunityRepository {
  _ImagePostRepository(AuthService authService)
    : super(authService: authService);

  @override
  Future<List<CommunityPost>> getPosts({bool following = false}) async => [
    CommunityPost(
      id: '1',
      description: 'Testing a post with multiple network images.',
      imageUrl: 'https://example.invalid/community-1.jpg',
      imageUrls: const [
        'https://example.invalid/community-1.jpg',
        'https://example.invalid/community-2.jpg',
      ],
      author: 'Community Member',
      role: 'Member',
    ),
  ];

  @override
  Future<Map<FriendsView, List<CommunityPerson>>> getPeople() async => {
    for (final view in FriendsView.values) view: const <CommunityPerson>[],
  };
}

class _CommunityHomeProvider extends HomeProvider {
  _CommunityHomeProvider(AuthService authService)
    : super(authService: authService);

  @override
  Future<int> getUnreadNotificationCount() async => 0;
}

class _CommunityAuthService extends AuthService {
  @override
  Future<AuthenticatedUser?> restoreSession() async => const AuthenticatedUser(
    id: 1,
    email: 'member@example.com',
    role: 'USER',
    fullName: 'Community Member',
  );

  @override
  Future<String?> readAccessToken() async => null;
}
