import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_page.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_composer_card.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_tab_switcher.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/widgets/profile_post_card.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
  });
  tearDown(Get.reset);

  Widget buildApp(Widget home) => GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    home: home,
  );

  testWidgets(
    'tablet portrait: feed uses the full tablet width and tabs stay compact',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      final authService = _CommunityAuthService();
      Get.put<AuthService>(authService);
      Get.put<CommunityController>(
        CommunityController(
          repository: _TabletCommunityRepository(authService),
          authService: authService,
          homeProvider: _CommunityHomeProvider(authService),
        ),
      );

      await tester.pumpWidget(buildApp(const CommunityPage()));
      await tester.pump(const Duration(milliseconds: 500));

      // Tab switcher must be constrained to at most 420
      final tabSwitcher = find.byType(CommunityTabSwitcher);
      expect(tabSwitcher, findsOneWidget);
      expect(tester.getSize(tabSwitcher).width, lessThanOrEqualTo(420));

      // Portrait tablet content should use the available width.
      final composer = find.byType(CommunityComposerCard);
      expect(composer, findsOneWidget);
      expect(tester.getSize(composer).width, greaterThan(620));

      // Post card should use the same full-width tablet canvas.
      final postCard = find.byType(ProfilePostCard);
      expect(postCard, findsOneWidget);
      expect(tester.getSize(postCard).width, greaterThan(620));

      // Post image carousel on tablet wide card (>= 450) should use 16:9 aspect ratio
      final carousel = find.byType(PageView);
      expect(carousel, findsOneWidget);
      final carouselSize = tester.getSize(carousel);
      expect(carouselSize.width, greaterThan(450));
      expect(
        carouselSize.height,
        closeTo(carouselSize.width / (16 / 9), 1.0),
      );

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tablet landscape: 2-column layout activates with sidebar and right feed',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.reset);

      final authService = _CommunityAuthService();
      Get.put<AuthService>(authService);
      Get.put<CommunityController>(
        CommunityController(
          repository: _TabletCommunityRepository(authService),
          authService: authService,
          homeProvider: _CommunityHomeProvider(authService),
        ),
      );

      await tester.pumpWidget(buildApp(const CommunityPage()));
      await tester.pump(const Duration(milliseconds: 500));

      // 2-column tablet layout must be present
      final tabletLayout = find.byKey(
        const ValueKey<String>('community-tablet-layout'),
      );
      expect(tabletLayout, findsOneWidget);

      // Tab switcher still constrained to 420
      final tabSwitcher = find.byType(CommunityTabSwitcher);
      expect(tabSwitcher, findsOneWidget);
      expect(tester.getSize(tabSwitcher).width, lessThanOrEqualTo(420));

      // Sidebar composer
      final composer = find.byType(CommunityComposerCard);
      expect(composer, findsOneWidget);
      expect(tester.getSize(composer).width, lessThanOrEqualTo(320));

      // Sidebar discover card
      expect(find.text('Discover'), findsOneWidget);

      // Right column post card
      final postCard = find.byType(ProfilePostCard);
      expect(postCard, findsOneWidget);

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'tablet portrait: people tab uses the full tablet width',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      final authService = _CommunityAuthService();
      Get.put<AuthService>(authService);
      final controller = Get.put<CommunityController>(
        CommunityController(
          repository: _TabletCommunityRepository(authService),
          authService: authService,
          homeProvider: _CommunityHomeProvider(authService),
        ),
      );
      controller.section.value = CommunitySection.people;

      await tester.pumpWidget(buildApp(const CommunityPage()));
      await tester.pump(const Duration(milliseconds: 500));

      // Tab switcher constrained to 420
      final tabSwitcher = find.byType(CommunityTabSwitcher);
      expect(tabSwitcher, findsOneWidget);
      expect(tester.getSize(tabSwitcher).width, lessThanOrEqualTo(420));

      // People cards should use the available portrait tablet width.
      final personCard = find.byKey(const ValueKey<String>('people-card-10'));
      expect(personCard, findsOneWidget);
      expect(tester.getSize(personCard).width, greaterThan(620));

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
    },
  );
}

class _TabletCommunityRepository extends CommunityRepository {
  _TabletCommunityRepository(AuthService authService)
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
    FriendsView.friends: const [
      CommunityPerson(
        id: '10',
        name: 'Srey Leak',
        avatarUrl: '',
        detail: 'Battambang',
        mutualFriends: 3,
        connectionStatus: 'FRIEND',
      ),
    ],
    FriendsView.followers: const [],
    FriendsView.following: const [],
    FriendsView.addFriends: const [],
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
