import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/meals/meal_model.dart';
import 'package:nhamhealth_flutter/app/modules/views/meals/widgets/meal_card.dart';
import 'package:nhamhealth_flutter/app/modules/views/meals/widgets/meal_idea_card.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/widgets/app_search_bar.dart';

void main() {
  const fallbackImage = 'assets/images/meals/healthy_salad.jpg';

  MealModel meal({bool favorite = false, String recommendationReason = ''}) =>
      MealModel(
        id: 7,
        name: 'High Protein Salad',
        calories: 380,
        image: fallbackImage,
        category: 'High Protein',
        categoryId: 2,
        proteinGrams: 32,
        cookingTimeMinutes: 15,
        difficulty: 'Easy',
        recommendationReason: recommendationReason,
        isFavorite: favorite,
      );

  Widget app(Widget child) => GetMaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('popular meal card fits the readable phone card width', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 160,
          height: 232,
          child: MealCard(meal: meal(), onTap: () {}, onFavorite: () {}),
        ),
      ),
    );

    expect(find.text('High Protein Salad'), findsOneWidget);
    expect(find.text('High Protein'), findsOneWidget);
    expect(find.text('380 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('idea card shows recommendation metadata and favorite action', (
    tester,
  ) async {
    var favoriteTaps = 0;
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 341,
          child: MealIdeaCard(
            meal: meal(),
            onTap: () {},
            onFavorite: () => favoriteTaps++,
          ),
        ),
      ),
    );

    expect(find.text('High Protein Salad'), findsOneWidget);
    expect(find.text('Easy  •  High Protein  •  Healthy'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    expect(favoriteTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI recommendation reason fits the idea card', (tester) async {
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 341,
          child: MealIdeaCard(
            meal: meal(
              recommendationReason:
                  'Selected using your saved height, weight, BMI, activity and remaining protein goal.',
            ),
            onTap: () {},
            onFavorite: () {},
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Selected using your saved height'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared search uses the standard page size', (tester) async {
    await tester.pumpWidget(
      app(
        const SizedBox(
          width: 341,
          child: AppSearchBar(hintText: 'Search meals and healthy ideas'),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppSearchBar)).height, 56);
    expect(find.text('Search meals and healthy ideas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared search accepts a filter action', (tester) async {
    await tester.pumpWidget(
      app(
        SizedBox(
          width: 341,
          child: AppSearchBar(
            hintText: 'Search meals',
            trailing: IconButton(
              key: const ValueKey<String>('test-filter'),
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('test-filter')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('recommended meal response maps AI reason and API image', () {
    final result = MealModel.fromRecommendationJson({
      'id': 12,
      'name': 'Balanced Bowl',
      'imageUrl': '/uploads/bowl.jpg',
      'calories': 420,
      'proteinGrams': 28,
      'cookingTimeMinutes': 25,
      'reason': 'Fits the saved BMI context and remaining protein goal.',
    }, baseUrl: 'http://localhost:8080');

    expect(result.image, 'http://localhost:8080/uploads/bowl.jpg');
    expect(result.cookingTimeMinutes, 25);
    expect(result.proteinGrams, 28);
    expect(result.recommendationReason, contains('BMI'));
  });
}
