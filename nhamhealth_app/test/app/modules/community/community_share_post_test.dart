import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_share_actions.dart';
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

  testWidgets(
    'clicking write area requests focus on text field and displays FB style elements',
    (tester) async {
      final post = CommunityPost(
        id: '12',
        description: 'Healthy recipe to share',
        imageUrl: '',
        author: 'Chef Healthy',
        role: 'Nutritionist',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: CommunitySharePostPage(
            post: post,
            authorName: 'Visal Dev',
            authorAvatarUrl: '',
            onShare: (_, _) async {},
          ),
        ),
      );

      // Verify Facebook-style elements
      expect(find.text('Share to Feed'), findsOneWidget);
      expect(find.text('Visal Dev'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Add to your post'), findsOneWidget);
      expect(find.byType(CommunitySharedPostCard), findsOneWidget);

      // Verify clicking write area / label focuses the text field
      final textFieldFinder = find.byKey(
        const ValueKey<String>('community-share-message'),
      );
      expect(textFieldFinder, findsOneWidget);

      final TextField textFieldBefore = tester.widget(textFieldFinder);
      expect(textFieldBefore.focusNode?.hasFocus, isFalse);

      // Tap on the write area
      await tester.tap(
        find.byKey(const ValueKey<String>('community-share-write-area')),
      );
      await tester.pump();

      final TextField textFieldAfter = tester.widget(textFieldFinder);
      expect(textFieldAfter.focusNode?.hasFocus, isTrue);
    },
  );

  testWidgets(
    'showCommunityShareComposer displays FB modal on current page and submits',
    (tester) async {
      String? submittedMessage;
      CommunityPostVisibility? submittedVisibility;
      final post = CommunityPost(
        id: '15',
        description: 'Modal share post preview test',
        imageUrl: '',
        author: 'Tester Member',
        role: 'Member',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder:
                    (context) => ElevatedButton(
                      onPressed:
                          () => showCommunityShareComposer(
                            post: post,
                            authorName: 'Feed Sharer',
                            authorAvatarUrl: '',
                            onShare: (message, visibility) async {
                              submittedMessage = message;
                              submittedVisibility = visibility;
                            },
                          ),
                      child: const Text('Open Share Modal'),
                    ),
              ),
            ),
          ),
        ),
      );

      // Tap button to trigger modal on same page
      await tester.tap(find.text('Open Share Modal'));
      await tester.pumpAndSettle();

      // Verify modal elements are displayed on current page
      expect(find.text('Feed Sharer'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Share now'), findsOneWidget);
      expect(find.byType(CommunitySharedPostCard), findsNothing);

      // Tap write area to focus
      await tester.tap(
        find.byKey(const ValueKey<String>('community-share-write-area')),
      );
      await tester.pump();

      final textFieldFinder = find.byKey(
        const ValueKey<String>('community-share-message'),
      );
      final TextField textField = tester.widget(textFieldFinder);
      expect(textField.focusNode?.hasFocus, isTrue);

      // Enter text
      await tester.enterText(textFieldFinder, 'Shared via modal sheet');

      // Tap emoji button
      await tester.tap(
        find.byKey(const ValueKey<String>('community-share-emoji-button')),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('community-share-submit')),
      );
      await tester.pump();

      expect(submittedMessage, 'Shared via modal sheet😊');
      expect(submittedVisibility, CommunityPostVisibility.public);

      // Pump to settle bottom sheet dismissal and snackbar
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Modal is closed, back on the same page
      expect(find.text('Feed Sharer'), findsNothing);
      expect(find.text('Open Share Modal'), findsOneWidget);
    },
  );
}
