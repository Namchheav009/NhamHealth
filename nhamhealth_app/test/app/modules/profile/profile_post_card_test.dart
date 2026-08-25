import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/widgets/profile_post_card.dart';

void main() {
  for (final width in <double>[320, 381]) {
    testWidgets('profile image carousel is constrained at ${width.toInt()} px', (
      tester,
    ) async {
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
                  title: 'Profile update',
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
      expect(tester.getSize(carousel).height, 218);
      expect(tester.takeException(), isNull);
    });
  }
}

void _noop() {}
