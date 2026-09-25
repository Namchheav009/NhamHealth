import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post_draft.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_tag.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/ingredient_suggestion.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_category_model.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_post_editor_page.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/app_alert.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    AppAlert.resetForTesting();
    Get.testMode = true;
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
    final authService = _ComposerAuthService();
    Get.put<CommunityRepository>(_ComposerRepository(authService));
  });

  tearDown(() {
    AppAlert.resetForTesting();
    Get.reset();
  });

  for (final dismissBeforeResponse in [false, true]) {
    testWidgets(
      'tag creation survives picker dismissal: $dismissBeforeResponse',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repository =
            Get.find<CommunityRepository>() as _ComposerRepository;
        repository.tagResult = Completer<CommunityTag>();
        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
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

        // Step 0 -> Step 1
        await tester.scrollUntilVisible(
          find.text('Continue to ingredients'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Continue to ingredients'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Continue to ingredients'));
        await tester.pumpAndSettle();

        // Step 1: Add Tag directly in the unified second step
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
        expect(find.text('#Fresh'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('community-add-tag')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
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
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    CommunityPostDraft? submitted;
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
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
    expect(find.text('Continue to ingredients'), findsWidgets);

    await tester.ensureVisible(find.text('Choose a category'));
    await tester.scrollUntilVisible(
      find.text('Choose a category'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Choose a category'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main dishes').last);
    await tester.pumpAndSettle();

    expect(find.text('New meal'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ex. Salad'),
      'Healthy lunch',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -260));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Ex. 40'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Ex. 40'), '30');
    await tester.enterText(find.widgetWithText(TextFormField, '1'), '2');
    await tester.ensureVisible(find.text('Continue to ingredients'));
    await tester.scrollUntilVisible(
      find.text('Continue to ingredients'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue to ingredients'));
    await tester.pumpAndSettle();

    // Step 2: Ingredients & How to Cook
    expect(find.text('Ingredients'), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('community-ingredient-search-input')),
      'Chicken',
    );
    await tester.enterText(
      find.byKey(const ValueKey('community-ingredient-amount-input')),
      '300',
    );
    await tester.tap(find.byKey(const ValueKey('community-add-ingredient')));
    await tester.pumpAndSettle();

    expect(find.text('How to Cook'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('community-new-cooking-step-input')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('community-new-cooking-step-input')),
      'Serve with fresh herbs.',
    );
    await tester.tap(find.byKey(const ValueKey('community-add-another-step')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('community-new-cooking-step-input')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('community-new-cooking-step-input')),
      'Prepare and cook the chicken.',
    );
    await tester.tap(find.byKey(const ValueKey('community-add-another-step')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post meal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Meal published'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('app-action-alert-confirm')),
    );
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.mealName, 'Healthy lunch');
    expect(submitted!.description, 'Healthy lunch');
    expect(submitted!.categoryId, 1);
    expect(submitted!.steps, hasLength(2));
    expect(submitted!.steps.first.instruction, 'Serve with fresh herbs.');
    expect(submitted!.steps.last.instruction, 'Prepare and cook the chicken.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing submits without a description', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    CommunityPostDraft? submitted;
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
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
    await tester.scrollUntilVisible(
      find.text('Continue to ingredients'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue to ingredients'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Meal updated'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('app-action-alert-confirm')),
    );
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.description, 'Original message');
    expect(submitted!.tagIds, const [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'submits a recipe with empty ingredients and empty cooking steps',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      CommunityPostDraft? submitted;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunityPostEditorPage(
            authorName: 'Nham Member',
            authorAvatarUrl: '',
            onSubmit: (draft) async => submitted = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Choose a category'));
      await tester.scrollUntilVisible(
        find.text('Choose a category'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Choose a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Main dishes').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Ex. Salad',
        ),
        'Simple Quick Meal',
      );
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Ex. 40'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Ex. 40'), '15');
      await tester.enterText(find.widgetWithText(TextFormField, '1'), '1');

      await tester.ensureVisible(find.text('Continue to ingredients'));
      await tester.scrollUntilVisible(
        find.text('Continue to ingredients'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Continue to ingredients'));
      await tester.pumpAndSettle();

      // Step 2: Ingredients & How to Cook - both optional, so post immediately
      expect(find.text('Ingredients'), findsWidgets);
      await tester.tap(find.text('Post meal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Meal published'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('app-action-alert-confirm')),
      );
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.mealName, 'Simple Quick Meal');
      expect(submitted!.ingredients, isEmpty);
      expect(submitted!.steps, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'users can post directly from Step 1 without inputting ingredients and cooking steps',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      CommunityPostDraft? submitted;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunityPostEditorPage(
            authorName: 'Nham Member',
            authorAvatarUrl: '',
            onSubmit: (draft) async => submitted = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Choose a category'));
      await tester.scrollUntilVisible(
        find.text('Choose a category'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Choose a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Main dishes').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex. Salad'),
        'Quick Breakfast Bowl',
      );
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Ex. 40'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Ex. 40'), '10');
      await tester.enterText(find.widgetWithText(TextFormField, '1'), '1');

      // Tapping the Post meal button directly on Step 1
      final postMealButton = find.byKey(
        const ValueKey<String>('community-continue-button-0'),
      );
      expect(postMealButton, findsOneWidget);
      await tester.tap(postMealButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Meal published'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('app-action-alert-confirm')),
      );
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.mealName, 'Quick Breakfast Bowl');
      expect(submitted!.ingredients, isEmpty);
      expect(submitted!.steps, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'users can add custom ingredients by themselves via suggestion and modal sheet',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      CommunityPostDraft? submitted;
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: CommunityPostEditorPage(
            authorName: 'Nham Member',
            authorAvatarUrl: '',
            onSubmit: (draft) async => submitted = draft,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Choose a category'));
      await tester.scrollUntilVisible(
        find.text('Choose a category'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Choose a category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Main dishes').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ex. Salad'),
        'Healthy Homemade Bowl',
      );
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Ex. 40'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Ex. 40'), '25');
      await tester.enterText(find.widgetWithText(TextFormField, '1'), '2');

      await tester.ensureVisible(find.text('Continue to ingredients'));
      await tester.scrollUntilVisible(
        find.text('Continue to ingredients'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Continue to ingredients'));
      await tester.pumpAndSettle();

      // 1. Add custom ingredient via inline search box custom suggestion
      await tester.enterText(
        find.byKey(const ValueKey('community-ingredient-search-input')),
        'Tofu',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Add "Tofu" as custom ingredient'), findsOneWidget);
      await tester.tap(find.text('Add "Tofu" as custom ingredient'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('community-ingredient-amount-input')),
        '150',
      );
      await tester.tap(find.byKey(const ValueKey('community-add-ingredient')));
      await tester.pumpAndSettle();

      expect(find.text('Tofu'), findsOneWidget);

      // 2. Add custom ingredient via modal sheet
      await tester.tap(
        find.byKey(const ValueKey('community-add-custom-ingredient-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add custom ingredient'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(TextFormField, 'e.g. Brown rice'),
        ),
        'Mushrooms',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(TextFormField, 'e.g. 200'),
        ),
        '100',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(FilledButton, 'Add'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mushrooms'), findsOneWidget);

      // Submit and verify
      await tester.tap(find.text('Post meal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Meal published'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey<String>('app-action-alert-confirm')),
      );
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.ingredients, hasLength(2));
      expect(submitted!.ingredients[0].ingredientName, 'Tofu');
      expect(submitted!.ingredients[0].amount, 150);
      expect(submitted!.ingredients[1].ingredientName, 'Mushrooms');
      expect(submitted!.ingredients[1].amount, 100);
      expect(tester.takeException(), isNull);
    },
  );
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
