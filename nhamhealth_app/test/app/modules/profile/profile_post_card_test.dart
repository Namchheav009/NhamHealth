import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/config/api_config.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_shared_post_card.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/widgets/profile_post_card.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  for (final width in <double>[320, 381]) {
    testWidgets(
      'profile image carousel is constrained at ${width.toInt()} px',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ProfilePostCard(
                  post: CommunityPost(
                    id: '1',
                    description: 'A profile post with multiple images.',
                    imageUrl: '/uploads/profile-1.jpg',
                    imageUrls: const [
                      '/uploads/profile-1.jpg',
                      '/uploads/profile-2.jpg',
                    ],
                    author: 'Profile Member',
                    role: 'Member',
                  ),
                  authorName: 'Profile Member',
                  authorAvatarUrl: '',
                  membership: 'WellBite Member',
                  onEdit: _noop,
                  onDelete: _noop,
                  onLike: _noop,
                  onComment: _noop,
                  onShare: _noop,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final carousel = find.byType(PageView);
        expect(carousel, findsOneWidget);
        final carouselSize = tester.getSize(carousel);
        expect(carouselSize.height, carouselSize.width / (5 / 4));
        expect(carouselSize.height, lessThanOrEqualTo(360));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is NetworkImage &&
                (widget.image as NetworkImage).url ==
                    '${ApiConfig.baseUrl}/uploads/profile-1.jpg',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('profile renders the original post inside a feed share', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfilePostCard(
              post: CommunityPost(
                id: '2',
                description: '',
                imageUrl: '',
                author: 'Sharing member',
                role: 'Member',
                sharedPost: CommunitySharedPost(
                  id: '1',
                  authorId: 7,
                  author: 'Original member',
                  role: 'Member',
                  authorAvatarUrl: '',
                  description: 'Original healthy idea',
                  imageUrl: '',
                ),
              ),
              authorName: 'Sharing member',
              authorAvatarUrl: '',
              membership: 'WellBite Member',
              onEdit: _noop,
              onDelete: _noop,
              onLike: _noop,
              onComment: _noop,
              onShare: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CommunitySharedPostCard), findsOneWidget);
    expect(find.text('Original member'), findsOneWidget);
    expect(find.text('Original healthy idea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the like count opens the post likers action', (
    tester,
  ) async {
    var didRequestLikers = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePostCard(
            post: CommunityPost(
              id: '3',
              description: 'A liked community post.',
              imageUrl: '',
              author: 'Profile Member',
              role: 'Member',
              likes: 4,
            ),
            onLike: _noop,
            onShowLikes: () => didRequestLikers = true,
            onComment: _noop,
            onShare: _noop,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('post-likers-3')));

    expect(didRequestLikers, isTrue);
  });

  testWidgets('renders action metrics and header favorite button when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePostCard(
            post: CommunityPost(
              id: '4',
              description: 'A community post.',
              imageUrl: '',
              author: 'Profile Member',
              role: 'Member',
              isSaved: true,
            ),
            onLike: _noop,
            onComment: _noop,
            onShare: _noop,
            onFavorite: _noop,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  testWidgets('forwards shared post relationship, options, and tap actions to CommunitySharedPostCard', (
    tester,
  ) async {
    var didTapSharedRel = false;
    var didTapSharedOptions = false;
    var didTapSharedAuthor = false;
    var didTapSharedPost = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfilePostCard(
              post: CommunityPost(
                id: '20',
                description: 'Shared by user',
                imageUrl: '',
                author: 'Sharing user',
                role: 'Member',
                sharedPost: CommunitySharedPost(
                  id: '10',
                  authorId: 99,
                  author: 'Original creator',
                  role: 'Member',
                  authorAvatarUrl: '',
                  description: 'Original food post',
                  imageUrl: '',
                ),
              ),
              onLike: _noop,
              onComment: _noop,
              onShare: _noop,
              sharedRelationshipLabel: 'Friend',
              onSharedRelationshipTap: () => didTapSharedRel = true,
              onSharedOptions: () => didTapSharedOptions = true,
              onSharedAuthorTap: () => didTapSharedAuthor = true,
              onSharedPostTap: () => didTapSharedPost = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CommunitySharedPostCard), findsOneWidget);
    expect(find.text('Original creator'), findsOneWidget);
    expect(find.text('community.friend'.tr), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    await tester.tap(find.text('community.friend'.tr));
    await tester.pump();
    expect(didTapSharedRel, isTrue);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pump();
    expect(didTapSharedOptions, isTrue);

    await tester.tap(find.text('Original creator'));
    await tester.pump();
    expect(didTapSharedAuthor, isTrue);

    await tester.tap(find.text('Original food post'));
    await tester.pump();
    expect(didTapSharedPost, isTrue);
  });

  testWidgets('profile post options sheet shows Save to favorites and triggers onFavorite', (
    tester,
  ) async {
    var didTapFavorite = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: ProfilePostCard(
            post: CommunityPost(
              id: '10',
              description: 'Profile post description',
              imageUrl: '',
              author: 'Ron Namchheav',
              role: 'Member',
              isSaved: false,
            ),
            showFavoriteButton: false,
            onEdit: _noop,
            onDelete: _noop,
            onLike: _noop,
            onComment: _noop,
            onShare: _noop,
            onFavorite: () => didTapFavorite = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap more options
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Post options'), findsOneWidget);
    expect(find.text('Save to favorites'), findsOneWidget);
    expect(find.text('Edit post'), findsOneWidget);
    expect(find.text('Delete post'), findsOneWidget);

    await tester.tap(find.text('Save to favorites'));
    await tester.pumpAndSettle();

    expect(didTapFavorite, isTrue);
  });

  testWidgets('profile post options sheet shows Remove from favorites when already saved', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: ProfilePostCard(
            post: CommunityPost(
              id: '11',
              description: 'Saved profile post',
              imageUrl: '',
              author: 'Ron Namchheav',
              role: 'Member',
              isSaved: true,
            ),
            showFavoriteButton: false,
            onEdit: _noop,
            onDelete: _noop,
            onLike: _noop,
            onComment: _noop,
            onShare: _noop,
            onFavorite: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Post options'), findsOneWidget);
    expect(find.text('Remove from favorites'), findsOneWidget);
    expect(find.text('Edit post'), findsOneWidget);
    expect(find.text('Delete post'), findsOneWidget);
  });
}

void _noop() {}
