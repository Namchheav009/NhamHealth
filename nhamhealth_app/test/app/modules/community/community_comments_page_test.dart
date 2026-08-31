import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_comment.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_comments_page.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    final authService = _CommentsAuthService();
    Get.put<CommunityRepository>(_CommentsRepository(authService));
  });
  tearDown(Get.reset);

  testWidgets('recipe details can be hidden and shown again', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
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

    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Fish'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('recipe-details-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Show all'), findsOneWidget);
    expect(find.text('Fish'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('recipe-details-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Fish'), findsOneWidget);
  });
}

class _CommentsRepository extends CommunityRepository {
  _CommentsRepository(AuthService authService) : super(authService: authService);

  @override
  Future<List<CommunityComment>> getComments(String postId) async => const [];
}

class _CommentsAuthService extends AuthService {}
