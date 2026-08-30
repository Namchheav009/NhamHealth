import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_tag.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_post_editor_page.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post_draft.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    final authService = _ComposerAuthService();
    Get.put<CommunityRepository>(_ComposerRepository(authService));
  });

  tearDown(Get.reset);

  testWidgets('new meal composer validates and submits a recipe', (
    tester,
  ) async {
    CommunityPostDraft? submitted;
    await tester.pumpWidget(
      GetMaterialApp(
        home: CommunityPostEditorPage(
          authorName: 'Nham Member',
          authorAvatarUrl: '',
          onSubmit: (draft) async => submitted = draft,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Create Meal'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Khmer Fish Amok'),
      'Healthy lunch',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tell people about this meal'),
      'Today I prepared a healthy lunch.',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, '45'), '30');
    await tester.enterText(find.widgetWithText(TextFormField, '2'), '2');
    await tester.ensureVisible(find.text('Next: Ingredients'));
    await tester.tap(find.text('Next: Ingredients'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredients & Steps'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Search ingredient'),
      'Chicken',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '300');
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Describe this cooking step'),
      'Prepare and cook the chicken.',
    );
    await tester.ensureVisible(find.text('Publish Meal'));
    await tester.tap(find.text('Publish Meal'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.mealName, 'Healthy lunch');
    expect(submitted!.description, 'Today I prepared a healthy lunch.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing submits the existing message', (tester) async {
    CommunityPostDraft? submitted;
    await tester.pumpWidget(
      GetMaterialApp(
        home: CommunityPostEditorPage(
          post: CommunityPost(
            id: '7',
            description: 'Original message',
            mealName: 'Original meal',
            cookingTimeMinutes: 20,
            servings: 2,
            difficulty: 'EASY',
            ingredients: const [
              MealPostIngredient(
                ingredientName: 'Fish',
                amount: 200,
                unit: 'g',
              ),
            ],
            steps: const [
              MealPostStep(stepNumber: 1, instruction: 'Cook the fish.'),
            ],
            imageUrl: '',
            author: 'Nham Member',
            role: 'Member',
          ),
          authorName: 'Nham Member',
          authorAvatarUrl: '',
          onSubmit: (draft) async => submitted = draft,
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.description, 'Original message');
    expect(tester.takeException(), isNull);
  });
}

class _ComposerRepository extends CommunityRepository {
  _ComposerRepository(AuthService authService)
    : super(authService: authService);

  @override
  Future<List<CommunityTag>> getTags() async => const [];
}

class _ComposerAuthService extends AuthService {}
