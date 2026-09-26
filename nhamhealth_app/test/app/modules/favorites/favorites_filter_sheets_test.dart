import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/favorites/favorites_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/favorites/favorite_food.dart';
import 'package:nhamhealth_flutter/app/modules/models/recipes/community_recipe.dart';
import 'package:nhamhealth_flutter/app/modules/providers/favorites/favorites_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/favorites/favorites_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/favorites/favorites_view.dart';
import 'package:nhamhealth_flutter/app/modules/views/favorites/widgets/food_filter_sheet.dart';
import 'package:nhamhealth_flutter/app/modules/views/favorites/widgets/post_filter_sheet.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

import 'package:nhamhealth_flutter/app/modules/views/favorites/saved_posts_view.dart';

class _FakeFavoritesRepository implements FavoritesRepository {
  _FakeFavoritesRepository();

  @override
  FavoritesProvider get provider => throw UnimplementedError();

  @override
  Future<List<FavoriteFood>> getFoods() async => [
        const FavoriteFood(
          id: 1,
          name: 'Bai Sach Chrouk',
          calories: 1108,
          image: '',
          category: 'Breakfast',
        ),
      ];

  @override
  Future<List<String>> getFoodCategories() async => ['Breakfast', 'Lunch'];

  @override
  Future<List<CommunityRecipe>> getPosts() async => [
        CommunityRecipe(
          id: 1,
          postId: 101,
          authorName: 'Chef Ron',
          authorAvatarUrl: '',
          name: 'Healthy Khmer Soup',
          description: 'Delicious morning soup recipe',
          status: 'APPROVED',
          ingredients: const [],
          steps: const [],
          tags: const ['soup', 'breakfast'],
          imageUrl: '',
          difficulty: 'EASY',
          cookingTimeMinutes: 20,
          servings: 2,
          publishedAt: DateTime.now(),
        ),
      ];

  @override
  Future<void> addFood(int mealId) async {}

  @override
  Future<void> removeFood(int mealId) async {}

  @override
  Future<void> removePost(int recipeId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Widget createFavoritesApp() {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: const FavoritesView(),
    );
  }

  Widget createSavedPostsApp() {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: const SavedPostsView(),
    );
  }

  testWidgets(
    'tapping food filter opens FoodFilterSheet as bottom sheet',
    (tester) async {
      final controller = FavoritesController(repository: _FakeFavoritesRepository());
      Get.put<FavoritesController>(controller);

      await tester.pumpWidget(createFavoritesApp());
      await tester.pumpAndSettle();

      // Tap filter button on foods tab
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      // FoodFilterSheet should be open
      expect(find.byType(FoodFilterSheet), findsOneWidget);
      expect(find.text('Filter by category'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Apply Filter'), findsOneWidget);

      // Tap Apply filter button to dismiss
      await tester.tap(find.text('Apply Filter'));
      await tester.pumpAndSettle();

      expect(find.byType(FoodFilterSheet), findsNothing);
    },
  );

  testWidgets(
    'tapping post filter opens PostFilterSheet from bottom with Filter by time',
    (tester) async {
      final controller = FavoritesController(repository: _FakeFavoritesRepository());
      Get.put<FavoritesController>(controller);

      await tester.pumpWidget(createSavedPostsApp());
      await tester.pumpAndSettle();

      // Tap Filter button
      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      // PostFilterSheet should be open as modal bottom sheet
      expect(find.byType(PostFilterSheet), findsOneWidget);
      expect(find.text('Filter by time'), findsOneWidget);
      expect(find.text('Newest'), findsOneWidget);
      expect(find.text('Oldest'), findsOneWidget);

      // Select Oldest
      await tester.tap(find.text('Oldest'));
      await tester.pumpAndSettle();

      // Apply
      await tester.tap(find.text('Apply Filter'));
      await tester.pumpAndSettle();

      expect(find.byType(PostFilterSheet), findsNothing);
      expect(controller.postSort.value, equals(FavoritePostSort.oldest));
    },
  );

  testWidgets(
    'tapping post card more options opens remove alert from under',
    (tester) async {
      final controller = FavoritesController(repository: _FakeFavoritesRepository());
      Get.put<FavoritesController>(controller);

      await tester.pumpWidget(createSavedPostsApp());
      await tester.pumpAndSettle();

      // Tap the three dots on the post card
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      // Removal confirmation bottom sheet should open from under
      expect(find.text('Remove from favorites'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Post should still exist
      expect(controller.posts.length, equals(1));

      // Tap again and tap Remove
      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Post should be removed
      expect(controller.posts.isEmpty, isTrue);
    },
  );
}

