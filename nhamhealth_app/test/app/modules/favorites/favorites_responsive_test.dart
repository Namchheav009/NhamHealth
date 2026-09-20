import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/favorites/favorites_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/favorites/favorite_food.dart';
import 'package:nhamhealth_flutter/app/modules/models/recipes/community_recipe.dart';
import 'package:nhamhealth_flutter/app/modules/providers/favorites/favorites_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/favorites/favorites_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/favorites/favorites_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

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
          image: 'assets/images/meals/breakfast/bai-sach-chrouk.png',
          category: 'Breakfast',
        ),
      ];

  @override
  Future<List<String>> getFoodCategories() async => ['Breakfast', 'Lunch'];

  @override
  Future<List<CommunityRecipe>> getPosts() async => [
        const CommunityRecipe(
          id: 1,
          postId: 101,
          authorName: 'Chef Ron',
          authorAvatarUrl: '',
          name: 'Healthy Khmer Soup',
          description: 'Delicious morning soup recipe',
          status: 'APPROVED',
          ingredients: [],
          steps: [],
          tags: ['soup', 'breakfast'],
          imageUrl: '',
          difficulty: 'EASY',
          cookingTimeMinutes: 20,
          servings: 2,
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

  testWidgets(
    'renders centered constrained 2-column layout on tablet in portrait mode (like setting)',
    (tester) async {
      // 800 x 1280 tablet in portrait (standing upright)
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      final controller = FavoritesController(repository: _FakeFavoritesRepository());
      Get.put<FavoritesController>(controller);

      await tester.pumpWidget(createFavoritesApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify tablet portrait key is present
      expect(
        find.byKey(const ValueKey<String>('favorites-tablet-portrait')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('favorites-tablet-landscape')),
        findsNothing,
      );

      // Verify content is constrained to <= 600 width (matching setting)
      final contentWidget = find.byKey(
        const ValueKey<String>('favorites-tablet-portrait'),
      );
      final size = tester.getSize(contentWidget);
      expect(size.width, greaterThan(600.0));

      // Food grid should have 2 columns on tablet portrait
      expect(
        find.byKey(const ValueKey<String>('favorites-food-grid-2')),
        findsOneWidget,
      );

      // Food card should be rendered
      expect(find.text('Bai Sach Chrouk'), findsOneWidget);

      // Back button is present
      expect(
        find.byKey(const ValueKey<String>('favorites-back-button')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renders wide layout with 4-column food grid on tablet in landscape mode',
    (tester) async {
      // 1280 x 800 tablet in landscape
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.reset);

      final controller = FavoritesController(repository: _FakeFavoritesRepository());
      Get.put<FavoritesController>(controller);

      await tester.pumpWidget(createFavoritesApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify tablet landscape key is present
      expect(
        find.byKey(const ValueKey<String>('favorites-tablet-landscape')),
        findsOneWidget,
      );

      // Content can expand up to 960 width
      final contentWidget = find.byKey(
        const ValueKey<String>('favorites-tablet-landscape'),
      );
      final size = tester.getSize(contentWidget);
      expect(size.width, greaterThan(600.0));
      expect(size.width, lessThanOrEqualTo(960.0));

      // Food grid should have 4 columns on wide tablet landscape
      expect(
        find.byKey(const ValueKey<String>('favorites-food-grid-4')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders mobile layout on phone', (tester) async {
    // 390 x 844 smartphone
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final controller = FavoritesController(repository: _FakeFavoritesRepository());
    Get.put<FavoritesController>(controller);

    await tester.pumpWidget(createFavoritesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey<String>('favorites-mobile')),
      findsOneWidget,
    );

    // Food grid should have 2 columns on phone
    expect(
      find.byKey(const ValueKey<String>('favorites-food-grid-2')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('switches to posts tab and renders constrained list on tablet', (
    tester,
  ) async {
    // 800 x 1280 tablet
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1280);
    addTearDown(tester.view.reset);

    final controller = FavoritesController(repository: _FakeFavoritesRepository());
    Get.put<FavoritesController>(controller);

    await tester.pumpWidget(createFavoritesApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap the posts tab
    await tester.tap(find.text('Posts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey<String>('favorites-posts-list')),
      findsOneWidget,
    );
    expect(find.text('Healthy Khmer Soup'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
