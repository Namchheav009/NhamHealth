import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_comment.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_comments_page.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    final authService = _CommentsAuthService();
    Get.put<CommunityRepository>(_CommentsRepository(authService));
  });
  tearDown(Get.reset);

  testWidgets('shows the post while comments are still loading', (
    tester,
  ) async {
    final repository = _SlowCommentsRepository(_CommentsAuthService());
    Get.replace<CommunityRepository>(repository);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: CommunityCommentsPage(
          post: CommunityPost(
            id: 'post-42',
            description: 'The notification post is visible immediately.',
            imageUrl: '',
            author: 'Nham Member',
            role: 'Member',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('The notification post is visible immediately.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('full recipe opens from the comments post card', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: CommunityCommentsPage(
          post: CommunityPost(
            id: 'recipe-1',
            description: 'A healthy recipe.',
            imageUrl: '',
            author: 'Nham Member',
            role: 'Member',
            ingredients: const [
              MealPostIngredient(
                ingredientName: 'Fish',
                amount: 500,
                unit: 'g',
              ),
            ],
            steps: const [
              MealPostStep(stepNumber: 1, instruction: 'Steam the fish.'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Full Recipe'), findsOneWidget);
    expect(find.text('Fish'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('view-full-recipe-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recipe details'), findsOneWidget);
    expect(find.text('Fish'), findsOneWidget);
    expect(find.text('Steam the fish.'), findsOneWidget);
  });

  testWidgets('own post options does not show save to favorite', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: CommunityCommentsPage(
          canEdit: true,
          onEditPost:
              (draft) async => CommunityPost(
                id: 'own-1',
                description: draft.description,
                imageUrl: '',
                author: 'Me',
                role: 'Member',
              ),
          post: CommunityPost(
            id: 'own-1',
            description: 'My own recipe post.',
            imageUrl: '',
            author: 'Me',
            role: 'Member',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap more options button
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Post options'), findsOneWidget);
    expect(find.text('Save to favorites'), findsNothing);
    expect(find.text('Edit post'), findsOneWidget);
    expect(find.text('Delete post'), findsOneWidget);
  });

  testWidgets('other user post options shows save to favorite', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: CommunityCommentsPage(
          canEdit: false,
          post: CommunityPost(
            id: 'other-1',
            description: 'Other person recipe post.',
            imageUrl: '',
            author: 'Other Person',
            role: 'Member',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap more options button
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('More options'), findsOneWidget);
    expect(find.text('Save to favorites'), findsOneWidget);
    expect(find.text('Report post'), findsOneWidget);
    expect(find.text('Edit post'), findsNothing);
    expect(find.text('Delete post'), findsNothing);
  });
}

class _CommentsRepository extends CommunityRepository {
  _CommentsRepository(AuthService authService)
    : super(authService: authService);

  @override
  Future<List<CommunityComment>> getComments(String postId) async => const [];
}

class _SlowCommentsRepository extends CommunityRepository {
  _SlowCommentsRepository(AuthService authService)
    : super(authService: authService);

  final _comments = Completer<List<CommunityComment>>();

  @override
  Future<List<CommunityComment>> getComments(String postId) => _comments.future;

  void complete() => _comments.complete(const []);
}

class _CommentsAuthService extends AuthService {}
