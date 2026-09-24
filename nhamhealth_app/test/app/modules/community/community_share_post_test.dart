import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_share_actions.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_shared_post_card.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

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
        'mealName': 'Nom Banh Chok',
        'description': 'Original healthy idea',
        'imageUrl': '/posts/11.jpg',
        'imageUrls': ['/posts/11.jpg'],
        'ageLabel': '2h ago',
        'cookingTimeMinutes': 45,
        'servings': 2,
        'difficulty': 'MEDIUM',
        'tags': ['NomBanhChok', 'Yummy'],
        'ingredients': [
          {'name': 'Rice noodles', 'amount': 200, 'unit': 'g'},
        ],
        'steps': [
          {'stepNumber': 1, 'instruction': 'Cook noodles'},
        ],
      },
    });

    expect(post.sharedPost?.id, '11');
    expect(post.sharedPost?.author, 'Original member');
    expect(post.sharedPost?.mealName, 'Nom Banh Chok');
    expect(post.sharedPost?.description, 'Original healthy idea');
    expect(post.sharedPost?.imageUrls, ['/posts/11.jpg']);
    expect(post.sharedPost?.cookingTimeMinutes, 45);
    expect(post.sharedPost?.servings, 2);
    expect(post.sharedPost?.difficulty, 'MEDIUM');
    expect(post.sharedPost?.tags, ['NomBanhChok', 'Yummy']);
    expect(post.sharedPost?.hasRecipe, isTrue);
  });

  testWidgets(
    'shared post card displays original post pills, tags, and recipe button',
    (tester) async {
      final sharedPost = CommunitySharedPost(
        id: '11',
        authorId: 7,
        author: 'Smos os trim Bong',
        role: 'Member',
        authorAvatarUrl: '',
        mealName: 'នំបាញ់ឆុក',
        description: 'Tasty Khmer noodles',
        imageUrl: '',
        imageUrls: const [
          'https://example.com/meal1.jpg',
          'https://example.com/meal2.jpg',
        ],
        cookingTimeMinutes: 45,
        servings: 2,
        difficulty: 'MEDIUM',
        tags: const ['NomBanhChok', 'Yummy'],
        ingredients: const [
          MealPostIngredient(
            ingredientName: 'Rice noodles',
            amount: 200,
            unit: 'g',
          ),
        ],
        steps: const [
          MealPostStep(stepNumber: 1, instruction: 'Prepare fresh noodles'),
        ],
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunitySharedPostCard(post: sharedPost),
            ),
          ),
        ),
      );

      expect(find.text('Smos os trim Bong'), findsOneWidget);
      expect(find.text('Tasty Khmer noodles'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);
      expect(find.text('2 servings'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('#NomBanhChok'), findsOneWidget);
      expect(find.text('#Yummy'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('shared-view-full-recipe-button')),
        findsOneWidget,
      );
      expect(find.text('View Full Recipe'), findsOneWidget);
    },
  );

  testWidgets(
    'shared post card displays relationship label and options button and triggers callbacks',
    (tester) async {
      var didTapRel = false;
      var didTapOptions = false;
      var didTapAuthor = false;

      final sharedPost = CommunitySharedPost(
        id: '1',
        authorId: 7,
        author: 'Smos os trim Bong',
        role: 'Member',
        authorAvatarUrl: '',
        mealName: 'Nom Banh Chok',
        description: 'Tasty Khmer noodles',
        imageUrl: '',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunitySharedPostCard(
                post: sharedPost,
                relationshipLabel: 'Friend',
                onRelationshipTap: () => didTapRel = true,
                onOptions: () => didTapOptions = true,
                onAuthorTap: () => didTapAuthor = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Smos os trim Bong'), findsOneWidget);
      expect(find.text('Friend'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      await tester.tap(find.text('Friend'));
      await tester.pump();
      expect(didTapRel, isTrue);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pump();
      expect(didTapOptions, isTrue);

      await tester.tap(find.text('Smos os trim Bong'));
      await tester.pump();
      expect(didTapAuthor, isTrue);
    },
  );

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
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
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
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
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
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
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

  testWidgets(
    'showCommunityShareComposer supports editing an existing shared post',
    (tester) async {
      String? updatedMessage;
      CommunityPostVisibility? updatedVisibility;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showCommunityShareComposer(
                          authorName: 'Feed Sharer',
                          authorAvatarUrl: '',
                          initialMessage: 'Original share message',
                          initialVisibility: CommunityPostVisibility.friends,
                          isEditing: true,
                          submitButtonText: 'Save',
                          onShare: (message, visibility) async {
                            updatedMessage = message;
                            updatedVisibility = visibility;
                          },
                        );
                      },
                      child: const Text('Edit Share Modal'),
                    ),
                  ),
                ),
          ),
        ),
      );

      await tester.tap(find.text('Edit Share Modal'));
      await tester.pumpAndSettle();

      // Verify initial message, audience, and Save button
      expect(find.text('Original share message'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      final textFieldFinder = find.byKey(
        const ValueKey<String>('community-share-message'),
      );
      await tester.enterText(textFieldFinder, 'Updated share message');
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('community-share-submit')),
      );
      await tester.pump();

      expect(updatedMessage, 'Updated share message');
      expect(updatedVisibility, CommunityPostVisibility.friends);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(find.text('Edit Share Modal'), findsOneWidget);
    },
  );
}
