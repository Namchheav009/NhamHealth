import '../../models/meals/meal_model.dart';
import '../../models/meals/meal_category_model.dart';
import '../../providers/meals/meal_provider.dart';

class MealRepository {
  MealRepository({required MealProvider provider}) : _provider = provider;

  final MealProvider _provider;

  Future<List<MealModel>> getMeals() => _provider.getMeals();
  Future<List<MealCategoryModel>> getCategories() => _provider.getCategories();
  Future<Set<int>> getFavoriteMealIds() => _provider.getFavoriteMealIds();
  Future<int> getUnreadNotificationCount() =>
      _provider.getUnreadNotificationCount();
  Future<void> setFavorite(int mealId, {required bool favorite}) =>
      _provider.setFavorite(mealId, favorite: favorite);
}
