import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_tag.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/ingredient_suggestion.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_post_editor_page.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post_draft.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_category_model.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    final authService = _ComposerAuthService();
    Get.put<CommunityRepository>(_ComposerRepository(authService));
  });

  tearDown(Get.reset);

  for (final dismissBeforeResponse in [false, true]) {
    testWidgets(
      'tag creation survives picker dismissal: $dismissBeforeResponse',
      (tester) async {
        final repository =
            Get.find<CommunityRepository>() as _ComposerRepository;
        repository.tagResult = Completer<CommunityTag>();
        await tester.pumpWidget(
          GetMaterialApp(
            home: CommunityPostEditorPage(
              post: CommunityPost(
                id: '7',
                mealName: 'Fish',
                cookingTimeMinutes: 20,
                servings: 2,
                categoryId: 1,
                description: '',
                imageUrl: '',
                author: 'Member',
                role: 'Member',
              ),
              authorName: 'Member',
              authorAvatarUrl: '',
              onSubmit: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Continue to ingredients'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Continue to ingredients'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('community-add-tag')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const ValueKey('community-add-tag')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Search tags'),
          'Fresh',
        );
        await tester.pump();
        await tester.tap(find.text('Create "Fresh"'));
        await tester.pump();
        if (dismissBeforeResponse) {
          await tester.tap(find.text('Done'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        repository.tagResult!.complete(
          const CommunityTag(id: 4, name: 'Fresh', scope: 'LIFESTYLE'),
        );
        await tester.pumpAndSettle();
        if (!dismissBeforeResponse) {
          await tester.tap(find.text('Done (1)'));
          await tester.pumpAndSettle();
        }
        expect(find.widgetWithText(FilterChip, 'Fresh'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('community-add-tag')));
        await tester.pumpAndSettle();
        expect(find.text('Create "Fresh"'), findsNothing);
        await tester.tap(find.text('Done (1)'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

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
    await tester.pumpAndSettle();

    expect(find.text('New meal'), findsOneWidget);
    expect(find.text('Add a cover photo'), findsOneWidget);
    expect(tester.getSize(find.byType(Form)).height, greaterThan(0));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('community-post-editor-scroll-0')),
        matching: find.text('Continue to ingredients'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Choose a category'));
    await tester.tap(find.text('Choose a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main dishes').last);
    await tester.pumpAndSettle();

    expect(find.text('Create Meal'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Khmer Fish Amok'),
      'Healthy lunch',
    );
    expect(find.text('Description'), findsNothing);
    expect(
      find.widgetWithText(TextFormField, 'Tell people about this meal'),
      findsNothing,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, '45'), '30');
    await tester.enterText(find.widgetWithText(TextFormField, '2'), '2');
    await tester.ensureVisible(find.text('Continue to ingredients'));
    await tester.tap(find.text('Continue to ingredients'));
    await tester.pumpAndSettle();
    expect(find.text('Ingredients & Steps'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Search ingredient'),
      'Chicken',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '300');
    await tester.tap(find.byKey(const ValueKey('community-add-ingredient')));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('community-new-cooking-step')),
      'Prepare and cook the chicken.',
    );
    await tester.tap(find.byKey(const ValueKey('community-add-cooking-step')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('community-new-cooking-step')),
      'Serve with fresh herbs.',
    );
    await tester.tap(find.byKey(const ValueKey('community-add-cooking-step')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('community-step-up-1')));
    await tester.pump();
    await tester.ensureVisible(find.text('Publish Meal'));
    await tester.tap(find.text('Publish Meal'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.mealName, 'Healthy lunch');
    expect(submitted!.description, isEmpty);
    expect(submitted!.categoryId, 1);
    expect(submitted!.steps, hasLength(2));
    expect(submitted!.steps.first.instruction, 'Serve with fresh herbs.');
    expect(submitted!.steps.last.instruction, 'Prepare and cook the chicken.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing submits without a description', (tester) async {
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
            categoryId: 1,
            tagIds: const [1],
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
    await tester.pumpAndSettle();

    expect(find.text('Edit meal'), findsOneWidget);
    expect(find.text('Basic Info'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue to ingredients'));
    await tester.tap(find.text('Continue to ingredients'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.description, isEmpty);
    expect(submitted!.tagIds, const [1]);
    expect(tester.takeException(), isNull);
  });
}

class _ComposerRepository extends CommunityRepository {
  Completer<CommunityTag>? tagResult;

  @override
  Future<CommunityTag> createTag(String name) => tagResult!.future;

  _ComposerRepository(AuthService authService)
    : super(authService: authService);

  @override
  Future<List<CommunityTag>> getTags() async => const [
    CommunityTag(id: 1, name: 'High protein', scope: 'LIFESTYLE'),
    CommunityTag(id: 2, name: 'Under 30 min', scope: 'LIFESTYLE'),
    CommunityTag(id: 3, name: 'Khmer', scope: 'CUISINE'),
  ];

  @override
  Future<List<MealCategoryModel>> getMealCategories() async => const [
    MealCategoryModel(id: 1, name: 'Main dishes'),
  ];

  @override
  Future<List<IngredientSuggestion>> searchIngredients(String query) async =>
      const [IngredientSuggestion(id: 1, name: 'Chicken', defaultUnit: 'g')];
}

class _ComposerAuthService extends AuthService {}
