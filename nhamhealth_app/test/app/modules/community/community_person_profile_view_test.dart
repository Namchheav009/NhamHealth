import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_person_profile.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_person_profile_view.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<CommunityRepository>(_ProfileRepository());
  });

  tearDown(Get.reset);

  testWidgets('other profile uses the compact public profile header', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(346, 600);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: '/community/people/7',
        getPages: [
          GetPage<void>(
            name: '/community/people/:userId',
            page: () => const CommunityPersonProfileView(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsNothing);
    expect(find.text('Smos os trim Bong'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget);
    expect(find.text('Joined September 2026'), findsOneWidget);
    expect(find.text('Enjoying homemade meals every day.'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNWidgets(2));
    expect(find.text('Posts'), findsNWidgets(2));
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsNWidgets(2));
    expect(find.text('Edit Profile'), findsNothing);
    expect(find.text("You're doing amazing!"), findsNothing);
    expect(find.text("What's on your healthy mind?"), findsNothing);
    expect(find.text('Photo'), findsNothing);
    expect(find.text('Ask community'), findsNothing);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile-tab-all')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('profile-tab-photos')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('other-profile-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('other-profile-avatar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('other-profile-identity')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('other-profile-stats')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('other-profile-follow-button')),
      findsOneWidget,
    );
    final followButtonSize = tester.getSize(
      find.byKey(const ValueKey<String>('other-profile-follow-button')),
    );
    expect(followButtonSize.width, greaterThan(172));
    expect(followButtonSize.height, 40);
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('other-profile-share-button')),
      ),
      const Size.square(40),
    );
    expect(
      find.byKey(const ValueKey<String>('other-profile-headline')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-tab-photos')),
    );
    await tester.pumpAndSettle();
    expect(find.text('No photos shared yet.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('other-profile-share-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share profile'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('More apps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _ProfileRepository extends CommunityRepository {
  _ProfileRepository() : super(authService: _ProfileAuthService());

  @override
  Future<CommunityPersonProfile> getPersonProfile(int userId) async =>
      const CommunityPersonProfile(
        id: 7,
        name: 'Smos os trim Bong',
        avatarUrl: '',
        role: 'USER',
        headline: 'Enjoying homemade meals every day.',
        joinedLabel: 'September 2026',
        verified: false,
        posts: 1,
        followers: 2,
        following: 2,
        isFollowing: true,
        followsViewer: false,
      );

  @override
  Future<List<CommunityPost>> getPersonPosts(int userId) async => const [];
}

class _ProfileAuthService extends AuthService {}
