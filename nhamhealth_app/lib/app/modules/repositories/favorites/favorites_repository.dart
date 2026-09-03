import '../../models/favorites/favorite_food.dart';
import '../../models/recipes/community_recipe.dart';
import '../../providers/favorites/favorites_provider.dart';

class FavoritesRepository {
  const FavoritesRepository({required this.provider});
  final FavoritesProvider provider;

  Future<List<FavoriteFood>> getFoods() => provider.getFoods();
  Future<List<String>> getFoodCategories() => provider.getFoodCategories();
  Future<void> addFood(int mealId) => provider.addFood(mealId);
  Future<void> removeFood(int mealId) => provider.removeFood(mealId);
  Future<List<CommunityRecipe>> getPosts() => provider.getPosts();
  Future<void> removePost(int recipeId) => provider.removePost(recipeId);
}
