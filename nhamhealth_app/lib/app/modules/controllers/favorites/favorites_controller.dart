import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/favorite_removal_confirmation.dart';

import '../home/home_controller.dart';
import '../../models/favorites/favorite_food.dart';
import '../../models/recipes/community_recipe.dart';
import '../../repositories/favorites/favorites_repository.dart';

enum FavoritesTab { foods, posts }

enum FavoritePostSort { newest, oldest }

class FavoritesController extends GetxController {
  FavoritesController({required this.repository});

  final FavoritesRepository repository;
  final selectedTab = FavoritesTab.foods.obs;
  final selectedFoodCategories = <String>{}.obs;
  final postSort = FavoritePostSort.newest.obs;
  final foods = <FavoriteFood>[].obs;
  final foodCategories = <String>['All'].obs;
  final isLoading = false.obs;

  final posts = <CommunityRecipe>[].obs;
  final isPostsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadFoods();
    loadFoodCategories();
    loadPosts();
  }

  Future<void> loadFoods() async {
    try {
      isLoading.value = true;
      foods.assignAll(await repository.getFoods());
    } on Object catch (error) {
      AppAlert.error(title: 'Favorites unavailable', message: error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFoodCategories() async {
    try {
      final categories = await repository.getFoodCategories();
      foodCategories.assignAll(['All', ...categories.toSet()]);
      selectedFoodCategories.removeWhere(
        (category) => !foodCategories.contains(category),
      );
    } on Object {
      // The default "All" filter remains usable if categories cannot load.
      foodCategories.assignAll(const ['All']);
      selectedFoodCategories.clear();
    }
  }

  Future<void> loadPosts() async {
    if (isPostsLoading.value) return;
    isPostsLoading.value = true;
    try {
      posts.assignAll(await repository.getPosts());
    } on Object catch (error) {
      AppAlert.error(title: 'Favorites unavailable', message: error.toString());
    } finally {
      isPostsLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await Future.wait([loadFoods(), loadFoodCategories(), loadPosts()]);
  }

  void selectTab(FavoritesTab tab) {
    selectedTab.value = tab;
    if (tab == FavoritesTab.posts && posts.isEmpty) loadPosts();
  }

  void applyFoodCategories(Set<String> categories) {
    selectedFoodCategories.assignAll(categories.where(foodCategories.contains));
  }

  void setPostSort(FavoritePostSort sort) => postSort.value = sort;
  Future<void> removeFood(int id) async {
    final index = foods.indexWhere((food) => food.id == id);
    if (index < 0) return;
    if (!await confirmFavoriteRemoval()) return;

    final removed = foods.removeAt(index);
    try {
      await repository.removeFood(id);
      // The Home screen remains in the navigation stack. Update its local
      // favorite IDs so its heart is immediately ready to add this meal again.
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().setMealFavoriteState(id, favorite: false);
      }
    } on Object catch (error) {
      foods.insert(index, removed);
      AppAlert.error(title: 'Favorite not removed', message: error.toString());
    }
  }

  Future<void> removePost(int id) async {
    final index = posts.indexWhere((post) => post.id == id);
    if (index < 0 || !await confirmFavoriteRemoval()) return;
    final removed = posts.removeAt(index);
    try {
      await repository.removePost(id);
    } on Object catch (error) {
      posts.insert(index, removed);
      AppAlert.error(title: 'Favorite not removed', message: error.toString());
    }
  }
}
