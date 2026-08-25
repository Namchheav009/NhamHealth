import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_share_post_page.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_shared_post_card.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('community post decodes the original post inside a feed share', () {
    final post = CommunityPost.fromJson({
      'id': 22,
      'description': 'This helped me today.',
      'imageUrl': '',
      'author': 'Sharing member',
      'sharedPost': {
        'id': 11,
        'authorId': 7,
        'author': 'Original member',
        'role': 'Member',
        'authorAvatarUrl': '/avatars/7.jpg',
        'description': 'Original healthy idea',
        'imageUrl': '/posts/11.jpg',
        'imageUrls': ['/posts/11.jpg'],
        'ageLabel': '2h ago',
      },
    });

    expect(post.sharedPost?.id, '11');
    expect(post.sharedPost?.author, 'Original member');
    expect(post.sharedPost?.description, 'Original healthy idea');
    expect(post.sharedPost?.imageUrls, ['/posts/11.jpg']);
  });

  testWidgets('share composer previews the original and submits a message', (
    tester,
  ) async {
    String? submittedMessage;
    CommunityPostVisibility? submittedVisibility;
    final post = CommunityPost(
      id: '11',
      description: 'Original healthy breakfast idea',
      imageUrl: '',
      author: 'Original member',
      role: 'Member',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: CommunitySharePostPage(
          post: post,
          authorName: 'Sharing member',
          authorAvatarUrl: '',
          onShare: (message, visibility) async {
            submittedMessage = message;
            submittedVisibility = visibility;
          },
        ),
      ),
    );

    expect(find.byType(CommunitySharedPostCard), findsOneWidget);
    expect(find.text('Original healthy breakfast idea'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('community-share-message')),
      'Worth trying this week',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Share'));
    await tester.pump();

    expect(submittedMessage, 'Worth trying this week');
    expect(submittedVisibility, CommunityPostVisibility.public);

    // Let GetX's success snackbar finish before the test disposes its overlay.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
