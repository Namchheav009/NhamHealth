import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/favorite_removal_confirmation.dart';

import '../home/home_controller.dart';
import '../../models/favorites/favorite_food.dart';
import '../../models/favorites/favorite_post.dart';
import '../../repositories/favorites/favorites_repository.dart';

enum FavoritesTab { foods, posts }

enum FavoritePostSort { newest, oldest }

class FavoritesController extends GetxController {
  FavoritesController({required this.repository});

  final FavoritesRepository repository;
  final selectedTab = FavoritesTab.foods.obs;
  final hiddenPostIds = <int>{}.obs;
  final selectedFoodCategories = <String>{}.obs;
  final postSort = FavoritePostSort.newest.obs;
  final foods = <FavoriteFood>[].obs;
  final foodCategories = <String>['All'].obs;
  final isLoading = false.obs;

  final posts = const <FavoritePost>[
    FavoritePost(
      id: 1,
      author: 'Sophia Martinez',
      role: 'Nutritionist',
      timeAgo: '2h ago',
      title: 'Healthy breakfast idea!',
      body:
          'Avocado toast with poached egg and fresh fruits.\nSimple, quick and nutritious!',
      image: 'assets/images/meals/healthy_salad.jpg',
      likes: 1000,
      comments: 200,
      shares: 10,
    ),
    FavoritePost(
      id: 2,
      author: 'Sophia Martinez',
      role: 'Nutritionist',
      timeAgo: '6h ago',
      title: 'A colorful snack for today!',
      body:
          'Fresh fruit is an easy way to add more fiber and vitamins to your day.',
      image: 'assets/images/homepage/healthy_salad.png',
      likes: 824,
      comments: 96,
      shares: 18,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    loadFoods();
    loadFoodCategories();
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

  void selectTab(FavoritesTab tab) => selectedTab.value = tab;
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

  void removePost(int id) => hiddenPostIds.add(id);
}
