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
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    final authService = _TestAuthService();
    Get.put<CommunityRepository>(_TestCommunityRepository(authService));
  });

  tearDown(Get.reset);

  void setDeviceDimensions(
    WidgetTester tester, {
    required double width,
    required double height,
  }) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.reset);
  }

  Widget createEditorApp({CommunityPost? post}) {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en'),
      home: CommunityPostEditorPage(
        post: post,
        authorName: 'Test Chef',
        authorAvatarUrl: '',
        onSubmit: (CommunityPostDraft _) async {},
      ),
    );
  }

  final samplePost = CommunityPost(
    id: '10',
    mealName: 'Khmer Fish Amok',
    cookingTimeMinutes: 45,
    servings: 2,
    categoryId: 1,
    difficulty: 'EASY',
    description: '',
    imageUrl: '',
    author: 'Chef',
    role: 'Member',
  );

  testWidgets(
    'Step 1 renders two-column layout on landscape tablet (1024x768)',
    (tester) async {
      setDeviceDimensions(tester, width: 1024, height: 768);

      await tester.pumpWidget(createEditorApp(post: samplePost));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-wide')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-single')),
        findsNothing,
      );
      expect(find.byType(CommunityPostEditorPage), findsOneWidget);
    },
  );

  testWidgets(
    'Step 1 renders centered single-column layout on Galaxy Tab portrait (800x1280)',
    (tester) async {
      setDeviceDimensions(tester, width: 800, height: 1280);

      await tester.pumpWidget(createEditorApp(post: samplePost));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-single')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-wide')),
        findsNothing,
      );

      final box = tester.firstWidget<ConstrainedBox>(
        find.ancestor(
          of: find.byKey(
            const ValueKey<String>('community-post-editor-step1-single'),
          ),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, greaterThan(600.0));
    },
  );

  testWidgets(
    'Step 1 renders centered single-column layout on iPad portrait (768x1024)',
    (tester) async {
      setDeviceDimensions(tester, width: 768, height: 1024);

      await tester.pumpWidget(createEditorApp(post: samplePost));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-single')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-wide')),
        findsNothing,
      );

      final box = tester.firstWidget<ConstrainedBox>(
        find.ancestor(
          of: find.byKey(
            const ValueKey<String>('community-post-editor-step1-single'),
          ),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, greaterThan(600.0));
    },
  );

  testWidgets(
    'Step 1 renders single-column layout on mobile phone (390x844)',
    (tester) async {
      setDeviceDimensions(tester, width: 390, height: 844);

      await tester.pumpWidget(createEditorApp(post: samplePost));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-single')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step1-wide')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Step 2 renders two-column layout on landscape tablet (1024x768)',
    (tester) async {
      setDeviceDimensions(tester, width: 1024, height: 768);

      await tester.pumpWidget(createEditorApp(post: samplePost));
      await tester.pumpAndSettle();

      // Tap continue to navigate to step 2
      final continueButton = find.byKey(
        const ValueKey<String>('community-navigation-button-0'),
      );
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step2-wide')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step2-single')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Step 2 renders centered single-column layout on Galaxy Tab portrait (800x1280)',
    (tester) async {
      setDeviceDimensions(tester, width: 800, height: 1280);

      await tester.pumpWidget(createEditorApp(post: samplePost));
      await tester.pumpAndSettle();

      // Tap continue to navigate to step 2
      final continueButton = find.byKey(
        const ValueKey<String>('community-navigation-button-0'),
      );
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step2-single')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('community-post-editor-step2-wide')),
        findsNothing,
      );

      final box = tester.firstWidget<ConstrainedBox>(
        find.ancestor(
          of: find.byKey(
            const ValueKey<String>('community-post-editor-step2-single'),
          ),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, greaterThan(600.0));
    },
  );
}

class _TestCommunityRepository extends CommunityRepository {
  _TestCommunityRepository(AuthService authService)
    : super(authService: authService);

  @override
  Future<List<CommunityTag>> getTags() async => const [
    CommunityTag(id: 1, name: 'High protein', scope: 'LIFESTYLE'),
    CommunityTag(id: 2, name: 'Under 30 min', scope: 'LIFESTYLE'),
  ];

  @override
  Future<List<MealCategoryModel>> getMealCategories() async => const [
    MealCategoryModel(id: 1, name: 'Main dishes'),
  ];

  @override
  Future<List<IngredientSuggestion>> searchIngredients(String query) async =>
      const [IngredientSuggestion(id: 1, name: 'Fish', defaultUnit: 'g')];
}

class _TestAuthService extends AuthService {}
