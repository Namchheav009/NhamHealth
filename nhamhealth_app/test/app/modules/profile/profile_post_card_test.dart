import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_shared_post_card.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/widgets/profile_post_card.dart';

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
                    imageUrl: 'https://example.invalid/profile-1.jpg',
                    imageUrls: const [
                      'https://example.invalid/profile-1.jpg',
                      'https://example.invalid/profile-2.jpg',
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
                sharedPost: const CommunitySharedPost(
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
}

void _noop() {}
