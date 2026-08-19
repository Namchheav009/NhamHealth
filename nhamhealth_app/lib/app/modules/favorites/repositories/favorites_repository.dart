import '../models/favorite_food.dart';
import '../providers/favorites_provider.dart';

class FavoritesRepository {
  const FavoritesRepository({required this.provider});
  final FavoritesProvider provider;

  Future<List<FavoriteFood>> getFoods() => provider.getFoods();
  Future<List<String>> getFoodCategories() => provider.getFoodCategories();
  Future<void> addFood(int mealId) => provider.addFood(mealId);
  Future<void> removeFood(int mealId) => provider.removeFood(mealId);
}
