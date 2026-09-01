import '../../models/meals/meal_model.dart';
import '../../models/meals/meal_category_model.dart';
import '../../providers/meals/meal_provider.dart';

class MealRepository {
  MealRepository({required MealProvider provider}) : _provider = provider;

  final MealProvider _provider;

  Future<List<MealModel>> getMeals({String keyword = '', int categoryId = 0}) =>
      _provider.getMeals(keyword: keyword, categoryId: categoryId);
  Future<MealModel> getMealDetail(int mealId) =>
      _provider.getMealDetail(mealId);
  Future<List<MealCategoryModel>> getCategories() => _provider.getCategories();
  Future<List<MealModel>> getPersonalizedMealIdeas({bool refresh = false}) =>
      _provider.getPersonalizedMealIdeas(refresh: refresh);
  Future<Set<int>> getFavoriteMealIds() => _provider.getFavoriteMealIds();
  Future<int> getUnreadNotificationCount() =>
      _provider.getUnreadNotificationCount();
  Future<void> setFavorite(int mealId, {required bool favorite}) =>
      _provider.setFavorite(mealId, favorite: favorite);
}
